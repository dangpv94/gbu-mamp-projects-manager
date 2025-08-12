#!/bin/bash

# MAMP Projects Manager v3.0.0 - Quick Install Script
# Installs the package to MAMP projects directory

echo "🚀 MAMP Projects Manager v3.0.0 - Quick Install"
echo "==============================================="

MAMP_DIR="/Applications/MAMP/htdocs/projects"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if MAMP is installed
if [ ! -d "/Applications/MAMP" ]; then
    echo "❌ MAMP not found at /Applications/MAMP"
    echo "   Please install MAMP first from: https://www.mamp.info/"
    exit 1
fi

echo "✅ MAMP found"

# Create projects directory if it doesn't exist
if [ ! -d "$MAMP_DIR" ]; then
    echo "📁 Creating projects directory..."
    mkdir -p "$MAMP_DIR"
fi

# Backup existing installation
if [ -f "$MAMP_DIR/index.html" ]; then
    BACKUP_DIR="$HOME/Desktop/mamp-projects-backup-$(date +%Y%m%d-%H%M%S)"
    echo "📦 Backing up existing installation to: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -R "$MAMP_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
fi

# Install files
echo "📥 Installing MAMP Projects Manager..."
cp -R "$CURRENT_DIR"/* "$MAMP_DIR/" 2>/dev/null || {
    echo "❌ Installation failed. Trying with sudo..."
    sudo cp -R "$CURRENT_DIR"/* "$MAMP_DIR/"
}

# Set permissions
echo "🔐 Setting permissions..."
chmod +x "$MAMP_DIR"/*.sh "$MAMP_DIR"/*.php 2>/dev/null || {
    sudo chmod +x "$MAMP_DIR"/*.sh "$MAMP_DIR"/*.php
}

# Remove the install script from target directory
rm -f "$MAMP_DIR/INSTALL_NOW.sh"
rm -f "$MAMP_DIR/PACKAGE_INFO.txt"

# Create backups directory
mkdir -p "$MAMP_DIR/backups"

# Test installation
if [ -f "$MAMP_DIR/index.html" ] && [ -f "$MAMP_DIR/api.php" ]; then
    echo "✅ Installation successful!"
    echo ""
    echo "🌐 Access your MAMP Projects Manager at:"
    echo "   • Port 80: http://localhost/projects/"
    echo "   • Port 8888: http://localhost:8888/projects/"
    echo "   • Port 8080: http://localhost:8080/projects/"
    echo "   • Custom Port: http://localhost:YOUR_PORT/projects/"
    echo ""
    echo "📚 For detailed usage guide, see:"
    echo "   $MAMP_DIR/README.md"
    echo ""
    echo "🧪 To test compatibility:"
    echo "   cd $MAMP_DIR"
    echo "   php test-port-compatibility.php"
    echo ""
    echo "🎉 Ready to create your first project!"
else
    echo "❌ Installation may have failed"
    echo "   Please check permissions and try again"
    exit 1
fi
