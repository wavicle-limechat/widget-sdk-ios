# Limechat iOS SDK

Native iOS SDK for integrating Limechat customer support widget into your iOS applications.

## Features

- 🎯 Native Swift implementation
- 📱 Full-screen modal presentation
- 🎨 Light/Dark/Auto theme support
- 🔒 Secure user identification
- 🌍 Multi-language support
- 📦 Swift Package Manager support
- 🔄 SwiftUI and UIKit compatible
- 📲 iOS 13.0+ support
- 🎯 Floating widget icon (optional)

## Installation

### Swift Package Manager

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/limechat/limechat-ios-sdk.git`
3. Select the version you want to use
4. Click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/limechat/limechat-ios-sdk.git", from: "1.0.0")
]
```

## Quick Start

### Option 1: Floating Widget Icon (Recommended)

Add a floating widget icon to any view controller - **Just 3 lines of code!**

```swift
import LimechatWidget

class YourViewController: UIViewController, LimechatWidgetDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add floating widget icon - that's it!
        addWidgetIcon(
            configuration: WidgetConfiguration(
                websiteToken: "YOUR_WEBSITE_TOKEN",
                user: WidgetConfiguration.User(name: "John", email: "john@example.com")
            ),
            delegate: self
        )
    }
    
    // MARK: - LimechatWidgetDelegate
    
    func widgetDidLoad() {
        print("Widget loaded successfully")
    }
    
    func widgetDidRequestClose() {
        print("Widget closed")
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        print("Widget error: \(error.localizedDescription)")
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        print("Widget message: \(message)")
    }
    
    func widgetDidReceiveUnreadCount(_ count: Int) {
        print("Unread count: \(count)")
    }
}
```

### Option 2: Manual Presentation

Present the widget manually when needed:

```swift
import LimechatWidget

class YourViewController: UIViewController, LimechatWidgetDelegate {
    
    @IBAction func openSupportTapped(_ sender: Any) {
        // Present widget manually
        LimechatWidgetViewController.present(
            from: self,
            configuration: WidgetConfiguration(
                websiteToken: "YOUR_WEBSITE_TOKEN",
                user: WidgetConfiguration.User(name: "John", email: "john@example.com")
            ),
            delegate: self
        )
    }
    
    // MARK: - LimechatWidgetDelegate
    
    func widgetDidLoad() {
        print("Widget loaded successfully")
    }
    
    func widgetDidRequestClose() {
        print("Widget closed")
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        print("Widget error: \(error.localizedDescription)")
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        print("Widget message: \(message)")
    }
    
    func widgetDidReceiveUnreadCount(_ count: Int) {
        print("Unread count: \(count)")
    }
}
```

### SwiftUI Integration

Complete SwiftUI example with both options:

```swift
import SwiftUI
import LimechatWidget

struct ContentView: View {
    @State private var showWidget = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Limechat Widget Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    Button("Open Widget Manually") {
                        showWidget = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("Or use the floating icon (UIKit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showWidget) {
            WidgetViewWrapper()
        }
    }
}

struct WidgetViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> LimechatWidgetViewController {
        let config = WidgetConfiguration(
            websiteToken: "YOUR_WEBSITE_TOKEN",
            user: WidgetConfiguration.User(name: "John", email: "john@example.com")
        )
        
        let widgetVC = LimechatWidgetViewController(configuration: config)
        widgetVC.widgetDelegate = context.coordinator
        return widgetVC
    }
    
    func updateUIViewController(_ uiViewController: LimechatWidgetViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, LimechatWidgetDelegate {
        func widgetDidLoad() {
            print("Widget loaded")
        }
        
        func widgetDidRequestClose() {
            print("Widget closed")
        }
        
        func widgetDidReceiveError(_ error: WidgetError) {
            print("Widget error: \(error.localizedDescription)")
        }
        
        func widgetDidReceiveMessage(_ message: [String : Any]) {
            print("Widget message: \(message)")
        }
        
        func widgetDidReceiveUnreadCount(_ count: Int) {
            print("Unread count: \(count)")
        }
    }
}

// MARK: - UIKit Example with Floating Icon

class UIKitExampleViewController: UIViewController, LimechatWidgetDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // Add floating widget icon - just one line!
        addWidgetIcon(
            configuration: WidgetConfiguration(
                websiteToken: "YOUR_WEBSITE_TOKEN",
                user: WidgetConfiguration.User(name: "John", email: "john@example.com")
            ),
            delegate: self
        )
        
        // Add some UI
        let titleLabel = UILabel()
        titleLabel.text = "Limechat Widget Demo"
        titleLabel.font = .largeTitle
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Tap the floating icon to open the widget"
        descriptionLabel.font = .body
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - LimechatWidgetDelegate
    
    func widgetDidLoad() {
        print("Widget loaded successfully")
    }
    
    func widgetDidRequestClose() {
        print("Widget closed")
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        print("Widget error: \(error.localizedDescription)")
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        print("Widget message: \(message)")
    }
    
    func widgetDidReceiveUnreadCount(_ count: Int) {
        print("Unread count: \(count)")
    }
}

#Preview {
    ContentView()
}
```

## Integration Comparison

Both iOS and React Native SDKs are designed to be equally easy to integrate:

### iOS SDK (Floating Icon)
```swift
// Just 3 lines of code!
addWidgetIcon(
    configuration: WidgetConfiguration(websiteToken: "YOUR_TOKEN"),
    delegate: self
)
```

### React Native SDK (Floating Icon)
```javascript
// Just 3 lines of code!
<LimeChatWidget
  websiteToken="YOUR_TOKEN"
  onWidgetLoad={() => console.log('Widget loaded')}
/>
```

Both SDKs provide:
- ✅ **Default floating icon** with message icon
- ✅ **Unread count badge** support
- ✅ **Custom icon** support
- ✅ **Manual presentation** option
- ✅ **Same configuration** structure
- ✅ **Same delegate/callback** pattern

## Configuration

### WidgetConfiguration

```swift
let configuration = WidgetConfiguration(
    websiteToken: "YOUR_WEBSITE_TOKEN",  // Required
    locale: "en",                        // Optional, defaults to "en"
    colorScheme: .auto,                  // Optional, defaults to .auto
    user: user,                          // Optional
    customAttributes: ["key": "value"]   // Optional
)
```

### Color Schemes

- `.light` - Always use light theme
- `.dark` - Always use dark theme  
- `.auto` - Automatically match system theme (default)

### User Information

```swift
let user = WidgetConfiguration.User(
    name: "John Doe",           // Optional
    email: "john@example.com",  // Optional
    phoneNumber: "+1234567890"  // Optional
)
```

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
icon.iconSize = 70
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
        // Widget finished loading
    }
    
    func widgetDidRequestClose() {
        // Widget requested to close
    }
    
    func widgetDidReceiveError(_ error: WidgetError) {
        // Widget encountered an error
    }
    
    func widgetDidReceiveMessage(_ message: [String: Any]) {
        // Widget sent a message
    }
    
    func widgetDidReceiveUnreadCount(_ count: Int) {
        // Widget updated unread count
        // Update your floating icon if using one
        widgetIcon?.setUnreadCount(count)
    }
}
```

## Requirements

- iOS 13.0+
- Xcode 13.0+
- Swift 5.7+

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@limechat.ai
- 🐛 Issues: [GitHub Issues](https://github.com/limechat/limechat-ios-sdk/issues)
- 📚 Documentation: [docs.limechat.ai](https://docs.limechat.ai)