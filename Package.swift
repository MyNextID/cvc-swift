// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "cvc-swift",
    platforms: [
        .iOS(.v18)  // int128 requirements
    ],
    products: [
        .library(
            name: "cvc-swift",
            targets: ["cvc-swift"])
    ],
    targets: [
        .binaryTarget(
            name: "cvc",
            url: "https://github.com/MyNextID/cvc-swift/releases/download/0.1.0/cvc.xcframework.zip",
            checksum: "todo"
        ),
        .target(
            name: "cvc-swift",
            dependencies: ["cvc"]
        ),
        .testTarget(
            name: "cvc-swiftTests",
            dependencies: ["cvc-swift"]
        ),
    ]
)