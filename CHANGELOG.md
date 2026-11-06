# Changelog

All notable changes to the Limechat iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- `sendMessage` now posts `chatwoot-widget:` + json, the only form the widget reads. it was a silent no-op before.
- the widget bridge listens on the `limechat` handler only. `limechatNative`, string bodies, the `close` event alias and `limechat://close` are removed, the widget never sent them.
- user `name`, `email` and `phoneNumber` are passed through `window.chatwootWebChannel.rnUser` and no longer sit in the widget url. hosts that pass a user now update the contact on the first message.
- a delegate set on `LimechatWidget` after init is passed to the default icon.

### Added
- `open(message:)` and `open(messageData:)` on the widget view and view controller, plus `initialMessage` and `initialMessageData` on `initialize`, the view controller init and `present`.
- `WidgetConfiguration.hideFilePicker`.
- `WidgetConfiguration.User.identifier` and `identifierHash`. `set-user` is sent after load only when both are set.
- `LimechatWidget.open(message:messageData:)` on the launcher. when this launcher's widget is already open, the message goes to it. an open widget with another `websiteToken` or `instanceId` does not get the message.
- non-json message data reports an error and no longer crashes. view controller calls work before the view loads.
- under external token management the live token is kept, not the config token.
- `%` in `lc_open_message` is escaped.
- no icon fetch when a custom icon is set.
- the launcher icon uses `widgetIconMobile` from `widget_config`, falling back to the default icon on any failure.

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
