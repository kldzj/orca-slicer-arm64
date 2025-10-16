#!/bin/bash
set -e

# OrcaSlicer ARM64 Build Script
# Based on: https://github.com/SoftFever/OrcaSlicer/wiki/How-to-build#linux

ORCA_VERSION="${1:-2.3.1}"
BUILD_DIR="/tmp/orca-build-${ORCA_VERSION}"
OUTPUT_DIR="$(pwd)/output"

echo "=========================================="
echo "Building OrcaSlicer ${ORCA_VERSION} for ARM64"
echo "=========================================="

# Clean up any previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

cd "$BUILD_DIR"

echo "📥 Cloning OrcaSlicer repository..."
git clone https://github.com/SoftFever/OrcaSlicer.git
cd OrcaSlicer

echo "🔖 Checking out tag v${ORCA_VERSION}..."
git fetch --tags
git checkout "v${ORCA_VERSION}"

# Fix version.inc to match the actual tag version
# Often the checked-out tag has a -dev version for the next release
VERSION_INC_FILE="version.inc"
if [ -f "$VERSION_INC_FILE" ]; then
    echo "🔧 Fixing version in version.inc to match tag v${ORCA_VERSION}..."
    sed -i "s/set(SoftFever_VERSION \".*\")/set(SoftFever_VERSION \"${ORCA_VERSION}\")/" "$VERSION_INC_FILE"
    echo "   Updated version.inc to: ${ORCA_VERSION}"
fi

# Apply patch to skip hash verification for older versions with upstream dependency changes
PATCH_SCRIPT="${OUTPUT_DIR}/../scripts/patch-deps.sh"
if [ -f "$PATCH_SCRIPT" ]; then
    echo "🔧 Applying compatibility patches..."
    bash "$PATCH_SCRIPT" "${ORCA_VERSION}"
else
    echo "❌ Error: Patch script not found at $PATCH_SCRIPT"
    exit 1
fi

BUILD_SCRIPT=""
if [ -f "BuildLinux.sh" ]; then
    BUILD_SCRIPT="./BuildLinux.sh"
elif [ -f "build_linux.sh" ]; then
    BUILD_SCRIPT="./build_linux.sh"
else
    echo "❌ Error: Neither BuildLinux.sh nor build_linux.sh found!"
    exit 1
fi

echo "🔧 Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y \
    autoconf build-essential cmake curl eglexternalplatform-dev libboost-all-dev libtbb-dev libglfw3-dev libnlopt-dev libnlopt-cxx-dev \
    extra-cmake-modules file git libcairo2-dev libcurl4-openssl-dev libdbus-1-dev libglew-dev libglu1-mesa-dev libfuse2t64 libopenvdb-dev \
    libglu1-mesa-dev libgstreamer1.0-dev libgstreamerd-3-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev \
    libgtk-3-dev libgtk-3-dev libmspack-dev libsecret-1-dev libsoup2.4-dev libssl-dev libudev-dev libwayland-dev libcereal-dev \
    libwebkit2gtk-4.1-dev libxkbcommon-dev locales locales-all m4 pkgconf sudo wayland-protocols wget libopenexr-dev

echo "🔧 Installing system dependencies..."
${BUILD_SCRIPT} -u

echo "🔨 Building dependencies..."
${BUILD_SCRIPT} -d

echo "🏗️  Building OrcaSlicer..."
${BUILD_SCRIPT} -si

echo "📦 Packaging build..."
APPIMAGE_PATH="build/OrcaSlicer_Linux_V${ORCA_VERSION}.AppImage"
if [ -f "$APPIMAGE_PATH" ]; then
    echo "✅ Found AppImage: $APPIMAGE_PATH"
    cp "$APPIMAGE_PATH" "$OUTPUT_DIR/OrcaSlicer-${ORCA_VERSION}-arm64-linux.AppImage"
    
    VALIDATOR_PATH="build/src/Release/OrcaSlicer_profile_validator"
    if [ -f "$VALIDATOR_PATH" ]; then
        echo "✅ Found profile validator: $VALIDATOR_PATH"
        cp "$VALIDATOR_PATH" "$OUTPUT_DIR/OrcaSlicer_profile_validator-${ORCA_VERSION}-arm64-linux"
        chmod +x "$OUTPUT_DIR/OrcaSlicer_profile_validator-${ORCA_VERSION}-arm64-linux"
    fi
    
    echo "✅ Build complete!"
    echo "📄 AppImage: $OUTPUT_DIR/OrcaSlicer-${ORCA_VERSION}-arm64-linux.AppImage"
    
    cd "$OUTPUT_DIR"
    for file in OrcaSlicer*-${ORCA_VERSION}-arm64-linux.*; do
        if [ -f "$file" ]; then
            sha256sum "$file" > "${file}.sha256"
            echo "🔐 SHA256 for $file: $(cat ${file}.sha256)"
        fi
    done
else
    echo "❌ Build failed: AppImage not found at $APPIMAGE_PATH"
    echo "🔍 Contents of build directory:"
    ls -la build/ || echo "Build directory not found"
    if [ -d "build" ]; then
        find build -name "*.AppImage" -o -name "OrcaSlicer*" | head -10
    fi
    exit 1
fi

echo "🧹 Cleaning up..."
rm -rf "$BUILD_DIR"

echo "=========================================="
echo "Build successful!"
echo "=========================================="
