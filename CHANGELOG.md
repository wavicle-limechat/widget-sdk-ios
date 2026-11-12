# Changelog

All notable changes to the Limechat iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-11-13

> **Upgrade note: unverified contact update.** User details passed to the SDK reach the widget through `rnUser` with no verification. `name`, `email` and `phoneNumber` go out as `contact` with every message, and the server updates the contact each time, and can merge into an existing contact with the same email or phone. If you use identity validation, pass `identifier` and `identifierHash` so the contact is verified.

### Known issues
- The key `"default"` is shared across website tokens, so a second user on the same device can see the first user's history and update their contact. Call `LimechatWidgetView.reset(instanceId:)` on logout, or use one `instanceId` per user.

### Changed
- `open(messageData:)` and `initialMessageData` with no `content` (missing, null or empty) and at least one other key, such as `submitted_values`, send `content: "Hi"`, like the web SDK's `setOpenMessage`. `{}` and a lone empty `content` are unchanged.
- `LimechatWidgetIcon.initialize(with:)` drops held message attributes when the user (`identifier`, `email`, `phoneNumber`) or `conversationToken` changes, so a new user's first message does not carry the previous user's attributes. Same user keeps them. A token that first arrives (empty or nil to a value) is not a change.
- `widgetDidLoad` fires once per page load, when the widget is ready to receive messages, not on page finish. A failed page gives `widgetDidReceiveError` and no `widgetDidLoad`.
- `open(message:)` and `open(messageData:)` send now when the widget is ready and never reload a ready widget. When it is not ready the message is held and sent at ready, with no message in the url. An empty value does nothing.
- `widgetDidReceiveUnreadCount` is optional on `LimechatWidgetDelegate`.
- `LimechatWidget.open` reports an error on the delegate when another view controller is presented and a message cannot be delivered.
- `sdk_version` is no longer sent in the widget url. `platform=ios` is still sent, and all SDKs now send `platform`.
- `sendMessage` now posts `chatwoot-widget:` + json, the only form the widget reads. it was a silent no-op before.
- the widget bridge listens on the `limechat` handler only. `limechatNative`, string bodies, the `close` event alias and `limechat://close` are removed, the widget never sent them.
- user `name`, `email` and `phoneNumber` are passed through `window.chatwootWebChannel.rnUser` and no longer sit in the widget url. hosts that pass a user now update the contact with every message.
- a delegate set on `LimechatWidget` after init is passed to the default icon.

### Added
- `reset()` on `LimechatWidgetView` and `LimechatWidgetViewController`, and static `LimechatWidgetView.reset(instanceId:)`. Clears the stored or live conversation token and the user, a token or user passed in the configuration (until the next `initialize`), held attributes and a held open message, then reloads without a conversation. Does not close the widget. Call it on logout.
- `reset()` on `LimechatWidget` and `LimechatWidgetIcon`. Clears the live token and held attributes, drops the user and token from the launcher's configuration (until a new one is applied), resets the stored token, and resets a widget presented from the launcher. Call it on logout.
- `setMessageAttributes(_:)` on `LimechatWidgetView`, `LimechatWidgetViewController`, `LimechatWidget` and `LimechatWidgetIcon`. Attaches custom attributes to the customer's next message. Needs a widget build containing `c8126fb7cd`, older builds ignore it. A tap on the default launcher icon delivers attributes set on `LimechatWidget`.
- `reload()` on `LimechatWidgetView` and `LimechatWidgetViewController`. Before `initialize` the call does nothing.
- `WidgetConfiguration.User.customAttributes`, sent through `rnUser` and attached to the next message.
- `open(message:)` and `open(messageData:)` on the widget view and view controller, plus `initialMessage` and `initialMessageData` on `initialize`, the view controller init and `present`.
- `WidgetConfiguration.hideFilePicker`.
- `WidgetConfiguration.User.identifier` and `identifierHash`. `set-user` is sent after load only when both are set.
- `LimechatWidget.open(message:messageData:)` on the launcher. when this launcher's widget is already open, the message goes to it. an open widget with another `websiteToken` or `instanceId` does not get the message.
- non-json message data reports an error and no longer crashes. view controller calls work before the view loads.
- under external token management the live token is kept, not the config token.
- no icon fetch when a custom icon is set.
- the launcher icon uses `widgetIconMobile` from `widget_config`, falling back to the default icon on any failure.

### Fixed
- `open` before the widget is ready holds the message until ready, and reloads only after a failed load or a page that never became ready (see below), the same as Android and React Native.
- If the page loads but the widget never becomes ready, `open` reloads after 10 seconds instead of holding forever.
- `initialize` drops the stored conversation token when the user (`identifier`, `email`, `phoneNumber`) changes or is removed on the same `instanceId`, so a new user does not see the previous user's conversation. No user to a user, and the same user with a new name, keep it. A token passed in the configuration still wins. Memory only: call `reset()` on logout.
- `LimechatWidget` and `LimechatWidgetIcon` carry the live conversation token into the next open when you use external token management (`onConversationTokenChange`), so a reopen continues the conversation. Without external management the config is unchanged. A new user drops the live token.
- `LimechatWidgetSwiftUIView` applies a new configuration on update. `LimechatWidget.configuration` is now `public private(set)`. A new user drops held attributes, and the icon is fetched again only when `websiteToken` or `baseURL` changes.
- `LimechatWidgetSwiftUIView` keeps its delegate alive and passes a new one to the launcher on update. `LimechatWidget.delegate` is weak, so an inline delegate was freed. A delegate set on `LimechatWidget` also reaches a widget that is already presented.
- The bridge accepts messages from the main frame only. An embedded iframe can no longer post `set-cw-conversation` with a token it picked, or `close-widget`.
- A `set-cw-conversation` from an old page is ignored after `reset()` or a reload, until the new page has committed. Its token is not saved or sent to the delegate.
- Embedded iframes can navigate. Only top-frame navigations are checked against the widget host.
- the swiftui view is now `LimechatWidgetSwiftUIView`. in 0.0.1 it shared the name `LimechatWidgetView` with the uikit view, so the package did not compile. uikit hosts change nothing.
- main frame http errors (status 400 and above) reach `widgetDidReceiveError`.
- when the web content process dies, ready resets and the page reloads once with the live token. A second death before ready does not reload and reports `Widget web process died again before ready` through `widgetDidReceiveError`. The page stays blank then, so dismiss the widget on that error. Only a ready page resets the allowance.
- `reload()` before `initialize` does nothing instead of reporting a configuration error.
- attributes that were not flushed when a launcher widget closes stay held on the launcher.
- held attributes stay held when the send cannot be serialised.

### Deprecated
- `WidgetConfiguration.colorScheme` and `WidgetConfiguration.ColorScheme` are ignored by the widget and will be removed in the next major release.
- `LimechatWidget.containerStyle` is unused and will be removed in the next major release.
- `WidgetError.networkError`, `WidgetError.unknownError` and `WidgetError.from(_:)` are never produced by the sdk and will be removed in the next major release.

## [0.0.1] - 2025-08-20

### Added
- Initial release of Limechat iOS SDK
- Native Swift implementation with WebView integration
- Full-screen modal presentation
- Light/Dark/Auto theme support
- Multi-language support
- User identification and custom attributes
- SwiftUI and UIKit compatibility
- Delegate pattern for widget events
- Error handling and logging
- **Floating widget icon** - Optional floating icon with default message icon
- **Unread count support** - Display unread message count on floating icon
- **Custom icon support** - Use custom images for the floating icon
- **Multiple positions** - Position floating icon in any corner of the screen

### Features
- `LimechatWidgetViewController` - Main view controller for presenting the widget
- `LimechatWidgetIcon` - Floating widget icon with default message icon
- `WidgetConfiguration` - Configuration class for widget settings
- `WidgetConfiguration.User` - User information structure
- `LimechatWidgetDelegate` - Delegate protocol for widget events
- `WidgetError` - Error handling for widget operations
- `WidgetIconPosition` - Enum for floating icon positions

### Technical Details
- iOS 13.0+ support
- Swift 5.7+ compatibility
- WebKit-based WebView implementation
- Secure URL handling and navigation
- Message passing between native and web content
- Automatic close button handling from web content
- Floating icon with shadow and tap gestures
- Unread count badge with automatic updates
