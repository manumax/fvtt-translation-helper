// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FvttTranslationHelper",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        //.package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2")
        .package(url: "https://github.com/manumax/SwiftyJSON", branch: "fix-nsnumber-comparable"),
    ],
    targets: [
        .executableTarget(
            name: "fvtt-translation-helper",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
            ]
        )
    ]
)
