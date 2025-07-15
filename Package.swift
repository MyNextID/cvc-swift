// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "cvc-swift",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "cvc-swift",
            targets: ["cvc-swift"])
    ],
    targets: [
        .binaryTarget(
            name: "cvc",
            path: "cvc.xcframework"
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