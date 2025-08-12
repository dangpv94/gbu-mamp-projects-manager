#!/bin/bash

# MAMP Projects Troubleshooting & Auto-Fix Tool
# This script diagnoses and fixes common MAMP virtual host issues

set -e

echo "🔧 MAMP Projects Troubleshooting Tool"
echo "====================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_debug() {
    echo -e "${PURPLE}🔍 $1${NC}"
}

# Configuration
VHOSTS_FILE="/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf"
HOSTS_FILE="/etc/hosts"
APACHE_CONF="/Applications/MAMP/conf/apache/httpd.conf"
BACKUP_DIR="/Applications/MAMP/htdocs/projects/backups"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to get MAMP Apache port
get_mamp_port() {
    if [ -f "/Applications/MAMP/bin/apachectl" ]; then
        port=$(/Applications/MAMP/bin/apachectl -S | grep "port " | head -n 1 | sed -e 's/.*port //g' -e 's/ .*//')
        echo "${port:-8888}"
    elif [ -f "$APACHE_CONF" ]; then
        port=$(grep "^Listen" "$APACHE_CONF" | head -1 | sed 's/Listen //' | sed 's/:.*//')
        echo "${port:-8888}"
    else
        echo "8888"
    fi
}

MAMP_PORT=$(get_mamp_port)

# Function to check if MAMP is running
check_mamp_status() {
    print_info "Checking MAMP status..."
    
    if pgrep -f "Applications/MAMP/Library/bin/httpd" > /dev/null; then
        print_status "MAMP Apache is running on port $MAMP_PORT"
        return 0
    else
        print_error "MAMP Apache is not running!"
        return 1
    fi
}

# Function to analyze virtual hosts
analyze_virtual_hosts() {
    print_info "Analyzing virtual host configuration..."
    
    if [ ! -f "$VHOSTS_FILE" ]; then
        print_error "Virtual hosts file not found: $VHOSTS_FILE"
        return 1
    fi
    
    # Check if vhosts are included in main config
    if grep -q "^Include.*httpd-vhosts.conf" "$APACHE_CONF"; then
        print_status "Virtual hosts are enabled in Apache configuration"
    else
        print_warning "Virtual hosts may not be enabled in Apache configuration"
        print_debug "Looking for Include directive in $APACHE_CONF"
        grep -n "httpd-vhosts" "$APACHE_CONF" || print_debug "No httpd-vhosts include found"
    fi
    
    # Count virtual hosts
    local vhost_count=$(grep -c "^<VirtualHost" "$VHOSTS_FILE" 2>/dev/null || echo "0")
    print_info "Found $vhost_count virtual host(s) configured"
    
    # Analyze each virtual host
    echo ""
    print_info "Virtual Host Analysis:"
    echo "====================="
    
    local current_vhost=""
    local current_domain=""
    local current_docroot=""
    local line_num=0
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        if [[ $line =~ ^\#.*Virtual\ Host\ for\ (.+)$ ]]; then
            current_vhost="${BASH_REMATCH[1]}"
            echo ""
            print_info "Project: $current_vhost"
        elif [[ $line =~ ^\<VirtualHost.*\*:([0-9]+)\> ]]; then
            local vhost_port="${BASH_REMATCH[1]}"
            if [ "$vhost_port" != "$MAMP_PORT" ]; then
                print_warning "  Port mismatch: VHost uses $vhost_port, MAMP runs on $MAMP_PORT"
            else
                print_status "  Port: $vhost_port (matches MAMP)"
            fi
        elif [[ $line =~ ^[[:space:]]*ServerName[[:space:]]+(.+)$ ]]; then
            current_domain="${BASH_REMATCH[1]}"
            echo "  🌐 Domain: $current_domain"
            
            # Check hosts file
            if grep -q "127.0.0.1.*$current_domain" "$HOSTS_FILE"; then
                print_status "    ✅ Found in hosts file"
            else
                print_error "    ❌ Missing from hosts file"
            fi
            
            # Test DNS resolution
            if nslookup "$current_domain" >/dev/null 2>&1; then
                local resolved_ip=$(nslookup "$current_domain" | grep "Address:" | tail -1 | awk '{print $2}')
                if [ "$resolved_ip" = "127.0.0.1" ]; then
                    print_status "    ✅ Resolves to localhost"
                else
                    print_warning "    ⚠️  Resolves to: $resolved_ip (should be 127.0.0.1)"
                fi
            else
                print_error "    ❌ DNS resolution failed"
            fi
            
        elif [[ $line =~ ^[[:space:]]*DocumentRoot[[:space:]]+\"([^\"]+)\" ]]; then
            current_docroot="${BASH_REMATCH[1]}"
            echo "  📁 Document Root: $current_docroot"
            
            if [ -d "$current_docroot" ]; then
                print_status "    ✅ Directory exists"
                
                # Check if it has content
                if [ "$(ls -A "$current_docroot" 2>/dev/null)" ]; then
                    print_status "    ✅ Contains files"
                else
                    print_warning "    ⚠️  Directory is empty"
                fi
                
                # Check index file
                if [ -f "$current_docroot/index.html" ] || [ -f "$current_docroot/index.php" ]; then
                    print_status "    ✅ Has index file"
                else
                    print_warning "    ⚠️  No index file found"
                fi
                
                # Check permissions
                if [ -r "$current_docroot" ] && [ -x "$current_docroot" ]; then
                    print_status "    ✅ Permissions OK"
                else
                    print_error "    ❌ Permission issues"
                fi
            else
                print_error "    ❌ Directory does not exist"
            fi
        fi
    done < "$VHOSTS_FILE"
}

# Function to check hosts file
check_hosts_file() {
    print_info "Analyzing hosts file..."
    
    if [ ! -f "$HOSTS_FILE" ]; then
        print_error "Hosts file not found: $HOSTS_FILE"
        return 1
    fi
    
    print_status "Hosts file exists: $HOSTS_FILE"
    
    # Check localhost entry
    if grep -q "^127.0.0.1.*localhost" "$HOSTS_FILE"; then
        print_status "Localhost entry found"
    else
        print_warning "No localhost entry found"
    fi
    
    # Find project entries
    print_info "Project domains in hosts file:"
    grep "127.0.0.1.*\.local" "$HOSTS_FILE" | while read -r line; do
        domain=$(echo "$line" | awk '{print $2}')
        echo "  🌐 $domain"
    done
    
    # Check for duplicates
    local duplicates=$(grep "127.0.0.1" "$HOSTS_FILE" | awk '{print $2}' | sort | uniq -d)
    if [ -n "$duplicates" ]; then
        print_warning "Duplicate entries found:"
        echo "$duplicates" | while read -r domain; do
            echo "  🔄 $domain (duplicate)"
        done
    fi
}

# Function to test HTTP connectivity
test_connectivity() {
    print_info "Testing HTTP connectivity..."
    
    # Test localhost
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$MAMP_PORT" | grep -q "200\|301\|302"; then
        print_status "MAMP localhost accessible"
    else
        print_error "MAMP localhost not accessible"
    fi
    
    # Test project domains
    grep -o "ServerName [^[:space:]]*" "$VHOSTS_FILE" | awk '{print $2}' | while read -r domain; do
        if [ "$domain" != "localhost" ]; then
            local url="http://$domain"
            if [ "$MAMP_PORT" != "80" ]; then
                url="$url:$MAMP_PORT"
            fi
            
            print_debug "Testing: $url"
            local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
            
            if [[ "$http_code" =~ ^(200|301|302)$ ]]; then
                print_status "  ✅ $domain (HTTP $http_code)"
            else
                print_error "  ❌ $domain (HTTP $http_code or unreachable)"
                
                # Diagnose the issue
                if ! grep -q "127.0.0.1.*$domain" "$HOSTS_FILE"; then
                    echo "    💡 Issue: Missing hosts entry"
                elif ! nslookup "$domain" >/dev/null 2>&1; then
                    echo "    💡 Issue: DNS resolution failed"
                else
                    echo "    💡 Issue: Server/DocumentRoot problem"
                fi
            fi
        fi
    done
}

# Function to auto-fix common issues
auto_fix_issues() {
    print_info "Starting automatic fixes..."
    
    local backup_suffix=$(date +%Y%m%d_%H%M%S)
    
    # Backup files
    cp "$VHOSTS_FILE" "$BACKUP_DIR/vhosts_backup_$backup_suffix.conf"
    cp "$HOSTS_FILE" "$BACKUP_DIR/hosts_backup_$backup_suffix"
    print_status "Configuration files backed up"
    
    # Fix 1: Port mismatch in virtual hosts
    print_info "Checking for port mismatches..."
    local temp_vhosts=$(mktemp)
    local port_fixes=0
    
    while IFS= read -r line; do
        if [[ $line =~ ^(\<VirtualHost.*\*:)[0-9]+(\>.*)$ ]]; then
            local prefix="${BASH_REMATCH[1]}"
            local suffix="${BASH_REMATCH[2]}"
            echo "${prefix}${MAMP_PORT}${suffix}" >> "$temp_vhosts"
            port_fixes=$((port_fixes + 1))
        else
            echo "$line" >> "$temp_vhosts"
        fi
    done < "$VHOSTS_FILE"
    
    if [ $port_fixes -gt 0 ]; then
        mv "$temp_vhosts" "$VHOSTS_FILE"
        print_status "Fixed $port_fixes virtual host port(s) to match MAMP port $MAMP_PORT"
    else
        rm "$temp_vhosts"
        print_status "No port mismatches found"
    fi
    
    # Fix 2: Missing hosts entries
    print_info "Checking for missing hosts entries..."
    local hosts_fixes=0
    local temp_hosts=$(mktemp)
    cp "$HOSTS_FILE" "$temp_hosts"
    
    grep -o "ServerName [^[:space:]]*" "$VHOSTS_FILE" | awk '{print $2}' | while read -r domain; do
        if [ "$domain" != "localhost" ] && ! grep -q "127.0.0.1.*$domain" "$HOSTS_FILE"; then
            echo "127.0.0.1    $domain" >> "$temp_hosts"
            echo "  ➕ Added: $domain"
            hosts_fixes=$((hosts_fixes + 1))
        fi
    done
    
    if [ $hosts_fixes -gt 0 ]; then
        sudo cp "$temp_hosts" "$HOSTS_FILE"
        print_status "Added $hosts_fixes missing hosts entries"
    else
        print_status "No missing hosts entries found"
    fi
    rm -f "$temp_hosts"
    
    # Fix 3: Enable virtual hosts in Apache config
    if ! grep -q "^Include.*httpd-vhosts.conf" "$APACHE_CONF"; then
        print_info "Enabling virtual hosts in Apache configuration..."
        sudo sed -i '' 's/^#Include.*httpd-vhosts.conf/Include conf\/extra\/httpd-vhosts.conf/' "$APACHE_CONF"
        print_status "Virtual hosts enabled in Apache configuration"
    fi
    
    # Fix 4: Create missing project directories
    print_info "Checking for missing project directories..."
    local dir_fixes=0
    
    grep -A5 "DocumentRoot" "$VHOSTS_FILE" | grep "DocumentRoot" | sed 's/.*DocumentRoot "\([^"]*\)".*/\1/' | while read -r docroot; do
        if [ ! -d "$docroot" ]; then
            mkdir -p "$docroot"
            cat > "$docroot/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Project Ready</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #f0f8ff; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .status { color: #28a745; font-size: 18px; margin: 20px 0; }
        .path { background: #f8f9fa; padding: 10px; border-radius: 5px; font-family: monospace; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Project Directory Ready</h1>
        <div class="status">✅ Virtual host is configured correctly</div>
        <div class="path">$docroot</div>
        <p>Your project files can be placed in this directory.</p>
        <p><small>Created by MAMP Troubleshooting Tool</small></p>
    </div>
</body>
</html>
EOF
            print_status "  ➕ Created directory: $docroot"
            dir_fixes=$((dir_fixes + 1))
        fi
    done
    
    # Fix 5: Flush DNS cache
    print_info "Flushing DNS cache..."
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder 2>/dev/null || true
    print_status "DNS cache flushed"
    
    # Fix 6: Restart MAMP Apache
    print_info "Restarting MAMP Apache..."
    pkill -f "Applications/MAMP/Library/bin/httpd" 2>/dev/null || true
    sleep 2
    /Applications/MAMP/bin/startApache.sh >/dev/null 2>&1 &
    sleep 3
    
    if pgrep -f "Applications/MAMP/Library/bin/httpd" > /dev/null; then
        print_status "MAMP Apache restarted successfully"
    else
        print_warning "Apache restart may have failed - please check MAMP manually"
    fi
}

# Function to show summary and recommendations
show_recommendations() {
    echo ""
    echo "📋 RECOMMENDATIONS"
    echo "=================="
    
    print_info "For future troubleshooting:"
    echo "1. Always restart MAMP after modifying virtual hosts"
    echo "2. Flush DNS cache after modifying hosts file: sudo dscacheutil -flushcache"
    echo "3. Ensure virtual hosts port matches MAMP Apache port ($MAMP_PORT)"
    echo "4. Check DocumentRoot paths exist and have proper permissions"
    echo "5. Verify hosts file entries use correct format: 127.0.0.1    domain.local"
    echo ""
    
    print_info "Quick commands for manual fixes:"
    echo "• Check MAMP port: grep '^Listen' '$APACHE_CONF'"
    echo "• Test domain resolution: nslookup domain.local"
    echo "• View hosts file: cat '$HOSTS_FILE'"
    echo "• Edit hosts file: sudo nano '$HOSTS_FILE'"
    echo "• Restart MAMP: pkill -f httpd && /Applications/MAMP/bin/startApache.sh"
    echo ""
}

# Main menu
show_menu() {
    echo "🛠️  TROUBLESHOOTING OPTIONS"
    echo "=========================="
    echo "1. 🔍 Run Full Diagnosis"
    echo "2. 🔧 Auto-Fix Common Issues"
    echo "3. 🩺 Check MAMP Status Only"
    echo "4. 🌐 Test Project Connectivity"
    echo "5. 📝 Show Manual Fix Commands"
    echo "6. 🚪 Exit"
    echo ""
    read -p "Choose an option (1-6): " choice
    
    case $choice in
        1)
            echo ""
            print_info "Running full diagnosis..."
            check_mamp_status
            analyze_virtual_hosts
            check_hosts_file
            test_connectivity
            show_recommendations
            ;;
        2)
            echo ""
            print_info "Running auto-fix..."
            if check_mamp_status; then
                auto_fix_issues
                echo ""
                print_status "Auto-fix completed! Running verification..."
                sleep 2
                test_connectivity
            else
                print_error "Please start MAMP first"
            fi
            ;;
        3)
            echo ""
            check_mamp_status
            ;;
        4)
            echo ""
            if check_mamp_status; then
                test_connectivity
            else
                print_error "MAMP is not running"
            fi
            ;;
        5)
            show_recommendations
            ;;
        6)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read
    clear
}

# Main loop
clear
while true; do
    show_menu
done
