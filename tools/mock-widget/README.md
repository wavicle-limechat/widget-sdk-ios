# mock-widget

local stand-in for the limechat web widget page (`/widget`) and `/widget_config`, so the
sdk webview bridge can be tested without deploying anything. python3 stdlib only.
this folder is identical in the android and ios repos.

## run

```sh
python3 tools/mock-widget/serve.py --port 8787 --transcript /tmp/lc-mock.log
```

it binds `0.0.0.0` and prints the urls to use:

| where the app runs | baseUrl |
| --- | --- |
| ios simulator, desktop browser | `http://localhost:8787` |
| android emulator | `http://10.0.2.2:8787` |
| android device | `adb reverse tcp:8787 tcp:8787`, then `http://localhost:8787` |
| physical device on the same wifi | `http://<lan ip printed at start>:8787` |

open `http://localhost:8787/widget?website_token=mock` in a browser for a quick look.

## routes

- `GET /widget` the mock page. `website_token=bad` -> 404 (rails uses `find_by!`).
  `?mock_token=x` (or `cw_conversation=x`) sets the token the page reports, otherwise `mock-<n>`.
- `GET /widget_config` same shape as `WidgetConfigController#index`. `config` is a json
  *string* with `widgetIconMobile`/`widgetIconDesktop` pointing at `/icon.png` on the host the
  app used. `website_token=noicon` -> `config: "{}"`, `website_token=error500` -> 500.
- `GET /icon.png` a green 64x64 square.
- `POST /log` `{kind, detail}` -> one timestamped line on the terminal and in `--transcript`.

## what the page does

mirrors `app/views/widgets/show.html.erb`, `deviceHelper.js` and `webViewHelper.js` from
the limechat repo:

- head inline script reassigns `window.chatwootWebChannel = {...}` and sets `window.authToken`,
  same as the real page, so anything injected before load is wiped (logged as `pre_injected_channel`).
- on load logs: every url param, user agent, detected platform and which bridges exist
  (`ReactNativeWebView`, `webkit.messageHandlers.limechat` / `limechatNative`, `LimechatAndroid`,
  `LimeChatAndroid`), then sends `set-cw-conversation` with `window.authToken` (like `App.vue`),
  then polls `window.chatwootWebChannel.rnUser` for up to 5s (sdks inject after load).
- messages are `{event, type, timestamp, ...data}` sent through the same route the real page
  would pick: rn `ReactNativeWebView.postMessage(json)`, ios `webkit.messageHandlers.limechat.postMessage(obj)`,
  android `LimechatAndroid|LimeChatAndroid.postMessage(json)`, else `window.postMessage('limechat-widget:'+json)`.
  in a plain browser nothing is sent (`ok:false`), same as prod.
- buttons: close-widget, set-cw-conversation with a new token, external link, `target=_blank`,
  `window.open`, same-host link, `limechat://close`, file input (`accept`, `multiple`), mic probe, read rnUser.
- logs every `message` event on `window` and `document`, with `real_page_accepts` (the real page
  only handles `chatwoot-widget:` strings) and `own_fallback_echo` (our own `limechat-widget:` fallback).

## pointing each example app at it

- **rn** (`example/`): HEAD has no `baseUrl` prop (base url is `WIDGET_CONFIG.DEFAULT_BASE_URL`
  in `src/constants.js`). for a HEAD baseline, edit that constant in the *installed copy*
  (`example/node_modules/<package>/src/constants.js`), not in the repo. once the `baseUrl`
  prop lands, pass `baseUrl="http://localhost:8787"` (or `EXPO_PUBLIC_LC_BASE_URL`). ios needs
  `NSAllowsLocalNetworking` for cleartext.
- **ios** (`WidgetConfiguration(websiteToken:..., baseURL: "http://localhost:8787")`, example reads
  `LCBaseURL` from `Config.xcconfig` written as `http:/$()/localhost:8787`). example Info.plist
  needs `NSAllowsLocalNetworking`.
- **android** (`WidgetConfig.builder(token).setBaseUrl("http://10.0.2.2:8787")`, `local-sdk-demo`
  reads `lc.baseUrl` from `local.properties`). debug build needs a network security config that
  allows cleartext for `10.0.2.2` and `localhost`.

use any website token, e.g. `mock`. use `noicon`, `error500`, `bad` for the failure paths.

## record a baseline transcript

1. `python3 tools/mock-widget/serve.py --transcript test-fixtures/baseline-<sdk>.log` (delete the file first, it appends).
2. run the example app, open the widget, wait ~5s for the `rnUser` line.
3. press, in order: send set-cw-conversation, each link (go back after each), file input
   (pick, then cancel), mic probe, close-widget. reopen once.
4. stop the server.

## diff two transcripts

```sh
python3 tools/mock-widget/diff_transcripts.py test-fixtures/baseline-rn.log /tmp/lc-mock.log
```

ignores timestamps, `mock-*` and jwt tokens, `timestamp`/`after_ms`/`size` numbers. exit 0 = same.
compare runs on the same simulator/emulator image, the `userAgent` line differs across os versions.
