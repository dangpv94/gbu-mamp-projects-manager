# 🚀 MAMP Projects Manager v3.0.0

**Công cụ quản lý dự án web toàn diện cho MAMP (Mac Apache MySQL PHP)** - Tự động phát hiện cấu hình và tạo virtual host một cách thông minh, hỗ trợ migration giữa các máy khác nhau.

## ✨ Tính năng mới trong v3.0.0

### 🔄 Smart Migration System
- **Auto Path Detection**: Tự động phát hiện và sửa đường dẫn project khi di chuyển qua máy mới
- **Flexible Migration Options**: 3 tùy chọn migration linh hoạt (Interactive, Custom Directory, MAMP Projects)
- **Dynamic User Detection**: Tự động phát hiện thư mục home của user hiện tại
- **Auto Backup**: Backup tự động trước khi thay đổi cấu hình
- **Placeholder Creation**: Tạo thư mục và file HTML mẫu cho projects mới

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
curl -L -o mamp-projects-manager.zip https://github.com/yourusername/mamp-projects-manager/archive/main.zip
unzip mamp-projects-manager.zip

# Run installer
cd mamp-projects-manager-main
chmod +x install.sh
./install.sh
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

## 🛠️ Troubleshooting

### "This site can't be reached"
1. **Check hosts file**: Verify `/etc/hosts` contains domain entry
2. **Verify Apache port**: Run compatibility test to check port detection
3. **Restart Apache**: Use built-in restart button or MAMP control panel
4. **Clear DNS cache**: `sudo dscacheutil -flushcache`

### Port Detection Issues
1. **Verify MAMP installation**: Check if `/Applications/MAMP/conf/apache/httpd.conf` exists
2. **Check file permissions**: Ensure PHP can read Apache config files
3. **Restart services**: Restart MAMP Apache and MySQL services
4. **Run diagnostic**: Use `test-port-compatibility.php` for detailed analysis

### Virtual Host Not Working
1. **Check Apache syntax**: `/Applications/MAMP/Library/bin/httpd -t`
2. **View virtual hosts**: `/Applications/MAMP/Library/bin/httpd -S`  
3. **Check error logs**: `/Applications/MAMP/logs/apache_error.log`
4. **Verify port match**: Ensure virtual host port matches Apache Listen port

### Permission Issues
```bash
# Fix project folder permissions
sudo chmod -R 755 /Applications/MAMP/htdocs/projects/
sudo chown -R $(whoami):staff /Applications/MAMP/htdocs/projects/

# Fix Apache config permissions (if needed)
sudo chmod 644 /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf
```

## 📦 Migration & Updates

### Moving Between Machines
1. **Copy package**: Transfer entire `/Applications/MAMP/htdocs/projects/` folder
2. **No configuration needed**: Port detection happens automatically
3. **Verify compatibility**: Run `test-port-compatibility.php` on new machine
4. **Recreate projects**: Use the interface to recreate virtual hosts as needed

### Upgrading from v1.x
1. **Backup existing**: Copy current configuration files
2. **Install v2.0**: Follow installation instructions
3. **Auto-migration**: Existing projects will work with detected port
4. **Test functionality**: Run compatibility test to verify everything works

### Changing MAMP Ports
1. **Update MAMP**: Change ports in MAMP preferences
2. **Restart Apache**: Restart MAMP Apache service
3. **Auto-detection**: System automatically detects new port for new projects
4. **Update existing**: May need to recreate existing virtual hosts with new port

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

| Feature | v1.x | v2.0 |
|---------|------|------|
| Port Support | Fixed port 80 only | Any port (dynamic detection) |
| Configuration | Manual setup required | Zero configuration |
| Compatibility | MAMP with port 80 only | All MAMP configurations |
| Migration | Manual reconfiguration | Seamless auto-migration |
| Testing | Manual verification | Built-in compatibility tests |
| Error Detection | Basic | Advanced with auto-troubleshooting |
| Project Management | Basic CRUD | Advanced with system controls |

---

## 🎉 Version 2.0 Benefits

- **🌐 Universal Compatibility**: Works with ANY MAMP port configuration
- **⚡ Zero Setup**: No configuration needed when moving between machines  
- **🔧 Smart Detection**: Automatically adapts to your MAMP setup
- **🧪 Built-in Testing**: Comprehensive compatibility and functionality tests
- **🛠️ Enhanced Management**: Advanced project and system controls
- **📚 Better Documentation**: Comprehensive guides and troubleshooting

**Ready to streamline your MAMP development workflow? Install v2.0 today!** 🚀

---

*MAMP Projects Manager v2.0 - Making local development effortless across all configurations.*
