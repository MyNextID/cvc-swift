# Get newer CVC library

Use `install.sh` script first and specify the version that you want.
Look at https://github.com/MyNextID/cvc/releases to get the correct version example: `v0.2.0`

```bash
scripts/release.sh v0.1.3
```

```bash
xcodebuild -create-xcframework \
-library lib/ios-device/arm64/libcvc.a \
-headers include/ \
-library lib/ios-simulator/arm64/libcvc.a \
-headers include/ \
-output cvc.xcframework
```

# XCFramework Distribution via Swift Package Manager

This guide explains how to distribute your XCFramework as a public Swift Package that can be consumed by iOS 18+
projects.

## Overview

Your `cvc.xcframework` contains C library code with `int128` support, which requires iOS 18+ devices. This guide will
help you:

1. Prepare your XCFramework for distribution
2. Create GitHub releases with proper assets
3. Update your Package.swift for public consumption
4. Tag and publish your package

## Prerequisites

- ✅ Your XCFramework is already built (`cvc.xcframework`)
- ✅ You have a GitHub repository: `https://github.com/MyNextID/cvc-swift`
- ✅ Swift Package Manager tools installed locally
- ✅ Write access to your GitHub repository

## Step-by-Step Release Process

### Step 1: Prepare Your XCFramework for Distribution

First, create a ZIP archive of your XCFramework from your project root:

```bash
# Navigate to your project directory (where cvc.xcframework exists)
cd /path/to/your/cvc-swift-project

# Create a ZIP file of your XCFramework
zip -r cvc.xcframework.zip cvc.xcframework
```

**Why ZIP?** Swift Package Manager requires binary targets to be distributed as ZIP files with specific checksums for
security and integrity verification.

### Step 2: Compute the Checksum

Generate the SHA256 checksum that Swift Package Manager requires:

```bash
# Compute the checksum (save this output for Step 4)
swift package compute-checksum cvc.xcframework.zip
```

**Example output:**

```
a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

**⚠️ Important:** Save this checksum value - you'll need it in Step 4.

### Step 3: Create a GitHub Release

1. **Go to your repository on GitHub**: `https://github.com/MyNextID/cvc-swift`

2. **Click on "Releases"** (in the right sidebar or under the Code tab)

3. **Click "Create a new release"**

4. **Fill out the release form:**
    - **Tag version**: `1.0.0` (or your preferred version)
    - **Release title**: `v1.0.0`
    - **Description**: Brief description of your release
    - **Attach files**: Drag and drop your `cvc.xcframework.zip` file

5. **Click "Publish release"**

**Result:** Your ZIP file will now be available at:
`https://github.com/MyNextID/cvc-swift/releases/download/1.0.0/cvc.xcframework.zip`

### Step 4: Update Your Package.swift

Replace your current Package.swift with this updated version:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "cvc-swift",
    platforms: [
        .iOS(.v18)  // Required for int128 support
    ],
    products: [
        .library(
            name: "cvc-swift",
            targets: ["cvc-swift"])
    ],
    targets: [
        .binaryTarget(
            name: "cvc",
            url: "https://github.com/MyNextID/cvc-swift/releases/download/1.0.0/cvc.xcframework.zip",
            checksum: "PASTE_YOUR_CHECKSUM_HERE"
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
```

**Key changes:**

- ✅ `url`: Points to your GitHub release ZIP file
- ✅ `checksum`: Replace `PASTE_YOUR_CHECKSUM_HERE` with the checksum from Step 2
- ✅ Version in URL matches your GitHub release tag

### Step 5: Commit and Tag Your Changes

```bash
# Add the updated Package.swift
git add Package.swift

# Commit the changes
git commit -m "Update Package.swift for public distribution v1.0.0"

# Create and push the tag (must match your GitHub release tag)
git tag 1.0.0
git push origin main --tags
```

**Why tag?** The git tag must match your GitHub release tag so consumers can reference specific versions.

### Step 6: Verify Your Package

Test that your package works correctly:

```bash
# Resolve dependencies to verify the package works
swift package resolve
```

If successful, you should see output indicating the package resolved correctly.

## How Consumers Will Use Your Package

Once published, developers can add your package to their iOS 18+ projects:

### In Xcode:

1. **File → Add Package Dependencies...**
2. **Enter URL**: `https://github.com/MyNextID/cvc-swift`
3. **Select version**: `1.0.0` (or latest)
4. **Add to target**

### In another Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/MyNextID/cvc-swift", from: "1.0.0")
]
```

### Usage in Swift code:

```swift
import cvc_swift

// Your framework functions will be available here
```

## Releasing Updates (Future Versions)

When you need to release a new version (e.g., 1.1.0):

1. **Update your XCFramework** (rebuild with new changes)
2. **Repeat Steps 1-2** (ZIP and compute new checksum)
3. **Create new GitHub release** with tag `1.1.0`
4. **Update Package.swift** with new URL and checksum
5. **Commit and tag** with `1.1.0`

## Troubleshooting

### ❌ "No such module 'cvc_swift'"

- Verify the import name matches your target name
- Check that iOS deployment target is 18.0+

### ❌ Checksum validation failed

- Ensure the checksum in Package.swift exactly matches the computed checksum
- Verify the ZIP file wasn't corrupted during upload

### ❌ Cannot resolve package dependencies

- Check that the GitHub release URL is publicly accessible
- Verify the tag exists in your repository
- Ensure the ZIP file is attached to the release

## Additional Notes

- **iOS 18+ Requirement**: Your package correctly specifies iOS 18+ due to int128 usage
- **Public Distribution**: Your package will be publicly available once published
- **Versioning**: Follow semantic versioning (major.minor.patch) for releases
- **Security**: Checksums ensure integrity - never skip this step

## Repository Structure

Your final repository should look like:

```
cvc-swift/
├── Package.swift          # Updated with remote URL and checksum
├── Sources/
│   └── cvc-swift/        # Your Swift wrapper code
├── Tests/
│   └── cvc-swiftTests/   # Your test files  
├── cvc.xcframework/      # Your built framework (local development)
└── README.md            # This file
```

---

**🎉 Success!** Your XCFramework is now distributed as a Swift Package and ready for public consumption.