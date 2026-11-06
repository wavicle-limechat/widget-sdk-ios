# Changelog

All notable changes to the Limechat iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

> **Upgrade note: unverified contact update.** User details passed to the SDK reach the widget through `rnUser` with no verification. On the customer's first message the server updates the contact, and can merge into an existing contact with the same email or phone. If you use identity validation, pass `identifier` and `identifierHash` so the contact is verified.

### Changed
- `widgetDidLoad` fires once per page load, when the widget is ready to receive messages, not on page finish. A failed page gives `widgetDidReceiveError` and no `widgetDidLoad`.
- `open(message:)` and `open(messageData:)` send now when the widget is ready and never reload a ready widget. When it is not ready the message is held and sent at ready, with no message in the url. An empty value does nothing.
- `widgetDidReceiveUnreadCount` is optional on `LimechatWidgetDelegate`.
- `LimechatWidget.open` reports an error on the delegate when another view controller is presented and a message cannot be delivered.
- `sdk_version` is no longer sent in the widget url. `platform=ios` is still sent, and all SDKs now send `platform`.
- `sendMessage` now posts `chatwoot-widget:` + json, the only form the widget reads. it was a silent no-op before.
- the widget bridge listens on the `limechat` handler only. `limechatNative`, string bodies, the `close` event alias and `limechat://close` are removed, the widget never sent them.
- user `name`, `email` and `phoneNumber` are passed through `window.chatwootWebChannel.rnUser` and no longer sit in the widget url. hosts that pass a user now update the contact on the first message.
- a delegate set on `LimechatWidget` after init is passed to the default icon.

### Added
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
- main frame http errors (status 400 and above) reach `widgetDidReceiveError`.
- when the web content process dies, ready resets and the page reloads once with the live token. A second death before ready does not reload and reports `Widget web process died again before ready` through `widgetDidReceiveError`. The page stays blank then, so dismiss the widget on that error. Only a ready page resets the allowance.
- `reload()` before `initialize` does nothing instead of reporting a configuration error.
- attributes that were not flushed when a launcher widget closes stay held on the launcher.
- held attributes stay held when the send cannot be serialised.

### Deprecated
- `LimechatWidget.containerStyle` is unused and is removed at the next major.

### Removed
- `WidgetError.networkError` and `WidgetError.unknownError`. Nothing in the SDK produced them. An exhaustive `switch` over `WidgetError` must be updated.

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
