// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Remind",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Remind", targets: ["Remind"])
    ],
    targets: [
        .executableTarget(
            name: "Remind",
            path: "Sources/Remind"
        )
    ]
)
