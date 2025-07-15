#!/bin/bash

# Script to create XCFramework from mixed-platform static libraries
# This script fixes the "binaries with multiple platforms are not supported" error

set -e  # Exit on any error

# Configuration
DEVICE_LIB="lib/ios-device/arm64/libcvc.a"
SIMULATOR_LIB="lib/ios-simulator/arm64/libcvc.a"
HEADERS_DIR="include"
OUTPUT_XCFRAMEWORK="cvc.xcframework"
WORK_DIR="temp_xcframework_build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        print_error "File not found: $1"
        exit 1
    fi
}

# Function to get platform of an object file
get_platform() {
    local file="$1"
    local platform=$(otool -l "$file" 2>/dev/null | grep -A 2 "LC_BUILD_VERSION" | grep "platform" | head -1 | awk '{print $2}')
    echo "$platform"
}

# Function to check if object file is for iOS device (platform 1)
is_ios_device() {
    local platform=$(get_platform "$1")
    [ "$platform" = "1" ]
}

# Function to check if object file is for iOS simulator (platform 2 or 7)
is_ios_simulator() {
    local platform=$(get_platform "$1")
    [ "$platform" = "2" ] || [ "$platform" = "7" ]
}

# Function to extract and filter object files
extract_and_filter() {
    local input_lib="$1"
    local output_dir="$2"
    local platform_filter="$3"  # "device" or "simulator"

    print_info "Processing $input_lib for $platform_filter..."

    # Store original directory
    local original_dir=$(pwd)

    # Create extraction directory
    local extract_dir="$WORK_DIR/extract_$(basename "$input_lib" .a)"
    mkdir -p "$extract_dir"

    # Extract all object files
    cd "$extract_dir"
    ar -x "$input_lib"

    # Filter and copy appropriate object files
    local copied_count=0
    for obj in *.o; do
        if [ -f "$obj" ]; then
            if [ "$platform_filter" = "device" ] && is_ios_device "$obj"; then
                cp "$obj" "$output_dir/"
                ((copied_count++))
            elif [ "$platform_filter" = "simulator" ] && is_ios_simulator "$obj"; then
                cp "$obj" "$output_dir/"
                ((copied_count++))
            fi
        fi
    done

    cd "$original_dir"

    print_success "Copied $copied_count object files for $platform_filter"
}

# Function to create library from object files
create_library() {
    local obj_dir="$1"
    local output_lib="$2"
    local platform_name="$3"

    print_info "Creating $platform_name library: $output_lib"

    # Store original directory
    local original_dir=$(pwd)

    cd "$obj_dir"

    # Count object files
    local obj_count=$(ls -1 *.o 2>/dev/null | wc -l)
    if [ "$obj_count" -eq 0 ]; then
        print_error "No object files found for $platform_name"
        exit 1
    fi

    # Create the library
    ar -rcs "$output_lib" *.o

    cd "$original_dir"

    print_success "Created $platform_name library with $obj_count object files"
}

# Function to verify library platform
verify_library() {
    local lib_path="$1"
    local expected_platform="$2"
    local platform_name="$3"

    print_info "Verifying $platform_name library..."

    local platforms=$(otool -l "$lib_path" | grep -A 2 "LC_BUILD_VERSION" | grep "platform" | awk '{print $2}' | sort -u)

    echo "Platforms found in $platform_name library:"
    for platform in $platforms; do
        case $platform in
            1) echo "  - Platform 1 (iOS Device)" ;;
            2) echo "  - Platform 2 (iOS Simulator - old)" ;;
            7) echo "  - Platform 7 (iOS Simulator - new)" ;;
            *) echo "  - Platform $platform (Unknown)" ;;
        esac
    done

    # Check if library contains only expected platform(s)
    local platform_count=$(echo "$platforms" | wc -w)
    if [ "$expected_platform" = "device" ] && [ "$platform_count" -eq 1 ] && [ "$platforms" = "1" ]; then
        print_success "$platform_name library is clean (iOS Device only)"
    elif [ "$expected_platform" = "simulator" ] && [ "$platform_count" -le 2 ]; then
        # Simulator can have platform 2 or 7, or both
        local has_invalid=0
        for platform in $platforms; do
            if [ "$platform" != "2" ] && [ "$platform" != "7" ]; then
                has_invalid=1
            fi
        done
        if [ $has_invalid -eq 0 ]; then
            print_success "$platform_name library is clean (iOS Simulator only)"
        else
            print_warning "$platform_name library may contain mixed platforms"
        fi
    else
        print_warning "$platform_name library may contain mixed platforms"
    fi
}

# Main script starts here
print_info "Starting XCFramework creation process..."

# Convert to absolute paths manually
DEVICE_LIB=$(cd "$(dirname "$DEVICE_LIB")" && pwd)/$(basename "$DEVICE_LIB")
SIMULATOR_LIB=$(cd "$(dirname "$SIMULATOR_LIB")" && pwd)/$(basename "$SIMULATOR_LIB")
HEADERS_DIR=$(cd "$HEADERS_DIR" && pwd)

# Check prerequisites
check_file "$DEVICE_LIB"
check_file "$SIMULATOR_LIB"

if [ ! -d "$HEADERS_DIR" ]; then
    print_error "Headers directory not found: $HEADERS_DIR"
    exit 1
fi

# Clean up previous work directory
if [ -d "$WORK_DIR" ]; then
    print_info "Cleaning up previous work directory..."
    rm -rf "$WORK_DIR"
fi

# Create work directory structure
print_info "Creating work directory structure..."
mkdir -p "$WORK_DIR"/{device_objects,simulator_objects}

# Get absolute path for work directory
WORK_DIR=$(cd "$WORK_DIR" && pwd)

print_info "Work directory created: $WORK_DIR"

# Extract and filter object files
extract_and_filter "$DEVICE_LIB" "$WORK_DIR/device_objects" "device"
extract_and_filter "$SIMULATOR_LIB" "$WORK_DIR/simulator_objects" "simulator"

# Create clean platform-specific libraries
create_library "$WORK_DIR/device_objects" "libcvc-device.a" "iOS Device"
create_library "$WORK_DIR/simulator_objects" "libcvc-simulator.a" "iOS Simulator"

# Verify the cleaned libraries
verify_library "$WORK_DIR/device_objects/libcvc-device.a" "device" "iOS Device"
verify_library "$WORK_DIR/simulator_objects/libcvc-simulator.a" "simulator" "iOS Simulator"

# Remove existing XCFramework if it exists
if [ -d "$OUTPUT_XCFRAMEWORK" ]; then
    print_info "Removing existing XCFramework..."
    rm -rf "$OUTPUT_XCFRAMEWORK"
fi

# Create XCFramework
print_info "Creating XCFramework: $OUTPUT_XCFRAMEWORK"

xcodebuild -create-xcframework \
    -library "$WORK_DIR/device_objects/libcvc-device.a" \
    -headers "$HEADERS_DIR" \
    -library "$WORK_DIR/simulator_objects/libcvc-simulator.a" \
    -headers "$HEADERS_DIR" \
    -output "$OUTPUT_XCFRAMEWORK"

if [ $? -eq 0 ]; then
    print_success "XCFramework created successfully: $OUTPUT_XCFRAMEWORK"

    # Show XCFramework info
    print_info "XCFramework structure:"
    if [ -f "$OUTPUT_XCFRAMEWORK/Info.plist" ]; then
        echo "Supported platforms:"
        plutil -p "$OUTPUT_XCFRAMEWORK/Info.plist" | grep -A 10 "SupportedPlatform"
    fi

    print_info "XCFramework size: $(du -sh "$OUTPUT_XCFRAMEWORK" | cut -f1)"
else
    print_error "Failed to create XCFramework"
    exit 1
fi

# Clean up work directory
print_info "Cleaning up work directory..."
rm -rf "$WORK_DIR"

print_success "XCFramework creation completed successfully!"
print_info "You can now use $OUTPUT_XCFRAMEWORK in your Xcode project"

# Show next steps
echo ""
print_info "Next steps:"
echo "1. Add $OUTPUT_XCFRAMEWORK to your Xcode project"
echo "2. Go to your target's General tab"
echo "3. Add the XCFramework to 'Frameworks, Libraries, and Embedded Content'"
echo "4. Make sure it's set to 'Do Not Embed' for static libraries"