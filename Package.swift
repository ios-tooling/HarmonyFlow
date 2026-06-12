// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HarmonyFlow",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "HarmonyFlow",
            targets: ["HarmonyFlow"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ios-tooling/chronicle", from: "0.0.29"),
        .package(url: "https://github.com/ios-tooling/suite", from: "1.4.12"),
    ],
    targets: [
        .target(
            name: "HarmonyFlow",
            dependencies: [
                .product(name: "Chronicle", package: "chronicle"),
                .product(name: "Suite", package: "suite"),
            ]
        ),
        .testTarget(
            name: "HarmonyFlowTests",
            dependencies: ["HarmonyFlow"]
        ),
    ]
)
