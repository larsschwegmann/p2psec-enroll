// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "p2psec-enroll",
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/IBM-Swift/BlueSocket.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "p2psec-enroll",
            dependencies: ["CryptoSwift", "Socket"])
    ]
)
