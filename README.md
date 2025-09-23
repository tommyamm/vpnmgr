# VPN Manager 🔒

A lightweight bash script that simplifies OpenVPN connections with an intuitive interface, 
secure credential management, and smart server discovery.

## ✨ Features

- 🚀 **One-command connections** - Connect to VPN servers with a single command
- 🔐 **Secure credential storage** - Encrypted authentication file handling
- 🎯 **Smart server discovery** - Fuzzy matching for config files (supports both short and full names)
- 🎨 **Colorful interface** - Visual feedback with emoji and colors
- 📁 **Centralized management** - All configs organized in `~/.vpn/configs/`
- ⚡ **Fast switching** - Easily switch between different VPN servers
- 🔄 **Easy updates** - Symbolic link-based installation for seamless updates

## 🚀 Quick Start

### Installation

```bash
# Clone and install
git clone https://github.com/yourusername/vpnmgr.git
cd vpnmgr
./install.sh
```

### Basic Usage

```bash
# Setup your credentials (first time only)
vpn --setup-auth

# List available servers
vpn --list

# Connect to a server (using short or full name)
vpn nl1
vpn nl1.udp-1000

# Interactive mode (choose from list)
vpn
```

## 🛠️ Usage Examples

```bash
# Add new VPN configuration
vpn --add

# Interactive server selection
vpn

# Connect to specific server
vpn us-east
vpn nl2

# Show help
vpn --help
```

## 📋 Requirements

- **OpenVPN** 2.4 or newer
- **Bash** 4.0+
- **sudo** privileges
- **Linux** environment

## Is it possible for free?

You can create a temporary server for free on https://www.vpnjantit.com/free-openvpn