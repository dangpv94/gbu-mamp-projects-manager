#!/bin/bash

# MAMP Project Setup Helper
# This script completes the setup of a MAMP virtual host project by:
# 1. Adding the hosts entry (requires sudo)
# 2. Restarting MAMP Apache to load the new virtual host

if [ $# -ne 1 ]; then
    echo "Usage: $0 <domain>"
    echo "Example: $0 myproject.local"
    exit 1
fi

DOMAIN=$1

echo "🚀 MAMP Project Setup Helper"
echo "=================================="
echo "Setting up virtual host for: $DOMAIN"
echo ""

# Check if domain already exists in hosts file
if grep -q "127.0.0.1.*$DOMAIN" /etc/hosts; then
    echo "✅ Hosts entry already exists for $DOMAIN"
else
echo "📝 Adding hosts entry for $DOMAIN..."
    # Use a more reliable method to add hosts entry
    if echo "127.0.0.1	$DOMAIN" | sudo tee -a /etc/hosts >/dev/null 2>&1; then
        echo "✅ Hosts entry added successfully"
    else
        echo "❌ Failed to add hosts entry. Please add manually:"
        echo "   sudo echo '127.0.0.1	$DOMAIN' >> /etc/hosts"
        # Don't exit on hosts failure, continue with Apache restart
        echo "⚠️  Continuing with Apache restart..."
    fi
fi

echo ""
echo "🔄 Restarting MAMP Apache..."

# Stop Apache
sudo /Applications/MAMP/Library/bin/httpd -k stop 2>/dev/null

# Wait a moment
sleep 2

# Start Apache
sudo /Applications/MAMP/Library/bin/httpd -k start

if [ $? -eq 0 ]; then
    echo "✅ MAMP Apache restarted successfully"
    echo ""
    echo "🎉 Setup complete! Your project is ready:"
    echo "   URL: http://$DOMAIN"
    echo ""
    echo "💡 You can now open http://$DOMAIN in your browser"
else
    echo "❌ Failed to restart MAMP Apache"
    echo "   Please restart MAMP manually through the MAMP application"
    exit 1
fi
