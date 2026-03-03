#!/usr/bin/env bash
# Bootstrap script — downloads and runs the full AfterBoot installer

set -euo pipefail

REPO="https://github.com/satya77-lang/afterboot.git"
INSTALL_DIR="/tmp/afterboot"

# Clean up any previous attempt
rm -rf "$INSTALL_DIR"

# Clone the repo
git clone "$REPO" "$INSTALL_DIR"

# Make it executable and run the installer
chmod +x "$INSTALL_DIR/install.sh"
"$INSTALL_DIR/install.sh"

# Clean up after installation
rm -rf "$INSTALL_DIR"
