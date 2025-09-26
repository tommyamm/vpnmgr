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
    echo "  vpn -d, --delete      - delete a config"
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
            # We show a short name if the file has a long name.
            short_name=$(echo "$server_name" | cut -d'.' -f1)
            if [ "$short_name" != "$server_name" ]; then
                echo "  👉 $short_name (full: $server_name)"
            else
                echo "  👉 $server_name"
            fi
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

# Deleting a config
delete_config() {
    check_configs || return 1
    
    echo -e "${YELLOW}Deleting a VPN config${NC}"
    
    # If the server name is passed as an argument
    if [ -n "$1" ]; then
        local server_name="$1"
        local config_file="$CONFIGS_DIR/$server_name.ovpn"
        
        if [ -f "$config_file" ]; then
            rm -f "$config_file"
            echo -e "${GREEN}✓ Configuration '$server_name' deleted${NC}"
            return 0
        else
            echo -e "${RED}⚠️  Config '$server_name' not found!${NC}"
            return 1
        fi
    fi
    
    # Interactive mode
    echo -e "${BLUE}Select the config to delete:${NC}"
    
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
    read -p "Enter the config number: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
        local selected_config="${configs[choice]}"
        local config_file="$CONFIGS_DIR/$selected_config.ovpn"
        
        # Confirm deletion
        read -p "Are you sure you want to delete '$selected_config'? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -f "$config_file"
            echo -e "${GREEN}✓ Configuration '$selected_config' deleted${NC}"
        else
            echo -e "${YELLOW}Deletion cancelled${NC}"
        fi
    else
        echo -e "${RED}⚠️  Wrong choice!${NC}"
        return 1
    fi
}

# Connecting to a VPN
connect_vpn() {
    local server_name="$1"
    local config_file
    
    # Search for a configuration file
    if [ -f "$CONFIGS_DIR/$server_name.ovpn" ]; then
        config_file="$CONFIGS_DIR/$server_name.ovpn"
    else
        # Search for files containing the server name
        local matches=($(find "$CONFIGS_DIR" -name "*$server_name*.ovpn" -type f))
        
        if [ ${#matches[@]} -eq 1 ]; then
            config_file="${matches[0]}"
            server_name=$(basename "$config_file" .ovpn)
            echo -e "${YELLOW}Using config: $server_name${NC}"
        elif [ ${#matches[@]} -eq 0 ]; then
            echo -e "${RED}❌ Server '$server_name' not found!${NC}"
            list_servers
            return 1
        else
            echo -e "${YELLOW}Multiple configs found for '$server_name':${NC}"
            for match in "${matches[@]}"; do
                local name=$(basename "$match" .ovpn)
                echo "  👉 $name"
            done
            echo -e "${YELLOW}Please specify exact server name.${NC}"
            return 1
        fi
    fi
    
    if [ ! -f "$AUTH_FILE" ]; then
        echo -e "${YELLOW}Authentication credentials not set up${NC}"
        setup_auth
    fi
    
    echo -e "${GREEN}🔌 Connecting to $server_name...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to disconnect${NC}"
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
        -d|--delete)
            delete_config "$2"
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

if [ "$#" -gt 2 ]; then
    echo -e "${RED}⚠️  There are too many arguments!${NC}"
    show_help
    exit 1
fi

main "$@"
