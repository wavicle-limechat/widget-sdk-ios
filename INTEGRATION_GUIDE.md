# Limechat iOS SDK Integration Guide

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Integration](#basic-integration)
- [Full-Screen Modal Implementation](#full-screen-modal-implementation)
- [SwiftUI Integration](#swiftui-integration)
- [Customization Options](#customization-options)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)

## Requirements

- iOS 13.0+
- Xcode 13.0+
- Swift 5.7+

## Installation

### Swift Package Manager (Recommended)

#### Using Xcode

1. In Xcode, select **File → Add Packages**
2. Enter the repository URL: `https://github.com/wavicle-limechat/widget-sdk-ios.git`
3. Select version rule (e.g., "Up to Next Major Version")
4. Click **Add Package**

#### Using Package.swift

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/wavicle-limechat/widget-sdk-ios.git", from: "0.0.1")
]
```

## Basic Integration

### UIKit Implementation

#### Step 1: Import the SDK

```swift
import LimechatWidget
```

#### Step 2: Add Widget to View Controller

```swift
import UIKit
import LimechatWidget

class ViewController: UIViewController {
    
    private var widgetView: LimechatWidgetView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWidget()
    }
    
    private func setupWidget() {
        // Create widget view
        widgetView = LimechatWidgetView(frame: view.bounds)
        widgetView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        widgetView.delegate = self
        view.addSubview(widgetView)
        
        // Configure widget
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890",
            identifier: nil,     // Optional. Set together with identifierHash
            identifierHash: nil  // Optional. HMAC-SHA256(hmac_token, identifier) from your server
        )
        
        let configuration = WidgetConfiguration(
            websiteToken: "YOUR_WEBSITE_TOKEN", // e.g., "MEFFACy4xaovJayhLjSt836h"
            locale: "en", // Supported: en, es, fr, de, it, pt
            user: user,
            customAttributes: [
                "source": "ios_app",
                "version": "1.0.0"
            ]
        )
        
        // Initialize widget
        widgetView.initialize(with: configuration)
    }
}

// MARK: - LimechatWidgetDelegate

extension ViewController: LimechatWidgetDelegate {
    
    func widgetDidLoad() {
        print("Widget loaded successfully")
    }
    
    func widgetDidRequestClose() {
        print("Widget requested close")
        // Handle close action
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        print("Widget error: \(error.localizedDescription)")
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        print("Widget message: \(message)")
    }
}
```

## Full-Screen Modal Implementation

### Presenting as Modal (Recommended)

```swift
import UIKit
import LimechatWidget

class MainViewController: UIViewController {
    
    @IBAction func openWidgetTapped(_ sender: UIButton) {
        presentWidget()
    }
    
    private func presentWidget() {
        // Create configuration
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john.doe@example.com",
            phoneNumber: "+1234567890"
        )
        
        let configuration = WidgetConfiguration(
            websiteToken: "MEFFACy4xaovJayhLjSt836h",
            locale: "en",
            user: user,
            customAttributes: [
                "source": "ios_app",
                "app_version": "1.0.0",
                "user_id": "12345"
            ]
        )
        
        // Present widget modally
        LimechatWidgetViewController.present(
            from: self,
            configuration: configuration,
            delegate: self
        )
    }
}
```

Implement `LimechatWidgetDelegate` as in the previous section.

## SwiftUI Integration

### SwiftUI View Wrapper

`LimechatWidgetSwiftUIView` wraps the `LimechatWidget` launcher. It has no `open` or `setMessageAttributes`. To open with a message or set attributes, present `LimechatWidgetViewController` as below and call its methods.

```swift
import SwiftUI
import LimechatWidget

struct LimechatWidgetSheet: UIViewControllerRepresentable {
    let configuration: WidgetConfiguration
    @Binding var isPresented: Bool
    var onLoad: (() -> Void)?
    var onError: ((WidgetError) -> Void)?
    
    func makeUIViewController(context: Context) -> LimechatWidgetViewController {
        let controller = LimechatWidgetViewController(configuration: configuration)
        controller.widgetDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: LimechatWidgetViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, LimechatWidgetDelegate {
        let parent: LimechatWidgetSheet
        
        init(_ parent: LimechatWidgetSheet) {
            self.parent = parent
        }
        
        func widgetDidLoad() {
            parent.onLoad?()
        }
        
        func widgetDidRequestClose() {
            parent.isPresented = false
        }
        
        func widgetDidReceiveError(_ error: WidgetError) {
            parent.onError?(error)
        }
        
        func widgetDidReceiveMessage(_ message: [String: Any]) {
            print("Message: \(message)")
        }
    }
}

// Usage in SwiftUI View
struct ContentView: View {
    @State private var showWidget = false
    
    var body: some View {
        VStack {
            Button("Open Support") {
                showWidget = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showWidget) {
            LimechatWidgetSheet(
                configuration: createConfiguration(),
                isPresented: $showWidget,
                onLoad: {
                    print("Widget loaded")
                },
                onError: { error in
                    print("Error: \(error)")
                }
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func createConfiguration() -> WidgetConfiguration {
        let user = WidgetConfiguration.User(
            name: "John Doe",
            email: "john.doe@example.com"
        )
        
        return WidgetConfiguration(
            websiteToken: "MEFFACy4xaovJayhLjSt836h",
            locale: "en",
            user: user
        )
    }
}
```

## Customization Options

### Configuration Parameters

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `websiteToken` | String | Your Limechat website token | Yes |
| `locale` | String | Language locale (en, es, fr, de, it, pt) | No (default: "en") |
| `user` | User? | User details object | No |
| `customAttributes` | [String: Any]? | Custom data to attach | No |
| `baseURL` | String | Custom base URL | No (default: production) |
| `conversationToken` | String? | External conversation token, used instead of the stored one | No |
| `onConversationTokenChange` | ((String) -> Void)? | External token management. When set, the SDK does not persist tokens | No |
| `instanceId` | String? | Storage key for the managed token (default: "default") | No |
| `hideFilePicker` | Bool | Hides the attachment button in the widget | No (default: false) |

### User Object

```swift
let user = WidgetConfiguration.User(
    name: "John Doe",           // Optional
    email: "john@example.com",  // Optional
    phoneNumber: "+1234567890",  // Optional
    identifier: "user-42",       // Optional - needs identifierHash
    identifierHash: "hash123",   // Optional - needs identifier
    customAttributes: ["plan": "pro"] // Optional
)
```

The verified `set-user` event is sent once per page load, at ready, and only when both `identifier` and `identifierHash` are set. `name`, `email`, `phoneNumber` and the user `customAttributes` are passed to the widget on their own and need no hash. They are not verified: on the customer's first message the server updates the contact, and can merge into an existing contact with the same email or phone. User custom attributes go with every message the customer types, not onto the contact.

### Conversation Tokens

By default the SDK stores the conversation token in `UserDefaults` under `instanceId` and loads it on the next `initialize`. To manage it yourself, pass `conversationToken` and `onConversationTokenChange`. The SDK then stores nothing, and `widgetDidChangeConversationToken(_:)` on the delegate also reports each new token. A re-`initialize` reads the token again from the configuration or the store, so pass a new configuration when the user changes.

### Custom Attributes

```swift
let customAttributes: [String: Any] = [
    "plan": "premium",
    "account_created": "2024-01-01",
    "total_orders": 42,
    "preferences": ["email_notifications": true]
]
```

## API Reference

### LimechatWidgetView Methods

#### `initialize(with configuration: WidgetConfiguration, initialMessage: String? = nil, initialMessageData: [String: Any]? = nil)`
Initialize the widget with configuration. `initialMessage` or `initialMessageData` (`["content": ..., "submitted_values": ...]`) opens the widget with that message.

#### `open(message: String)` / `open(messageData: [String: Any])`
Open the widget with a message. Sent now if the widget is ready, otherwise held and sent at ready. A ready widget is never reloaded. If no load is running, `open` starts one. An empty value or a call before `initialize` does nothing. See [Open With a Message](README.md#open-with-a-message).

#### `setMessageAttributes(_ attributes: [String: Any]) -> Bool`
Attach custom attributes to the customer's next message. Returns `false` for an empty or non-JSON value. File attachments and email-only submits do not use up held attributes. `custom_attributes` set explicitly on the message payload win over held ones. See [Message Attributes](README.md#message-attributes). Needs a widget build containing `c8126fb7cd`.

#### `reload()`
Load the page again. Before `initialize` it does nothing. Held attributes and open messages stay, sent attributes are lost with the page.

#### `sendMessage(event: String, data: [String: Any])`
Send custom messages to the widget. A message sent before the widget is ready is lost.

```swift
widgetView.sendMessage(event: "custom-event", data: [
    "action": "button_clicked",
    "value": "subscribe"
])
```

### LimechatWidgetViewController

`LimechatWidgetViewController` also has `sendMessage`, `open(message:)`, `open(messageData:)`, `setMessageAttributes` and `reload()`, same as the view.

#### Static Method
```swift
static func present(
    from viewController: UIViewController,
    configuration: WidgetConfiguration,
    delegate: LimechatWidgetDelegate? = nil,
    initialMessage: String? = nil,
    initialMessageData: [String: Any]? = nil,
    animated: Bool = true,
    completion: (() -> Void)? = nil
)
```

### Launchers

`addWidgetIcon(configuration:delegate:position:customIcon:)` returns a `LimechatWidgetIcon`. `LimechatWidget(configuration:customButton:delegate:)` is a view you place yourself, with an optional custom button. Both present the widget on tap. `LimechatWidget` also has `open(message:messageData:)`, `setMessageAttributes` and `setUnreadCount(_:)`, and `LimechatWidgetIcon` has `setMessageAttributes` and `setUnreadCount(_:)`. The badge shows the count you set. Attributes reach the widget on tap or `open`. Attributes not sent yet when the user closes the widget stay held for the next open. Attributes already sent are lost when the widget closes, since each open is a new page. Set them again.

### LimechatWidgetDelegate

```swift
protocol LimechatWidgetDelegate: AnyObject {
    func widgetDidLoad()
    func widgetDidRequestClose()
    func widgetDidReceiveError(_ error: WidgetError)
    func widgetDidReceiveMessage(_ message: [String: Any])
    func widgetDidReceiveUnreadCount(_ count: Int) // optional
    func widgetDidChangeConversationToken(_ token: String) // optional
}
```

`widgetDidLoad` fires once per page load, when the widget can receive messages. A failed page gives `widgetDidReceiveError` and no `widgetDidLoad`. A page that returns 200 but never mounts gives neither.

At ready the SDK sends the verified `set-user` event, held attributes, then a held open message. Then `widgetDidChangeConversationToken` and `widgetDidLoad` fire. `widgetDidReceiveError` also reports web process failures: if the web process dies (for example under memory pressure), ready resets and the SDK reloads the page once. Held attributes and a held open message stay and go out at the next ready, attributes first. Attributes already sent are lost with the page. If the process dies again before the page is ready, the SDK does not reload again and `widgetDidReceiveError` gets `Widget web process died again before ready`. The page stays blank after that, so dismiss the widget on this error. `LimechatWidgetViewController` and the launchers have no native close. Only a ready page resets the one-reload allowance. A later `open(message:)` or `reload()` still loads the page.

| callback | fires |
|---|---|
| `widgetDidLoad` | once per page load, at ready |
| `widgetDidReceiveError` | configuration, load, http (400 and above), serialisation and web process errors |
| `widgetDidRequestClose` | the widget asked to close |
| `widgetDidReceiveUnreadCount` | the widget reported a new unread count |
| `widgetDidChangeConversationToken` | the widget reported a conversation token |
| `widgetDidReceiveMessage` | any other widget event |

### WidgetError

```swift
enum WidgetError: LocalizedError {
    case configurationError(String)
    case webViewError(String)
}
```

A main frame http error of 400 or more arrives as `webViewError("HTTP error: <status>")`. A launcher that cannot present the widget or deliver a message reports it on the delegate.

All calls must run on the main thread.

## Best Practices

### 1. Memory Management

The widget view releases its resources when it is deallocated. Keep a single reference to it and drop that reference when you are done.

### 2. Error Handling

```swift
func widgetDidReceiveError(_ error: WidgetError) {
    switch error {
    case .configurationError(let message):
        showAlert(title: "Configuration Error", message: message)
    case .webViewError(let message):
        showAlert(title: "Widget Error", message: message)
    }
}
```

### 3. User Authentication

For secure user identification:
```swift
// Generate the hash on your backend: HMAC-SHA256(hmac_token, identifier)
let identifierHash = generateSecureHash(userId: currentUser.id)

let user = WidgetConfiguration.User(
    name: currentUser.name,
    email: currentUser.email,
    identifier: currentUser.id,
    identifierHash: identifierHash
)
```

### 4. Localization

Support multiple languages:
```swift
let locale = Locale.current.languageCode ?? "en"
let configuration = WidgetConfiguration(
    websiteToken: "YOUR_TOKEN",
    locale: locale,
    // ... other config
)
```

## Troubleshooting

### Widget Not Loading
- Verify internet connectivity
- Check website token is correct
- Ensure Info.plist allows web content (if needed):
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```

### Layout Issues
- Ensure proper Auto Layout constraints
- Check safe area handling for devices with notch

### JavaScript Errors
- Enable WebView debugging in Safari
- Check console logs for JavaScript errors

## Support

- GitHub Issues: [limechat-ios-sdk/issues](https://github.com/wavicle-limechat/widget-sdk-ios/issues)
- Email: support@limechat.ai
- Documentation: [docs.limechat.ai](https://docs.limechat.ai)