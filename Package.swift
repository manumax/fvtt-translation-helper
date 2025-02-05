// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FvttTranslationHelper",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2")
    ],
    targets: [
        .executableTarget(
            name: "FvttTranslationHelper",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
            ],
            path: "Sources/Main"
        ),
        .testTarget(
            name: "FvttTranslationHelperTests",
            dependencies: ["FvttTranslationHelper"],
            path: "Sources/Tests"
        )
    ]
)
