# Limechat example app

Minimal SwiftUI app (iOS 15+) that uses the SDK from the local package (`..`), so it always builds against the code in this repo.

## Run

1. open `Example/LimechatExample.xcodeproj` in Xcode
2. set `websiteToken` (and `baseURL` if needed) in `LimechatExample/ExampleConfig.swift`
3. pick a simulator and run the `LimechatExample` scheme

Or from the terminal:

```sh
xcodebuild -project Example/LimechatExample.xcodeproj -scheme LimechatExample \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Demos

- UIKit view controller: `LimechatWidgetViewController` with buttons for open with a message, open with `messageData` (`submitted_values` only, the widget adds the default "Hi" content), `setMessageAttributes`, `reload` and `reset`
- SwiftUI view: `LimechatWidgetSwiftUIView` with a delegate. The wrapper has no open or reset calls, tap the icon
- Launcher icon: `LimechatWidget` with open, `messageData`, attributes and a reset of the stored conversation

The Info.plist has `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`, which the file picker needs.

SwiftUI also has a `WidgetConfiguration` type. In a file that imports both `SwiftUI` and `LimechatWidget` the name is ambiguous, which is why `ExampleConfig.swift` imports only `LimechatWidget`.
