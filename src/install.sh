#!/bin/bash

# Network & Service Status Checker Installation Script
# This script sets up the network service checker with proper permissions and systemd integration

set -e

SCRIPT_NAME="Network & Service Status Checker"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/network-service-checker"
LOG_DIR="/var/log/network-service-checker"
SYSTEMD_DIR="/etc/systemd/system"
USER="networkcheck"
GROUP="networkcheck"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing $SCRIPT_NAME...${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Create user and group for the service
echo -e "${BLUE}Creating user and group...${NC}"
if ! id "$USER" &>/dev/null; then
    useradd -r -s /bin/false -d /nonexistent "$USER"
    echo -e "${GREEN}Created user: $USER${NC}"
else
    echo -e "${YELLOW}User $USER already exists${NC}"
fi

# Create directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"
chown "$USER:$GROUP" "$LOG_DIR"
chmod 750 "$LOG_DIR"

# Copy main script
echo -e "${BLUE}Installing main script...${NC}"
cp network_service_checker.sh "$INSTALL_DIR/"
chmod 755 "$INSTALL_DIR/network_service_checker.sh"
chown root:root "$INSTALL_DIR/network_service_checker.sh"

# Copy configuration file
echo -e "${BLUE}Installing configuration...${NC}"
cp config.conf "$CONFIG_DIR/"
chown root:root "$CONFIG_DIR/config.conf"
chmod 644 "$CONFIG_DIR/config.conf"

# Update config file to use correct paths
sed -i "s|LOG_FILE="/var/log/network_service_check.log"|LOG_FILE="$LOG_DIR/network_service_check.log"|" "$CONFIG_DIR/config.conf"

# Install systemd service files if requested
read -p "Do you want to install systemd service and timer? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Installing systemd files...${NC}"

    # Update service file with correct paths
    sed -e "s|/usr/local/bin/network_service_checker.sh|$INSTALL_DIR/network_service_checker.sh|"         -e "s|User=networkcheck|User=$USER|"         -e "s|Group=networkcheck|Group=$GROUP|"         network-service-check.service > "$SYSTEMD_DIR/network-service-check.service"

    cp network-service-check.timer "$SYSTEMD_DIR/"

    # Set permissions
    chmod 644 "$SYSTEMD_DIR/network-service-check.service"
    chmod 644 "$SYSTEMD_DIR/network-service-check.timer"

    # Reload systemd
    systemctl daemon-reload

    echo -e "${GREEN}Systemd files installed${NC}"
    echo -e "${BLUE}To enable and start the timer:${NC}"
    echo "  systemctl enable --now network-service-check.timer"
    echo -e "${BLUE}To check timer status:${NC}"
    echo "  systemctl status network-service-check.timer"
fi

# Create symlink for easy access
echo -e "${BLUE}Creating command alias...${NC}"
ln -sf "$INSTALL_DIR/network_service_checker.sh" /usr/local/bin/netcheck
chmod 755 /usr/local/bin/netcheck

# Set up log rotation
echo -e "${BLUE}Setting up log rotation...${NC}"
cat > /etc/logrotate.d/network-service-checker << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 640 $USER $GROUP
    postrotate
        systemctl reload-or-restart network-service-check.service > /dev/null 2>&1 || true
    endscript
}
EOF

echo -e "${GREEN}Installation completed!${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo "  $INSTALL_DIR/network_service_checker.sh [options]"
echo "  netcheck [options]  # Short alias"
echo ""
echo -e "${BLUE}Configuration file:${NC}"
echo "  $CONFIG_DIR/config.conf"
echo ""
echo -e "${BLUE}Log files:${NC}"
echo "  $LOG_DIR/network_service_check.log"
echo ""
echo -e "${BLUE}Test the installation:${NC}"
echo "  netcheck --help"
echo "  netcheck"
echo ""

if [[ -f "$SYSTEMD_DIR/network-service-check.service" ]]; then
    echo -e "${BLUE}Systemd integration:${NC}"
    echo "  systemctl enable --now network-service-check.timer"
    echo "  systemctl status network-service-check.timer"
    echo ""
fi

echo -e "${GREEN}Installation successful!${NC}"
