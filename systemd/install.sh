#!/bin/bash
# =============================================================================
# TeamSync Editor - systemd Service Installation Script
# =============================================================================

set -e

INSTALL_DIR="/opt/teamsync-editor"
SERVICE_FILE="coolwsd.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "TeamSync Editor - Service Installation"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not available"
    exit 1
fi

echo ""
echo "[1/5] Creating installation directory..."
mkdir -p "$INSTALL_DIR"

echo "[2/5] Copying project files..."
# Copy all project files to installation directory
cp -r "$SCRIPT_DIR/../"* "$INSTALL_DIR/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/../".* "$INSTALL_DIR/" 2>/dev/null || true

echo "[3/5] Setting permissions..."
chmod 600 "$INSTALL_DIR/.env" 2>/dev/null || true
chmod +x "$INSTALL_DIR/docker/scripts/"*.sh 2>/dev/null || true

echo "[4/5] Installing systemd service..."
cp "$SCRIPT_DIR/$SERVICE_FILE" /etc/systemd/system/
systemctl daemon-reload

echo "[5/5] Enabling service..."
systemctl enable coolwsd.service

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Edit the environment file:"
echo "   sudo nano $INSTALL_DIR/.env"
echo ""
echo "2. Update nginx.conf with your domain:"
echo "   sudo nano $INSTALL_DIR/docker/nginx/nginx.conf"
echo ""
echo "3. Start the service:"
echo "   sudo systemctl start coolwsd.service"
echo ""
echo "4. Check service status:"
echo "   sudo systemctl status coolwsd.service"
echo ""
echo "5. View logs:"
echo "   sudo journalctl -u coolwsd.service -f"
echo ""
echo "=========================================="
