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
    echo "❌ Error: You must be on the main branch to release"
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

echo "📦 Building package..."
swift build

echo "🧪 Running tests..."
swift test

echo "📝 Updating CHANGELOG.md..."
# Add a placeholder for the release date
sed -i '' "s/## \[$VERSION\] - Unreleased/## [$VERSION] - $(date +%Y-%m-%d)/" CHANGELOG.md

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
