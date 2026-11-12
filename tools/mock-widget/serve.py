#!/usr/bin/env python3
"""local mock of the limechat web widget page + /widget_config. python3 stdlib only.

usage: python3 tools/mock-widget/serve.py [--port 8787] [--transcript out.log]
"""
import argparse, datetime, itertools, json, os, socket, struct, threading, zlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

HERE = os.path.dirname(os.path.abspath(__file__))
LOCK = threading.Lock()
TOKENS = itertools.count(1)
TRANSCRIPT = None


def make_icon_png(size=64, rgb=(50, 205, 50)):
    """solid green square, so the launcher shows something recognisable."""
    row = b"\x00" + bytes(rgb) * size
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(row * size)) + chunk(b"IEND", b"")


ICON = make_icon_png()


def log_line(kind, detail):
    ts = datetime.datetime.now().isoformat(timespec="milliseconds")
    line = f"{ts} {kind} {json.dumps(detail, sort_keys=True, ensure_ascii=False)}"
    with LOCK:
        print(line, flush=True)
        if TRANSCRIPT:
            with open(TRANSCRIPT, "a", encoding="utf-8") as f:
                f.write(line + "\n")


def widget_config(host, token):
    # same shape as WidgetConfigController#index. `config` is the configsetting
    # jsonb column, which holds a json *string* (sdk.js JSON.parses it).
    cfg = {} if token == "noicon" else {
        "widgetIconMobile": f"http://{host}/icon.png",
        "widgetIconDesktop": f"http://{host}/icon.png",
    }
    return {
        "widget_color": "#32cd32",
        "homepopupsettingOptions": {},
        "closewidgetpopupsettingOptions": {},
        "popup_configs": [],
        "popup_message_enabled": False,
        "disappear_on_scrolling": False,
        "config": json.dumps(cfg),
        "utm_for_widget": False,
        "hide_widget_icon": False,
        "pre_chat_form_enabled": False,
        "pre_chat_fields": [],
        "enabled_features": [],
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):  # silence default access log, we print our own
        pass

    def send(self, status, body, ctype):
        if isinstance(body, str):
            body = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        url = urlparse(self.path)
        q = {k: v[0] for k, v in parse_qs(url.query, keep_blank_values=True).items()}
        token = q.get("website_token", "")
        if url.path in ("/widget", "/widget_config"):
            log_line("server", {"path": url.path, "raw_query": url.query})
        if url.path == "/widget":
            if token == "bad":  # rails: find_by! -> 404
                return self.send(404, "not found", "text/plain")
            # like widgets_controller#set_token: cw_conversation wins, else a new token
            auth = q.get("mock_token") or q.get("cw_conversation") or f"mock-{next(TOKENS)}"
            with open(os.path.join(HERE, "index.html"), encoding="utf-8") as f:
                html = f.read()
            html = html.replace("__WEBSITE_TOKEN__", json.dumps(token)).replace("__AUTH_TOKEN__", json.dumps(auth))
            return self.send(200, html, "text/html; charset=utf-8")
        if url.path == "/widget_config":
            if token == "error500":
                return self.send(500, json.dumps({"error": "mock 500"}), "application/json")
            body = widget_config(self.headers.get("Host", "localhost"), token)
            return self.send(200, json.dumps(body), "application/json")
        if url.path == "/icon.png":
            return self.send(200, ICON, "image/png")
        self.send(404, "not found", "text/plain")

    def do_POST(self):
        if urlparse(self.path).path != "/log":
            return self.send(404, "not found", "text/plain")
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        try:
            msg = json.loads(raw or b"{}")
            log_line(str(msg.get("kind", "page")), msg.get("detail"))
        except ValueError:
            log_line("page-raw", raw.decode("utf-8", "replace"))
        self.send(204, b"", "text/plain")


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))  # no packet is sent, just picks the route
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def main():
    global TRANSCRIPT
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8787)
    ap.add_argument("--transcript", help="append every log line to this file")
    args = ap.parse_args()
    TRANSCRIPT = args.transcript
    p, ip = args.port, lan_ip()
    print(f"mock widget on 0.0.0.0:{p}")
    print(f"  ios simulator / desktop browser : http://localhost:{p}")
    print(f"  android emulator                : http://10.0.2.2:{p}")
    print(f"  android device (adb reverse tcp:{p} tcp:{p}): http://localhost:{p}")
    print(f"  physical device on same wifi    : http://{ip}:{p}")
    print(f"  try: http://localhost:{p}/widget?website_token=mock")
    if TRANSCRIPT:
        print(f"  transcript -> {TRANSCRIPT}")
    ThreadingHTTPServer(("0.0.0.0", p), Handler).serve_forever()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
