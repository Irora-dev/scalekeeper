// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScaleUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ScaleUI",
            targets: ["ScaleUI"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ScaleUI",
            dependencies: []
        ),
        .testTarget(
            name: "ScaleUITests",
            dependencies: ["ScaleUI"]
        ),
    ]
)
