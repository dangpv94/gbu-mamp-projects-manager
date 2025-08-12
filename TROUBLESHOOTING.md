# 🔧 MAMP Projects Troubleshooting Guide

Hướng dẫn chi tiết để chẩn đoán và sửa lỗi các vấn đề phổ biến khi sử dụng MAMP với Virtual Hosts.

## 🚀 Giải pháp nhanh (Recommended)

Khi gặp vấn đề về project không truy cập được, hãy chạy lệnh này trước:

```bash
./quick-fix.sh
```

Script này sẽ tự động:
- ✅ Thêm domain thiếu vào hosts file
- 📁 Tạo thư mục project nếu không tồn tại
- 🌐 Flush DNS cache
- 🔍 Test kết nối tới các project

## 🛠️ Chẩn đoán chi tiết

Để chạy chẩn đoán toàn diện:

```bash
./troubleshoot-mamp.sh
```

### Menu các tùy chọn:

1. **🔍 Run Full Diagnosis** - Chẩn đoán toàn bộ hệ thống
2. **🔥 Diagnose Apache Startup Fail** - Chẩn đoán lỗi startup của Apache
3. **🔧 Auto-Fix Common Issues** - Tự động sửa lỗi phổ biến
4. **🚨 Emergency Fix (MAMP Won't Start)** - Sửa khẩn cấp khi MAMP hoàn toàn không khởi động
5. **🩺 Check MAMP Status Only** - Kiểm tra trạng thái MAMP
6. **🌐 Test Project Connectivity** - Test kết nối project
7. **📝 Show Manual Fix Commands** - Hiện lệnh sửa thủ công
8. **🚪 Exit** - Thoát

## ❗ Các vấn đề phổ biến và cách khắc phục

### 1. Project trỏ về MAMP htdocs thay vì thư mục gốc

**Triệu chứng:**
- Domain đã được thêm vào hosts file
- Virtual host đã được cấu hình
- Nhưng khi truy cập vẫn thấy trang mặc định của MAMP

**Nguyên nhân:**
- DocumentRoot trong virtual host bị sai
- Virtual host không được enable
- Port mismatch giữa MAMP và virtual host

**Khắc phục:**
```bash
# Chạy auto-fix
./troubleshoot-mamp.sh
# Chọn option 2: Auto-Fix Common Issues
```

### 2. "This site can't be reached" error

**Triệu chứng:**
- Browser báo lỗi "This site can't be reached"
- Domain không resolve được

**Nguyên nhân:**
- Domain thiếu trong hosts file
- DNS cache chưa được clear
- Sai format trong hosts file

**Khắc phục thủ công:**
```bash
# 1. Thêm domain vào hosts file
sudo nano /etc/hosts

# Thêm dòng:
127.0.0.1    your-domain.local

# 2. Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### 3. Port mismatch issues

**Triệu chứng:**
- Virtual host có port khác với MAMP
- Project không load đúng

**Khắc phục:**
```bash
# 1. Kiểm tra MAMP port
grep "^Listen" /Applications/MAMP/conf/apache/httpd.conf

# 2. Cập nhật virtual host port
sudo nano /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf

# Đảm bảo <VirtualHost *:80> hoặc <VirtualHost *:8888> phù hợp với MAMP
```

### 4. Missing project directories

**Triệu chứng:**
- DocumentRoot không tồn tại
- Apache không thể serve files

**Khắc phục:**
```bash
# Tự động tạo thư mục thiếu với placeholder
./quick-fix.sh

# Hoặc tạo thủ công
mkdir -p /path/to/your/project
echo "<h1>Project Ready</h1>" > /path/to/your/project/index.html
```

## 🔍 Diagnostic Commands

### Check MAMP status:
```bash
# Kiểm tra MAMP process
pgrep -f "Applications/MAMP/Library/bin/httpd"

# Kiểm tra MAMP port
grep "^Listen" /Applications/MAMP/conf/apache/httpd.conf
```

### Check virtual hosts:
```bash
# Xem virtual host config
cat /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf

# Check if virtual hosts enabled
grep "httpd-vhosts" /Applications/MAMP/conf/apache/httpd.conf
```

### Check hosts file:
```bash
# Xem hosts file
cat /etc/hosts

# Kiểm tra domain specific
grep "your-domain.local" /etc/hosts
```

### Test connectivity:
```bash
# Test HTTP response
curl -I http://your-domain.local:8888

# Test DNS resolution
nslookup your-domain.local
```

## 📋 Prevention Tips

### 1. Khi thêm project mới:
- ✅ Luôn dùng đường dẫn tuyệt đối cho DocumentRoot
- ✅ Đảm bảo thư mục project tồn tại
- ✅ Check port consistency
- ✅ Restart MAMP sau khi thêm virtual host

### 2. Khi di chuyển giữa các máy:
- ✅ Chạy `./quick-fix.sh` trên máy mới
- ✅ Kiểm tra đường dẫn home directory
- ✅ Update DocumentRoot nếu cần
- ✅ Re-generate hosts file entries

### 3. Best practices:
- 📁 Đặt tất cả project trong một thư mục chung (vd: ~/Works/)
- 🌐 Dùng .local domain cho development
- 💾 Backup config files trước khi modify
- 🔄 Restart MAMP sau mọi thay đổi config

## 🆘 Emergency Recovery

### 🚨 Emergency Fix (Option 4) - Khi MAMP hoàn toàn không start

Dành cho trường hợp MAMP hoàn toàn không thể khởi động, script sẽ thực hiện các bước quyết liệt:

**Bước 1: Backup toàn bộ config**
- Lưu Apache config, virtual hosts, hosts file vào backup folder có timestamp
- Đảm bảo có thể restore lại nếu cần

**Bước 2: Force stop tất cả web servers**
- Kill tất cả httpd, apache, nginx, MAMP processes
- Đảm bảo clean slate trước khi fix

**Bước 3: Dọn lock files và PIDs**
- Xóa các .pid files trong /Applications/MAMP/
- Xóa system lock files có thể block startup

**Bước 4: Reset về config tối giản**
- Tạo Apache config minimal chỉ với modules cần thiết
- Tùy chọn replace config hiện tại

**Bước 5: Sửa tất cả permissions**
- Fix ownership và permissions cho logs/, tmp/, htdocs/
- Set proper permissions cho log files

**Bước 6: Tạo lại virtual hosts file sạch**
- Tạo file vhosts minimal chỉ có localhost
- Ready để add lại virtual hosts từ từ

**Bước 7: Thử start với config tối giản**
- Test syntax trước khi start
- Fallback qua nhiều methods khác nhau
- Kiểm tra startup thành công

### Manual Recovery nếu cần:

```bash
# 1. Restore backup manually
# Backup files được lưu tại:
/Applications/MAMP/htdocs/projects/backups/emergency_YYYYMMDD_HHMMSS/

# Restore virtual hosts
sudo cp emergency_backup/httpd-vhosts.conf.backup /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf

# Restore hosts file  
sudo cp emergency_backup/hosts.backup /etc/hosts

# Restore Apache config
sudo cp emergency_backup/httpd.conf.backup /Applications/MAMP/conf/apache/httpd.conf
```

```bash
# 2. Complete reset (last resort)
# Stop MAMP
pkill -f "Applications/MAMP"

# Reset virtual hosts (keep backup first!)
echo "# Virtual Hosts" > /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf

# Restart MAMP from GUI
```

## 🔗 Integration với Web Interface

Các script này được tích hợp vào web interface thông qua:

- **API endpoint:** `/api/system/diagnose` - chạy chẩn đoán
- **API endpoint:** `/api/system/autofix` - chạy auto-fix
- **Web buttons:** System Controls trong project management page

### API Response format:
```json
{
    "success": true,
    "message": "Diagnosis completed",
    "issues": [
        {
            "type": "missing_hosts",
            "description": "Domain missing from hosts file",
            "project": "myproject.local"
        }
    ],
    "fixes_applied": 3
}
```

## 📞 Support

Nếu vẫn gặp vấn đề sau khi thử các bước trên:

1. Chạy `./troubleshoot-mamp.sh` với option 1 (Full Diagnosis)
2. Copy output và gửi để được support
3. Đính kèm thông tin:
   - MAMP version
   - macOS version
   - Error message cụ thể
   - Screenshot nếu có

---

*Tài liệu này được tạo cho MAMP Projects Manager v3.0.1*
