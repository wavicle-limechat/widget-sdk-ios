// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LimechatWidget",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "LimechatWidget",
            targets: ["LimechatWidget"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LimechatWidget",
            dependencies: [],
            path: "Sources/LimechatWidget"
        ),
        .testTarget(
            name: "LimechatWidgetTests",
            dependencies: ["LimechatWidget"],
            path: "Tests/LimechatWidgetTests"
        ),
    ]
)