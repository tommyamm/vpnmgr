#!/bin/bash

set -e

echo "🔧 Installing VPN Manager..."

# Checking dependencies
if ! command -v openvpn &> /dev/null; then
    echo "⚠️ OpenVPN is not installed. Install: sudo apt install openvpn"
    exit 1
fi

# Determine the absolute path to the directory where this script is located.
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
VPNMGR_SCRIPT="$SCRIPT_DIR/vpnmgr.sh"

# Checking if the original script exists.
if [ ! -f "$VPNMGR_SCRIPT" ]; then
    echo "⚠️ The main script vpnmgr.sh not found on the way: $VPNMGR_SCRIPT"
    exit 1
fi

echo $VPNMGR_SCRIPT
# Creating a symlink in /usr/local/bin/vpn
sudo ln -sf "$VPNMGR_SCRIPT" /usr/local/bin/vpn

# Creating directories
mkdir -p ~/.vpn/configs

echo "✅ The installation is complete! (using a symlink)"
echo "💡 Use: vpn --help"
echo ""
echo "📝 Note: If you move or delete the repository, the symlink will become inoperable."
