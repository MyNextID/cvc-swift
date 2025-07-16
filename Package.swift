// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CVC",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "CVC",
            targets: ["CVC"])
    ],
    targets: [
        .binaryTarget(
            name: "cvc",
            path: "cvc.xcframework"
        ),
        .target(
            name: "CVC",
            dependencies: ["cvc"],
            path: "Sources/CVC"
        ),
        .testTarget(
            name: "CVCTests",
            dependencies: ["CVC"],
            path: "Tests/CVCTests"
        )
    ]
)