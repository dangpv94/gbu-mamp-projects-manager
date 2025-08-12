# 🛠️ MAMP Projects Troubleshooting Suite

Bộ công cụ chẩn đoán và sửa lỗi toàn diện cho MAMP Projects Manager, giải quyết các vấn đề phổ biến khi sử dụng virtual hosts với MAMP.

## 📦 Bao gồm các công cụ

### 🚀 Quick Fix (`quick-fix.sh`)
**Giải pháp nhanh cho các lỗi phổ biến**
- Tự động thêm domain thiếu vào hosts file
- Tạo thư mục project không tồn tại với placeholder
- Flush DNS cache
- Test connectivity
- Thời gian thực hiện: ~30 giây

### 🔧 Full Troubleshoot (`troubleshoot-mamp.sh`)
**Chẩn đoán chi tiết và sửa lỗi toàn diện**
- Phân tích cấu hình virtual hosts
- Kiểm tra hosts file và DNS
- Test HTTP connectivity
- Auto-fix với nhiều tùy chọn
- Backup và restore config
- Thời gian thực hiện: ~2-5 phút

### 🧪 Demo Issues (`demo-issues.sh`)
**Tạo các lỗi demo để test**
- Mô phỏng missing hosts entries
- Tạo wrong DocumentRoot paths
- Simulate port mismatch
- Tạo empty directories
- Safe backup/restore

## 🎯 Giải pháp cho các vấn đề phổ biến

### ❌ "This site can't be reached"
```bash
# Giải pháp nhanh
./quick-fix.sh

# Hoặc manual fix
sudo nano /etc/hosts
# Thêm: 127.0.0.1    your-domain.local
sudo dscacheutil -flushcache
```

### 🏠 Project hiển thị MAMP default page
```bash
# Chạy chẩn đoán đầy đủ
./troubleshoot-mamp.sh
# Chọn option 2: Auto-Fix Common Issues
```

### 🔌 Port mismatch issues
```bash
# Sửa tự động trong troubleshoot script
./troubleshoot-mamp.sh
# Script sẽ detect và fix port mismatch
```

### 📁 Missing project directories
```bash
# Quick fix sẽ tạo placeholder
./quick-fix.sh
# Hoặc tạo thủ công
mkdir -p /path/to/project
```

## 🚀 Hướng dẫn sử dụng

### Khi gặp lỗi MAMP (Recommended workflow):

1. **Bước 1: Quick Fix**
   ```bash
   cd /path/to/mamp-projects-manager
   ./quick-fix.sh
   ```

2. **Bước 2: Test lại projects**
   - Mở browser và test các domain
   - Nếu vẫn lỗi, chuyển sang bước 3

3. **Bước 3: Full Diagnosis**
   ```bash
   ./troubleshoot-mamp.sh
   # Chọn option 1: Run Full Diagnosis
   ```

4. **Bước 4: Auto-Fix (nếu cần)**
   ```bash
   ./troubleshoot-mamp.sh
   # Chọn option 2: Auto-Fix Common Issues
   ```

### Khi setup trên máy mới:

1. **Clone/copy MAMP Projects Manager**
2. **Chạy quick fix ngay**
   ```bash
   ./quick-fix.sh
   ```
3. **Kiểm tra và fix các path cụ thể**
   ```bash
   ./troubleshoot-mamp.sh
   ```

### Testing và development:

1. **Tạo demo issues**
   ```bash
   ./demo-issues.sh
   # Chọn option 1: Create Demo Issues
   ```

2. **Test troubleshooting tools**
   ```bash
   ./quick-fix.sh
   ./troubleshoot-mamp.sh
   ```

3. **Cleanup demo**
   ```bash
   ./demo-issues.sh
   # Chọn option 2: Cleanup Demo Issues
   ```

## 🔍 Chi tiết từng script

### quick-fix.sh
```bash
#!/bin/bash
# ✅ Thêm missing hosts entries
# 📁 Tạo missing project directories
# 🌐 Flush DNS cache
# 🔍 Test connectivity
# ⏱️ Thời gian: ~30s
```

**Khi nào dùng:**
- Sau khi thêm project mới
- Khi di chuyển giữa các máy
- Lỗi "site can't be reached"
- Muốn fix nhanh không cần phân tích

### troubleshoot-mamp.sh
```bash
#!/bin/bash
# 🔍 Full system diagnosis
# 🔧 Comprehensive auto-fix
# 💾 Automatic backups
# 📊 Detailed reporting
# ⏱️ Thời gian: 2-5 phút
```

**Menu options:**
1. **Full Diagnosis** - Phân tích toàn diện
2. **Auto-Fix** - Sửa lỗi tự động
3. **MAMP Status** - Kiểm tra MAMP
4. **Test Connectivity** - Test từng project
5. **Manual Commands** - Hiển thị lệnh thủ công

### demo-issues.sh
```bash
#!/bin/bash
# 🎭 Create realistic demo issues
# 🧹 Safe cleanup
# 🔄 Backup/restore configs
# 📋 Issue status tracking
```

**Demo scenarios:**
1. Missing hosts entries
2. Wrong DocumentRoot paths  
3. Port mismatch (80 vs 8888)
4. Empty project directories

## 🔗 Integration với Web Interface

### API Endpoints được hỗ trợ:

```javascript
// Chẩn đoán
fetch('/api/system/diagnose')

// Auto-fix nhanh
fetch('/api/system/quick-fix')

// Auto-fix toàn diện
fetch('/api/system/autofix', {
    method: 'POST',
    body: JSON.stringify({ mode: 'smart' })
})
```

### Web UI Controls:
- **🔍 Check Issues** - Chạy chẩn đoán
- **🎯 Smart Fix** - Tự động sửa thông minh
- **💼 Fix to Works** - Chuyển về ~/Works/
- **🌐 Fix to MAMP** - Chuyển về MAMP htdocs

## 🛡️ Safety Features

### Automatic Backups:
```bash
# Backup location
/Applications/MAMP/htdocs/projects/backups/
├── vhosts_backup_20240101_120000.conf
├── hosts_backup_20240101_120000
└── ...
```

### Safe Operations:
- ✅ Backup before modify
- ✅ Validation before apply changes
- ✅ Rollback capabilities
- ✅ Non-destructive operations
- ✅ Permission checks

### What scripts DO:
- ✅ Add missing hosts entries
- ✅ Create placeholder directories
- ✅ Fix port mismatches
- ✅ Enable virtual hosts
- ✅ Flush DNS cache
- ✅ Test connectivity

### What scripts DON'T do:
- ❌ Delete existing projects
- ❌ Modify existing project files
- ❌ Change MAMP core settings
- ❌ Affect other applications
- ❌ Require dangerous permissions

## 🐛 Troubleshooting the Troubleshooter

### Nếu script không chạy được:

```bash
# Check permissions
ls -la *.sh

# Fix permissions
chmod +x *.sh

# Check MAMP status
pgrep -f "Applications/MAMP"
```

### Nếu sudo password required:

```bash
# Some operations need admin rights:
# - Modifying /etc/hosts
# - Flushing DNS cache
# - Restarting Apache
```

### Nếu scripts báo lỗi:

1. **Check MAMP is running**
2. **Run with sudo if needed**
3. **Check disk space**
4. **Verify file paths exist**

## 📊 Performance & Compatibility

### System Requirements:
- ✅ macOS (tested on 10.15+)
- ✅ MAMP/MAMP PRO
- ✅ Bash 3.2+ (default macOS)
- ✅ Standard CLI tools (curl, grep, sed)

### Performance:
- **quick-fix.sh**: ~30 seconds
- **troubleshoot-mamp.sh**: 2-5 minutes
- **demo-issues.sh**: ~1 minute
- **Memory usage**: <10MB
- **Disk impact**: Minimal (backups ~1KB each)

### Compatibility:
- ✅ MAMP v4.x, v5.x, v6.x
- ✅ Apache virtual hosts
- ✅ Standard MAMP directory structure
- ✅ Custom DocumentRoot paths
- ✅ Multiple PHP versions

## 📝 Changelog

### v1.0.0 (2024-01-01)
- ✨ Initial release
- ✨ Quick fix script
- ✨ Full troubleshoot script
- ✨ Demo issues script
- ✨ Comprehensive documentation

## 🤝 Contributing

### Báo cáo lỗi:
1. Chạy `./troubleshoot-mamp.sh` option 1
2. Copy full output
3. Bao gồm MAMP version, macOS version
4. Mô tả steps to reproduce

### Đề xuất tính năng:
- Mô tả use case cụ thể
- Explain expected behavior
- Suggest implementation approach

## 📞 Support

### Tự khắc phục:
1. **Đọc `TROUBLESHOOTING.md`**
2. **Chạy `./troubleshoot-mamp.sh`**
3. **Check backup files**
4. **Test với demo issues**

### Cần hỗ trợ:
- Include full diagnosis output
- Specify MAMP and macOS versions  
- Describe exact error messages
- Mention any custom configurations

---

*MAMP Projects Troubleshooting Suite - Making MAMP virtual hosts reliable and easy! 🚀*
