#!/bin/bash

# MAMP Projects Manager - Installation Script
# Author: PhamDang
# Version: 2.0.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
MAMP_PATH="/Applications/MAMP"
PROJECTS_PATH="$MAMP_PATH/htdocs/projects"
VHOSTS_CONFIG="$MAMP_PATH/conf/apache/extra/httpd-vhosts.conf"
BACKUP_DIR="$HOME/.mamp-projects-manager-backup"

# Function to print colored output
print_status() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}🚀 MAMP Projects Manager${NC}"
    echo -e "${PURPLE}   Installation Script${NC}"
    echo -e "${PURPLE}================================${NC}"
    echo ""
}

# Function to check if MAMP is installed
check_mamp() {
    print_status "Checking MAMP installation..."
    
    if [ ! -d "$MAMP_PATH" ]; then
        print_error "MAMP not found at $MAMP_PATH"
        print_error "Please install MAMP first: https://www.mamp.info/"
        exit 1
    fi
    
    if [ ! -f "$MAMP_PATH/bin/apache2/bin/httpd" ]; then
        print_error "Apache not found in MAMP installation"
        exit 1
    fi
    
    print_success "MAMP installation found"
}

# Function to check if script is run from the correct directory
check_source_directory() {
    print_status "Checking source directory..."
    
    if [ ! -f "index.html" ] || [ ! -f "api.php" ]; then
        print_error "Please run this script from the MAMP Projects Manager directory"
        print_error "Expected files: index.html, api.php"
        exit 1
    fi
    
    print_success "Source files found"
}

# Function to backup existing installation
backup_existing() {
    if [ -d "$PROJECTS_PATH" ]; then
        print_status "Backing up existing installation..."
        
        # Create backup directory
        mkdir -p "$BACKUP_DIR"
        
        # Backup with timestamp
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        BACKUP_PATH="$BACKUP_DIR/projects_backup_$TIMESTAMP"
        
        cp -r "$PROJECTS_PATH" "$BACKUP_PATH"
        print_success "Backup created at: $BACKUP_PATH"
    fi
}

# Function to create projects directory
create_projects_directory() {
    print_status "Creating projects directory..."
    
    # Create the projects directory if it doesn't exist
    mkdir -p "$PROJECTS_PATH"
    
    # Set proper permissions
    chmod 755 "$PROJECTS_PATH"
    
    print_success "Projects directory created: $PROJECTS_PATH"
}

# Function to copy files
copy_files() {
    print_status "Installing MAMP Projects Manager files..."
    
    # Copy main files
    cp index.html "$PROJECTS_PATH/"
    cp api.php "$PROJECTS_PATH/"
    cp README.md "$PROJECTS_PATH/"
    
    # Copy browse-folders.php if it exists
    if [ -f "browse-folders.php" ]; then
        cp browse-folders.php "$PROJECTS_PATH/"
    fi
    
    # Copy additional files if they exist
    if [ -f "add-host.php" ]; then
        cp add-host.php "$PROJECTS_PATH/"
    fi
    
    # Copy v2.0 files
    if [ -f "test-port-compatibility.php" ]; then
        cp test-port-compatibility.php "$PROJECTS_PATH/"
        chmod 644 "$PROJECTS_PATH/test-port-compatibility.php"
    fi
    
    if [ -f "PORT_COMPATIBILITY.md" ]; then
        cp PORT_COMPATIBILITY.md "$PROJECTS_PATH/"
    fi
    
    if [ -f "CHANGELOG.md" ]; then
        cp CHANGELOG.md "$PROJECTS_PATH/"
    fi
    
    if [ -f "VERSION" ]; then
        cp VERSION "$PROJECTS_PATH/"
    fi
    
    # Set proper permissions
    chmod 644 "$PROJECTS_PATH"/*.html
    chmod 644 "$PROJECTS_PATH"/*.php
    chmod 644 "$PROJECTS_PATH"/*.md
    
    print_success "Files installed successfully"
}

# Function to setup virtual hosts configuration
setup_virtual_hosts() {
    print_status "Setting up virtual hosts configuration..."
    
    if [ ! -f "$VHOSTS_CONFIG" ]; then
        print_warning "Virtual hosts config file not found, creating..."
        
        cat > "$VHOSTS_CONFIG" << EOF
#
# Virtual Hosts
#
# Required modules: mod_log_config

# If you want to maintain multiple domains/hostnames on your
# machine you can setup VirtualHost containers for them. Most configurations
# use only name-based virtual hosts so the server doesn't need to worry about
# IP addresses. This is indicated by the asterisks in the directives below.
#
# Please see the documentation at 
# <URL:http://httpd.apache.org/docs/2.4/vhosts/>
# for further details before you try to setup virtual hosts.
#
# You may use the command line option '-S' to verify your virtual host
# configuration.

#
# Use name-based virtual hosting.
#
NameVirtualHost *:80

#
# VirtualHost example:
# Almost any Apache directive may go into a VirtualHost container.
# The first VirtualHost section is used for all requests that do not
# match a ServerName or ServerAlias in any <VirtualHost> block.
#
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot "/Applications/MAMP/htdocs"
</VirtualHost>

# Template for adding new projects
# Copy and modify this template for new projects
#
# <VirtualHost *:80>
#     ServerName your-project.local
#     ServerAlias www.your-project.local
#     DocumentRoot "/Applications/MAMP/htdocs/projects/your-project"
#     ErrorLog "/Applications/MAMP/logs/your-project_error.log"
#     CustomLog "/Applications/MAMP/logs/your-project_access.log" common
#     
#     <Directory "/Applications/MAMP/htdocs/projects/your-project">
#         AllowOverride All
#         Options All
#         Require all granted
#     </Directory>
# </VirtualHost>

EOF
        print_success "Virtual hosts configuration created"
    else
        print_success "Virtual hosts configuration already exists"
    fi
}

# Function to create browse-folders.php if it doesn't exist
create_browse_folders() {
    if [ ! -f "$PROJECTS_PATH/browse-folders.php" ]; then
        print_status "Creating folder browser endpoint..."
        
        cat > "$PROJECTS_PATH/browse-folders.php" << 'EOF'
<?php
/**
 * Folder Browser Endpoint for MAMP Projects Manager
 * Provides folder listing functionality for the project creation interface
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

function respond($success, $data = null, $error = null) {
    echo json_encode([
        'success' => $success,
        'data' => $data,
        'error' => $error
    ]);
    exit;
}

// Get the requested path
$path = $_GET['path'] ?? '/Users';

// Validate path
if (!$path || !is_dir($path)) {
    respond(false, null, 'Invalid path');
}

// Security: Only allow paths under /Users, /Applications, and /Volumes
$allowedPrefixes = ['/Users', '/Applications', '/Volumes'];
$isAllowed = false;
foreach ($allowedPrefixes as $prefix) {
    if (strpos($path, $prefix) === 0) {
        $isAllowed = true;
        break;
    }
}

if (!$isAllowed) {
    respond(false, null, 'Access denied to this path');
}

try {
    $folders = [];
    $items = scandir($path);
    
    foreach ($items as $item) {
        if ($item === '.' || $item === '..') continue;
        
        $fullPath = $path . '/' . $item;
        
        // Only include directories that are readable
        if (is_dir($fullPath) && is_readable($fullPath)) {
            // Skip hidden folders unless specifically allowed
            if (strpos($item, '.') === 0 && !in_array($item, ['.vscode', '.git'])) {
                continue;
            }
            
            $folders[] = $item;
        }
    }
    
    // Sort folders alphabetically
    sort($folders);
    
    respond(true, ['folders' => $folders]);
    
} catch (Exception $e) {
    respond(false, null, 'Error reading directory: ' . $e->getMessage());
}
EOF
        
        chmod 644 "$PROJECTS_PATH/browse-folders.php"
        print_success "Folder browser created"
    fi
}

# Function to create uninstall script
create_uninstall_script() {
    print_status "Creating uninstall script..."
    
    cat > "$PROJECTS_PATH/uninstall.sh" << 'EOF'
#!/bin/bash

# MAMP Projects Manager - Uninstall Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${YELLOW}[UNINSTALL]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${RED}🗑️  MAMP Projects Manager Uninstaller${NC}"
echo ""

# Confirmation
read -p "Are you sure you want to uninstall MAMP Projects Manager? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Remove projects (with confirmation)
if [ "$1" != "--keep-projects" ]; then
    echo ""
    read -p "Do you want to remove all project folders? This cannot be undone! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing project folders..."
        find /Applications/MAMP/htdocs/projects/ -maxdepth 1 -type d -not -name "projects" -exec rm -rf {} +
        print_success "Project folders removed"
    fi
fi

# Remove main files
print_status "Removing MAMP Projects Manager files..."
rm -f /Applications/MAMP/htdocs/projects/index.html
rm -f /Applications/MAMP/htdocs/projects/api.php
rm -f /Applications/MAMP/htdocs/projects/browse-folders.php
rm -f /Applications/MAMP/htdocs/projects/README.md
rm -f /Applications/MAMP/htdocs/projects/uninstall.sh

print_success "MAMP Projects Manager has been uninstalled"
print_status "Note: Virtual host configurations and hosts file entries remain unchanged"
print_status "You may need to clean these up manually if desired"

EOF
    
    chmod +x "$PROJECTS_PATH/uninstall.sh"
    print_success "Uninstall script created"
}

# Function to display final instructions
show_final_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Start MAMP application"
    echo "2. Open your browser and go to: ${BLUE}http://localhost/projects${NC}"
    echo "   (or http://localhost:8888/projects if using default ports)"
    echo "3. Start creating and managing your development projects!"
    echo ""
    echo -e "${CYAN}Features Available:${NC}"
    echo "• ✅ Web-based project creation"
    echo "• ✅ Automatic virtual host setup"
    echo "• ✅ Apache server management"
    echo "• ✅ Project location updates"
    echo "• ✅ Debug logging and troubleshooting"
    echo "• ✅ Batch project operations"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "• Uninstall: ${BLUE}cd $PROJECTS_PATH && ./uninstall.sh${NC}"
    echo "• Access projects: ${BLUE}http://localhost/projects${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tip:${NC} Bookmark the projects page for quick access!"
    echo ""
}

# Main installation flow
main() {
    print_header
    
    # Pre-installation checks
    check_mamp
    check_source_directory
    
    # Installation steps
    backup_existing
    create_projects_directory
    copy_files
    setup_virtual_hosts
    create_browse_folders
    create_uninstall_script
    
    # Final steps
    show_final_instructions
    
    print_success "MAMP Projects Manager installation completed successfully! 🚀"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
