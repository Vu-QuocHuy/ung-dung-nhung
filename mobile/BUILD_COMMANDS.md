# Các lệnh Build App

## 1. Build APK Release (Để cài trên điện thoại thật)

### Bước 1: Clean project (xóa cache và build cũ)

```powershell
cd mobile
flutter clean
```

### Bước 2: Lấy dependencies

```powershell
flutter pub get
```

### Bước 3: Build APK Release

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
flutter build apk --release
```

### Bước 4: Copy file APK (nếu Flutter không tìm thấy)

```powershell
# Tạo thư mục nếu chưa có
New-Item -ItemType Directory -Force -Path "build\app\outputs\flutter-apk" | Out-Null

# Copy file từ vị trí Gradle tạo sang vị trí Flutter mong đợi
Copy-Item "android\app\build\outputs\flutter-apk\app-release.apk" -Destination "build\app\outputs\flutter-apk\app-release.apk" -Force
```

### Bước 5: Kiểm tra file APK đã tạo

```powershell
Get-Item "build\app\outputs\flutter-apk\app-release.apk" | Format-List FullName, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB, 2)}}, LastWriteTime
```

**Đường dẫn file APK:**

- `mobile\build\app\outputs\flutter-apk\app-release.apk`
- Hoặc: `mobile\android\app\build\outputs\flutter-apk\app-release.apk`

---

## 2. Build APK Debug (Để test nhanh)

```powershell
cd mobile
flutter clean
flutter pub get
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
flutter build apk --debug
```

---

## 3. Chạy trên máy ảo/thiết bị (Development mode)

### Chạy trên máy ảo:

```powershell
cd mobile
flutter run -d emulator-5554
```

### Chạy trên thiết bị thật (qua USB):

```powershell
cd mobile
flutter devices  # Xem danh sách thiết bị
flutter run -d <device-id>
```

### Chạy ở chế độ release trên thiết bị:

```powershell
cd mobile
flutter run -d <device-id> --release
```

---

## 4. Lệnh nhanh (All-in-one)

### Build APK Release (một lệnh):

```powershell
cd mobile; flutter clean; flutter pub get; $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"; $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"; flutter build apk --release; New-Item -ItemType Directory -Force -Path "build\app\outputs\flutter-apk" | Out-Null; Copy-Item "android\app\build\outputs\flutter-apk\app-release.apk" -Destination "build\app\outputs\flutter-apk\app-release.apk" -Force
```

---

## 5. Kiểm tra lỗi trước khi build

### Phân tích code:

```powershell
cd mobile
flutter analyze
```

### Kiểm tra format code:

```powershell
cd mobile
flutter format --dry-run lib/
```

### Format code tự động:

```powershell
cd mobile
flutter format lib/
```

---

## 6. Troubleshooting

### Nếu build bị lỗi về JAVA_HOME:

```powershell
# Kiểm tra JAVA_HOME hiện tại
echo $env:JAVA_HOME

# Set JAVA_HOME (nếu chưa có)
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

### Nếu Gradle build failed:

```powershell
# Xóa cache Gradle
cd mobile\android
.\gradlew clean
cd ..
```

### Nếu file APK không được tạo ở vị trí mong đợi:

```powershell
# Copy từ vị trí Gradle tạo sang vị trí Flutter mong đợi
New-Item -ItemType Directory -Force -Path "build\app\outputs\flutter-apk" | Out-Null
Copy-Item "android\app\build\outputs\flutter-apk\app-release.apk" -Destination "build\app\outputs\flutter-apk\app-release.apk" -Force
```

---

## 7. Thông tin file APK

Sau khi build thành công, file APK sẽ có:

- **Kích thước:** ~50-100 MB (tùy thuộc vào dependencies)
- **Vị trí:** `mobile\build\app\outputs\flutter-apk\app-release.apk`
- **Cài đặt:** Copy file này sang điện thoại và cài đặt

---

## Lưu ý

1. **JAVA_HOME** phải được set trước khi build
2. **flutter clean** nên chạy khi có thay đổi lớn về dependencies
3. **Build release** mất khoảng 5-15 phút tùy máy
4. File APK release đã được tối ưu và nhỏ hơn debug version
