#!/bin/bash

# install.sh - Download CVC library artifacts for iOS Swift integration
# Usage: ./install.sh [version] [--help]
# Example: ./install.sh v0.1.5

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_OWNER="MyNextID"
REPO_NAME="cvc"
GITHUB_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"
GITHUB_DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download"
LIB_DIR="lib"
INCLUDE_DIR="include"

# Print functions
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

show_help() {
    cat << EOF
CVC Library Installer for iOS Swift

USAGE:
    $0 [VERSION] [OPTIONS]

ARGUMENTS:
    VERSION     CVC library version to download (e.g., v0.1.5)
                If not provided, downloads the latest release

OPTIONS:
    --help      Show this help message
    --force     Overwrite existing files without prompting

EXAMPLES:
    $0                  # Download latest version
    $0 v0.1.5          # Download specific version
    $0 v0.1.5 --force  # Download and overwrite existing files

DESCRIPTION:
    This script downloads pre-compiled CVC library static libraries and headers
    for iOS development. This creates a complete Swift package that users
    can install with just 'swift package manager' - no additional setup required.

    Downloaded files are placed in:
    - lib/ios-device/arm64/      Static library (.a) for iOS device
    - lib/ios-simulator/arm64/   Static library (.a) for iOS simulator
    - include/                   Header files (.h) with flat structure

SUPPORTED PLATFORMS:
    - iOS Device: arm64
    - iOS Simulator: arm64

DEVELOPER WORKFLOW:
    1. Run this script to populate your Swift package with iOS libraries
    2. Commit the downloaded files to version control
    3. Users can then simply add the package to their Xcode project
EOF
}

get_latest_version() {
    print_info "Fetching latest release information..."
    local latest_release
    latest_release=$(curl -L -s -H 'Accept: application/json' "${GITHUB_API_URL}/releases/latest")
    if [ $? -ne 0 ]; then
        print_error "Failed to fetch release information from GitHub API"
        exit 1
    fi

    local version
    version=$(echo "$latest_release" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
    if [ -z "$version" ]; then
        print_error "Could not parse latest version from GitHub API response"
        exit 1
    fi

    echo "$version"
}

verify_version() {
    local version="$1"
    print_info "Verifying version ${version} exists..."

    local response
    response=$(curl -L -s -o /dev/null -w "%{http_code}" "${GITHUB_API_URL}/releases/tags/${version}")
    if [ "$response" != "200" ]; then
        print_error "Version ${version} not found. Please check the version number."
        print_info "You can view available versions at: https://github.com/${REPO_OWNER}/${REPO_NAME}/releases"
        exit 1
    fi
    print_success "Version ${version} found"
}

copy_headers_flat() {
    local temp_dir="$1"
    local is_first_run="$2"

    # Only copy headers on first run to avoid duplicates
    if [ "$is_first_run" != "true" ]; then
        return 0
    fi

    print_info "Copying header files with flat structure (preserving l8w8jwt directory)..."

    # Remove existing include directory if it exists
    if [ -d "$INCLUDE_DIR" ]; then
        rm -rf "$INCLUDE_DIR"
    fi
    mkdir -p "$INCLUDE_DIR"
    mkdir -p "${INCLUDE_DIR}/l8w8jwt"

    # Find all header files in the extracted archive
    find "$temp_dir" -name "*.h" | while read -r header_file; do
        local filename=$(basename "$header_file")
        local relative_path="${header_file#$temp_dir/}"

        # Handle l8w8jwt headers - keep them in l8w8jwt subdirectory
        if [[ "$relative_path" == *"l8w8jwt"* ]] || [[ "$filename" == l8w8jwt* ]]; then
            cp "$header_file" "${INCLUDE_DIR}/l8w8jwt/"
            print_success "Installed header: l8w8jwt/$filename"
        else
            # Copy all other headers directly to include/ directory (flat structure)
            cp "$header_file" "${INCLUDE_DIR}/"
            print_success "Installed header: $filename"
        fi
    done
}

download_and_extract() {
    local version="$1"
    local platform="$2"
    local arch="$3"
    local is_first_run="$4"

    local archive_name="libcvc-${platform}-${arch}.tar.gz"
    local download_url="${GITHUB_DOWNLOAD_URL}/${version}/${archive_name}"
    local temp_dir
    temp_dir=$(mktemp -d)

    print_info "Downloading ${archive_name}..."
    if ! curl -L -o "${temp_dir}/${archive_name}" "${download_url}"; then
        print_error "Failed to download ${archive_name}"
        rm -rf "$temp_dir"
        return 1
    fi
    print_success "Downloaded ${archive_name}"

    # Create target directories
    local lib_target_dir="${LIB_DIR}/${platform}/${arch}"
    mkdir -p "$lib_target_dir"

    print_info "Extracting ${archive_name}..."
    cd "$temp_dir"
    if ! tar -xzf "$archive_name"; then
        print_error "Failed to extract tar.gz archive"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    cd - > /dev/null

    # Copy static library
    local lib_file
    lib_file=$(find "$temp_dir" -name "*.a" | head -1)
    if [ -z "$lib_file" ]; then
        print_error "No static library (.a) found in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    cp "$lib_file" "$lib_target_dir/"
    print_success "Installed library: ${lib_target_dir}/$(basename "$lib_file")"

    # Copy headers with flat structure (only on first run)
    copy_headers_flat "$temp_dir" "$is_first_run"

    rm -rf "$temp_dir"
    return 0
}

# Download iOS platforms
download_ios_platforms() {
    local version="$1"
    local failed_downloads=()
    local is_first_run=true

    print_info "Downloading CVC library for iOS platforms..."
    echo

    # iOS Device
    print_info "Processing ios-device/arm64..."
    if ! download_and_extract "$version" "ios-device" "arm64" "$is_first_run"; then
        failed_downloads+=("ios-device/arm64")
        print_warning "Failed to download ios-device/arm64"
    fi
    is_first_run=false  # Only first extraction should copy headers
    echo

    # iOS Simulator
    print_info "Processing ios-simulator/arm64..."
    if ! download_and_extract "$version" "ios-simulator" "arm64" "$is_first_run"; then
        failed_downloads+=("ios-simulator/arm64")
        print_warning "Failed to download ios-simulator/arm64"
    fi
    echo

    if [ ${#failed_downloads[@]} -eq 0 ]; then
        print_success "All iOS platforms downloaded successfully!"
    else
        print_warning "Some downloads failed:"
        for failed in "${failed_downloads[@]}"; do
            echo "  - $failed"
        done
        echo
        print_info "You can retry failed downloads by running the script again"
    fi
}

# Parse command line arguments
VERSION=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --*)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$1"
            else
                print_error "Too many arguments. Only one version can be specified."
                echo "Use --help for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

main() {
    print_info "CVC Library Installer for iOS Swift"
    echo

    # Get version
    if [ -z "$VERSION" ]; then
        print_info "No version specified, fetching latest release..."
        VERSION=$(get_latest_version)
        print_success "Latest version: $VERSION"
    else
        print_info "Requested version: $VERSION"
        verify_version "$VERSION"
    fi

    # Check for existing files
    if [ -d "$LIB_DIR" ] && [ "$(ls -A "$LIB_DIR" 2>/dev/null)" ] && [ "$FORCE" != "true" ]; then
        print_warning "Library files already exist in ${LIB_DIR}/"
        read -p "Overwrite existing files? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation aborted by user"
            exit 0
        fi
        print_info "Removing existing library files..."
        rm -rf "${LIB_DIR:?}"/*
    fi

    # Download everything
    download_ios_platforms "$VERSION"

    echo
    print_success "CVC library $VERSION installed for iOS platforms!"
    print_info "Repository structure:"
    echo "  lib/"
    if [ -d "${LIB_DIR}/ios-device/arm64" ]; then
        echo "    ├── ios-device/arm64/"
        ls "${LIB_DIR}/ios-device/arm64/" | sed 's/^/    │   ├── /'
    fi
    if [ -d "${LIB_DIR}/ios-simulator/arm64" ]; then
        echo "    ├── ios-simulator/arm64/"
        ls "${LIB_DIR}/ios-simulator/arm64/" | sed 's/^/    │   ├── /'
    fi
    echo "  include/"
    if [ -d "$INCLUDE_DIR" ]; then
        ls "$INCLUDE_DIR/" | sed 's/^/    ├── /'
    fi

    echo
    print_info "Next steps:"
    echo "  1. Commit all files to Git: git add lib/ include/ && git commit -m 'Add CVC $VERSION iOS libraries'"
    echo "  2. Users can now add this Swift package to their Xcode project"
    echo "  3. No additional setup required for end users!"
}

main "$@"