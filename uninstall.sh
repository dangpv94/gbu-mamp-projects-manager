#!/bin/bash

# MAMP Projects Manager - Uninstall Script
# Author: MAMP Projects Manager Team
# Version: 2.0
# Description: Complete removal of MAMP Projects Manager and all configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
MAMP_PROJECTS_DIR="/Applications/MAMP/htdocs/projects"
VHOSTS_CONFIG="/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf"
HOSTS_FILE="/etc/hosts"
BACKUP_DIR="$HOME/Desktop/mamp-manager-uninstall-backup-$(date +%Y%m%d-%H%M%S)"

echo ""
echo -e "${BOLD}🗑️  MAMP Projects Manager - Uninstall Script${NC}"
echo -e "${BOLD}=================================================${NC}"
echo ""

# Function to print status messages
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

# Function to create backup
create_backup() {
    print_info "Creating backup in: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup project files
    if [ -d "$MAMP_PROJECTS_DIR" ]; then
        cp -R "$MAMP_PROJECTS_DIR" "$BACKUP_DIR/projects/"
        print_status "Projects backed up"
    fi
    
    # Backup Apache vhosts config
    if [ -f "$VHOSTS_CONFIG" ]; then
        cp "$VHOSTS_CONFIG" "$BACKUP_DIR/httpd-vhosts.conf.backup"
        print_status "Apache vhosts config backed up"
    fi
    
    # Backup hosts file
    if [ -f "$HOSTS_FILE" ]; then
        cp "$HOSTS_FILE" "$BACKUP_DIR/hosts.backup"
        print_status "Hosts file backed up"
    fi
}

# Function to check if user wants to proceed
confirm_removal() {
    echo -e "${YELLOW}${BOLD}WARNING: This will completely remove MAMP Projects Manager!${NC}"
    echo ""
    echo "The following will be removed:"
    echo "  • All project virtual hosts and configurations"
    echo "  • MAMP Projects Manager interface and files"
    echo "  • Hosts file entries for .local domains"
    echo "  • Project folders created within MAMP"
    echo ""
    echo -e "${GREEN}The following will be preserved:${NC}"
    echo "  • Original project files in external directories (link mode)"
    echo "  • MAMP application itself"
    echo "  • Other MAMP configurations"
    echo "  • Backup will be created on your Desktop"
    echo ""
    
    read -p "Do you want to proceed with uninstallation? (yes/no): " confirm
    
    if [[ $confirm != "yes" ]]; then
        print_info "Uninstallation cancelled by user"
        exit 0
    fi
}

# Function to remove projects via web interface
remove_projects_via_api() {
    print_info "Attempting to remove all projects via API..."
    
    # Try to detect Apache port
    local apache_port=80
    if [ -f "/Applications/MAMP/conf/apache/httpd.conf" ]; then
        local detected_port=$(grep "^Listen.*:" /Applications/MAMP/conf/apache/httpd.conf | head -1 | sed 's/.*://' | tr -d ' ')
        if [[ $detected_port =~ ^[0-9]+$ ]]; then
            apache_port=$detected_port
        fi
    fi
    
    # Try to call the API to remove all projects
    local api_url="http://localhost:$apache_port/projects/api.php"
    
    if command -v curl >/dev/null 2>&1; then
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"action":"remove_all_projects"}' \
            "$api_url" 2>/dev/null || echo "")
        
        if [[ $response == *"success"* ]]; then
            print_status "Projects removed via API"
            return 0
        fi
    fi
    
    print_warning "Could not remove projects via API (MAMP may not be running)"
    return 1
}

# Function to clean virtual hosts configuration
clean_vhosts_config() {
    print_info "Cleaning virtual hosts configuration..."
    
    if [ -f "$VHOSTS_CONFIG" ]; then
        # Remove MAMP Projects Manager sections
        sudo sed -i '' '/# MAMP Projects Manager/,/# End MAMP Projects Manager/d' "$VHOSTS_CONFIG" 2>/dev/null || {
            print_warning "Could not automatically clean vhosts config - manual cleanup may be needed"
            return 1
        }
        
        # Remove any remaining .local virtual hosts
        sudo sed -i '' '/<VirtualHost.*>.*\.local/,/<\/VirtualHost>/d' "$VHOSTS_CONFIG" 2>/dev/null || {
            print_warning "Could not remove .local virtual hosts - manual cleanup may be needed"
        }
        
        print_status "Virtual hosts configuration cleaned"
    else
        print_warning "Virtual hosts config file not found"
    fi
}

# Function to clean hosts file
clean_hosts_file() {
    print_info "Cleaning hosts file..."
    
    if [ -f "$HOSTS_FILE" ]; then
        # Remove MAMP Projects Manager entries
        sudo sed -i '' '/# Added by MAMP Projects Manager/d' "$HOSTS_FILE" 2>/dev/null || {
            print_warning "Could not remove MAMP Projects Manager entries from hosts file"
        }
        
        # Remove .local domain entries (be careful not to remove system .local entries)
        sudo sed -i '' '/127\.0\.0\.1.*\.local$/d' "$HOSTS_FILE" 2>/dev/null || {
            print_warning "Could not remove .local domain entries from hosts file"
        }
        
        print_status "Hosts file cleaned"
    else
        print_error "Hosts file not found"
    fi
}

# Function to remove MAMP Projects Manager files
remove_manager_files() {
    print_info "Removing MAMP Projects Manager files..."
    
    if [ -d "$MAMP_PROJECTS_DIR" ]; then
        # Remove the entire projects directory
        sudo rm -rf "$MAMP_PROJECTS_DIR" 2>/dev/null || {
            print_error "Could not remove projects directory - you may need to remove it manually"
            return 1
        }
        
        print_status "MAMP Projects Manager files removed"
    else
        print_warning "MAMP Projects Manager directory not found"
    fi
}

# Function to restart Apache
restart_apache() {
    print_info "Restarting Apache server..."
    
    # Try multiple Apache restart methods
    if /Applications/MAMP/bin/apache2/bin/apachectl restart >/dev/null 2>&1; then
        print_status "Apache restarted successfully"
    elif /Applications/MAMP/Library/bin/httpd -k restart >/dev/null 2>&1; then
        print_status "Apache restarted successfully (alternative method)"
    else
        print_warning "Could not restart Apache automatically - please restart MAMP manually"
    fi
}

# Function to clear DNS cache
clear_dns_cache() {
    print_info "Clearing DNS cache..."
    
    if sudo dscacheutil -flushcache >/dev/null 2>&1; then
        print_status "DNS cache cleared"
    else
        print_warning "Could not clear DNS cache - you may need to restart your system"
    fi
}

# Function to verify removal
verify_removal() {
    print_info "Verifying removal..."
    
    local issues_found=0
    
    # Check if projects directory still exists
    if [ -d "$MAMP_PROJECTS_DIR" ]; then
        print_warning "Projects directory still exists"
        issues_found=$((issues_found + 1))
    fi
    
    # Check for remaining virtual hosts
    if [ -f "$VHOSTS_CONFIG" ]; then
        local vhost_count=$(grep -c "\.local" "$VHOSTS_CONFIG" 2>/dev/null || echo "0")
        if [ "$vhost_count" -gt 0 ]; then
            print_warning "$vhost_count .local virtual host(s) may still exist in Apache config"
            issues_found=$((issues_found + 1))
        fi
    fi
    
    # Check for remaining hosts entries
    if [ -f "$HOSTS_FILE" ]; then
        local hosts_count=$(grep -c "\.local$" "$HOSTS_FILE" 2>/dev/null || echo "0")
        if [ "$hosts_count" -gt 0 ]; then
            print_warning "$hosts_count .local domain(s) may still exist in hosts file"
            issues_found=$((issues_found + 1))
        fi
    fi
    
    if [ $issues_found -eq 0 ]; then
        print_status "Verification complete - no issues found"
    else
        print_warning "Verification found $issues_found potential issue(s) - manual cleanup may be needed"
    fi
}

# Function to show completion message
show_completion_message() {
    echo ""
    echo -e "${GREEN}${BOLD}🎉 Uninstallation Complete!${NC}"
    echo ""
    echo -e "${BLUE}Summary of actions taken:${NC}"
    echo "  ✅ Created backup in: $BACKUP_DIR"
    echo "  ✅ Removed MAMP Projects Manager files"
    echo "  ✅ Cleaned virtual hosts configuration"
    echo "  ✅ Cleaned hosts file entries"
    echo "  ✅ Restarted Apache server"
    echo "  ✅ Cleared DNS cache"
    echo ""
    echo -e "${YELLOW}${BOLD}Important Notes:${NC}"
    echo "  • Your original project files in external directories are preserved"
    echo "  • MAMP application itself is unchanged"
    echo "  • Backups are available on your Desktop if you need to restore anything"
    echo "  • You may need to restart your browser to clear any cached redirects"
    echo ""
    echo -e "${GREEN}If you want to reinstall MAMP Projects Manager later, you can use the install.sh script.${NC}"
    echo ""
}

# Main execution
main() {
    # Check if running as root (we'll need sudo for some operations)
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root. It will prompt for sudo when needed."
        exit 1
    fi
    
    # Check if MAMP is installed
    if [ ! -d "/Applications/MAMP" ]; then
        print_error "MAMP installation not found. Nothing to uninstall."
        exit 1
    fi
    
    # Confirm removal
    confirm_removal
    
    echo ""
    print_info "Starting uninstallation process..."
    echo ""
    
    # Create backup first
    create_backup
    
    # Try to remove projects via API first (cleaner)
    remove_projects_via_api
    
    # Clean configurations
    clean_vhosts_config
    clean_hosts_file
    
    # Remove manager files
    remove_manager_files
    
    # Restart services
    restart_apache
    clear_dns_cache
    
    # Verify everything was removed
    verify_removal
    
    # Show completion message
    show_completion_message
}

# Trap to handle interrupts
trap 'print_error "Uninstallation interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"
