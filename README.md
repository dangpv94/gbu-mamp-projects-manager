# 🚀 MAMP Projects Manager v3.0.0

**Công cụ quản lý dự án web toàn diện cho MAMP (Mac Apache MySQL PHP)** - Hệ thống quản lý virtual host thông minh với khả năng migration tự động, phát hiện cấu hình động, và giao diện web hiện đại.

## ✨ Tính năng đột phá trong v3.0.0

### 🎯 Cross-Machine Migration System
- **🔄 Intelligent Path Fixing**: Tự động phát hiện và sửa các đường dẫn DocumentRoot bị lỗi khi di chuyển giữa các máy
- **🎛️ 3 Migration Modes**: Interactive (tương tác), Auto-fix to Directory (tự động sửa theo thư mục), Auto-fix to MAMP (sửa về MAMP htdocs)
- **👤 Dynamic User Detection**: Tự động phát hiện user hiện tại và thư mục home trên bất kỳ máy Mac nào
- **💾 Smart Backup System**: Backup tự động các file cấu hình quan trọng trước khi thay đổi
- **📁 Placeholder Generation**: Tự động tạo thư mục và file HTML mẫu cho các project bị thiếu

### 🌟 Enhanced User Interface
- **📱 Responsive Design**: Giao diện web responsive hoạt động tốt trên mọi kích thước màn hình
- **⚡ Real-time Status**: Hiển thị trạng thái project và hệ thống thời gian thực
- **🎨 Modern UI Components**: Toast notifications, loading states, modal dialogs hiện đại
- **🔍 Smart Error Detection**: Tự động phát hiện lỗi kết nối và đưa ra hướng dẫn khắc phục
- **📋 Copy-to-Clipboard**: Sao chép commands và thông tin hữu ích chỉ với một click

### 🛠️ Advanced System Controls
- **🔄 Apache Server Management**: Restart Apache trực tiếp từ giao diện web
- **📂 Project Location Updates**: Thay đổi document root của project mà không cần tạo lại
- **🔧 Dynamic Port Detection**: Tự động phát hiện và hỗ trợ mọi cấu hình port Apache
- **🧪 Comprehensive Testing**: Hệ thống test tương thích port và connectivity tích hợp
- **📊 System Health Monitoring**: Theo dõi trạng thái Apache, hosts file, và virtual hosts

### 🎯 Tính năng chính

- **🔄 Tạo Project Một Click**: Tự động tạo virtual host, hosts file, và thư mục
- **🌐 Hỗ Trợ Đa Port**: Hoạt động với mọi cấu hình Apache port (80, 8888, 8080, custom)
- **📁 Quản Lý Thư Mục Thông Minh**: Copy từ project có sẵn hoặc tạo mới
- **🔗 Chế Độ Link**: Trỏ đến thư mục project có sẵn mà không copy
- **⚡ Tự Động Setup**: Tự động cấu hình hosts file và restart Apache
- **🎨 Giao Diện Hiện Đại**: Interface web responsive với status thời gian thực
- **🛠️ Điều Khiển Hệ Thống**: Restart Apache và quản lý vị trí project tích hợp
- **🔍 Phát Hiện Lỗi**: Tự động test kết nối và hỗ trợ khắc phục sự cố
- **📊 Tổng Quan Project**: Quản lý project dễ dàng với controls truy cập nhanh
- **🧪 Test Tương Thích**: Hệ thống test tương thích port tích hợp
- **🚀 Migration Tools**: Scripts migration mạnh mẽ cho việc di chuyển giữa các máy

## 🌐 Hỗ Trợ Port

| Cấu hình | Port | Định dạng URL | Trạng thái |
|----------|------|---------------|------------|
| HTTP Chuẩn | 80 | `http://project.local` | ✅ Hỗ trợ đầy đủ |
| MAMP Mặc định | 8888 | `http://project.local:8888` | ✅ Hỗ trợ đầy đủ |
| Port Thay thế | 8080 | `http://project.local:8080` | ✅ Hỗ trợ đầy đủ |
| Port Tùy chỉnh | Bất kỳ | `http://project.local:PORT` | ✅ Hỗ trợ đầy đủ |

## 🚀 Hướng Dẫn Bắt Đầu

### 1. Installation

#### Option A: Automatic Installation (Recommended)
```bash
# Download and extract to Desktop
cd ~/Desktop
git clone https://github.com/dangpv94/gbu-mamp-projects-manager.git
cd gbu-mamp-projects-manager

# Run one-click installer
chmod +x INSTALL_NOW.sh
./INSTALL_NOW.sh
```

#### Option A2: Download ZIP (Alternative)
```bash
# Download and extract to Desktop
cd ~/Desktop
curl -L -o mamp-projects-manager.zip https://github.com/dangpv94/gbu-mamp-projects-manager/archive/main.zip
unzip mamp-projects-manager.zip

# Run installer
cd gbu-mamp-projects-manager-main
chmod +x INSTALL_NOW.sh
./INSTALL_NOW.sh
```

#### Option B: Manual Installation
```bash
# Clone or extract to MAMP projects directory
cp -R mamp-projects-manager/* /Applications/MAMP/htdocs/projects/

# Set permissions
chmod 755 /Applications/MAMP/htdocs/projects/*.php
chmod 755 /Applications/MAMP/htdocs/projects/*.sh
```

### 2. Access the Interface

The system automatically detects your MAMP Apache port. Access via:

- **Port 80**: [http://localhost/projects/](http://localhost/projects/)
- **Port 8888**: [http://localhost:8888/projects/](http://localhost:8888/projects/) 
- **Port 8080**: [http://localhost:8080/projects/](http://localhost:8080/projects/)
- **Custom Port**: `http://localhost:YOUR_PORT/projects/`

### 3. Create Your First Project

1. Click "**Add New Virtual Host**" 
2. Enter project name (e.g., "My Website")
3. Enter domain (e.g., "mywebsite.local")
4. Choose source folder or create new
5. Click "**Create Project**"

The system will automatically:
- ✅ Detect your Apache port configuration
- ✅ Create virtual host with correct port
- ✅ Add hosts file entry
- ✅ Create or copy project files
- ✅ Restart Apache server
- ✅ Verify everything works

## 🛠️ Advanced Features

### System Controls
- **🔄 Restart Apache**: One-click Apache server restart
- **📂 Update Project Location**: Change project document root paths
- **🔧 MAMP Configuration**: View current Apache and MySQL port settings
- **🧪 Compatibility Test**: Run comprehensive port compatibility tests

### Project Management
- **📋 Project List**: View all configured virtual hosts with status
- **🔗 Quick Access**: Direct links to projects with correct port
- **❌ Remove Projects**: Clean removal of virtual hosts and configurations
- **📊 Error Detection**: Automatic connectivity testing and troubleshooting

### Development Modes
- **Copy Mode**: Create new project by copying existing folder
- **Link Mode**: Point virtual host to existing project location
- **New Mode**: Create empty project with basic template

## 📋 Compatibility Testing

### Automatic Test
Run the built-in compatibility test:
```bash
# Navigate to projects directory
cd /Applications/MAMP/htdocs/projects

# Run compatibility test
/Applications/MAMP/bin/php/php8.2.20/bin/php test-port-compatibility.php
```

### Expected Output
```
🔍 MAMP Projects Manager - Port Compatibility Test
=================================================

1. Testing Apache Configuration Detection...
   Detected Apache Port: 8888
   📊 Custom port (8888) - Dynamic port support enabled

2. Testing MAMP Configuration Info...
   Apache Port: 8888
   MySQL Port: 8889
   Is Standard: No
   Web URL Base: http://localhost:8888

🎉 MAMP Projects Manager is compatible with your configuration!
```

## 🔧 Configuration

### Supported MAMP Configurations

#### Standard Configuration (Port 80)
```apache
# /Applications/MAMP/conf/apache/httpd.conf
Listen 0.0.0.0:80
ServerName localhost:80
```
- **URLs**: `http://project.local`
- **Virtual Hosts**: `<VirtualHost *:80>`

#### MAMP Default (Port 8888)
```apache
# /Applications/MAMP/conf/apache/httpd.conf  
Listen 0.0.0.0:8888
ServerName localhost:8888
```
- **URLs**: `http://project.local:8888`
- **Virtual Hosts**: `<VirtualHost *:8888>`

#### Custom Port Configuration
```apache
# /Applications/MAMP/conf/apache/httpd.conf
Listen 0.0.0.0:3000
ServerName localhost:3000
```
- **URLs**: `http://project.local:3000`
- **Virtual Hosts**: `<VirtualHost *:3000>`

### Directory Structure
```
/Applications/MAMP/htdocs/projects/
├── index.html                     # Main interface
├── api.php                        # Backend API with port detection
├── browse-folders.php             # Folder browser
├── add-host.php                   # CLI helper script  
├── test-port-compatibility.php    # Compatibility testing
├── install.sh                     # Installation script
├── README.md                      # This documentation
├── PORT_COMPATIBILITY.md          # Detailed port guide
├── CHANGELOG.md                   # Version history
└── VERSION                        # Version information
```

## 🎯 API Reference

### Configuration Endpoint
```javascript
// Get MAMP configuration
fetch('api.php?action=mamp_config')
  .then(response => response.json())
  .then(data => {
    console.log('Apache Port:', data.data.apache_port);
    console.log('Web URL:', data.data.web_url);
  });
```

### Project Management
```javascript
// Create new project
fetch('api.php', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    action: 'create_project',
    projectName: 'My Website',
    domain: 'mywebsite.local',
    sourcePath: '/Users/me/project',
    locationType: 'copy'
  })
});

// Get all projects
fetch('api.php?action=projects')
  .then(response => response.json())
  .then(data => console.log(data.data));
```

### System Controls
```javascript
// Restart Apache
fetch('api.php', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ action: 'restart_apache' })
});
```

## 🛠️ Troubleshooting & Auto-Fix Suite

### 🚀 Quick Fix Tool (`quick-fix.sh`)
**30-second solution for common issues**

When projects aren't working, run the quick fix first:
```bash
cd /Applications/MAMP/htdocs/projects/
./quick-fix.sh
```

**Automatically fixes:**
- ✅ Missing domains in hosts file
- ✅ Missing project directories (creates beautiful placeholders)
- ✅ DNS cache issues
- ✅ Tests HTTP connectivity for all projects
- ✅ Smart port detection (handles IP:PORT formats)

### 🔥 Apache Startup Failure Diagnostics
**Comprehensive solution for "Apache couldn't be started" errors**

If MAMP shows "Apache couldn't be started":
```bash
cd /Applications/MAMP/htdocs/projects/
./troubleshoot-mamp.sh
# Choose option 2: Diagnose Apache Startup Fail
```

**Automatically detects and fixes:**
- 🔍 **Port conflicts** (Skype, AirPlay, other apps using same port)
- 📝 **Apache syntax errors** (shows exact file and line with error)
- 🔐 **Log file permission issues**
- 📁 **Missing log directories**
- 🔄 **Interactive process termination** for conflicting applications

### 🔧 Super Auto-Fix (`troubleshoot-mamp.sh`)
**Comprehensive diagnosis and auto-fix with safety checks**

```bash
cd /Applications/MAMP/htdocs/projects/
./troubleshoot-mamp.sh
# Choose option 3: Auto-Fix Common Issues
```

**Advanced features:**
- ✅ **Pre-validation**: Apache syntax check before making changes
- ✅ **Port conflict resolution**: Interactive process termination
- ✅ **Log file fixes**: Automatic permission and directory creation
- ✅ **Virtual host port matching**: Fixes port mismatches
- ✅ **Hosts file management**: Adds missing entries
- ✅ **Directory creation**: Creates missing project folders
- ✅ **DNS cache flushing**: Clears system DNS cache
- ✅ **Apache restart**: Safe restart with verification
- ✅ **Automatic backup**: Backs up configs before changes

### 📊 Full System Diagnosis
**Complete health check for MAMP configuration**

```bash
./troubleshoot-mamp.sh
# Choose option 1: Run Full Diagnosis
```

**Comprehensive analysis:**
- 🔍 MAMP status and port detection
- 📋 Virtual host configuration analysis
- 🌐 Hosts file validation
- 🔗 HTTP connectivity testing
- 💡 Detailed recommendations and manual fix commands

### 🧪 Demo & Testing (`demo-issues.sh`)
**Create test scenarios for troubleshooting validation**

```bash
./demo-issues.sh
# Creates realistic MAMP problems to test fix tools
```

**Test scenarios:**
- Missing hosts file entries
- Wrong DocumentRoot paths
- Port mismatches (80 vs 8888)
- Empty project directories
- Safe backup/restore for testing

### 🎯 Common Issue Solutions

#### "This site can't be reached"
```bash
# Quick solution
./quick-fix.sh

# Manual fix
sudo nano /etc/hosts
# Add: 127.0.0.1    your-domain.local
sudo dscacheutil -flushcache
```

#### "Apache couldn't be started"
```bash
# Comprehensive diagnosis
./troubleshoot-mamp.sh
# Option 2: Diagnose Apache Startup Fail

# Or run auto-fix
# Option 3: Auto-Fix Common Issues
```

#### Projects showing MAMP default page
```bash
# Full auto-fix
./troubleshoot-mamp.sh
# Option 3: Auto-Fix Common Issues

# This fixes DocumentRoot issues automatically
```

#### Port detection problems
```bash
# The new scripts handle these automatically:
# - Listen 0.0.0.0:8888 format
# - ServerName localhost:8888 format
# - Mixed configurations
```

### 🛡️ Safety Features
**All troubleshooting tools include:**
- ✅ **Automatic backups** before any configuration changes
- ✅ **Syntax validation** before applying Apache config changes
- ✅ **Interactive confirmations** for potentially destructive actions
- ✅ **Detailed logging** of all changes made
- ✅ **Rollback capabilities** for emergency recovery
- ✅ **Non-destructive operations** that preserve existing projects

### 📋 Manual Troubleshooting Commands
For advanced users who prefer manual diagnosis:

```bash
# Check MAMP process
pgrep -f "Applications/MAMP/Library/bin/httpd"

# Check Apache port
grep "^Listen\|^ServerName" /Applications/MAMP/conf/apache/httpd.conf

# Test Apache configuration
sudo /Applications/MAMP/bin/apachectl -t

# View virtual hosts
sudo /Applications/MAMP/bin/apachectl -S

# Check port conflicts
lsof -i :8888

# View error logs
tail -f /Applications/MAMP/logs/apache_error.log

# Test domain resolution
nslookup your-domain.local

# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

## 📦 Migration & Updates

### 🚀 Cross-Machine Migration (v3.0.0 Feature)

#### Automatic Migration with Path Fixing
```bash
# After copying package to new machine, run path fixer
cd /Applications/MAMP/htdocs/projects/
chmod +x fix-project-paths.sh
./fix-project-paths.sh
```

#### Migration Options:

**1. Interactive Mode** (Recommended)
- Manually select correct path for each broken project
- Full control over project location decisions
- Safe and precise migration

**2. Auto-fix to Directory**
- Automatically fixes all projects to a chosen directory (e.g., ~/Works)
- Creates missing project folders with placeholder files
- Fastest migration for organized projects

**3. Auto-fix to MAMP**
- Moves all projects to MAMP htdocs directory
- Ensures all projects work immediately
- Best for centralized project management

### Moving Between Machines (Step-by-Step)

1. **📋 Export from Source Machine**:
   ```bash
   # Create complete backup
   cd /Applications/MAMP/htdocs
   tar -czf ~/Desktop/mamp-projects-export.tar.gz projects/
   ```

2. **📦 Import to Target Machine**:
   ```bash
   # Install on new machine
   cd ~/Desktop
   git clone https://github.com/dangpv94/gbu-mamp-projects-manager.git
   cd gbu-mamp-projects-manager
   ./INSTALL_NOW.sh
   
   # Import old projects (if you have backup)
   tar -xzf ~/Desktop/mamp-projects-export.tar.gz -C /Applications/MAMP/htdocs/
   ```

3. **🔧 Fix Paths Automatically**:
   ```bash
   # Run migration tool
   cd /Applications/MAMP/htdocs/projects/
   ./fix-project-paths.sh
   ```

4. **✅ Verification**:
   - Access web interface at detected port
   - Check all projects load correctly
   - Run compatibility test if needed

### Upgrading from Previous Versions

#### From v2.x to v3.0.0
1. **Backup existing configuration**
2. **Install v3.0.0** using installation guide
3. **Existing projects continue to work** with enhanced features
4. **New migration tools available** for cross-machine moves

#### From v1.x to v3.0.0
1. **Complete migration recommended** due to architecture changes
2. **Backup all project files and configurations**
3. **Fresh install v3.0.0** for best compatibility
4. **Recreate projects** using the modern interface

### MAMP Configuration Changes

#### Changing MAMP Ports
1. **Update MAMP**: Change ports in MAMP preferences
2. **Restart Apache**: Restart MAMP Apache service  
3. **Auto-detection**: v3.0.0 automatically detects new port
4. **Existing projects**: Continue working with updated port detection
5. **No manual changes needed**: System adapts automatically

#### Port Migration
```bash
# If projects aren't working after port change
cd /Applications/MAMP/htdocs/projects/
/Applications/MAMP/bin/php/php8.2.20/bin/php test-port-compatibility.php

# Restart Apache if needed
# Use web interface "Restart Apache" button
```

## 🗑️ Uninstallation

### Complete Removal

To completely remove MAMP Projects Manager and all associated configurations:

#### Option A: Automated Uninstall (Recommended)
```bash
# Navigate to projects directory
cd /Applications/MAMP/htdocs/projects/

# Run uninstall script
chmod +x uninstall.sh
./uninstall.sh
```

#### Option B: Manual Removal
```bash
# 1. Remove all virtual hosts and projects via interface
# Go to http://localhost:YOUR_PORT/projects/
# Use "Remove All Projects" in Danger Zone

# 2. Remove MAMP Projects Manager files
sudo rm -rf /Applications/MAMP/htdocs/projects/

# 3. Clean up virtual hosts configuration
sudo cp /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf.backup
sudo sed -i '' '/# MAMP Projects Manager/,/# End MAMP Projects Manager/d' /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf

# 4. Remove hosts entries
sudo cp /etc/hosts /etc/hosts.backup
sudo sed -i '' '/# Added by MAMP Projects Manager/d' /etc/hosts
sudo sed -i '' '/\.local$/d' /etc/hosts

# 5. Restart Apache
/Applications/MAMP/bin/apache2/bin/apachectl restart

# 6. Clear DNS cache
sudo dscacheutil -flushcache
```

### Selective Removal

#### Remove Only Projects (Keep Manager)
```bash
# Use the web interface
# Go to "Danger Zone" → "Remove All Projects"
# This will clean up all virtual hosts and hosts entries
```

#### Remove Specific Project
```bash
# Use the web interface
# Click "Remove" button next to specific project
# Or use command line:
cd /Applications/MAMP/htdocs/projects/
./setup-project.sh remove PROJECT_DOMAIN.local
```

### Post-Uninstall Verification

```bash
# Check virtual hosts are removed
/Applications/MAMP/Library/bin/httpd -S | grep -i "projects\|local"

# Check hosts file is clean
grep ".local" /etc/hosts

# Verify Apache starts without errors
/Applications/MAMP/Library/bin/httpd -t
```

### Backup Before Uninstall

**Important**: Always backup your project files before uninstalling:

```bash
# Backup all projects
cp -R /Applications/MAMP/htdocs/projects/ ~/Desktop/mamp-projects-backup/

# Backup MAMP configuration
cp /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf ~/Desktop/httpd-vhosts-backup.conf
cp /etc/hosts ~/Desktop/hosts-backup
```

### What Gets Removed

✅ **Files Removed**:
- `/Applications/MAMP/htdocs/projects/` (entire directory)
- Project folders within MAMP htdocs (if created by manager)

✅ **Configuration Cleaned**:
- Virtual host entries from `httpd-vhosts.conf`
- Domain entries from `/etc/hosts`
- Project-specific Apache configurations

✅ **Services Reset**:
- Apache server restarted with clean configuration
- DNS cache cleared

❌ **NOT Removed** (Preserved):
- Original project files in external directories (if using link mode)
- MAMP application itself
- Other MAMP configurations
- Backups created during installation

## 📊 Performance & Security

### Performance
- **Port detection**: < 1ms overhead per request
- **Configuration caching**: MAMP config cached in PHP session
- **Minimal I/O**: Only reads config files when necessary
- **Efficient parsing**: Optimized regex patterns for config analysis

### Security
- **Input validation**: All user inputs sanitized and validated
- **File permissions**: Proper Unix permissions on all files
- **Safe paths**: Prevents directory traversal attacks
- **Controlled access**: Only modifies intended configuration files

## 🆘 Support & Documentation

### Getting Help
1. **Run diagnostics**: Use `test-port-compatibility.php` for detailed system analysis
2. **Check documentation**: Review `PORT_COMPATIBILITY.md` for advanced scenarios
3. **Review logs**: Check MAMP error logs for specific error messages
4. **Community support**: Submit issues with diagnostic output

### Required Information for Support
- MAMP version and configuration
- macOS version  
- Output from `test-port-compatibility.php`
- Apache error logs (if applicable)
- Specific error messages or behaviors

## 📚 Additional Resources

- [Port Compatibility Guide](PORT_COMPATIBILITY.md) - Detailed port configuration documentation
- [CHANGELOG](CHANGELOG.md) - Version history and update notes
- [Apache Virtual Host Docs](https://httpd.apache.org/docs/2.4/vhosts/) - Official Apache documentation
- [MAMP Documentation](https://www.mamp.info/en/documentation/) - Official MAMP guides

## ⭐ Features Comparison

| Feature | v1.x | v2.0 | v3.0.0 |
|---------|------|------|--------|
| Port Support | Fixed port 80 only | Any port (dynamic detection) | Universal dynamic port detection |
| Configuration | Manual setup required | Zero configuration | Zero config + auto path fixing |
| Compatibility | MAMP with port 80 only | All MAMP configurations | All MAMP + cross-machine |
| Migration | Manual reconfiguration | Basic auto-migration | Advanced migration with 3 modes |
| Testing | Manual verification | Built-in compatibility tests | Comprehensive testing + debugging |
| Error Detection | Basic | Advanced with auto-troubleshooting | Smart detection with auto-fix |
| Project Management | Basic CRUD | Advanced with system controls | Full system + Apache management |
| User Interface | None | Basic web interface | Modern responsive UI |
| Path Management | Fixed paths | Static paths | Dynamic user-aware paths |
| Backup System | Manual | None | Automatic smart backups |

---

## 🎉 Version 3.0.0 Revolutionary Features

### 🚀 **Cross-Machine Intelligence**
- **🔄 Smart Migration**: Automatic path detection and fixing when moving between Macs
- **👤 User-Aware**: Dynamically detects current user and adapts all paths accordingly
- **🎛️ Multiple Fix Modes**: Interactive, directory-based, or MAMP-based migration options
- **💾 Safe Operations**: Automatic backups before any system changes

### 🌟 **Advanced User Experience** 
- **📱 Modern Interface**: Fully responsive web UI with real-time status updates
- **⚡ Instant Feedback**: Toast notifications, loading states, and progress indicators
- **🔍 Smart Diagnostics**: Automatic error detection with copy-to-clipboard fix commands
- **🎨 Professional Design**: Clean, intuitive interface following modern UI principles

### 🛠️ **Enterprise-Grade Management**
- **🔄 Apache Control**: Direct server restart from web interface
- **📂 Location Management**: Update project paths without recreating virtual hosts
- **🧪 Health Monitoring**: Comprehensive system health checks and compatibility testing
- **📊 Real-time Status**: Live monitoring of Apache, hosts file, and project connectivity

### 🔧 **Developer-Friendly Tools**
- **📋 One-Click Operations**: Copy commands, open files, and quick actions
- **🚨 Proactive Alerts**: Early detection of configuration issues
- **🔗 Smart Linking**: Automatic detection and creation of missing components
- **📈 Performance Optimized**: Minimal overhead with intelligent caching

**Ready to experience the future of MAMP development? Upgrade to v3.0.0 today!** 🎯

---

## 📦 Quick Installation

```bash
# One-click installer
cd ~/Desktop
git clone https://github.com/dangpv94/gbu-mamp-projects-manager.git
cd gbu-mamp-projects-manager
chmod +x INSTALL_NOW.sh
./INSTALL_NOW.sh
```

---

*MAMP Projects Manager v3.0.0 - The ultimate MAMP development companion with cross-machine intelligence.*
