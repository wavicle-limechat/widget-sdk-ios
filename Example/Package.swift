// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LimechatWidgetExample",
    platforms: [
        .iOS(.v13)
    ],
    dependencies: [
        .package(name: "LimechatWidget", path: "../")
    ],
    targets: [
        .executableTarget(
            name: "LimechatWidgetExample",
            dependencies: [
                .product(name: "LimechatWidget", package: "LimechatWidget")
            ]
        )
    ]
)