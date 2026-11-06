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
    .package(url: "https://github.com/wavicle-limechat/widget-sdk-ios.git", from: "1.0.0")
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
            colorScheme: .light, // .light, .dark, or .auto
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
            colorScheme: .auto,
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

// MARK: - LimechatWidgetDelegate

extension MainViewController: LimechatWidgetDelegate {
    
    func widgetDidLoad() {
        print("Widget loaded")
    }
    
    func widgetDidRequestClose() {
        print("Widget closed")
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        print("Error: \(error)")
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        print("Message: \(message)")
    }
}
```

## SwiftUI Integration

### SwiftUI View Wrapper

```swift
import SwiftUI
import LimechatWidget

struct LimechatWidgetView: UIViewControllerRepresentable {
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
        let parent: LimechatWidgetView
        
        init(_ parent: LimechatWidgetView) {
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
            LimechatWidgetView(
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
            colorScheme: .auto,
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
| `colorScheme` | ColorScheme | .light, .dark, or .auto. The widget has no dark mode today, so this has no visible effect | No (default: .auto) |
| `user` | User? | User details object | No |
| `customAttributes` | [String: Any]? | Custom data to attach | No |
| `baseURL` | String | Custom base URL | No (default: production) |
| `hideFilePicker` | Bool | Hides the attachment button in the widget | No (default: false) |

### User Object

```swift
let user = WidgetConfiguration.User(
    name: "John Doe",           // Optional
    email: "john@example.com",  // Optional
    phoneNumber: "+1234567890",  // Optional
    identifier: "user-42",       // Optional - needs identifierHash
    identifierHash: "hash123"    // Optional - needs identifier
)
```

`set-user` is sent after the page loads only when both `identifier` and `identifierHash` are set. `name`, `email` and `phoneNumber` are passed to the widget on their own and need no hash.

### Color Schemes

`colorScheme` is set when you create the configuration. The widget has no dark mode today, so the value has no visible effect.

```swift
let configuration = WidgetConfiguration(
    websiteToken: "YOUR_WEBSITE_TOKEN",
    colorScheme: .auto // .light, .dark or .auto (default)
)
```

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
Reload the widget and open it with a message. Does nothing before `initialize`.

#### `sendMessage(event: String, data: [String: Any])`
Send custom messages to the widget.

```swift
widgetView.sendMessage(event: "custom-event", data: [
    "action": "button_clicked",
    "value": "subscribe"
])
```

### LimechatWidgetViewController

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

### LimechatWidgetDelegate

```swift
protocol LimechatWidgetDelegate: AnyObject {
    func widgetDidLoad()
    func widgetDidRequestClose()
    func widgetDidReceiveError(_ error: WidgetError)
    func widgetDidReceiveMessage(_ message: [String: Any])
}
```

### WidgetError

```swift
enum WidgetError: LocalizedError {
    case configurationError(String)
    case networkError(String)
    case webViewError(String)
    case unknownError(String)
}
```

## Best Practices

### 1. Memory Management

The widget view releases its resources when it is deallocated. Keep a single reference to it and drop that reference when you are done.

### 2. Error Handling

Implement comprehensive error handling:
```swift
func widgetDidReceiveError(_ error: WidgetError) {
    switch error {
    case .networkError(let message):
        showAlert(title: "Network Error", message: message)
    case .configurationError(let message):
        showAlert(title: "Configuration Error", message: message)
    default:
        showAlert(title: "Error", message: error.localizedDescription)
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