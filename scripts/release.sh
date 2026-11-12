#!/bin/bash

# Limechat iOS SDK Release Script
# Usage: ./scripts/release.sh <version>

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION=$1
TAG="v$VERSION"

echo "🚀 Preparing release for version $VERSION..."

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "❌ Error: You must be on the main branch to release. Merge your changes to main first, then run this from main."
    exit 1
fi

# Check if there are uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Error: You have uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Check if tag already exists
if git tag -l | grep -q "^$TAG$"; then
    echo "❌ Error: Tag $TAG already exists"
    exit 1
fi

# The package is iOS-only (UIKit), so swift build/test on macOS fails. Use xcodebuild on a simulator.
# Override with DESTINATION, e.g. DESTINATION='platform=iOS Simulator,name=iPhone 16'
if [ -z "$DESTINATION" ]; then
    SIM_ID=$(xcrun simctl list devices available | grep -E "iPhone" | grep -E "Booted" | head -1 | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}" || true)
    if [ -z "$SIM_ID" ]; then
        SIM_ID=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}" || true)
    fi
    if [ -z "$SIM_ID" ]; then
        echo "❌ Error: no available iPhone simulator found. Set DESTINATION and retry."
        exit 1
    fi
    DESTINATION="platform=iOS Simulator,id=$SIM_ID"
fi

echo "🧪 Running tests on $DESTINATION..."
xcodebuild test -scheme LimechatWidget -destination "$DESTINATION"

echo "📝 Updating CHANGELOG.md..."
# The header is "## [x.y.z]" with no date until release. Stamp today's date.
if ! grep -q "^## \[$VERSION\]$" CHANGELOG.md; then
    echo "❌ Error: CHANGELOG.md has no '## [$VERSION]' header without a date. Add or fix it and retry."
    exit 1
fi
sed -i '' "s/^## \[$VERSION\]$/## [$VERSION] - $(date +%Y-%m-%d)/" CHANGELOG.md

echo "🔖 Creating git tag..."
git add CHANGELOG.md
git commit -m "Release version $VERSION"
git tag -a "$TAG" -m "Release version $VERSION"

echo "📤 Pushing changes..."
git push origin main
git push origin "$TAG"

echo "✅ Release $VERSION prepared successfully!"
echo ""
echo "Next steps:"
echo "1. Go to GitHub and create a release for tag $TAG"
echo "2. Add release notes with features and changes"
echo "3. Publish the release"
echo ""
echo "Users can then add your package with:"
echo "https://github.com/wavicle-limechat/widget-sdk-ios.git"
echo "Version: $VERSION"
