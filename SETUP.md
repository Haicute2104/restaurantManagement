# 🛠️ Hướng dẫn cài đặt chi tiết

## 1. Cài đặt môi trường

### 1.1. Flutter SDK
```bash
# Tải Flutter SDK từ: https://flutter.dev/docs/get-started/install
# Giải nén và thêm vào PATH

# Kiểm tra
flutter doctor
```

### 1.2. Firebase CLI
```bash
# Cài đặt Node.js từ: https://nodejs.org
# Cài đặt Firebase CLI
npm install -g firebase-tools

# Đăng nhập
firebase login
```

### 1.3. IDE
- **Android Studio** (khuyên dùng) hoặc **VS Code**
- Cài đặt Flutter plugin

---

## 2. Setup Firebase Project

### 2.1. Tạo Firebase Project
1. Vào https://console.firebase.google.com
2. Tạo project mới: "Restaurant Management"
3. Enable các service:
   - **Authentication** → Email/Password
   - **Cloud Firestore** → Production mode
   - **Storage** (nếu cần upload ảnh)

### 2.2. Tạo Apps trong Firebase
1. **Android App**:
   - Package name: `com.example.quanlyphanmem`
   - Tải `google-services.json` → `android/app/`

2. **iOS App** (optional):
   - Bundle ID: `com.example.quanlyphanmem`
   - Tải `GoogleService-Info.plist` → `ios/Runner/`

### 2.3. FlutterFire CLI Setup
```bash
# Cài đặt FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase cho project
flutterfire configure
```

---

## 3. Setup Firestore

### 3.1. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 3.2. Tạo Collections ban đầu

#### Collection: `users`
Tự động tạo khi user đăng ký

#### Collection: `menuCategories`
```json
{
  "categoryId": "drinks",
  "name": "Đồ uống",
  "priority": 1
}
```

#### Collection: `menuItems`
```json
{
  "itemId": "coffee",
  "name": "Cà phê đen",
  "categoryId": "drinks",
  "price": 25000,
  "imageUrl": "",
  "isAvailable": true
}
```

### 3.3. Tạo Admin User
```bash
# Chạy script hoặc tạo thủ công trong Firebase Console

# Authentication → Add user:
# Email: admin@restaurant.com
# Password: 123456

# Firestore → users collection → Tạo document với uid từ Authentication:
{
  "uid": "<uid-from-auth>",
  "email": "admin@restaurant.com",
  "role": "admin",
  "displayName": "Admin"
}
```

---

## 4. Cài đặt dependencies

```bash
# Vào thư mục project
cd quanlyphanmem

# Cài đặt packages
flutter pub get

# Clean build (nếu cần)
flutter clean
flutter pub get
```

---

## 5. Chạy App

### 5.1. Chạy trên Android Emulator
```bash
# Kiểm tra devices
flutter devices

# Chạy customer app
flutter run -d <device-id> --target lib/main_customer.dart

# Chạy staff app
flutter run -d <device-id> --target lib/main_staff.dart

# Chạy admin app
flutter run -d <device-id> --target lib/main_admin.dart
```

### 5.2. Chạy trên thiết bị thật
```bash
# Android: Bật USB Debugging
# iOS: Trust developer certificate

flutter run -d <device-name> --target lib/main_customer.dart
```

### 5.3. Build APK
```bash
# Build release APK
flutter build apk --release --target lib/main_customer.dart
flutter build apk --release --target lib/main_staff.dart
flutter build apk --release --target lib/main_admin.dart

# APK output: build/app/outputs/flutter-apk/
```

---

## 6. Tạo tài khoản Staff

### Cách 1: Firebase Console
```
1. Authentication → Add user
   Email: staff@restaurant.com
   Password: 123456

2. Firestore → users → Create document
   {
     "uid": "<uid-from-auth>",
     "email": "staff@restaurant.com",
     "role": "staff",
     "displayName": "Staff"
   }
```

### Cách 2: Admin App
```
Tính năng tạo staff trong admin app (nếu đã implement)
```

---

## 7. Troubleshooting

### Lỗi: "No Firebase App"
```bash
flutter clean
flutter pub get
flutterfire configure
```

### Lỗi: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter run
```

### Lỗi: "CocoaPods not found" (iOS)
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
flutter run
```

### Lỗi: Permission denied khi cập nhật đơn hàng
```bash
# Deploy lại Firestore rules
firebase deploy --only firestore:rules
```

---

## 8. Cấu trúc Firebase

### Collections
```
firestore/
├── users/              # User profiles
├── menuCategories/     # Menu categories
├── menuItems/          # Menu items
├── orders/            # Orders
└── dailyReports/      # Daily statistics (auto-generated)
```

### Storage (optional)
```
storage/
└── menu-images/       # Menu item images
```

---

## 9. Môi trường Development vs Production

### Development
- Sử dụng Firebase test project
- Debug mode
- Hot reload enabled

### Production
- Tạo Firebase production project riêng
- Build release APK/IPA
- Enable ProGuard (Android)
- Enable obfuscation

---

## 10. Bảo trì

### Backup Firestore
```bash
# Export Firestore data
gcloud firestore export gs://[BUCKET_NAME]
```

### Update Dependencies
```bash
flutter pub outdated
flutter pub upgrade
```

### Check Security
```bash
# Review Firestore rules
firebase deploy --only firestore:rules --dry-run
```


