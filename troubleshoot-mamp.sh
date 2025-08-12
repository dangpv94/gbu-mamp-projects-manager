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
    # Try multiple methods to detect the port
    local port=""
    
    # Method 1: Check Listen directive for IP:PORT format
    if [ -f "$APACHE_CONF" ]; then
        port=$(grep "^Listen" "$APACHE_CONF" | head -1 | sed 's/.*://g' | tr -d ' ')
        if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" != "0" ]; then
            echo "$port"
            return
        fi
    fi
    
    # Method 2: Check ServerName directive
    if [ -f "$APACHE_CONF" ]; then
        port=$(grep "^ServerName" "$APACHE_CONF" | head -1 | sed 's/.*://g' | tr -d ' ')
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            echo "$port"
            return
        fi
    fi
    
    # Method 3: Try apachectl if available
    if [ -f "/Applications/MAMP/bin/apachectl" ]; then
        port=$(/Applications/MAMP/bin/apachectl -S 2>/dev/null | grep "port " | head -n 1 | sed -e 's/.*port //g' -e 's/ .*//' 2>/dev/null)
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            echo "$port"
            return
        fi
    fi
    
    # Default fallback
    echo "8888"
}

MAMP_PORT=$(get_mamp_port)

# Function to find apachectl binary location
get_apachectl_path() {
    # Common locations for apachectl in different MAMP versions
    local possible_paths=(
        "/Applications/MAMP/Library/bin/apachectl"
        "/Applications/MAMP/bin/apachectl"
        "/Applications/MAMP/bin/apache2/bin/apachectl"
        "/Applications/MAMP/Library/bin/httpd"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -f "$path" ] && [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # If not found in common locations, search dynamically
    local found_path
    found_path=$(find /Applications/MAMP -name "apachectl" -type f -executable 2>/dev/null | head -1)
    
    if [ -n "$found_path" ]; then
        echo "$found_path"
        return 0
    fi
    
    # Final fallback - try to find httpd binary
    found_path=$(find /Applications/MAMP -name "httpd" -path "*/bin/*" -type f -executable 2>/dev/null | head -1)
    
    if [ -n "$found_path" ]; then
        echo "$found_path"
        return 0
    fi
    
    # No Apache control found
    return 1
}

APACHECTL_PATH=$(get_apachectl_path)

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
    print_info "Starting comprehensive automatic fixes..."
    
    local backup_suffix=$(date +%Y%m%d_%H%M%S)
    
    # Backup files
    cp "$VHOSTS_FILE" "$BACKUP_DIR/vhosts_backup_$backup_suffix.conf"
    cp "$HOSTS_FILE" "$BACKUP_DIR/hosts_backup_$backup_suffix"
    print_status "Configuration files backed up"
    
    # PRE-CHECK: Apache syntax validation (Critical - must pass before proceeding)
    print_info "Pre-check: Validating Apache configuration syntax..."
    
    # Check if we found apachectl
    if [ -z "$APACHECTL_PATH" ]; then
        print_warning "Apache control binary not found - skipping syntax validation"
        print_info "Will proceed with other fixes (syntax check skipped)"
    else
        print_debug "Using Apache control: $APACHECTL_PATH"
        local config_test_output
        config_test_output=$(sudo "$APACHECTL_PATH" -t 2>&1)
        
        if ! echo "$config_test_output" | grep -q "Syntax OK"; then
            print_error "Apache configuration has syntax errors! Cannot proceed with auto-fix."
            echo -e "${RED}$config_test_output${NC}"
            print_warning "Please fix the syntax errors manually first, then run auto-fix again."
            return 1
        fi
        print_status "Apache configuration syntax is valid"
    fi
    
    # STEP 1: Handle port conflicts (Apache startup blocker)
    print_info "Checking for port conflicts on port $MAMP_PORT..."
    local conflicting_process=$(lsof -i :$MAMP_PORT 2>/dev/null | grep LISTEN | awk '{print $1, $2}' | head -1)
    
    if [ -n "$conflicting_process" ]; then
        local process_name=$(echo "$conflicting_process" | awk '{print $1}')
        local process_id=$(echo "$conflicting_process" | awk '{print $2}')
        print_error "Port $MAMP_PORT is being used by: $process_name (PID: $process_id)"
        
        echo -n "Do you want to terminate this process to free the port? (y/n): "
        read -r kill_confirm
        
        if [[ $kill_confirm =~ ^[Yy]$ ]]; then
            if sudo kill -9 "$process_id" 2>/dev/null; then
                print_status "Successfully terminated conflicting process (PID: $process_id)"
                sleep 2
            else
                print_error "Failed to terminate process. You may need to quit the application manually."
            fi
        else
            print_warning "Port conflict not resolved. Apache may fail to start."
        fi
    else
        print_status "Port $MAMP_PORT is available"
    fi
    
    # STEP 2: Fix log file permissions
    print_info "Checking and fixing log file permissions..."
    local log_dir="/Applications/MAMP/logs"
    local error_log="$log_dir/apache_error.log"
    local access_log="$log_dir/apache_access.log"
    
    # Create logs directory if it doesn't exist
    if [ ! -d "$log_dir" ]; then
        sudo mkdir -p "$log_dir"
        print_status "Created logs directory: $log_dir"
    fi
    
    # Fix log file permissions
    for log_file in "$error_log" "$access_log"; do
        if [ -f "$log_file" ]; then
            sudo chmod 666 "$log_file" 2>/dev/null
            print_status "Fixed permissions for $(basename "$log_file")"
        else
            # Create empty log file with correct permissions
            sudo touch "$log_file"
            sudo chmod 666 "$log_file"
            print_status "Created and set permissions for $(basename "$log_file")"
        fi
    done
    
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
    
    # Fix 5: Clean up problematic .htaccess files
    print_info "Scanning for problematic .htaccess files..."
    local htaccess_fixes=0
    
    # Find .htaccess files with php_value directives (common cause of startup issues)
    if [ -d "/Applications/MAMP/htdocs" ]; then
        find /Applications/MAMP/htdocs -name ".htaccess" -type f 2>/dev/null | while read -r htaccess_file; do
            if grep -q "^[[:space:]]*php_value" "$htaccess_file" 2>/dev/null; then
                print_warning "Found problematic .htaccess: $htaccess_file"
                
                # Backup and comment out php_value lines
                cp "$htaccess_file" "${htaccess_file}.backup_$backup_suffix"
                sed 's/^[[:space:]]*php_value/#php_value/g' "$htaccess_file" > "${htaccess_file}.tmp"
                mv "${htaccess_file}.tmp" "$htaccess_file"
                
                print_status "  Fixed: commented out php_value directives"
                htaccess_fixes=$((htaccess_fixes + 1))
            fi
        done
        
        if [ $htaccess_fixes -gt 0 ]; then
            print_status "Fixed $htaccess_fixes problematic .htaccess file(s)"
        else
            print_status "No problematic .htaccess files found"
        fi
    fi
    
    # Fix 6: Fix virtual host error log permissions 
    print_info "Checking virtual host error log permissions..."
    local vhost_log_fixes=0
    
    # Extract error log paths from virtual hosts and fix permissions
    grep -i "ErrorLog" "$VHOSTS_FILE" 2>/dev/null | sed 's/.*ErrorLog[[:space:]]*\(.*\)/\1/g' | while read -r log_path; do
        if [ -n "$log_path" ] && [[ "$log_path" != "#"* ]]; then
            # Create log directory if it doesn't exist
            local log_dir=$(dirname "$log_path")
            if [ ! -d "$log_dir" ]; then
                sudo mkdir -p "$log_dir" 2>/dev/null
                print_status "  Created log directory: $log_dir"
            fi
            
            # Create log file with proper permissions if it doesn't exist
            if [ ! -f "$log_path" ]; then
                sudo touch "$log_path" 2>/dev/null
                sudo chmod 666 "$log_path" 2>/dev/null
                print_status "  Created log file: $log_path"
                vhost_log_fixes=$((vhost_log_fixes + 1))
            elif [ ! -w "$log_path" ]; then
                sudo chmod 666 "$log_path" 2>/dev/null
                print_status "  Fixed permissions: $log_path"
                vhost_log_fixes=$((vhost_log_fixes + 1))
            fi
        fi
    done
    
    # Fix 7: Kill orphaned Apache processes
    print_info "Checking for orphaned Apache processes..."
    local orphaned_processes=$(pgrep -f "httpd" | grep -v "$(pgrep -f 'Applications/MAMP/Library/bin/httpd')" | head -5)
    
    if [ -n "$orphaned_processes" ]; then
        print_warning "Found orphaned Apache processes: $orphaned_processes"
        echo -n "Kill orphaned processes? (y/n): "
        read -r kill_confirm
        
        if [[ $kill_confirm =~ ^[Yy]$ ]]; then
            echo "$orphaned_processes" | xargs sudo kill -9 2>/dev/null || true
            sleep 2
            print_status "Orphaned processes terminated"
        fi
    else
        print_status "No orphaned Apache processes found"
    fi
    
    # Fix 8: Fix MAMP PHP module configuration
    print_info "Checking PHP module configuration..."
    local php_conf="/Applications/MAMP/conf/apache/httpd.conf"
    
    if [ -f "$php_conf" ]; then
        # Ensure PHP module is enabled
        if ! grep -q "^LoadModule php" "$php_conf"; then
            if grep -q "#LoadModule php" "$php_conf"; then
                sudo sed -i '' 's/^#LoadModule php/LoadModule php/' "$php_conf"
                print_status "Enabled PHP module in Apache configuration"
            else
                print_warning "PHP module configuration not found - may need manual setup"
            fi
        else
            print_status "PHP module is properly configured"
        fi
    fi
    
    # Fix 9: Flush DNS cache
    print_info "Flushing DNS cache..."
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder 2>/dev/null || true
    print_status "DNS cache flushed"
    
    # Fix 10: Clean restart MAMP Apache
    print_info "Performing clean restart of MAMP Apache..."
    
    # Stop all Apache processes
    pkill -f "Applications/MAMP/Library/bin/httpd" 2>/dev/null || true
    pkill -f "httpd" 2>/dev/null || true  # Stop any other httpd processes
    sleep 3
    
    # Ensure all processes are terminated
    local remaining_processes=$(pgrep -f "httpd" | wc -l)
    if [ "$remaining_processes" -gt 0 ]; then
        print_warning "Force killing remaining httpd processes..."
        pgrep -f "httpd" | xargs sudo kill -9 2>/dev/null || true
        sleep 2
    fi
    
    # Start Apache
    /Applications/MAMP/bin/startApache.sh > /dev/null 2>&1 &
    sleep 5
    
    # Verify startup
    local startup_attempts=0
    while [ $startup_attempts -lt 10 ]; do
        if pgrep -f "Applications/MAMP/Library/bin/httpd" > /dev/null; then
            print_status "MAMP Apache started successfully"
            break
        fi
        sleep 1
        startup_attempts=$((startup_attempts + 1))
    done
    
    if [ $startup_attempts -eq 10 ]; then
        print_error "Apache failed to start after $startup_attempts attempts"
        print_info "Checking recent error log for clues..."
        tail -10 "/Applications/MAMP/logs/apache_error.log" 2>/dev/null || print_warning "Could not read error log"
        return 1
    fi
}

# Function to check for Apache startup issues
check_apache_startup_issues() {
    print_info "Diagnosing Apache startup issues..."
    
    # 1. Check for port conflicts
    print_info "Checking for port conflicts on port $MAMP_PORT..."
    local conflicting_process=$(lsof -i :$MAMP_PORT 2>/dev/null | grep LISTEN | head -1 | awk '{print $1, $2}')
    
    if [ -n "$conflicting_process" ]; then
        local process_name=$(echo "$conflicting_process" | awk '{print $1}')
        local process_id=$(echo "$conflicting_process" | awk '{print $2}')
        print_error "Port $MAMP_PORT is already in use by: $process_name (PID: $process_id)"
        
        # Show all processes using the port
        local all_processes=$(lsof -i :$MAMP_PORT 2>/dev/null | grep LISTEN | awk '{print $2}' | sort -u | tr '\n' ' ')
        if [ $(echo "$all_processes" | wc -w) -gt 1 ]; then
            print_info "All processes using port $MAMP_PORT: PIDs $all_processes"
        fi
        
        print_warning "Suggestion: Quit the conflicting application or run 'sudo kill -9 $process_id'"
    else
        print_status "Port $MAMP_PORT is free"
    fi
    
    # 2. Check Apache syntax
    print_info "Checking Apache configuration syntax..."
    
    if [ -z "$APACHECTL_PATH" ]; then
        print_warning "Apache control binary not found - cannot check syntax"
        print_info "Searched in: /Applications/MAMP/Library/bin/, /Applications/MAMP/bin/"
        print_info "You may need to check syntax manually with: sudo [path-to-apachectl] -t"
    else
        print_debug "Using Apache control: $APACHECTL_PATH"
        local config_test_output
        config_test_output=$(sudo "$APACHECTL_PATH" -t 2>&1)
        
        if echo "$config_test_output" | grep -q "Syntax OK"; then
            print_status "Apache configuration syntax is OK"
        else
            print_error "Apache configuration syntax error found!"
            echo -e "${RED}$config_test_output${NC}"
        fi
    fi
    
    # 3. Check log file permissions
    print_info "Checking log file permissions..."
    local log_file="/Applications/MAMP/logs/apache_error.log"
    if [ -f "$log_file" ]; then
        if [ -w "$log_file" ]; then
            print_status "Log file permissions are OK"
        else
            print_error "Log file is not writable: $log_file"
            print_warning "Suggestion: Run 'sudo chmod 666 $log_file'"
        fi
    else
        print_warning "Log file not found, will be created by MAMP on successful start."
    fi
}

# Emergency fix function for when MAMP completely fails to start
emergency_fix() {
    print_error "🚨 EMERGENCY FIX MODE - MAMP WON'T START"
    print_info "This will perform aggressive fixes that may reset some configurations"
    
    echo -n "Continue with emergency fix? This may reset some MAMP settings (y/n): "
    read -r confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Emergency fix cancelled"
        return 0
    fi
    
    local backup_suffix=$(date +%Y%m%d_%H%M%S)
    
    print_info "Step 1: Backing up all critical configurations..."
    mkdir -p "$BACKUP_DIR/emergency_$backup_suffix"
    cp "$APACHE_CONF" "$BACKUP_DIR/emergency_$backup_suffix/httpd.conf.backup" 2>/dev/null || true
    cp "$VHOSTS_FILE" "$BACKUP_DIR/emergency_$backup_suffix/httpd-vhosts.conf.backup" 2>/dev/null || true
    cp "$HOSTS_FILE" "$BACKUP_DIR/emergency_$backup_suffix/hosts.backup" 2>/dev/null || true
    print_status "Configurations backed up to $BACKUP_DIR/emergency_$backup_suffix"
    
    print_info "Step 2: Force stopping all web servers and processes..."
    # Kill everything that could conflict
    sudo pkill -9 -f httpd 2>/dev/null || true
    sudo pkill -9 -f apache 2>/dev/null || true
    sudo pkill -9 -f nginx 2>/dev/null || true
    sudo pkill -9 -f "MAMP" 2>/dev/null || true
    sleep 3
    
    print_info "Step 3: Cleaning up lock files and PIDs..."
    # Remove lock files and PIDs that might prevent startup
    sudo rm -f /Applications/MAMP/logs/*.pid 2>/dev/null || true
    sudo rm -f /Applications/MAMP/tmp/apache/*.pid 2>/dev/null || true
    sudo rm -f /Applications/MAMP/tmp/mysql/*.pid 2>/dev/null || true
    sudo rm -f /tmp/httpd.lock 2>/dev/null || true
    sudo rm -f /var/run/httpd.pid 2>/dev/null || true
    
    print_info "Step 4: Resetting Apache configuration to minimal state..."
    # Create a minimal working Apache config
    local minimal_conf="/Applications/MAMP/conf/apache/httpd.conf.minimal"
    cat > "$minimal_conf" << 'EOF'
# Minimal MAMP Apache Configuration
ServerRoot "/Applications/MAMP/Library"
PidFile /Applications/MAMP/tmp/apache/httpd.pid
Listen 80
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule php8_module modules/libphp8.so

ServerName localhost:80
DocumentRoot "/Applications/MAMP/htdocs"

<Directory "/Applications/MAMP/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

DirectoryIndex index.html index.php

TypesConfig /Applications/MAMP/conf/apache/mime.types
ErrorLog /Applications/MAMP/logs/apache_error.log
LogLevel warn
CustomLog /Applications/MAMP/logs/apache_access.log combined

AddType application/x-httpd-php .php
PHPIniDir /Applications/MAMP/bin/php/php8.2.0/conf

# Include virtual hosts if they exist
IncludeOptional conf/extra/httpd-vhosts.conf
EOF
    
    echo -n "Replace main Apache config with minimal version? (y/n): "
    read -r replace_conf
    
    if [[ $replace_conf =~ ^[Yy]$ ]]; then
        sudo cp "$minimal_conf" "$APACHE_CONF"
        print_status "Applied minimal Apache configuration"
    fi
    
    print_info "Step 5: Fixing all permission issues..."
    # Fix all MAMP directory permissions
    sudo chown -R $(whoami):admin /Applications/MAMP/logs 2>/dev/null || true
    sudo chown -R $(whoami):admin /Applications/MAMP/tmp 2>/dev/null || true
    sudo chmod -R 755 /Applications/MAMP/logs 2>/dev/null || true
    sudo chmod -R 755 /Applications/MAMP/tmp 2>/dev/null || true
    sudo chmod -R 755 /Applications/MAMP/htdocs 2>/dev/null || true
    
    # Fix log files specifically
    sudo touch /Applications/MAMP/logs/apache_error.log
    sudo touch /Applications/MAMP/logs/apache_access.log
    sudo chmod 666 /Applications/MAMP/logs/*.log 2>/dev/null || true
    
    print_info "Step 6: Creating clean virtual hosts file..."
    cat > "$VHOSTS_FILE" << EOF
# Virtual Hosts Configuration
# Created by Emergency Fix $(date)

NameVirtualHost *:80

# Default localhost virtual host
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot "/Applications/MAMP/htdocs"
</VirtualHost>

# Add your virtual hosts below this line
EOF
    print_status "Created clean virtual hosts configuration"
    
    print_info "Step 7: Attempting to start Apache..."
    # Try to start with the minimal configuration
    if [ -n "$APACHECTL_PATH" ]; then
        # Test configuration first
        local config_test=$(sudo "$APACHECTL_PATH" -t 2>&1)
        if echo "$config_test" | grep -q "Syntax OK"; then
            print_status "Configuration syntax is OK"
            
            # Try to start
            sudo "$APACHECTL_PATH" -k start 2>/dev/null || {
                print_warning "Direct apachectl start failed, trying MAMP script..."
                /Applications/MAMP/bin/startApache.sh > /dev/null 2>&1 &
            }
        else
            print_error "Configuration still has syntax errors:"
            echo "$config_test"
        fi
    else
        /Applications/MAMP/bin/startApache.sh > /dev/null 2>&1 &
    fi
    
    sleep 5
    
    # Check if it started
    if pgrep -f "Applications/MAMP/Library/bin/httpd" > /dev/null; then
        print_status "🎉 SUCCESS! Apache started with emergency configuration"
        print_info "You can now:"
        echo "  1. Access http://localhost to test"
        echo "  2. Add your virtual hosts back gradually"
        echo "  3. Restore from backup if needed: $BACKUP_DIR/emergency_$backup_suffix"
        return 0
    else
        print_error "❌ Emergency fix failed. Apache still won't start."
        print_info "Last resort options:"
        echo "  1. Reinstall MAMP completely"
        echo "  2. Check system logs: tail -f /var/log/system.log"
        echo "  3. Check Apache error log: tail -f /Applications/MAMP/logs/apache_error.log"
        echo "  4. Restore from backup: cp $BACKUP_DIR/emergency_$backup_suffix/*.backup /original/locations"
        return 1
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
    echo "2. 🔥 Diagnose Apache Startup Fail"
    echo "3. 🔧 Auto-Fix Common Issues"
    echo "4. 🚨 Emergency Fix (MAMP Won't Start)"
    echo "5. 🩺 Check MAMP Status Only"
    echo "6. 🌐 Test Project Connectivity"
    echo "7. 📝 Show Manual Fix Commands"
    echo "8. 🚪 Exit"
    echo ""
    read -p "Choose an option (1-8): " choice
    
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
            check_apache_startup_issues
            ;;
        3)
            echo ""
            print_info "Running comprehensive auto-fix..."
            
            # Run auto-fix regardless of MAMP status - it can fix startup issues
            if auto_fix_issues; then
                echo ""
                print_status "Auto-fix completed! Running verification..."
                sleep 2
                
                # Check if MAMP is now running and test connectivity
                if check_mamp_status; then
                    test_connectivity
                else
                    print_warning "MAMP is still not running. Try starting it manually and check for any error messages."
                fi
            else
                print_error "Auto-fix encountered critical issues. Please review the errors above."
            fi
            ;;
        4)
            echo ""
            emergency_fix
            ;;
        5)
            echo ""
            check_mamp_status
            ;;
        6)
            echo ""
            if check_mamp_status; then
                test_connectivity
            else
                print_error "MAMP is not running"
            fi
            ;;
        7)
            show_recommendations
            ;;
        8)
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
