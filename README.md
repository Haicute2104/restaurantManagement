# 🍽️ Restaurant Management System

Hệ thống quản lý nhà hàng đa nền tảng (iOS/Android) được xây dựng với Flutter và Firebase.

## 📱 Các App

### 1. Customer App (`lib/main_customer.dart`)
- Xem thực đơn và đặt món
- Quản lý giỏ hàng
- Theo dõi trạng thái đơn hàng real-time
- Xem lịch sử đơn hàng

### 2. Staff App (`lib/main_staff.dart`)
- Kitchen Display System - màn hình bếp
- Cập nhật trạng thái đơn hàng (pending → confirmed → preparing → ready → completed)
- Nhận thông báo đơn hàng mới

### 3. Admin App (`lib/main_admin.dart`)
- Quản lý thực đơn (thêm/sửa/xóa món)
- Quản lý đơn hàng
- Dashboard thống kê theo tháng và theo ngày
- Quản lý người dùng

## 🚀 Bắt đầu nhanh

### Yêu cầu
- Flutter SDK (3.0+)
- Firebase CLI
- Android Studio / Xcode
- Tài khoản Firebase

### Cài đặt

```bash
# 1. Clone project
git clone <repository-url>
cd quanlyphanmem

# 2. Cài đặt dependencies
flutter pub get

# 3. Chạy app
flutter run --target lib/main_customer.dart  # Customer
flutter run --target lib/main_staff.dart     # Staff  
flutter run --target lib/main_admin.dart     # Admin
```

### Tài khoản test

**Admin:**
- Email: `admin@restaurant.com`
- Password: `123456`

**Staff:**
- Email: `staff@restaurant.com`
- Password: `123456`

**Customer:**
- Đăng ký tài khoản mới trong app

## 📚 Tài liệu

- [ARCHITECTURE.md](ARCHITECTURE.md) - Kiến trúc hệ thống
- [WORKFLOW.md](WORKFLOW.md) - Luồng hoạt động
- [SETUP.md](SETUP.md) - Hướng dẫn cài đặt chi tiết

## 🛠️ Công nghệ sử dụng

- **Frontend:** Flutter / Dart
- **Backend:** Firebase (Authentication, Firestore, Cloud Functions)
- **State Management:** Riverpod
- **Database:** Cloud Firestore
- **Storage:** Firebase Storage

## 📁 Cấu trúc thư mục

```
lib/
├── admin/          # Admin app
├── customer/       # Customer app
├── staff/          # Staff app
└── shared/         # Shared code
    ├── models/     # Data models
    ├── services/   # Firebase services
    ├── providers/  # Riverpod providers
    ├── widgets/    # Reusable widgets
    └── utils/      # Utilities & constants
```

## 📝 License

MIT License
