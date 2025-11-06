# 👨‍💼 Tài liệu Chi tiết - Admin Role (Quản lý)

## Mục lục
1. [Tổng quan về Admin Role](#tổng-quan)
2. [Cấu trúc File và Thư mục](#cấu-trúc-file)
3. [Giải thích File .g và .freeze](#file-g-và-freeze)
4. [Cơ chế Real-time](#cơ-chế-real-time)
5. [Chi tiết từng Chức năng và Hàm](#chi-tiết-chức-năng)

---

## Tổng quan {#tổng-quan}

Admin Role là ứng dụng quản lý dành cho chủ nhà hàng/quản lý, cho phép:
- Xem Dashboard với thống kê doanh thu, đơn hàng
- Quản lý thực đơn (thêm/sửa/xóa món ăn, categories)
- Quản lý đơn hàng (xem tất cả, hủy đơn)
- Quản lý nhân viên (tạo staff accounts)
- Xem báo cáo thống kê (theo ngày, theo tháng, top món bán chạy)

**Entry Point:** `lib/main_admin.dart`

---

## Cấu trúc File và Thư mục {#cấu-trúc-file}

```
lib/
├── main_admin.dart                       # Entry point cho Admin app
├── admin/
│   ├── screens/
│   │   ├── auth/
│   │   │   └── admin_login_screen.dart   # Màn hình đăng nhập Admin
│   │   ├── home/
│   │   │   └── admin_home_screen.dart   # Màn hình chính (Bottom Nav)
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart    # Dashboard với thống kê
│   │   ├── menu/
│   │   │   └── menu_management_screen.dart # Quản lý món ăn
│   │   ├── categories/
│   │   │   └── category_management_screen.dart # Quản lý danh mục
│   │   ├── orders/
│   │   │   └── orders_management_screen.dart # Quản lý đơn hàng
│   │   ├── users/
│   │   │   └── user_management_screen.dart # Quản lý nhân viên
│   │   └── profile/
│   │       └── admin_profile_screen.dart  # Thông tin tài khoản
│   └── utils/
│       └── create_staff_helper.dart     # Helper tạo staff/admin users
└── shared/                              # Code dùng chung
    ├── models/                          # Data models
    ├── services/                        # FirestoreService
    └── providers/                       # Riverpod providers
```

---

## Giải thích File .g và .freeze {#file-g-và-freeze}

### File .freezed.dart

**Mục đích:** Tương tự như Customer và Staff role, các models sử dụng freezed để đảm bảo immutability.

**Sử dụng trong Admin Role:**

Admin role làm việc với nhiều models:
- `MenuItem`: Quản lý món ăn
- `MenuCategory`: Quản lý danh mục
- `Order`: Quản lý đơn hàng
- `UserModel`: Quản lý users
- `DailyReport`: Báo cáo ngày
- `ItemReport`: Báo cáo món ăn

**Ví dụ với MenuItem:**

```dart
@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String itemId,
    required String name,
    required String categoryId,
    required double price,
    required String imageUrl,
    required bool isAvailable,
    String? description,
  }) = _MenuItem;
}
```

**Sử dụng:**

```dart
// Tạo món mới
final newItem = MenuItem(
  itemId: uuid.v4(),
  name: 'Phở Bò',
  categoryId: 'category123',
  price: 50000,
  imageUrl: 'https://...',
  isAvailable: true,
);

// Update với copyWith (immutable)
final updatedItem = newItem.copyWith(price: 55000, isAvailable: false);
```

**Code lấy từ đâu:**
- `lib/shared/models/menu_item_model.dart` - Định nghĩa MenuItem
- `lib/shared/models/menu_item_model.freezed.dart` - Generated file

**Code dùng ở đâu:**
- `menu_management_screen.dart`: CRUD menu items
- `firestore_service.dart`: Convert MenuItem ↔ Firestore

### File .g.dart

**Mục đích:** Serialize/Deserialize các models với JSON

**Sử dụng trong Admin Role:**

```dart
// Lưu MenuItem vào Firestore
await _firestore.collection('menuItems').doc(itemId).set(item.toJson());

// Đọc MenuItem từ Firestore
final doc = await _firestore.collection('menuItems').doc(itemId).get();
final item = MenuItem.fromJson({...doc.data()!, 'itemId': doc.id});
```

**Code lấy từ đâu:**
- `lib/shared/models/*.g.dart` - Generated files cho tất cả models

**Code dùng ở đâu:**
- Tất cả các Firestore operations trong `FirestoreService`
- CRUD operations trong admin screens

---

## Cơ chế Real-time {#cơ-chế-real-time}

### Tổng quan

Admin app sử dụng **Firestore Streams** để:
- Cập nhật menu real-time khi admin thêm/sửa/xóa món
- Cập nhật đơn hàng real-time khi có đơn mới hoặc status thay đổi
- Cập nhật thống kê real-time khi có đơn hoàn thành

### Cơ chế hoạt động

#### 1. Menu Categories Stream

**Định nghĩa:** `lib/shared/services/firestore_service.dart`

```11:19:lib/shared/services/firestore_service.dart
  Stream<List<MenuCategory>> getMenuCategories() {
    return _firestore
        .collection('menuCategories')
        .orderBy('priority')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuCategory.fromJson({...doc.data(), 'categoryId': doc.id}))
            .toList());
  }
```

**Sử dụng:** `lib/shared/providers/firestore_provider.dart`

```10:13:lib/shared/providers/firestore_provider.dart
final menuCategoriesProvider = StreamProvider<List<MenuCategory>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMenuCategories();
});
```

**Luồng cập nhật:**

```
1. Admin thêm/sửa/xóa category
   ↓ (addMenuCategory/updateMenuCategory/deleteMenuCategory)
2. Firestore update collection
   ↓ (Stream emit snapshot mới)
3. menuCategoriesProvider nhận update
   ↓ (ref.watch trong UI)
4. UI tự động rebuild với categories mới
   ↓ (Customer app cũng cập nhật real-time)
```

#### 2. Menu Items Stream

**Định nghĩa:**

```40:50:lib/shared/services/firestore_service.dart
  Stream<List<MenuItem>> getMenuItems({String? categoryId}) {
    Query query = _firestore.collection('menuItems');
    
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => MenuItem.fromJson({...doc.data() as Map<String, dynamic>, 'itemId': doc.id}))
        .toList());
  }
```

**Luồng cập nhật:**

```
1. Admin thêm món mới → Firestore tạo document
   ↓
2. Stream emit snapshot mới
   ↓
3. menuItemsProvider nhận update
   ↓
4. Admin UI: Hiển thị món mới
   Customer UI: Món mới xuất hiện trong menu
```

#### 3. Orders Stream

**Định nghĩa:**

```136:142:lib/shared/services/firestore_service.dart
  Stream<List<Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }
```

**Sử dụng:** `lib/shared/providers/firestore_provider.dart`

```32:35:lib/shared/providers/firestore_provider.dart
final allOrdersProvider = StreamProvider<List<Order>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllOrders();
});
```

**Luồng cập nhật:**

```
1. Customer đặt món / Staff cập nhật status
   ↓
2. Firestore update order document
   ↓
3. allOrdersProvider nhận update
   ↓
4. Admin dashboard cập nhật số liệu real-time
```

#### 4. Statistics Stream

**Định nghĩa:** `lib/shared/services/firestore_service.dart`

```228:262:lib/shared/services/firestore_service.dart
  Stream<Map<String, dynamic>> streamMonthlyStatistics(int year, int month) {
    // Get first and last day of the month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);

    // Stream orders in this month
    return _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: firstDay)
        .where('createdAt', isLessThanOrEqualTo: lastDay)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

      // Calculate statistics
      final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();
      final cancelledOrders = orders.where((o) => o.status == OrderStatus.cancelled).toList();
      
      final totalRevenue = completedOrders.fold<double>(
        0, 
        (sum, order) => sum + order.totalAmount
      );

      return {
        'totalOrders': orders.length,
        'completedOrders': completedOrders.length,
        'cancelledOrders': cancelledOrders.length,
        'totalRevenue': totalRevenue,
        'activeOrders': orders.where((o) => 
          o.status != OrderStatus.completed && 
          o.status != OrderStatus.cancelled
        ).length,
      };
    });
  }
```

**Giải thích:**
- Stream tất cả orders trong tháng
- Tính toán statistics real-time:
  - Total orders
  - Completed orders
  - Cancelled orders
  - Total revenue (chỉ tính completed orders)
  - Active orders
- Cập nhật tự động khi có đơn mới hoặc status thay đổi

---

## Chi tiết từng Chức năng và Hàm {#chi-tiết-chức-năng}

### 1. Đăng nhập Admin

#### 1.1. Admin Login Screen

**File:** `lib/admin/screens/auth/admin_login_screen.dart`

**Chức năng:** Cho phép admin đăng nhập với role admin

**Hàm chính:**

```dart
Future<void> _signIn() async {
  final authService = ref.read(authServiceProvider);
  final user = await authService.signInWithEmailAndPassword(
    email: _emailController.text,
    password: _passwordController.text,
  );
  
  // Kiểm tra role phải là admin
  if (user != null && user.role == UserRole.admin) {
    // Đăng nhập thành công
  } else {
    // Hiển thị lỗi: "Tài khoản không phải Admin"
  }
}
```

**Code lấy từ đâu:**
- `AuthService.signInWithEmailAndPassword()`: `lib/shared/services/auth_service.dart`

**Code dùng ở đâu:**
- Khi admin nhấn nút "Đăng nhập"
- Auth state được watch trong `main_admin.dart`:

```37:38:lib/main_admin.dart
      home: authState.when(
        data: (user) => user != null ? const AdminHomeScreen() : const AdminLoginScreen(),
```

---

### 2. Dashboard

#### 2.1. Dashboard Screen

**File:** `lib/admin/screens/dashboard/dashboard_screen.dart`

**Chức năng:** Hiển thị thống kê tổng quan (tháng, ngày, biểu đồ, top món)

**Hàm chính:**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final todayDate = _getTodayDate();
  final firestoreService = FirestoreService();
  final activeOrdersAsync = ref.watch(activeOrdersProvider);

  final now = DateTime.now();
  final currentYear = now.year;
  final currentMonth = now.month;

  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Monthly Stats
          StreamBuilder<Map<String, dynamic>>(
            stream: firestoreService.streamMonthlyStatistics(currentYear, currentMonth),
            builder: (context, snapshot) {
              // Hiển thị thống kê tháng
            },
          ),
          // Daily Stats
          StreamBuilder<Map<String, dynamic>>(
            stream: firestoreService.streamDailyStatistics(todayDate),
            builder: (context, snapshot) {
              // Hiển thị thống kê ngày
            },
          ),
          // Charts và Top Items
        ],
      ),
    ),
  );
}
```

**Code lấy từ đâu:**
- `FirestoreService.streamMonthlyStatistics()`: `lib/shared/services/firestore_service.dart`
- `FirestoreService.streamDailyStatistics()`: `lib/shared/services/firestore_service.dart`

**Giải thích:**
- Sử dụng `StreamBuilder` để lắng nghe statistics streams
- Tự động cập nhật khi có đơn mới hoặc status thay đổi
- Hiển thị biểu đồ doanh thu theo giờ, top món bán chạy

#### 2.2. Monthly Statistics

**Định nghĩa:** `lib/shared/services/firestore_service.dart`

```228:262:lib/shared/services/firestore_service.dart
  Stream<Map<String, dynamic>> streamMonthlyStatistics(int year, int month) {
    // Get first and last day of the month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);

    // Stream orders in this month
    return _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: firstDay)
        .where('createdAt', isLessThanOrEqualTo: lastDay)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();

      // Calculate statistics
      final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();
      final cancelledOrders = orders.where((o) => o.status == OrderStatus.cancelled).toList();
      
      final totalRevenue = completedOrders.fold<double>(
        0, 
        (sum, order) => sum + order.totalAmount
      );

      return {
        'totalOrders': orders.length,
        'completedOrders': completedOrders.length,
        'cancelledOrders': cancelledOrders.length,
        'totalRevenue': totalRevenue,
        'activeOrders': orders.where((o) => 
          o.status != OrderStatus.completed && 
          o.status != OrderStatus.cancelled
        ).length,
      };
    });
  }
```

**Giải thích:**
- Lấy tất cả orders trong tháng (từ ngày 1 đến ngày cuối tháng)
- Tính toán statistics:
  - `totalOrders`: Tổng số đơn
  - `completedOrders`: Số đơn hoàn thành
  - `cancelledOrders`: Số đơn hủy
  - `totalRevenue`: Tổng doanh thu (chỉ tính completed orders)
  - `activeOrders`: Số đơn đang xử lý

**Code dùng ở đâu:**
- `dashboard_screen.dart`: Hiển thị thống kê tháng trong cards

#### 2.3. Daily Statistics

**Định nghĩa:** `lib/shared/services/firestore_service.dart`

```265:313:lib/shared/services/firestore_service.dart
  Stream<Map<String, dynamic>> streamDailyStatistics(String date) {
    // Parse date string (YYYY-MM-DD)
    final dateParts = date.split('-');
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);
    
    final startOfDay = DateTime(year, month, day, 0, 0, 0);
    final endOfDay = DateTime(year, month, day, 23, 59, 59);

    return _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .where('createdAt', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
      
      // Calculate statistics
      final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();
      
      final totalRevenue = completedOrders.fold<double>(
        0, 
        (sum, order) => sum + order.totalAmount
      );

      // Calculate hourly revenue
      final hourlyRevenue = <String, double>{};
      for (var order in completedOrders) {
        final hour = order.createdAt.hour.toString().padLeft(2, '0');
        hourlyRevenue[hour] = (hourlyRevenue[hour] ?? 0) + order.totalAmount;
      }

      // Calculate item sales count
      final itemSalesCount = <String, int>{};
      for (var order in completedOrders) {
        for (var item in order.items) {
          itemSalesCount[item.name] = (itemSalesCount[item.name] ?? 0) + item.quantity;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': completedOrders.length,
        'hourlyRevenue': hourlyRevenue,
        'itemSalesCount': itemSalesCount,
      };
    });
  }
```

**Giải thích:**
- Lấy tất cả orders trong ngày (từ 00:00:00 đến 23:59:59)
- Tính toán:
  - `totalRevenue`: Doanh thu ngày
  - `totalOrders`: Số đơn hoàn thành
  - `hourlyRevenue`: Map giờ → doanh thu (để vẽ biểu đồ)
  - `itemSalesCount`: Map tên món → số lượng bán (để top món)

**Code dùng ở đâu:**
- `dashboard_screen.dart`: Hiển thị thống kê ngày và biểu đồ

---

### 3. Quản lý Thực đơn

#### 3.1. Menu Management Screen

**File:** `lib/admin/screens/menu/menu_management_screen.dart`

**Chức năng:** CRUD menu items (thêm/sửa/xóa/toggle availability)

**Hàm chính:**

```dart
@override
Widget build(BuildContext context) {
  final categoriesAsync = ref.watch(menuCategoriesProvider);
  final menuItemsAsync = ref.watch(menuItemsProvider);

  return Scaffold(
    body: Column(
      children: [
        // Category filter
        // Menu items list
        Expanded(
          child: menuItemsAsync.when(
            data: (items) {
              final filteredItems = _selectedCategoryId == null
                  ? items
                  : items.where((item) => item.categoryId == _selectedCategoryId).toList();
              // Hiển thị danh sách món
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const AddMenuItemDialog(),
        );
      },
      label: const Text('Thêm món mới'),
    ),
  );
}
```

**Code lấy từ đâu:**
- `menuCategoriesProvider`: `lib/shared/providers/firestore_provider.dart`
- `menuItemsProvider`: `lib/shared/providers/firestore_provider.dart`

#### 3.2. Thêm Món Mới

**Hàm:**

```dart
Future<void> _addMenuItem() async {
  final uuid = const Uuid();
  final newItem = MenuItem(
    itemId: uuid.v4(),
    name: _nameController.text,
    categoryId: _selectedCategoryId!,
    price: double.parse(_priceController.text),
    imageUrl: _imageUrlController.text,
    isAvailable: true,
    description: _descriptionController.text,
  );

  final firestoreService = FirestoreService();
  await firestoreService.addMenuItem(newItem);
}
```

**Code lấy từ đâu:**
- `FirestoreService.addMenuItem()`: `lib/shared/services/firestore_service.dart`

```74:79:lib/shared/services/firestore_service.dart
  Future<void> addMenuItem(MenuItem item) async {
    await _firestore
        .collection('menuItems')
        .doc(item.itemId)
        .set(item.toJson());
  }
```

**Giải thích:**
- Tạo MenuItem object với UUID
- `item.toJson()`: Convert thành Map (sử dụng file .g.dart)
- Lưu vào Firestore collection 'menuItems'
- Stream tự động emit update → UI cập nhật real-time

#### 3.3. Sửa Món

**Hàm:**

```dart
Future<void> _updateMenuItem() async {
  final updatedItem = item.copyWith(
    name: _nameController.text,
    price: double.parse(_priceController.text),
    imageUrl: _imageUrlController.text,
    description: _descriptionController.text,
  );

  final firestoreService = FirestoreService();
  await firestoreService.updateMenuItem(updatedItem);
}
```

**Code lấy từ đâu:**
- `FirestoreService.updateMenuItem()`: `lib/shared/services/firestore_service.dart`

```81:86:lib/shared/services/firestore_service.dart
  Future<void> updateMenuItem(MenuItem item) async {
    await _firestore
        .collection('menuItems')
        .doc(item.itemId)
        .update(item.toJson());
  }
```

**Giải thích:**
- `item.copyWith(...)`: Tạo copy với fields mới (immutable pattern)
- Update Firestore document
- Stream tự động cập nhật → Customer app thấy thay đổi ngay

#### 3.4. Toggle Availability

**Hàm:**

```dart
Future<void> _toggleAvailability(String itemId, bool isAvailable) async {
  final firestoreService = FirestoreService();
  await firestoreService.updateMenuItemAvailability(itemId, !isAvailable);
}
```

**Code lấy từ đâu:**
- `FirestoreService.updateMenuItemAvailability()`: `lib/shared/services/firestore_service.dart`

```88:93:lib/shared/services/firestore_service.dart
  Future<void> updateMenuItemAvailability(String itemId, bool isAvailable) async {
    await _firestore
        .collection('menuItems')
        .doc(itemId)
        .update({'isAvailable': isAvailable});
  }
```

**Giải thích:**
- Chỉ update field `isAvailable`
- Khi `isAvailable = false`, món không hiển thị trong Customer app
- Real-time update đến Customer app

#### 3.5. Xóa Món

**Hàm:**

```dart
Future<void> _deleteMenuItem(String itemId) async {
  final firestoreService = FirestoreService();
  await firestoreService.deleteMenuItem(itemId);
}
```

**Code lấy từ đâu:**
- `FirestoreService.deleteMenuItem()`: `lib/shared/services/firestore_service.dart`

```95:97:lib/shared/services/firestore_service.dart
  Future<void> deleteMenuItem(String itemId) async {
    await _firestore.collection('menuItems').doc(itemId).delete();
  }
```

---

### 4. Quản lý Danh mục

#### 4.1. Category Management Screen

**File:** `lib/admin/screens/categories/category_management_screen.dart`

**Chức năng:** CRUD menu categories

**Hàm chính:**

```dart
// Thêm category
Future<void> _addCategory() async {
  final newCategory = MenuCategory(
    categoryId: uuid.v4(),
    name: _nameController.text,
    priority: int.parse(_priorityController.text),
  );
  
  await firestoreService.addMenuCategory(newCategory);
}

// Sửa category
Future<void> _updateCategory() async {
  await firestoreService.updateMenuCategory(category);
}

// Xóa category
Future<void> _deleteCategory(String categoryId) async {
  await firestoreService.deleteMenuCategory(categoryId);
}
```

**Code lấy từ đâu:**
- `FirestoreService.addMenuCategory()`: `lib/shared/services/firestore_service.dart`

```21:26:lib/shared/services/firestore_service.dart
  Future<void> addMenuCategory(MenuCategory category) async {
    await _firestore
        .collection('menuCategories')
        .doc(category.categoryId)
        .set(category.toJson());
  }
```

**Giải thích:**
- Categories được sắp xếp theo `priority`
- Real-time update đến Customer app

---

### 5. Quản lý Đơn hàng

#### 5.1. Orders Management Screen

**File:** `lib/admin/screens/orders/orders_management_screen.dart`

**Chức năng:** Xem tất cả đơn hàng và hủy đơn (force cancel)

**Hàm chính:**

```dart
@override
Widget build(BuildContext context) {
  final ordersAsync = ref.watch(allOrdersProvider);

  return Scaffold(
    body: Column(
      children: [
        // Filter tabs
        // Orders list
        Expanded(
          child: ordersAsync.when(
            data: (orders) {
              final filteredOrders = _filterOrders(orders, _selectedFilter);
              // Hiển thị danh sách đơn
            },
          ),
        ),
      ],
    ),
  );
}
```

**Code lấy từ đâu:**
- `allOrdersProvider`: `lib/shared/providers/firestore_provider.dart`

#### 5.2. Hủy Đơn (Force Cancel)

**Hàm:**

```dart
Future<void> _cancelOrder(String orderId) async {
  final firestoreService = FirestoreService();
  await firestoreService.cancelOrder(orderId);
}
```

**Code lấy từ đâu:**
- `FirestoreService.cancelOrder()`: `lib/shared/services/firestore_service.dart`

```150:152:lib/shared/services/firestore_service.dart
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }
```

**Giải thích:**
- Admin có thể hủy đơn ở bất kỳ trạng thái nào (khác với Customer chỉ hủy được khi pending)
- Real-time update đến Customer và Staff app

---

### 6. Quản lý Nhân viên

#### 6.1. User Management Screen

**File:** `lib/admin/screens/users/user_management_screen.dart`

**Chức năng:** Xem danh sách users và tạo staff accounts

**Hàm chính:**

```dart
@override
Widget build(BuildContext context) {
  // Lấy danh sách users từ Firestore
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection('users').snapshots(),
    builder: (context, snapshot) {
      // Hiển thị danh sách users
      // Filter theo role: customer, staff, admin
    },
  );
}
```

#### 6.2. Tạo Staff Account

**Hàm:**

```dart
Future<void> _createStaff() async {
  final helper = CreateStaffHelper();
  final uid = await helper.createStaffUser(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
  );
  
  if (uid != null) {
    // Tạo thành công
  }
}
```

**Code lấy từ đâu:**
- `CreateStaffHelper.createStaffUser()`: `lib/admin/utils/create_staff_helper.dart`

```13:46:lib/admin/utils/create_staff_helper.dart
  static Future<String?> createStaffUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Tạo user trong Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Tạo document trong Firestore với role STAFF
        final staffUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: UserRole.staff,  // STAFF role
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(staffUser.uid)
            .set(staffUser.toJson());

        return staffUser.uid;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
```

**Giải thích:**
1. Tạo user trong Firebase Authentication
2. Tạo UserModel với `role = UserRole.staff`
3. Lưu vào Firestore collection 'users'
4. Staff có thể đăng nhập vào Staff app với credentials này

---

## Tóm tắt Luồng Dữ liệu

### Luồng Quản lý Menu:

```
1. Admin thêm món mới
   ↓ (addMenuItem trong Firestore)
2. Firestore tạo document mới
   ↓ (Stream emit snapshot mới)
3. menuItemsProvider nhận update
   ↓ (ref.watch trong UI)
4. Admin UI: Hiển thị món mới
   Customer UI: Món mới xuất hiện trong menu
```

### Luồng Thống kê:

```
1. Customer đặt món → Order được tạo
   ↓
2. Staff cập nhật status → completed
   ↓
3. Firestore update order document
   ↓
4. streamMonthlyStatistics() stream nhận update
   ↓
5. Dashboard tự động cập nhật:
   - Total revenue tăng
   - Completed orders tăng
   - Biểu đồ cập nhật
```

### Luồng Tạo Staff:

```
1. Admin điền form (email, password, name)
   ↓ (CreateStaffHelper.createStaffUser)
2. Firebase Auth tạo user
   ↓
3. Tạo UserModel với role = staff
   ↓
4. Lưu vào Firestore collection 'users'
   ↓
5. Staff có thể đăng nhập vào Staff app
```

---

## Kết luận

Admin Role sử dụng:
- **Firestore Streams**: Để cập nhật menu, orders, statistics real-time
- **Freezed Models**: Để đảm bảo immutability khi CRUD
- **JSON Serialization**: Để convert models ↔ Firestore documents
- **Statistics Calculation**: Tính toán real-time từ orders stream
- **User Management**: Tạo staff accounts với helper class

Tất cả thay đổi từ Admin đều real-time sync đến Customer và Staff app. Dashboard tự động cập nhật khi có đơn mới hoặc status thay đổi.


