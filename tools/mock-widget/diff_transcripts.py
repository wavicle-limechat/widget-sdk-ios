#!/usr/bin/env python3
"""diff two mock-widget transcripts, ignoring timestamps, tokens and timing noise.

usage: python3 tools/mock-widget/diff_transcripts.py baseline.log new.log
exit code 0 = same, 1 = different.
"""
import difflib, re, sys

RULES = [
    (re.compile(r"^\S+ "), ""),                                  # leading iso timestamp
    (re.compile(r"mock-(new-)?\d+"), "mock-<token>"),            # mock tokens
    (re.compile(r"eyJ[\w-]+\.[\w-]+\.[\w-]+"), "<jwt>"),         # real cw_conversation tokens
    (re.compile(r'"(timestamp|after_ms|size)": \d+'), r'"\1": <n>'),
]


def normalize(path):
    out = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            for rx, sub in RULES:
                line = rx.sub(sub, line)
            out.append(line)
    return out


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    a, b = sys.argv[1:]
    diff = list(difflib.unified_diff(normalize(a), normalize(b), a, b))
    sys.stdout.writelines(diff)
    sys.exit(1 if diff else 0)


if __name__ == "__main__":
    main()
