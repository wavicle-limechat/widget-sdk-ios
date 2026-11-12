# Deployment Guide

This guide explains how to publish the Limechat iOS SDK for public use.

## Publishing to GitHub

### 1. Prepare the Repository

`./scripts/release.sh <version>` (from `main`, clean tree, so merge to main first) runs `xcodebuild test -scheme LimechatWidget` on an iOS simulator, stamps today's date on the `## [<version>]` changelog header (it fails if that header is missing), then commits, tags and pushes. It picks the first booted or available iPhone simulator. Set `DESTINATION` to override, for example `DESTINATION='platform=iOS Simulator,name=iPhone 16'`. The manual steps are:

1. **Ensure all files are committed:**
   ```bash
   git add .
   git commit -m "Prepare for v0.2.0 release"
   ```

2. **Create a git tag for the version:**
   ```bash
   git tag -a v0.2.0 -m "Release version 0.2.0"
   git push origin v0.2.0
   ```

### 2. Create GitHub Release

1. Go to your GitHub repository
2. Click on "Releases" in the right sidebar
3. Click "Create a new release"
4. Select the tag you just created (`v0.2.0`)
5. Add release title: `Limechat iOS SDK v0.2.0`
6. Add release description with features and changes
7. Upload any additional files if needed
8. Click "Publish release"

### 3. Verify Swift Package Manager Integration

After publishing, users should be able to add your package in Xcode:

1. **In Xcode:**
   - File → Add Package Dependencies
   - Enter: `https://github.com/wavicle-limechat/widget-sdk-ios.git`
   - Select version: `0.2.0`

2. **Or in Package.swift:**
   ```swift
   dependencies: [
       .package(url: "https://github.com/wavicle-limechat/widget-sdk-ios.git", from: "0.2.0")
   ]
   ```

## Version Management

### Semantic Versioning

Follow [Semantic Versioning](https://semver.org/) for version numbers:

- **MAJOR.MINOR.PATCH** (e.g., 1.0.0)
- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Release Process

1. **Update version numbers:**
   - Update `CHANGELOG.md`
   - Update version in `Package.swift` (if needed)

2. **Create git tag:**
   ```bash
   git tag -a v1.0.1 -m "Release version 1.0.1"
   git push origin v1.0.1
   ```

3. **Create GitHub release**

## Testing Before Release

### 1. Local Testing

```bash
# Test the package locally
swift package test

# Build the package
swift build
```

### 2. Integration Testing

1. Create a test iOS project
2. Add your package as a dependency
3. Test all major functionality
4. Verify SwiftUI and UIKit integration

### 3. Documentation Review

- [ ] README.md is up to date
- [ ] Code examples work correctly
- [ ] Installation instructions are clear
- [ ] API documentation is complete

## Support and Maintenance

### After Release

1. **Monitor issues** on GitHub
2. **Respond to user questions** promptly
3. **Plan future releases** based on feedback
4. **Keep documentation updated**

### Breaking Changes

If you need to make breaking changes:

1. **Plan the migration** carefully
2. **Document the changes** clearly
3. **Provide migration guides**
4. **Consider maintaining multiple versions** if needed

## Security Considerations

- Keep dependencies updated
- Review code for security issues
- Use HTTPS for all URLs
- Validate user inputs
- Follow iOS security best practices