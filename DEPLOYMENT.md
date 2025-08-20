# iOS SDK Deployment Guide

## Prerequisites

- Xcode 13.0 or later
- Swift 5.7 or later
- iOS deployment target 13.0 or later
- Apple Developer Account (for App Store distribution)
- CocoaPods or Swift Package Manager

## Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/limechat/limechat-widget-sdks.git
cd limechat-widget-sdks/limechat-ios-sdk
```

### 2. Open in Xcode

```bash
open Package.swift
```

Or double-click the `Package.swift` file to open in Xcode.

### 3. Build the Package

In Xcode:
1. Select Product → Build (⌘B)
2. Ensure the build succeeds without errors

### 4. Run Tests

```bash
swift test
```

Or in Xcode:
1. Select Product → Test (⌘U)

## Publishing the SDK

### Option 1: Swift Package Manager (Recommended)

#### Step 1: Tag Your Release

```bash
# Ensure all changes are committed
git add .
git commit -m "Release version 1.0.0"

# Create a tag
git tag 1.0.0
git push origin main --tags
```

#### Step 2: Create GitHub Release

1. Go to your GitHub repository
2. Click on "Releases" → "Create a new release"
3. Select your tag (1.0.0)
4. Add release notes
5. Publish release

#### Step 3: Users Can Add via SPM

Users add the package in Xcode:
1. File → Add Packages
2. Enter repository URL: `https://github.com/limechat/limechat-ios-sdk.git`
3. Select version rules

Or in `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/limechat/limechat-ios-sdk.git", from: "1.0.0")
]
```

### Option 2: CocoaPods

#### Step 1: Create Podspec

Create `LimechatWidget.podspec`:

```ruby
Pod::Spec.new do |spec|
  spec.name         = "LimechatWidget"
  spec.version      = "1.0.0"
  spec.summary      = "iOS SDK for Limechat Widget"
  spec.description  = <<-DESC
    Native iOS SDK for integrating Limechat customer support widget into your iOS applications.
  DESC
  
  spec.homepage     = "https://github.com/limechat/limechat-ios-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Limechat" => "support@limechat.ai" }
  
  spec.platform     = :ios, "13.0"
  spec.swift_version = "5.7"
  
  spec.source       = { 
    :git => "https://github.com/limechat/limechat-ios-sdk.git", 
    :tag => "#{spec.version}" 
  }
  
  spec.source_files = "Sources/LimechatWidget/**/*.{swift,h,m}"
  spec.frameworks   = "UIKit", "WebKit", "Foundation"
  
  spec.requires_arc = true
end
```

#### Step 2: Validate Podspec

```bash
pod lib lint LimechatWidget.podspec
```

#### Step 3: Push to CocoaPods Trunk

```bash
# Register (first time only)
pod trunk register your-email@example.com 'Your Name'

# Push podspec
pod trunk push LimechatWidget.podspec
```

### Option 3: XCFramework Distribution

#### Step 1: Build XCFramework

Create build script `build-xcframework.sh`:

```bash
#!/bin/bash

# Clean previous builds
rm -rf build
mkdir build

# Build for iOS Simulator
xcodebuild archive \
  -scheme LimechatWidget \
  -archivePath build/LimechatWidget-iphonesimulator.xcarchive \
  -sdk iphonesimulator \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS Device
xcodebuild archive \
  -scheme LimechatWidget \
  -archivePath build/LimechatWidget-iphoneos.xcarchive \
  -sdk iphoneos \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Create XCFramework
xcodebuild -create-xcframework \
  -framework build/LimechatWidget-iphonesimulator.xcarchive/Products/Library/Frameworks/LimechatWidget.framework \
  -framework build/LimechatWidget-iphoneos.xcarchive/Products/Library/Frameworks/LimechatWidget.framework \
  -output build/LimechatWidget.xcframework

echo "XCFramework created at build/LimechatWidget.xcframework"
```

#### Step 2: Run Build Script

```bash
chmod +x build-xcframework.sh
./build-xcframework.sh
```

#### Step 3: Distribute

1. Zip the XCFramework:
```bash
cd build
zip -r LimechatWidget.xcframework.zip LimechatWidget.xcframework
```

2. Upload to your distribution channel (GitHub Release, CDN, etc.)

3. Create `Package.swift` for binary distribution:
```swift
// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "LimechatWidget",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "LimechatWidget",
            targets: ["LimechatWidget"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "LimechatWidget",
            url: "https://your-cdn.com/LimechatWidget.xcframework.zip",
            checksum: "YOUR_CHECKSUM_HERE"
        )
    ]
)
```

## Versioning

Follow [Semantic Versioning](https://semver.org/):
- MAJOR version for incompatible API changes
- MINOR version for backwards-compatible functionality
- PATCH version for backwards-compatible bug fixes

Example: `1.2.3`

## CI/CD Setup

### GitHub Actions Workflow

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - '*'

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode.app
    
    - name: Build Package
      run: swift build -c release
    
    - name: Run Tests
      run: swift test
    
    - name: Build XCFramework
      run: |
        chmod +x build-xcframework.sh
        ./build-xcframework.sh
    
    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        files: build/LimechatWidget.xcframework.zip
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Documentation

### Generate Documentation

Using [DocC](https://developer.apple.com/documentation/docc):

1. In Xcode: Product → Build Documentation
2. Export: Right-click on documentation → Export

Or using [Jazzy](https://github.com/realm/jazzy):

```bash
gem install jazzy
jazzy \
  --module LimechatWidget \
  --swift-version 5.7 \
  --author Limechat \
  --github_url https://github.com/limechat/limechat-ios-sdk \
  --output docs
```

## Testing Distribution

### Local Testing

1. Create a test app
2. Add local package dependency:
   - File → Add Packages
   - Click "Add Local..."
   - Select the SDK directory

### TestFlight Distribution

For testing with beta users:

1. Archive your sample app with the SDK
2. Upload to App Store Connect
3. Distribute via TestFlight

## Monitoring

### Analytics

Add analytics to track SDK usage:

```swift
// In LimechatWidgetView.swift
private func trackEvent(_ event: String, properties: [String: Any]? = nil) {
    // Send to your analytics service
    Analytics.track(event, properties: properties)
}
```

### Crash Reporting

Integrate crash reporting:

```swift
// Using Crashlytics example
import FirebaseCrashlytics

private func reportError(_ error: Error) {
    Crashlytics.crashlytics().record(error: error)
}
```

## Security

### Code Signing

1. Enable automatic code signing in Xcode
2. Use proper provisioning profiles
3. Sign XCFrameworks:

```bash
codesign --sign "Developer ID Application: Your Company" \
         --timestamp \
         build/LimechatWidget.xcframework
```

### App Transport Security

Ensure your SDK respects ATS:

```xml
<!-- In Info.plist if needed -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```

## Troubleshooting

### Common Issues

1. **Module not found**
   - Clean build folder: ⇧⌘K
   - Reset package caches: File → Packages → Reset Package Caches

2. **Signing issues**
   - Check provisioning profiles
   - Ensure developer certificate is valid

3. **Archive validation fails**
   - Check minimum deployment target
   - Verify all architectures are included

## Support

- GitHub Issues: [limechat-ios-sdk/issues](https://github.com/limechat/limechat-ios-sdk/issues)
- Email: support@limechat.ai
- Documentation: [docs.limechat.ai](https://docs.limechat.ai)