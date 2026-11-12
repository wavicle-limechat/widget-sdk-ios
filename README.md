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
    .package(url: "https://github.com/wavicle-limechat/widget-sdk-ios.git", exact: "0.2.0-beta.1")
]
```

Note: spm `from:` skips prereleases, so the beta is pinned with `exact:`. After the final release this moves to `from: "0.2.0"`.

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

`name`, `email`, `phoneNumber` and `customAttributes` reach the widget on their own and need no hash. They are not verified. `name`, `email` and `phoneNumber` go out as `contact` with every message, and the server updates the contact each time, and can merge into an existing contact with the same email or phone. User custom attributes go with every message the customer types, not onto the contact. Pass `identifier` and `identifierHash` together if you use identity validation.

The verified `set-user` event is sent once per page load, at ready, and only when both `identifier` and `identifierHash` are set.

### Logout and Multiple Users

**Logout and multiple users.** The stored conversation token is not tied to the user. With no `instanceId` it is saved under the key `"default"`, shared across website tokens. If user A logs out and user B logs in on the same device, B sees A's history and B's user details update A's contact. There is no public clear api yet (planned). Until then, pass a distinct `instanceId` per logged-in user (and per website token if the app uses more than one inbox), or manage the token yourself with `conversationToken` and `onConversationTokenChange` and drop it on logout.

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
- if the widget web process dies (for example under memory pressure), ready resets and the SDK reloads the page once. Held attributes and a held open message stay and go out at the next ready, attributes first. Attributes already sent are lost with the page. If the process dies again before the page is ready, the SDK does not reload again and `widgetDidReceiveError` gets `Widget web process died again before ready`. The page stays blank after that, so dismiss the widget on this error. `LimechatWidgetViewController` and the launchers have no native close. Only a ready page resets the one-reload allowance. A later `open(message:)` or `reload()` still loads the page.
- on `LimechatWidget`, a message is not delivered when another view controller is already presented. The delegate gets an error.

### Message Attributes

```swift
widgetView.setMessageAttributes(["order_id": "A-1042", "source": "checkout"])
// same on LimechatWidgetViewController, LimechatWidget and LimechatWidgetIcon
```

- attached as `custom_attributes` to the customer's next message only. Repeat calls merge, later keys win. They are message attributes, not contact attributes.
- file attachments and email-only submits do not use up held attributes. They stay held for the next message.
- `custom_attributes` set explicitly on the message payload win over held ones for the same key.
- the widget's auto-start `Hi` counts as the next message. With no welcome text, no pre-chat form and no conversation, the widget sends `Hi` on its own. If you did not call `open(message:)`, the attributes can land on `Hi` and not on what the customer types.
- call it at any time. They are held until the widget is ready, and sent before an `open` message, so the first message carries them.
- on `LimechatWidget` and `LimechatWidgetIcon`, attributes reach the widget when the user taps the icon or you call `open`.
- returns `false` for an empty dictionary or a value that is not valid JSON, such as `Date` or `Double.nan`. Pass JSON values.
- after the customer's message is sent, the widget clears them. If that message fails, the widget keeps them for the next one. Attributes already sent to the widget are lost on a page reload. Attributes still held are kept.
- on the launchers, attributes that were not sent yet when the user closes the widget stay held and go out the next time it opens. Held open messages are not kept. Attributes already sent are lost when the widget closes, since each open is a new page. Set them again.
- on `LimechatWidgetIcon`, held attributes are dropped when `initialize(with:)` is called with another user (`identifier`, `email` or `phoneNumber`) or when a non-empty `conversationToken` changes or is cleared, including a user that is cleared. A token that first arrives (empty or nil to a value) does not drop them. They are kept for the same user. `LimechatWidget` takes its configuration once, so a new user means a new launcher with an empty buffer.
- call from the main thread.
- needs a widget build containing `c8126fb7cd` (pr #120, 2026-09-25). Older builds ignore it silently.

### Reload

`reload()` loads the page again on the view and the view controller. Held attributes and open messages are kept and sent at the next ready. Before `initialize(with:)`, `reload()` does nothing.

### Callbacks

`widgetDidLoad` fires once per page load, when the widget can receive messages. A failed page gives `widgetDidReceiveError` and no `widgetDidLoad`. A page that returns 200 but never mounts gives neither.

At ready the SDK sends, in this order: the verified `set-user` event, held attributes, a held open message. Then `widgetDidChangeConversationToken` and `widgetDidLoad` fire.

| callback | fires |
|---|---|
| `widgetDidLoad` | once per page load, at ready |
| `widgetDidReceiveError` | configuration, load, http (400 and above), serialisation and web process errors |
| `widgetDidRequestClose` | the widget asked to close |
| `widgetDidReceiveUnreadCount` | the widget reported a new unread count |
| `widgetDidChangeConversationToken` | the widget reported a conversation token |
| `widgetDidReceiveMessage` | any other widget event |

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

## Troubleshooting

- Hosts need `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in Info.plist, otherwise the app can crash when the user picks "take photo" in the file picker.

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