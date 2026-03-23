# Hướng dẫn xuất file APK để cài trên điện thoại thật

## ⚡ Phát triển với Hot Reload (Khuyến nghị khi đang code)

### Sự khác biệt giữa `flutter run` và `flutter build apk`:

**`flutter run`** - Chạy app với Hot Reload (cho phát triển):

- ✅ Thay đổi code → Thấy ngay trên máy ảo/thiết bị (không cần build lại)
- ✅ Hot Reload: Nhấn `r` trong terminal → Cập nhật UI ngay lập tức
- ✅ Hot Restart: Nhấn `R` trong terminal → Restart app nhanh
- ✅ Nhanh, tiện lợi khi đang chỉnh sửa giao diện
- ❌ Không tạo file APK để cài trên điện thoại khác

**`flutter build apk`** - Build file APK (cho phân phối):

- ✅ Tạo file APK để cài trên điện thoại thật
- ✅ Tối ưu hóa cho production
- ❌ Mỗi lần thay đổi phải build lại từ đầu (mất thời gian)

### Cách sử dụng Hot Reload:

```bash
cd mobile
flutter run -d emulator-5554
```

**Sau khi app chạy, trong terminal bạn sẽ thấy:**

```
Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

**Khi chỉnh sửa code:**

1. Lưu file (Ctrl+S)
2. Nhấn `r` trong terminal → Thay đổi sẽ hiện ngay trên máy ảo
3. Nếu Hot Reload không hoạt động, nhấn `R` để Hot Restart

**Lưu ý:**

- Hot Reload hoạt động tốt với thay đổi UI, styling, text
- Một số thay đổi cần Hot Restart (nhấn `R`): thêm/xóa dependencies, thay đổi `main()`, thay đổi `initState()`
- Hot Reload KHÔNG hoạt động khi: thay đổi native code, thay đổi assets, thay đổi pubspec.yaml

---

## Cách 1: Build APK Release (Cho phân phối)

### Bước 1: Kiểm tra môi trường

```bash
flutter doctor
```

Đảm bảo Android toolchain đã được cài đặt đầy đủ.

### Bước 2: Build APK Release

```bash
cd mobile
flutter build apk --release
```

**Hoặc build APK split theo ABI (nhỏ hơn, khuyến nghị):**

```bash
flutter build apk --split-per-abi --release
```

### Bước 3: Tìm file APK

Sau khi build xong, file APK sẽ nằm tại:

**Vị trí thực tế (sau khi Gradle build):**

- `mobile/android/app/build/outputs/flutter-apk/app-release.apk`
- `mobile/android/app/build/outputs/apk/release/app-release.apk`

**Vị trí Flutter mong đợi (nếu Flutter tự copy):**

- `mobile/build/app/outputs/flutter-apk/app-release.apk`

**Lưu ý:** Nếu Flutter báo không tìm thấy APK nhưng Gradle build thành công, bạn có thể tìm file APK ở vị trí thực tế trong thư mục `android/app/build/outputs/`.

**APK split (nếu dùng `--split-per-abi`):**

- `mobile/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (32-bit)
- `mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (64-bit)
- `mobile/build/app/outputs/flutter-apk/app-x86_64-release.apk` (x86_64)

### Bước 4: Cài đặt trên điện thoại

#### Cách A: Copy file APK vào điện thoại

1. Kết nối điện thoại với máy tính qua USB
2. Copy file APK vào thư mục Download trên điện thoại
3. Trên điện thoại, mở File Manager → Tìm file APK → Cài đặt
4. Cho phép "Cài đặt từ nguồn không xác định" nếu được hỏi

#### Cách B: Cài trực tiếp qua ADB

```bash
flutter install --release
```

(Lưu ý: Cần bật USB Debugging trên điện thoại)

---

## Cách 2: Build APK Bundle (AAB) - Cho Google Play Store

Nếu bạn muốn upload lên Google Play Store:

```bash
flutter build appbundle --release
```

File AAB sẽ nằm tại: `mobile/build/app/outputs/bundle/release/app-release.aab`

---

## Lưu ý quan trọng:

### 1. Signing Key (Chữ ký ứng dụng)

Hiện tại app đang dùng debug key. Để publish lên Google Play, bạn cần:

- Tạo keystore file
- Cấu hình signing trong `android/app/build.gradle.kts`

### 2. Kích thước file

- APK đầy đủ: ~50-100MB (hỗ trợ tất cả kiến trúc)
- APK split: ~20-40MB mỗi file (chỉ hỗ trợ 1 kiến trúc)

### 3. Kiểm tra trước khi build

```bash
# Kiểm tra lỗi
flutter analyze

# Test trên thiết bị
flutter run --release
```

---

## Troubleshooting:

### Lỗi: "Gradle build failed" hoặc "Gradle build failed to produce an .apk file"

**Nếu Gradle build thành công nhưng Flutter không tìm thấy APK:**

1. Kiểm tra file APK có được tạo không:

   ```powershell
   # Windows PowerShell
   Get-ChildItem -Path "mobile\android\app\build\outputs" -Filter "*.apk" -Recurse
   ```

2. Nếu file APK tồn tại ở `android/app/build/outputs/`, bạn có thể sử dụng file đó trực tiếp.

3. Hoặc thử build lại với JAVA_HOME được set:
   ```powershell
   # Windows PowerShell
   $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
   $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
   cd mobile
   flutter build apk --release
   ```

**Nếu Gradle build thực sự thất bại:**

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Lỗi: "SDK location not found"

Đảm bảo đã cài đặt Android SDK và set biến môi trường ANDROID_HOME

### Lỗi: "Failed to find Build Tools"

```bash
# Cài đặt build tools qua Android Studio SDK Manager
# Hoặc chạy:
flutter doctor --android-licenses
```

---

## Tối ưu hóa APK:

### Giảm kích thước file:

1. Sử dụng `--split-per-abi` (đã đề cập ở trên)
2. Xóa unused resources:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### Tăng hiệu suất:

- Build với `--release` flag (đã tự động tối ưu)
- Kiểm tra ProGuard rules nếu cần

---

## Kiểm tra APK sau khi build:

```bash
# Xem thông tin APK
flutter build apk --release --analyze-size
```

---

## Các lệnh hữu ích khác:

```bash
# Build cho từng ABI riêng biệt
flutter build apk --target-platform android-arm --release
flutter build apk --target-platform android-arm64 --release
flutter build apk --target-platform android-x64 --release

# Build với profile mode (để test performance)
flutter build apk --profile

# Clean build
flutter clean
flutter pub get
flutter build apk --release
```
