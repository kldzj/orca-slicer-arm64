#!/bin/bash

# Patch to skip hash verification for older OrcaSlicer versions
# This removes URL_HASH verification from CMake ExternalProject_Add calls

set -e

ORCA_VERSION="$1"
BUILD_DIR="/tmp/orca-build-${ORCA_VERSION}/OrcaSlicer"

if [ -z "$ORCA_VERSION" ]; then
    echo "❌ Error: Version not specified"
    echo "Usage: $0 <version>"
    exit 1
fi

cd "$BUILD_DIR"
LATEST_TAG=$(git tag -l "v*" | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)

CURRENT_VERSION="${ORCA_VERSION#v}"
LATEST_VERSION="${LATEST_TAG#v}"

echo "📊 Version check:"
echo "   Building: v${CURRENT_VERSION}"
echo "   Latest:   ${LATEST_TAG}"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "✅ Building latest version - using proper hash verification (no patch needed)"
    exit 0
fi

echo "⚠️  Building older version - will patch to skip hash verification"

DEPS_DIR="${BUILD_DIR}/deps"

if [ ! -d "$DEPS_DIR" ]; then
    echo "⚠️  Dependencies directory not found at: $DEPS_DIR"
    echo "   This may be expected if the deps structure is different for this version."
    exit 0
fi

echo "🔧 Patching dependency files to skip hash checks..."
echo "   Searching in: $DEPS_DIR"

echo "🔗 Fixing known broken dependency URLs..."

# Fix MPFR URL if it's using old version (4.2.1 which is now 404)
MPFR_CMAKE="${DEPS_DIR}/MPFR/MPFR.cmake"
if [ -f "$MPFR_CMAKE" ]; then
    if grep -q "mpfr-4.2.1" "$MPFR_CMAKE"; then
        echo "   🔗 Updating MPFR URL to fix 404"
        sed -i 's|https://www.mpfr.org/mpfr-current/mpfr-4.2.1.tar.bz2|https://www.mpfr.org/mpfr-4.2.1/mpfr-4.2.1.tar.bz2|g' "$MPFR_CMAKE"
    fi
fi

# Template for other dependency fixes
# DEPENDENCY_CMAKE="${DEPS_DIR}/DEPENDENCY/DEPENDENCY.cmake"
# if [ -f "$DEPENDENCY_CMAKE" ]; then
#     if grep -q "old-version" "$DEPENDENCY_CMAKE"; then
#         echo "   🔗 Updating DEPENDENCY from old-version to new-version"
#         sed -i 's|old-url|new-url|g' "$DEPENDENCY_CMAKE"
#     fi
# fi

# Fix AppImageTool URL for ARM64
BUILD_APPIMAGE_TEMPLATE="${BUILD_DIR}/src/platform/unix/build_appimage.sh.in"
if [ -f "$BUILD_APPIMAGE_TEMPLATE" ]; then
    if grep -q 'AppImage/AppImageKit' "$BUILD_APPIMAGE_TEMPLATE"; then
        echo "   🔗 Updating AppImageKit URL for ARM64 compatibility"
        sed -i 's|https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-\$(uname -m).AppImage|https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-\$(uname -m).AppImage|g' "$BUILD_APPIMAGE_TEMPLATE"
    fi
fi

# Find all CMake files in deps directory
CMAKE_FILES=$(find "$DEPS_DIR" -name "*.cmake" -o -name "CMakeLists.txt")

if [ -z "$CMAKE_FILES" ]; then
    echo "⚠️  No CMake files found in deps directory"
    exit 0
fi

TOTAL_MODIFIED=0

while IFS= read -r cmake_file; do
    if [ -f "$cmake_file" ]; then
        if grep -q "URL_HASH" "$cmake_file"; then
            cp "$cmake_file" "${cmake_file}.backup"
            
            # Remove URL_HASH lines from ExternalProject_Add calls
            sed -i 's/^[[:space:]]*URL_HASH[[:space:]].*/    # URL_HASH removed for compatibility with older versions/g' "$cmake_file"
            
            MODIFIED_IN_FILE=$(diff "${cmake_file}.backup" "$cmake_file" 2>/dev/null | grep -c "^>" || true)
            
            if [ "$MODIFIED_IN_FILE" -gt 0 ]; then
                echo "   📝 Patched: $(basename "$cmake_file") ($MODIFIED_IN_FILE changes)"
                TOTAL_MODIFIED=$((TOTAL_MODIFIED + MODIFIED_IN_FILE))
            else
                rm "${cmake_file}.backup"
            fi
        fi
    fi
done <<< "$CMAKE_FILES"

if [ "$TOTAL_MODIFIED" -gt 0 ]; then
    echo "✅ Patch applied successfully! Modified $TOTAL_MODIFIED URL_HASH lines across multiple files."
else
    echo "ℹ️ No URL_HASH lines found to modify."
fi
