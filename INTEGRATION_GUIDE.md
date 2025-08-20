# Limechat iOS SDK Integration Guide

## Table of Contents
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Integration](#basic-integration)
- [Full-Screen Modal Implementation](#full-screen-modal-implementation)
- [SwiftUI Integration](#swiftui-integration)
- [Customization Options](#customization-options)
- [API Reference](#api-reference)
- [Comparison with React Native SDK](#comparison-with-react-native-sdk)
- [Best Practices](#best-practices)

## Requirements

- iOS 13.0+
- Xcode 13.0+
- Swift 5.7+

## Installation

### Swift Package Manager (Recommended)

#### Using Xcode

1. In Xcode, select **File → Add Packages**
2. Enter the repository URL: `https://github.com/limechat/limechat-ios-sdk.git`
3. Select version rule (e.g., "Up to Next Major Version")
4. Click **Add Package**

#### Using Package.swift

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/limechat/limechat-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'LimechatWidget', '~> 1.0.0'
```

Then run:
```bash
pod install
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
            identifierHash: nil // Optional for secure identification
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
            colorScheme: .auto, // Follows system theme
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
| `colorScheme` | ColorScheme | .light, .dark, or .auto | No (default: .light) |
| `user` | User? | User details object | No |
| `customAttributes` | [String: Any]? | Custom data to attach | No |
| `baseURL` | String | Custom base URL | No (default: production) |

### User Object

```swift
let user = WidgetConfiguration.User(
    name: "John Doe",           // Optional
    email: "john@example.com",  // Optional
    phoneNumber: "+1234567890",  // Optional
    identifierHash: "hash123"    // Optional - for secure identification
)
```

### Color Schemes

```swift
// Light theme
configuration.colorScheme = .light

// Dark theme
configuration.colorScheme = .dark

// Follow system theme (iOS 13+)
configuration.colorScheme = .auto
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

#### `initialize(with configuration: WidgetConfiguration)`
Initialize the widget with configuration.

#### `sendMessage(event: String, data: [String: Any])`
Send custom messages to the widget.

```swift
widgetView.sendMessage(event: "custom-event", data: [
    "action": "button_clicked",
    "value": "subscribe"
])
```

#### `goBack() -> Bool`
Navigate back in the WebView. Returns true if navigation occurred.

#### `destroy()`
Clean up resources when done.

### LimechatWidgetViewController

#### Static Method
```swift
static func present(
    from viewController: UIViewController,
    configuration: WidgetConfiguration,
    delegate: LimechatWidgetDelegate? = nil
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
    case javascriptError(String)
    case unknownError(String)
}
```

## Comparison with React Native SDK

### Similarities

Both iOS Native and React Native SDKs share:
- Same website token configuration
- User identification parameters
- Locale support
- Custom attributes
- Event callbacks (onLoad, onClose, onError)

### Key Differences

| Feature | React Native SDK | iOS Native SDK |
|---------|-----------------|----------------|
| **Integration** | JSX Component | UIViewController/UIView |
| **Custom Button** | `customButton` prop | Custom UIButton with presentation |
| **Unread Count** | Built-in with styling | Implement manually |
| **Configuration** | Props-based | WidgetConfiguration object |
| **Styling** | Style props | Native iOS UI |
| **Full Screen** | Modal/Navigation | LimechatWidgetViewController |
| **Language** | JavaScript/TypeScript | Swift/Objective-C |

### React Native Example
```jsx
<LimeChatWidget
  websiteToken="MEFFACy4xaovJayhLjSt836h"
  user={user}
  locale="en"
  customAttributes={customAttributes}
  onWidgetLoad={handleWidgetLoad}
  onWidgetClose={handleWidgetClose}
  onError={handleError}
  customButton={<CustomButton />}
  unreadCountStyle={{ top: -20 }}
/>
```

### iOS Native Equivalent
```swift
// Configuration
let config = WidgetConfiguration(
    websiteToken: "MEFFACy4xaovJayhLjSt836h",
    locale: "en",
    user: user,
    customAttributes: customAttributes
)

// Present modally
LimechatWidgetViewController.present(
    from: self,
    configuration: config,
    delegate: self
)

// Custom button
@IBAction func customButtonTapped(_ sender: UIButton) {
    presentWidget()
}
```

## Best Practices

### 1. Memory Management

Always clean up when done:
```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    widgetView?.destroy()
}
```

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
// Generate identifier hash on your backend
let identifierHash = generateSecureHash(userId: currentUser.id)

let user = WidgetConfiguration.User(
    name: currentUser.name,
    email: currentUser.email,
    identifierHash: identifierHash
)
```

### 4. Theme Handling

Respond to theme changes:
```swift
override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
        // Reinitialize widget with new color scheme if needed
    }
}
```

### 5. Localization

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

## Sample Project

A complete sample project is available in the `Example` directory:

```bash
cd limechat-ios-sdk/Example
open Example.xcodeproj
```

## Support

- GitHub Issues: [limechat-ios-sdk/issues](https://github.com/limechat/limechat-ios-sdk/issues)
- Email: support@limechat.ai
- Documentation: [docs.limechat.ai](https://docs.limechat.ai)