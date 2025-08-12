# MAMP Projects Manager - Port Compatibility Guide

## 🎯 Overview

MAMP Projects Manager now includes **Dynamic Port Detection** technology that automatically adapts to your MAMP configuration, ensuring seamless operation regardless of which port Apache is running on.

## ✅ Supported Configurations

The package is fully compatible with all MAMP port configurations:

### Standard Configurations
- **Port 80** (Standard HTTP) - Default web port, no port needed in URLs
- **Port 8888** (MAMP Default) - Most common MAMP configuration
- **Port 8080** (Alternative) - Common development port

### Custom Configurations
- **Any port** (1024-65535) - Full support for custom port configurations
- **Dynamic detection** - Automatically reads from MAMP's Apache config
- **Automatic adaptation** - Virtual hosts created with correct port settings

## 🔧 Technical Implementation

### Port Detection Process
1. **Configuration Reading**: Reads `/Applications/MAMP/conf/apache/httpd.conf`
2. **Listen Directive Parsing**: Extracts port from `Listen` directives
3. **Multiple Pattern Support**: Handles various Apache configuration formats
4. **Fallback Mechanism**: Defaults to port 80 if detection fails

### Dynamic Virtual Host Creation
```apache
# Example: Port 80 (Standard)
<VirtualHost *:80>
    ServerName myproject.local
    # ... configuration
</VirtualHost>

# Example: Port 8888 (MAMP Default)  
<VirtualHost *:8888>
    ServerName myproject.local
    # ... configuration
</VirtualHost>

# Example: Custom Port
<VirtualHost *:3000>
    ServerName myproject.local
    # ... configuration
</VirtualHost>
```

## 📋 Compatibility Testing

### Automatic Testing
Run the included compatibility test script:
```bash
/Applications/MAMP/bin/php/php8.2.20/bin/php test-port-compatibility.php
```

### Manual Testing
1. **Check Current Port**: Visit the projects manager interface
2. **Create Test Project**: Add a new virtual host
3. **Verify Configuration**: Check Apache config files
4. **Test Access**: Ensure project URLs work correctly

## 🌐 URL Formats by Port

| Port | URL Format | Example |
|------|------------|---------|
| 80 | `http://domain.local` | `http://myproject.local` |
| 8888 | `http://domain.local:8888` | `http://myproject.local:8888` |
| 3000 | `http://domain.local:3000` | `http://myproject.local:3000` |
| Custom | `http://domain.local:PORT` | `http://myproject.local:9999` |

## ⚙️ Configuration Examples

### MAMP Running on Port 80
```apache
# /Applications/MAMP/conf/apache/httpd.conf
Listen 0.0.0.0:80
ServerName localhost:80
```
**Result**: Standard HTTP URLs (no port needed)

### MAMP Running on Port 8888
```apache  
# /Applications/MAMP/conf/apache/httpd.conf
Listen 0.0.0.0:8888
ServerName localhost:8888
```
**Result**: URLs with `:8888` port suffix

### MAMP Running on Custom Port
```apache
# /Applications/MAMP/conf/apache/httpd.conf  
Listen 0.0.0.0:3000
ServerName localhost:3000
```
**Result**: URLs with `:3000` port suffix

## 🔍 API Endpoints

### Get MAMP Configuration
```javascript
// GET request to api.php?action=mamp_config
fetch('api.php?action=mamp_config')
.then(response => response.json())
.then(data => {
    console.log('Apache Port:', data.data.apache_port);
    console.log('Is Standard:', data.data.is_standard);
    console.log('Web URL Base:', data.data.web_url);
});
```

### Response Example
```json
{
    "success": true,
    "message": "MAMP configuration retrieved successfully",
    "data": {
        "apache_port": 8888,
        "mysql_port": 8889,
        "is_standard": false,
        "web_url": "http://localhost:8888"
    }
}
```

## 🛠️ Troubleshooting

### Port Detection Issues
1. **Verify MAMP Installation**: Ensure `/Applications/MAMP/conf/apache/httpd.conf` exists
2. **Check File Permissions**: Ensure PHP can read Apache config files  
3. **Restart Apache**: Changes may require Apache restart
4. **Clear Cache**: Refresh the projects manager interface

### Virtual Host Issues  
1. **Port Mismatch**: Run compatibility test to verify port detection
2. **Apache Not Running**: Start MAMP Apache server
3. **Firewall Blocking**: Ensure firewall allows custom port access
4. **Hosts File**: Verify `/etc/hosts` entries exist for domains

### Common Error Solutions

#### "This site can't be reached"
- **Cause**: Hosts file missing entry or Apache not on expected port
- **Solution**: Run the projects manager's auto-setup or manually add hosts entry

#### "Port already in use"
- **Cause**: Another service using the configured port
- **Solution**: Change MAMP port or stop conflicting service

#### "Virtual host not working"
- **Cause**: Apache config syntax error or port mismatch
- **Solution**: Run compatibility test and check Apache error logs

## 📦 Migration Guide

### From Fixed Port (Legacy)
If upgrading from an older version with fixed port 80:

1. **Automatic Detection**: New version automatically detects your current port
2. **Existing Projects**: Will continue working with their current port configuration  
3. **New Projects**: Will use detected port automatically
4. **No Action Required**: Upgrade is seamless for most users

### Changing MAMP Port
If you change your MAMP Apache port after installation:

1. **Restart Apache**: Restart MAMP Apache server
2. **Test Compatibility**: Run `test-port-compatibility.php`
3. **Update Existing Projects**: May need to recreate virtual hosts with new port
4. **Clear Browser Cache**: Clear cache for affected domains

## 🔮 Advanced Features

### Multi-Port Support
- **Simultaneous Ports**: Apache can listen on multiple ports
- **Automatic Detection**: Uses the first detected port
- **Manual Override**: Can be configured for specific use cases

### SSL/HTTPS Support  
- **Port 443**: Standard HTTPS port supported
- **Custom SSL Ports**: Any SSL port configuration supported
- **Certificate Management**: Manual SSL certificate setup required

### Development vs Production
- **Development**: Use non-standard ports (8888, 3000, etc.)
- **Production**: Use standard ports (80, 443)
- **Switching**: Change MAMP config and restart Apache

## 📊 Performance Impact

### Port Detection Overhead
- **Detection Time**: < 1ms per API call
- **Caching**: Configuration cached in session
- **File I/O**: Minimal impact from reading Apache config
- **Memory Usage**: Negligible additional memory usage

### Recommended Setup
- **Standard Port 80**: Best performance, no port in URLs
- **Port 8888**: Good performance, slightly longer URLs  
- **High Ports (>8000)**: No performance difference, may need firewall config

## 🆘 Support

### Compatibility Test Results
When reporting issues, include the output from:
```bash
/Applications/MAMP/bin/php/php8.2.20/bin/php test-port-compatibility.php
```

### Common Information Needed
1. **MAMP Version**: Which version of MAMP you're using
2. **Apache Port**: Current Apache port configuration  
3. **macOS Version**: Operating system version
4. **Error Messages**: Any specific error messages encountered
5. **Test Results**: Output from compatibility test script

---

## 📚 Related Documentation
- [Installation Guide](README.md#installation)
- [Usage Guide](README.md#usage)
- [API Documentation](README.md#api-reference)
- [Troubleshooting](README.md#troubleshooting)

---

*This port compatibility system ensures MAMP Projects Manager works seamlessly across all MAMP configurations, from standard setups to highly customized development environments.*
