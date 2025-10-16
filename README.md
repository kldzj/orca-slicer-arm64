# OrcaSlicer ARM64 Linux Builds

Automated ARM64 Linux builds of [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer) for use on ARM-based systems.

## Overview

This repository automatically builds OrcaSlicer for ARM64 Linux architecture when new releases are detected. The official OrcaSlicer project only provides x86_64 AppImages, so these builds enable ARM64 systems (like Raspberry Pi 4/5, ARM servers, and Apple Silicon with Linux) to run OrcaSlicer.

## Downloads

Visit the [Releases](https://github.com/kldzj/orca-slicer-arm64/releases) page to download pre-built ARM64 binaries.

Each release is tagged as `v{version}-arm64` (e.g., `v2.3.1-arm64`) and includes:
- `OrcaSlicer-{version}-arm64-linux.AppImage` - The compiled AppImage binary
- `OrcaSlicer-{version}-arm64-linux.AppImage.sha256` - SHA256 checksum for verification

## Installation

### Quick Start

```bash
# Download the latest release (replace VERSION with the desired version)
VERSION="2.3.1"
wget https://github.com/kldzj/orca-slicer-arm64/releases/download/v${VERSION}-arm64/OrcaSlicer-${VERSION}-arm64-linux.AppImage

# Verify the download (optional but recommended)
wget https://github.com/kldzj/orca-slicer-arm64/releases/download/v${VERSION}-arm64/OrcaSlicer-${VERSION}-arm64-linux.AppImage.sha256
sha256sum -c OrcaSlicer-${VERSION}-arm64-linux.AppImage.sha256

# Make it executable
chmod +x OrcaSlicer-${VERSION}-arm64-linux.AppImage

# Run OrcaSlicer
./OrcaSlicer-${VERSION}-arm64-linux.AppImage
```

### Notes

- AppImages are self-contained executables that bundle all dependencies
- No installation required - just download, make executable, and run
- If you encounter issues running the AppImage, you may need to install `libfuse2` or `fuse2` on newer systems

## Contributing

Found an issue or have a suggestion? Please [open an issue](../../issues)!

## License

This repository contains build scripts and automation only. OrcaSlicer itself is licensed under the [AGPL-3.0 License](https://github.com/SoftFever/OrcaSlicer?tab=AGPL-3.0-1-ov-file#readme).

## Disclaimer

These are **unofficial** ARM64 builds compiled from the official OrcaSlicer source code. For official releases and support, please visit the [main OrcaSlicer repository](https://github.com/SoftFever/OrcaSlicer).

## Acknowledgments

- [OrcaSlicer](https://github.com/SoftFever/OrcaSlicer) - The amazing 3D printing slicer
- GitHub Actions ARM runners - Making ARM64 builds accessible
