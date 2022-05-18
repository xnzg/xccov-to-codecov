// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xccov-to-codecov",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "xccov-to-codecov",
            targets: ["xccov-to-codecov"]),
    ],
    dependencies: [
        .package(url: "https://github.com/xnzg/swift-async-shell", exact: "0.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .executableTarget(
            name: "xccov-to-codecov",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Library",
            ]),
        .target(
            name: "Library",
            dependencies: [
                .product(name: "AsyncShell", package: "swift-async-shell"),
            ]
        )
    ]
)
