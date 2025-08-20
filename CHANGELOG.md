# Changelog

All notable changes to the Limechat iOS SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - Unreleased

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
