#!/bin/bash

# VPN Manager Script
CONFIG_DIR="$HOME/.vpn"
AUTH_FILE="$CONFIG_DIR/auth"
CONFIGS_DIR="$CONFIG_DIR/configs"

# Creating the necessary directories
mkdir -p "$CONFIGS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help and information functions
show_help() {
    echo "VPN Manager - managing OpenVPN connections"
    echo ""
    echo "Usage:"
    echo "  vpn [SERVER]          - connect to the specified server"
    echo "  vpn -l, --list        - list of available servers"
    echo "  vpn -a, --add         - add a new config"
    echo "  vpn -s, --setup-auth  - set up credentials"
    echo "  vpn -h, --help        - show this help"
}

# Checking for configs
check_configs() {
    if [ ! "$(ls -A "$CONFIGS_DIR"/*.ovpn 2>/dev/null)" ]; then
        echo -e "${YELLOW}Attention: there are no configuration files (.ovpn) в $CONFIGS_DIR${NC}"
        echo "Use $0 --add to add configs"
        return 1
    fi
    return 0
}

# List of available servers
list_servers() {
    check_configs || return 1
    
    echo -e "${BLUE}Available servers:${NC}"
    for config in "$CONFIGS_DIR"/*.ovpn; do
        if [ -f "$config" ]; then
            server_name=$(basename "$config" .ovpn)
            echo "  👉 $server_name"
        fi
    done
}

# Setting up Credentials
setup_auth() {
    echo -e "${YELLOW}Setting up Credentials VPN${NC}"
    read -p "Login: " username
    read -s -p "Password: " password
    echo
    
    # Save it to a file with limited rights
    echo "$username" > "$AUTH_FILE"
    echo "$password" >> "$AUTH_FILE"
    chmod 600 "$AUTH_FILE"
    
    echo -e "${GREEN}✓ Credentials are saved${NC}"
}

# Adding a new config
add_config() {
    echo -e "${YELLOW}Adding a new config VPN${NC}"
    
    read -p "Path to .ovpn file: " config_path
    if [ ! -f "$config_path" ]; then
        echo -e "${RED}⚠️  File not found!${NC}"
        return 1
    fi
    
    # Extracting the server name from the file name
    server_name=$(basename "$config_path" .ovpn)
    cp "$config_path" "$CONFIGS_DIR/$server_name.ovpn"
    
    echo -e "${GREEN}✓ Configuration '$server_name' added${NC}"
}

# Connecting to a VPN
connect_vpn() {
    local server_name="$1"
    local config_file="$CONFIGS_DIR/$server_name.ovpn"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}⚠️  Server '$server_name' not found!${NC}"
        list_servers
        return 1
    fi
    
    if [ ! -f "$AUTH_FILE" ]; then
        echo -e "${YELLOW}Credentials are not configured${NC}"
        setup_auth
    fi
    
    echo -e "${GREEN}🔌 Connecting to $server_name...${NC}"
    echo -e "${YELLOW}To disable it, press Ctrl+C${NC}"
    echo ""
    
    # Creating a temporary file for authentication
    TEMP_AUTH=$(mktemp /tmp/vpn_auth_XXXXXX)
    chmod 600 "$TEMP_AUTH"
    cp "$AUTH_FILE" "$TEMP_AUTH"
    
    # Launching OpenVPN
    sudo openvpn --config "$config_file" --auth-user-pass "$TEMP_AUTH"
    
    # Deleting the temporary file at the end
    rm -f "$TEMP_AUTH"
}

# Interactive server selection
interactive_connect() {
    check_configs || return 1
    
    echo -e "${BLUE}Select the server to connect to:${NC}"
    
    local configs=()
    local i=1
    
    # Collecting a list of configs
    for config in "$CONFIGS_DIR"/*.ovpn; do
        if [ -f "$config" ]; then
            server_name=$(basename "$config" .ovpn)
            configs[i]="$server_name"
            echo "  $i) $server_name"
            ((i++))
        fi
    done
    
    echo ""
    read -p "Enter the server number: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
        connect_vpn "${configs[choice]}"
    else
        echo -e "${RED}⚠️  Wrong choice!${NC}"
        return 1
    fi
}

# The basic logic
main() {
    case "$1" in
        -l|--list)
            list_servers
            ;;
        -a|--add)
            add_config
            ;;
        -s|--setup-auth)
            setup_auth
            ;;
        -h|--help)
            show_help
            ;;
        "")
            # No arguments - interactive mode
            interactive_connect
            ;;
        *)
            # Connecting to the specified server
            connect_vpn "$1"
            ;;
    esac
}

# Signal processing for graceful shutdown
trap 'echo -e "\n${YELLOW}Disabling the VPN...${NC}"; exit 0' SIGINT SIGTERM

if [ "$#" -gt 1 ]; then
    echo -e "${RED}⚠️  There are too many arguments!${NC}"
    show_help
    exit 1
fi

main "$@"
