# Limechat iOS SDK

Native iOS SDK for integrating Limechat customer support widget into your iOS applications.

## Features

- 🎯 Native Swift implementation
- 📱 Full-screen modal presentation
- 🔒 Secure user identification
- 🌍 Multi-language support
- 📦 Swift Package Manager support
- 🔄 SwiftUI and UIKit compatible
- 📲 iOS 13.0+ support
- 🎯 Floating widget icon (optional)

## Installation

### Swift Package Manager

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/wavicle-limechat/widget-sdk-ios.git`
3. Select the version you want to use
4. Click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wavicle-limechat/widget-sdk-ios.git", from: "1.0.0")
]
```

## Quick Start

Both options need a `LimechatWidgetDelegate`, see [Delegate Methods](#delegate-methods).

### Option 1: Floating Widget Icon (Recommended)

```swift
import LimechatWidget

class YourViewController: UIViewController {
    private var widgetIcon: LimechatWidgetIcon?

    override func viewDidLoad() {
        super.viewDidLoad()

        widgetIcon = addWidgetIcon(
            configuration: WidgetConfiguration(
                websiteToken: "YOUR_WEBSITE_TOKEN",
                user: WidgetConfiguration.User(name: "John", email: "john@example.com")
            ),
            delegate: self
        )
    }
}
```

### Option 2: Manual Presentation

```swift
import LimechatWidget

class YourViewController: UIViewController {
    @IBAction func openSupportTapped(_ sender: Any) {
        LimechatWidgetViewController.present(
            from: self,
            configuration: WidgetConfiguration(
                websiteToken: "YOUR_WEBSITE_TOKEN",
                user: WidgetConfiguration.User(name: "John", email: "john@example.com")
            ),
            delegate: self
        )
    }
}
```

### SwiftUI

Present `LimechatWidgetViewController` from a `UIViewControllerRepresentable`, see [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md#swiftui-integration). `LimechatWidgetSwiftUIView` wraps the `LimechatWidget` launcher. It has no `open` or `setMessageAttributes`.

## Configuration

### WidgetConfiguration

```swift
let configuration = WidgetConfiguration(
    websiteToken: "YOUR_WEBSITE_TOKEN",  // Required
    locale: "en",                        // Optional, defaults to "en"
    user: user,                          // Optional
    customAttributes: ["key": "value"],  // Optional
    hideFilePicker: false                // Optional, hides the attachment button
)
```

### User Information

```swift
let user = WidgetConfiguration.User(
    name: "John Doe",           // Optional
    email: "john@example.com",  // Optional
    phoneNumber: "+1234567890", // Optional
    identifier: "user-42",      // Optional, needs identifierHash
    identifierHash: "hash123",  // Optional, HMAC-SHA256(hmac_token, identifier) from your server
    customAttributes: ["plan": "pro"] // Optional, see below
)
```

`name`, `email`, `phoneNumber` and `customAttributes` reach the widget on their own and need no hash. They are not verified. On the customer's first message the server updates the contact, and can merge into an existing contact with the same email or phone. `customAttributes` on the user go with the customer's next message, they are not set on the contact. Pass `identifier` and `identifierHash` together if you use identity validation.

The verified `set-user` event is sent once per page load, at ready, and only when both `identifier` and `identifierHash` are set.

### Open With a Message

```swift
// on first load
LimechatWidgetViewController.present(from: self, configuration: configuration, initialMessage: "Hi")

// later, on a view or view controller you hold
widgetView.open(message: "Hi")
widgetView.open(messageData: ["content": "Hi", "submitted_values": ["plan": "pro"]])

// from the launcher view (`LimechatWidget`): presents the widget with the message
launcher.open(message: "Hi")
```

- if the widget is ready, the message is sent now. A ready widget is never reloaded.
- if it is not ready, the message is held and sent at ready. If no load is running, `open` starts one, so it also retries after a failed load.
- an empty message does nothing. `open` before `initialize` does nothing.
- only the latest held message is kept. A held message can go out at a much later load. To drop it, call `initialize(with:)` again or close the widget.
- `sendMessage(event:data:)` before ready is lost. Only `open` and `setMessageAttributes` wait.
- if the widget web process is killed (for example under memory pressure), ready resets. The next `open` or `reload()` loads the page again.
- on `LimechatWidget`, a message is not delivered when another view controller is already presented. The delegate gets an error.

### Message Attributes

```swift
widgetView.setMessageAttributes(["order_id": "A-1042", "source": "checkout"])
// same on LimechatWidgetViewController, LimechatWidget and LimechatWidgetIcon
```

- attached as `custom_attributes` to the customer's next message only. Repeat calls merge, later keys win. They are message attributes, not contact attributes.
- call it at any time. They are held until the widget is ready, and sent before an `open` message, so the first message carries them.
- on `LimechatWidget` and `LimechatWidgetIcon`, attributes reach the widget when the user taps the icon or you call `open`.
- returns `false` for an empty dictionary or a value that is not valid JSON, such as `Date` or `Double.nan`. Pass JSON values.
- the widget clears them once they are sent. If the send fails, the delegate gets an error and they are not restored.
- attributes already sent are gone with the page on a reload. Attributes still held stay held. On the launchers, if the user closes the widget before ready, held attributes are lost: set them again.
- call from the main thread.
- needs a widget build containing `c8126fb7cd` (pr #120, 2026-09-25). Older builds ignore it silently.

### Reload

`reload()` loads the page again on the view and the view controller. Held attributes and open messages are kept and sent at the next ready. Before `initialize(with:)`, the view reports a configuration error.

### Callbacks

`widgetDidLoad` fires once per page load, when the widget can receive messages. A failed page gives `widgetDidReceiveError` and no `widgetDidLoad`. A page that returns 200 but never mounts gives neither.

### Floating Widget Icon Customization

The floating widget icon provides a default message icon that users can tap to open the widget:

```swift
// Basic usage - just one line!
let icon = addWidgetIcon(
    configuration: configuration,
    delegate: self
)

// Advanced customization
let icon = addWidgetIcon(
    configuration: configuration,
    delegate: self,
    position: .bottomRight,
    customIcon: UIImage(named: "custom_icon")
)

// Customize appearance
icon.cornerRadius = 35
icon.backgroundColor = .systemGreen
icon.tintColor = .white

// Update unread count
icon.setUnreadCount(5)
```

### Icon Positions

- `.topLeft` - Top left corner
- `.topRight` - Top right corner
- `.bottomLeft` - Bottom left corner
- `.bottomRight` - Bottom right corner (default)

## Delegate Methods

Implement `LimechatWidgetDelegate` to handle widget events:

```swift
extension YourViewController: LimechatWidgetDelegate {
    func widgetDidLoad() {
        // Widget is ready to receive messages
    }

    func widgetDidRequestClose() {
        // Widget requested to close
    }

    func widgetDidReceiveError(_ error: WidgetError) {
        // Configuration, web view or http error
        print("Widget error: \(error.localizedDescription)")
    }

    func widgetDidReceiveMessage(_ message: [String: Any]) {
        // Widget sent a message
    }

    // optional
    func widgetDidChangeConversationToken(_ token: String) {}
}
```

`WidgetError` has two cases, `configurationError` and `webViewError`. A main frame http error of 400 or more arrives as `webViewError("HTTP error: <status>")`. If you switch over `WidgetError`, handle both.

The floating icon badge is driven by your own count: keep the icon returned by `addWidgetIcon` and call `widgetIcon?.setUnreadCount(count)`.

## Requirements

- iOS 13.0+
- Xcode 13.0+
- Swift 5.7+

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@limechat.ai
- 🐛 Issues: [GitHub Issues](https://github.com/wavicle-limechat/widget-sdk-ios/issues)
- 📚 Documentation: [docs.limechat.ai](https://docs.limechat.ai)