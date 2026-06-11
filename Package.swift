// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Harmony",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "Harmony",
            targets: ["Harmony"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ios-tooling/chronicle", from: "0.0.29"),
        .package(url: "https://github.com/ios-tooling/suite", from: "1.4.12"),
    ],
    targets: [
        .target(
            name: "Harmony",
            dependencies: [
                .product(name: "Chronicle", package: "chronicle"),
                .product(name: "Suite", package: "suite"),
            ]
        ),
        .testTarget(
            name: "HarmonyTests",
            dependencies: ["Harmony"]
        ),
    ]
)
