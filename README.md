# Limechat iOS SDK

Native iOS SDK for integrating Limechat customer support widget into your iOS applications.

## Features

- 🎯 Native Swift implementation
- 📱 Full-screen modal presentation
- 🎨 Light/Dark/Auto theme support
- 🔒 Secure user identification
- 🌍 Multi-language support (en, es, fr, de, it, pt)
- 📦 Swift Package Manager & CocoaPods support
- 🔄 SwiftUI and UIKit compatible
- 📲 iOS 13.0+ support

## Quick Start

### Installation

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/limechat/limechat-ios-sdk.git", from: "1.0.0")
]
```

#### CocoaPods

```ruby
pod 'LimechatWidget', '~> 1.0.0'
```

### Basic Usage

```swift
import LimechatWidget

// Create configuration
let user = WidgetConfiguration.User(
    name: "John Doe",
    email: "john.doe@example.com"
)

let configuration = WidgetConfiguration(
    websiteToken: "YOUR_WEBSITE_TOKEN",
    locale: "en",
    colorScheme: .auto,
    user: user
)

// Present widget modally
LimechatWidgetViewController.present(
    from: self,
    configuration: configuration,
    delegate: self
)
```

### SwiftUI Integration

```swift
struct ContentView: View {
    @State private var showWidget = false
    
    var body: some View {
        Button("Open Support") {
            showWidget = true
        }
        .sheet(isPresented: $showWidget) {
            LimechatWidgetView(
                configuration: configuration,
                isPresented: $showWidget
            )
        }
    }
}
```

## Documentation

- [Integration Guide](INTEGRATION_GUIDE.md) - Detailed integration instructions
- [Deployment Guide](DEPLOYMENT.md) - Publishing and distribution
- [API Reference](https://docs.limechat.ai/ios) - Complete API documentation

## Example App

To test the iOS SDK:

1. **Open the main package in Xcode:**
```bash
open Package.swift
```

2. **Or create a new iOS app project and follow the integration guide:**
```bash
cd Example
cat README.md  # Follow the detailed instructions
```

Note: The SDK requires iOS/Xcode to build since it uses UIKit and WebKit frameworks.

## Requirements

- iOS 13.0+
- Xcode 13.0+
- Swift 5.7+

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@limechat.ai
- 🐛 Issues: [GitHub Issues](https://github.com/limechat/limechat-ios-sdk/issues)
- 📚 Docs: [docs.limechat.ai](https://docs.limechat.ai)