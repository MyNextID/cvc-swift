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
            url: "https://github.com/MyNextID/cvc-swift/releases/download/v0.1.0/cvc.xcframework.zip",
            checksum: "f5a6b4cba5f9c00e6c9b4bdd79541622f1ef857d283c3496cc55d317f51860d8"
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