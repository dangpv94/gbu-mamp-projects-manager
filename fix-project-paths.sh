#!/bin/bash

# Fix Project Paths - Migration Script
# This script fixes DocumentRoot paths when moving MAMP Manager to a new machine

set -e

echo "🔧 MAMP Project Paths Migration Tool"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
VHOSTS_FILE="/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf"
BACKUP_DIR="/Applications/MAMP/htdocs/projects/backups"
CURRENT_USER=$(whoami)
CURRENT_HOME="$HOME"  # Use $HOME environment variable instead of hardcoded path

# Detect hosts file location (different on some systems)
detect_hosts_file() {
    local hosts_locations=(
        "/etc/hosts"           # Standard macOS/Linux location
        "/private/etc/hosts"   # Alternative macOS location
        "/System/etc/hosts"    # Some macOS configurations
    )
    
    for hosts_file in "${hosts_locations[@]}"; do
        if [ -f "$hosts_file" ]; then
            echo "$hosts_file"
            return 0
        fi
    done
    
    # Default fallback
    echo "/etc/hosts"
}

HOSTS_FILE=$(detect_hosts_file)

# Check if vhosts file exists
if [ ! -f "$VHOSTS_FILE" ]; then
    print_error "Virtual hosts file not found: $VHOSTS_FILE"
    print_info "Please ensure MAMP is properly installed."
    exit 1
fi

print_info "Analyzing current virtual host configuration..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup
BACKUP_FILE="$BACKUP_DIR/vhosts_backup_before_migration_$(date +%Y%m%d_%H%M%S)"
cp "$VHOSTS_FILE" "$BACKUP_FILE"
print_status "Configuration backed up to: $BACKUP_FILE"

# Analyze current configuration
echo ""
print_info "Current virtual host projects found:"

# Extract project information
PROJECTS_FOUND=0
while IFS= read -r line; do
    if [[ $line =~ ^#\ Virtual\ Host\ for\ (.+)$ ]]; then
        PROJECT_NAME="${BASH_REMATCH[1]}"
        echo "  📁 Project: $PROJECT_NAME"
        PROJECTS_FOUND=$((PROJECTS_FOUND + 1))
    elif [[ $line =~ ^[[:space:]]*DocumentRoot[[:space:]]+\"([^\"]+)\"$ ]]; then
        DOC_ROOT="${BASH_REMATCH[1]}"
        echo "     Path: $DOC_ROOT"
        
        # Check if path exists
        if [ -d "$DOC_ROOT" ]; then
            echo -e "     Status: ${GREEN}✅ Exists${NC}"
        else
            echo -e "     Status: ${RED}❌ Missing${NC}"
        fi
        echo ""
    fi
done < "$VHOSTS_FILE"

if [ $PROJECTS_FOUND -eq 0 ]; then
    print_warning "No projects found in virtual host configuration."
    print_info "This script is only needed if you have existing projects with broken paths."
    exit 0
fi

echo ""
print_info "Migration options:"
echo ""
echo "1. 🔍 Interactive Path Fixing - Review and fix each missing path individually"
echo "2. 🏠 Auto-fix to Custom Directory - Automatically redirect missing paths to a directory you choose"
echo "3. 📂 Auto-fix to MAMP Projects - Move all projects to /Applications/MAMP/htdocs/projects/"
echo "4. 🚫 Cancel - Exit without making changes"
echo ""

read -p "Choose an option (1-4): " choice

case $choice in
    1)
        print_info "Starting interactive path fixing..."
        fix_paths_interactive
        ;;
    2)
        print_info "Auto-fixing paths to custom directory..."
        fix_paths_to_custom_directory
        ;;
    3)
        print_info "Auto-fixing paths to MAMP projects directory..."
        fix_paths_to_mamp_projects
        ;;
    4)
        print_info "Migration cancelled."
        exit 0
        ;;
    *)
        print_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Function for interactive fixing
fix_paths_interactive() {
    local temp_file=$(mktemp)
    local changes_made=false
    
    print_info "Reviewing each project path..."
    echo ""
    
    # Process the file line by line
    while IFS= read -r line; do
        if [[ $line =~ ^#\ Virtual\ Host\ for\ (.+)$ ]]; then
            current_project="${BASH_REMATCH[1]}"
            echo "$line" >> "$temp_file"
        elif [[ $line =~ ^([[:space:]]*DocumentRoot[[:space:]]+\")([^\"]+)(\".*)$ ]]; then
            prefix="${BASH_REMATCH[1]}"
            old_path="${BASH_REMATCH[2]}"
            suffix="${BASH_REMATCH[3]}"
            
            if [ ! -d "$old_path" ]; then
                print_warning "Missing path for project '$current_project':"
                echo "  Old path: $old_path"
                echo ""
                echo "  Suggested fixes:"
                echo "  1. Skip (keep current path)"
                echo "  2. $CURRENT_HOME/Works/${current_project}"
                echo "  3. /Applications/MAMP/htdocs/projects/${current_project}"
                echo "  4. Enter custom path"
                echo ""
                
                read -p "Choose option (1-4): " fix_choice
                
                case $fix_choice in
                    1)
                        echo "$line" >> "$temp_file"
                        ;;
                    2)
                        new_path="$CURRENT_HOME/Works/${current_project}"
                        echo "${prefix}${new_path}${suffix}" >> "$temp_file"
                        changes_made=true
                        print_status "Updated to: $new_path"
                        ;;
                    3)
                        new_path="/Applications/MAMP/htdocs/projects/${current_project}"
                        echo "${prefix}${new_path}${suffix}" >> "$temp_file"
                        changes_made=true
                        print_status "Updated to: $new_path"
                        ;;
                    4)
                        read -p "Enter new path: " custom_path
                        if [ -d "$custom_path" ]; then
                            echo "${prefix}${custom_path}${suffix}" >> "$temp_file"
                            changes_made=true
                            print_status "Updated to: $custom_path"
                        else
                            print_warning "Path doesn't exist. Keeping original."
                            echo "$line" >> "$temp_file"
                        fi
                        ;;
                    *)
                        print_warning "Invalid choice. Keeping original path."
                        echo "$line" >> "$temp_file"
                        ;;
                esac
                echo ""
            else
                echo "$line" >> "$temp_file"
            fi
        elif [[ $line =~ ^([[:space:]]*\<Directory[[:space:]]+\")([^\"]+)(\".*)$ ]]; then
            # Also update Directory paths
            prefix="${BASH_REMATCH[1]}"
            old_dir_path="${BASH_REMATCH[2]}"
            suffix="${BASH_REMATCH[3]}"
            
            # Check if this directory path was updated in DocumentRoot
            if [ ! -d "$old_dir_path" ] && [ "$changes_made" = true ]; then
                # Find the corresponding new path from DocumentRoot
                # This is a simplified approach - in real implementation you'd track the changes
                if [[ "$old_dir_path" == *"/Users/"* ]]; then
                    # Try to match with current user's home
                    new_dir_path=$(echo "$old_dir_path" | sed "s|/Users/[^/]*|$CURRENT_HOME|")
                    if [ -d "$new_dir_path" ]; then
                        echo "${prefix}${new_dir_path}${suffix}" >> "$temp_file"
                    else
                        echo "$line" >> "$temp_file"
                    fi
                else
                    echo "$line" >> "$temp_file"
                fi
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$VHOSTS_FILE"
    
    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$VHOSTS_FILE"
        print_status "Virtual host configuration updated successfully!"
        print_info "Please restart MAMP to apply changes."
    else
        rm "$temp_file"
        print_info "No changes were made."
    fi
}

# Function to auto-fix to custom directory
fix_paths_to_custom_directory() {
    local temp_file=$(mktemp)
    local changes_made=false
    local base_directory
    
    echo ""
    print_info "Choose the base directory for your projects:"
    echo ""
    echo "Common options:"
    echo "1. $CURRENT_HOME/Works - Your Works directory"
    echo "2. $CURRENT_HOME/Documents - Your Documents folder"
    echo "3. $CURRENT_HOME/Desktop - Your Desktop"
    echo "4. $CURRENT_HOME/Developer - Developer folder (if exists)"
    echo "5. Custom path - Enter your own path"
    echo ""
    
    read -p "Choose an option (1-5): " dir_choice
    
    case $dir_choice in
        1)
            base_directory="$CURRENT_HOME/Works"
            ;;
        2)
            base_directory="$CURRENT_HOME/Documents"
            ;;
        3)
            base_directory="$CURRENT_HOME/Desktop"
            ;;
        4)
            base_directory="$CURRENT_HOME/Developer"
            ;;
        5)
            echo ""
            print_info "Enter the full path to your projects directory:"
            print_info "(Projects will be created as subdirectories here)"
            read -p "Base directory: " custom_base_directory
            
            # Expand tilde if present
            if [[ "$custom_base_directory" =~ ^~/ ]]; then
                custom_base_directory="$HOME/${custom_base_directory:2}"
            fi
            
            # Validate the directory
            if [ ! -d "$custom_base_directory" ]; then
                print_warning "Directory doesn't exist: $custom_base_directory"
                read -p "Do you want to create it? (y/N): " create_dir
                if [[ $create_dir =~ ^[Yy]$ ]]; then
                    mkdir -p "$custom_base_directory"
                    print_status "Created directory: $custom_base_directory"
                else
                    print_error "Directory doesn't exist. Cannot proceed."
                    return 1
                fi
            fi
            
            base_directory="$custom_base_directory"
            ;;
        *)
            print_error "Invalid choice. Using default: $CURRENT_HOME/Works"
            base_directory="$CURRENT_HOME/Works"
            ;;
    esac
    
    print_info "Redirecting missing paths to $base_directory/..."
    
    # Create base directory if it doesn't exist
    if [ ! -d "$base_directory" ]; then
        mkdir -p "$base_directory"
        print_status "Created base directory: $base_directory"
    fi
    
    while IFS= read -r line; do
        if [[ $line =~ ^([[:space:]]*DocumentRoot[[:space:]]+\")([^\"]+)(\".*)$ ]]; then
            prefix="${BASH_REMATCH[1]}"
            old_path="${BASH_REMATCH[2]}"
            suffix="${BASH_REMATCH[3]}"
            
            if [ ! -d "$old_path" ] && [[ "$old_path" == *"/Users/"* ]]; then
                # Extract project name from path
                project_name=$(basename "$old_path")
                new_path="$base_directory/$project_name"
                echo "${prefix}${new_path}${suffix}" >> "$temp_file"
                changes_made=true
                print_status "Updated: $old_path → $new_path"
                
                # Create project directory if it doesn't exist
                if [ ! -d "$new_path" ]; then
                    mkdir -p "$new_path"
                    echo "<h1>Project: $project_name</h1><p>Please copy your project files here.</p>" > "$new_path/index.html"
                    print_info "Created placeholder directory: $new_path"
                fi
            else
                echo "$line" >> "$temp_file"
            fi
        elif [[ $line =~ ^([[:space:]]*\<Directory[[:space:]]+\")([^\"]+)(\".*)$ ]]; then
            prefix="${BASH_REMATCH[1]}"
            old_dir_path="${BASH_REMATCH[2]}"
            suffix="${BASH_REMATCH[3]}"
            
            if [ ! -d "$old_dir_path" ] && [[ "$old_dir_path" == *"/Users/"* ]]; then
                project_name=$(basename "$old_dir_path")
                new_dir_path="$base_directory/$project_name"
                echo "${prefix}${new_dir_path}${suffix}" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$VHOSTS_FILE"
    
    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$VHOSTS_FILE"
        print_status "All missing paths redirected to $base_directory/"
        print_warning "Make sure to copy your actual project files to the new directories!"
        print_info "Detected hosts file location: $HOSTS_FILE"
        print_info "Please restart MAMP to apply changes."
    else
        rm "$temp_file"
        print_info "No missing paths found to fix."
    fi
}

# Function to auto-fix to MAMP projects
fix_paths_to_mamp_projects() {
    local temp_file=$(mktemp)
    local changes_made=false
    local projects_dir="/Applications/MAMP/htdocs/projects"
    
    print_info "Moving projects to $projects_dir..."
    
    # Create projects directory if it doesn't exist
    mkdir -p "$projects_dir"
    
    while IFS= read -r line; do
        if [[ $line =~ ^([[:space:]]*DocumentRoot[[:space:]]+\")([^\"]+)(\".*)$ ]]; then
            prefix="${BASH_REMATCH[1]}"
            old_path="${BASH_REMATCH[2]}"
            suffix="${BASH_REMATCH[3]}"
            
            if [ ! -d "$old_path" ] && [[ "$old_path" != "$projects_dir"* ]]; then
                # Extract project name from path
                project_name=$(basename "$old_path")
                new_path="$projects_dir/$project_name"
                echo "${prefix}${new_path}${suffix}" >> "$temp_file"
                changes_made=true
                print_status "Updated: $old_path → $new_path"
                
                # Create placeholder directory
                if [ ! -d "$new_path" ]; then
                    mkdir -p "$new_path"
                    echo "<h1>Project: $project_name</h1><p>Please copy your project files here.</p>" > "$new_path/index.html"
                    print_info "Created placeholder directory: $new_path"
                fi
            else
                echo "$line" >> "$temp_file"
            fi
        elif [[ $line =~ ^([[:space:]]*\<Directory[[:space:]]+\")([^\"]+)(\".*)$ ]]; then
            prefix="${BASH_REMATCH[1]}"
            old_dir_path="${BASH_REMATCH[2]}"
            suffix="${BASH_REMATCH[3]}"
            
            if [ ! -d "$old_dir_path" ] && [[ "$old_dir_path" != "$projects_dir"* ]]; then
                project_name=$(basename "$old_dir_path")
                new_dir_path="$projects_dir/$project_name"
                echo "${prefix}${new_dir_path}${suffix}" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$VHOSTS_FILE"
    
    if [ "$changes_made" = true ]; then
        mv "$temp_file" "$VHOSTS_FILE"
        print_status "All projects redirected to MAMP projects directory!"
        print_warning "Copy your actual project files to the appropriate directories in $projects_dir"
        print_info "Please restart MAMP to apply changes."
    else
        rm "$temp_file"
        print_info "No paths needed to be updated."
    fi
}

echo ""
print_status "Migration completed!"
echo ""
print_info "Next steps:"
echo "1. Restart MAMP to apply configuration changes"
echo "2. Verify your projects are accessible at their domains" 
echo "3. Copy any missing project files to their new locations"
echo ""
print_info "Backup location: $BACKUP_FILE"
