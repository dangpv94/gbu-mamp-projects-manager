#!/bin/bash

# Quick MAMP Fix - One-command solution for common MAMP issues
# This is a simplified version of the full troubleshooting tool

echo "🚀 MAMP Quick Fix Tool"
echo "====================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Configuration
VHOSTS_FILE="/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf"
HOSTS_FILE="/etc/hosts"
APACHE_CONF="/Applications/MAMP/conf/apache/httpd.conf"

# Get MAMP port
MAMP_PORT=$(/Applications/MAMP/bin/apachectl -S | grep "port " | head -n 1 | sed -e 's/.*port //g' -e 's/ .*//')

echo "🔍 Quick diagnosis..."

# Check if MAMP is running
if ! pgrep -f "Applications/MAMP/Library/bin/httpd" > /dev/null; then
    print_error "MAMP is not running! Please start MAMP first."
    exit 1
fi

print_status "MAMP is running on port $MAMP_PORT"

# Quick fixes
echo ""
print_info "Applying quick fixes..."

# Fix 1: Add missing hosts entries
missing_domains=()
if [ -f "$VHOSTS_FILE" ]; then
    while read -r domain; do
        if [ "$domain" != "localhost" ] && ! grep -q "127.0.0.1.*$domain" "$HOSTS_FILE"; then
            missing_domains+=("$domain")
        fi
    done < <(grep -o "ServerName [^[:space:]]*" "$VHOSTS_FILE" | awk '{print $2}')
fi

if [ ${#missing_domains[@]} -gt 0 ]; then
    print_info "Adding missing domains to hosts file..."
    temp_hosts=$(mktemp)
    cp "$HOSTS_FILE" "$temp_hosts"
    
    for domain in "${missing_domains[@]}"; do
        echo "127.0.0.1    $domain" >> "$temp_hosts"
        print_status "  ➕ Added: $domain"
    done
    
    sudo cp "$temp_hosts" "$HOSTS_FILE"
    rm -f "$temp_hosts"
    print_status "Updated hosts file"
else
    print_status "All domains found in hosts file"
fi

# Fix 2: Create missing project directories with placeholder
if [ -f "$VHOSTS_FILE" ]; then
    missing_dirs=()
    while read -r docroot; do
        if [ ! -d "$docroot" ]; then
            missing_dirs+=("$docroot")
        fi
    done < <(grep -o 'DocumentRoot "[^"]*"' "$VHOSTS_FILE" | sed 's/DocumentRoot "\([^"]*\)"/\1/')
    
    if [ ${#missing_dirs[@]} -gt 0 ]; then
        print_info "Creating missing project directories..."
        for docroot in "${missing_dirs[@]}"; do
            mkdir -p "$docroot"
            cat > "$docroot/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Project Ready - $(basename "$docroot")</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 50px;
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            max-width: 500px;
        }
        h1 { margin: 0 0 20px 0; font-size: 2.5em; }
        .status { font-size: 1.2em; margin: 20px 0; opacity: 0.9; }
        .path { 
            background: rgba(0, 0, 0, 0.2);
            padding: 15px;
            border-radius: 10px;
            font-family: 'Monaco', 'Courier New', monospace;
            font-size: 0.9em;
            margin: 20px 0;
            word-break: break-all;
        }
        .note { 
            font-size: 0.9em;
            opacity: 0.8;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Project Ready!</h1>
        <div class="status">✅ Virtual host configured successfully</div>
        <div class="path">$docroot</div>
        <p>Your project files can be placed in this directory.</p>
        <div class="note">
            <small>✨ Created by MAMP Quick Fix Tool</small>
        </div>
    </div>
</body>
</html>
EOF
            print_status "  📁 Created: $docroot"
        done
    else
        print_status "All project directories exist"
    fi
fi

# Fix 3: Flush DNS cache
print_info "Flushing DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder 2>/dev/null || true
print_status "DNS cache cleared"

# Fix 4: Test connectivity
echo ""
print_info "Testing project connectivity..."

if [ -f "$VHOSTS_FILE" ]; then
    while read -r domain; do
        if [ "$domain" != "localhost" ]; then
            url="http://$domain"
            if [ "$MAMP_PORT" != "80" ]; then
                url="$url:$MAMP_PORT"
            fi
            
            http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            
            if [[ "$http_code" =~ ^(200|301|302)$ ]]; then
                print_status "  ✅ $domain (HTTP $http_code)"
            else
                print_warning "  ⚠️  $domain (HTTP $http_code) - May need Apache restart"
            fi
        fi
    done < <(grep -o "ServerName [^[:space:]]*" "$VHOSTS_FILE" | awk '{print $2}')
fi

echo ""
print_info "Quick fix completed! 🎉"
echo ""
print_info "If projects still don't work:"
echo "1. Restart MAMP from the application"
echo "2. Wait 10-15 seconds after restart"
echo "3. Try accessing your project domains again"
echo ""
print_info "For detailed diagnosis, run: ./troubleshoot-mamp.sh"
