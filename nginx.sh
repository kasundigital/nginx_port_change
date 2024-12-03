#!/bin/bash

# File path for the Nginx configuration
NGINX_CONFIG="/etc/nginx/sites-enabled/default"
BACKUP_DIR="/etc/nginx/backups"

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: Please run this script as root or use sudo."
    exit 1
fi

# Create a backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if the Nginx configuration file exists
if [[ ! -f "$NGINX_CONFIG" ]]; then
    echo "Error: Nginx configuration file not found at $NGINX_CONFIG"
    exit 1
fi

# Backup the original configuration
BACKUP_FILE="$BACKUP_DIR/default.bak.$(date +%Y%m%d%H%M%S)"
cp "$NGINX_CONFIG" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Replace ports in the configuration file (IPv4 and IPv6)
sed -i -E \
    -e 's/\b443\b/444/g' \
    -e 's/\b80\b/82/g' \
    "$NGINX_CONFIG"

# Validate the Nginx configuration
if nginx -t; then
    echo "Nginx configuration updated successfully."
    echo "Restarting Nginx..."
    systemctl restart nginx

    if [[ $? -eq 0 ]]; then
        echo "Nginx restarted successfully."
    else
        echo "Error: Failed to restart Nginx. Check the logs for more details."
        exit 1
    fi
else
    echo "Error: Invalid Nginx configuration. Reverting changes..."
    cp "$BACKUP_FILE" "$NGINX_CONFIG"
    nginx -t && systemctl restart nginx
    exit 1
fi
