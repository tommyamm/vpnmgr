#!/bin/bash

set -e

echo "🗑️ Uninstalling VPN Manager..."

SCRIPT_NAME="vpn"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.vpn"

# Remove symlink
if [ -L "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    sudo rm "$INSTALL_DIR/$SCRIPT_NAME"
    echo "✅ Symlink removed: $INSTALL_DIR/$SCRIPT_NAME"
else
    echo "⚠️ Symlink not found: $INSTALL_DIR/$SCRIPT_NAME"
fi

echo "✅ Uninstallation complete!"
echo ""
echo "📝 Note: Configuration directory $CONFIG_DIR was not removed."
echo "   If you want to remove it, run manually: rm -rf $CONFIG_DIR"