// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_social_share_plus",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "flutter-social-share-plus", targets: ["flutter_social_share_plus"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "Facebook", url: "https://github.com/facebook/facebook-ios-sdk.git", from: "17.0.0"),
    ],
    targets: [
        .target(
            name: "flutter_social_share_plus",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "FacebookCore", package: "Facebook"),
                .product(name: "FacebookShare", package: "Facebook"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
    ]
)
