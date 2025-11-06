# 📱 Tài liệu Chi tiết - Customer Role (Khách hàng)

## Mục lục
1. [Tổng quan về Customer Role](#tổng-quan)
2. [Cấu trúc File và Thư mục](#cấu-trúc-file)
3. [Giải thích File .g và .freeze](#file-g-và-freeze)
4. [Cơ chế Real-time](#cơ-chế-real-time)
5. [Chi tiết từng Chức năng và Hàm](#chi-tiết-chức-năng)

---

## Tổng quan {#tổng-quan}

Customer Role là ứng dụng dành cho khách hàng của nhà hàng, cho phép:
- Xem thực đơn món ăn
- Thêm món vào giỏ hàng
- Đặt món và theo dõi trạng thái đơn hàng real-time
- Xem lịch sử đơn hàng
- Hủy đơn hàng (khi còn pending)

**Entry Point:** `lib/main_customer.dart`

---

## Cấu trúc File và Thư mục {#cấu-trúc-file}

```
lib/
├── main_customer.dart              # Entry point cho Customer app
├── customer/
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart          # Màn hình đăng nhập
│   │   │   └── register_screen.dart       # Màn hình đăng ký
│   │   ├── home/
│   │   │   └── home_screen.dart           # Màn hình chính (Bottom Nav)
│   │   ├── menu/
│   │   │   ├── menu_screen.dart           # Hiển thị thực đơn
│   │   │   └── menu_item_detail_screen.dart # Chi tiết món ăn
│   │   ├── cart/
│   │   │   └── cart_screen.dart           # Giỏ hàng và đặt món
│   │   ├── orders/
│   │   │   ├── orders_screen.dart         # Lịch sử đơn hàng
│   │   │   └── order_tracking_screen.dart  # Theo dõi đơn hàng real-time
│   │   └── profile/
│   │       └── profile_screen.dart         # Thông tin tài khoản
│   └── providers/
│       └── cart_provider.dart             # State management cho giỏ hàng
└── shared/                                # Code dùng chung
    ├── models/                            # Data models
    ├── services/                          # Business logic
    └── providers/                         # Riverpod providers
```

---

## Giải thích File .g và .freeze {#file-g-và-freeze}

### File .freezed.dart

**Mục đích:** File được tự động generate bởi package `freezed` để tạo immutable classes với các tính năng:
- Immutability (không thể thay đổi sau khi tạo)
- Pattern matching
- CopyWith method
- Equality comparison

**Ví dụ:** `lib/shared/models/user_model.freezed.dart`

```dart
// File này được generate tự động từ user_model.dart
// Chứa implementation của các mixin và methods:
// - _$UserModel: Base class với getters
// - copyWith: Tạo bản copy với các field được thay đổi
// - toString, hashCode, ==: Equality methods
```

**Cách generate:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Sử dụng ở đâu:**
- Được import tự động trong file model gốc: `part 'user_model.freezed.dart';`
- Không cần import trực tiếp trong code, chỉ cần import file model gốc

**Ví dụ sử dụng:**
```dart
// Trong user_model.dart
@freezed
class UserModel with _$UserModel {
  const factory UserModel({...}) = _UserModel;
}

// Sử dụng trong code
final user = UserModel(uid: '123', email: 'test@test.com', ...);
final updatedUser = user.copyWith(displayName: 'New Name'); // Tạo copy mới
```

### File .g.dart

**Mục đích:** File được tự động generate bởi package `json_serializable` để:
- Serialize object thành JSON (`toJson()`)
- Deserialize JSON thành object (`fromJson()`)

**Ví dụ:** `lib/shared/models/user_model.g.dart`

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      uid: json['uid'] as String,
      email: json['email'] as String,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      // ...
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'role': _$UserRoleEnumMap[instance.role]!,
      // ...
    };
```

**Sử dụng ở đâu:**
- Khi lưu data vào Firestore: `user.toJson()`
- Khi đọc data từ Firestore: `UserModel.fromJson(doc.data()!)`
- Trong `FirestoreService` khi convert giữa model và Firestore document

**Ví dụ sử dụng:**
```dart
// Lưu vào Firestore
await _firestore.collection('users').doc(uid).set(user.toJson());

// Đọc từ Firestore
final doc = await _firestore.collection('users').doc(uid).get();
final user = UserModel.fromJson(doc.data()!);
```

---

## Cơ chế Real-time {#cơ-chế-real-time}

### Tổng quan

Hệ thống sử dụng **Firestore Streams** kết hợp với **Riverpod StreamProvider** để cập nhật real-time:

```
Firestore Database
    ↓ (Stream)
FirestoreService.getOrdersByUser()
    ↓ (Stream<List<Order>>)
Riverpod StreamProvider
    ↓ (ref.watch)
UI Widget tự động rebuild
```

### Cơ chế hoạt động

#### 1. Firestore Streams

**Định nghĩa:** Firestore cung cấp `.snapshots()` để lắng nghe thay đổi real-time

**Code định nghĩa:** `lib/shared/services/firestore_service.dart`

```113:120:lib/shared/services/firestore_service.dart
  Stream<List<Order>> getOrdersByUser(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }
```

**Giải thích:**
- `collection('orders')`: Truy cập collection orders
- `where('userId', isEqualTo: userId)`: Lọc đơn hàng của user hiện tại
- `orderBy('createdAt', descending: true)`: Sắp xếp theo thời gian (mới nhất trước)
- `.snapshots()`: Tạo stream lắng nghe thay đổi
- `.map(...)`: Convert Firestore documents thành Order objects

**Khi nào cập nhật:**
- Khi staff cập nhật trạng thái đơn hàng
- Khi có đơn hàng mới được tạo
- Khi đơn hàng bị hủy

#### 2. Riverpod StreamProvider

**Định nghĩa:** `lib/shared/providers/firestore_provider.dart`

```37:40:lib/shared/providers/firestore_provider.dart
final userOrdersProvider = StreamProvider.family<List<Order>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getOrdersByUser(userId);
});
```

**Giải thích:**
- `StreamProvider.family`: Provider nhận tham số (userId)
- `ref.watch(firestoreServiceProvider)`: Lấy FirestoreService instance
- Return stream từ FirestoreService

**Sử dụng trong UI:** `lib/customer/screens/orders/orders_screen.dart`

```dart
final ordersAsync = ref.watch(userOrdersProvider(currentUser.uid));

ordersAsync.when(
  data: (orders) => ListView(...),  // Hiển thị danh sách đơn
  loading: () => CircularProgressIndicator(),  // Đang tải
  error: (e, _) => ErrorView(error: e),  // Lỗi
);
```

**Luồng cập nhật real-time:**

```
1. Staff cập nhật order status trong Firestore
   ↓
2. Firestore gửi update event qua stream
   ↓
3. FirestoreService.getOrdersByUser() nhận snapshot mới
   ↓
4. StreamProvider tự động emit data mới
   ↓
5. UI widget rebuild với data mới (không cần refresh)
```

### Ví dụ cụ thể: Theo dõi đơn hàng

**File:** `lib/customer/screens/orders/order_tracking_screen.dart`

```dart
// Widget lắng nghe thay đổi của một đơn hàng cụ thể
final orderAsync = ref.watch(orderProvider(orderId));

orderAsync.when(
  data: (order) {
    // UI tự động cập nhật khi order.status thay đổi
    switch (order.status) {
      case OrderStatus.pending:
        return Text('Đang chờ xác nhận');
      case OrderStatus.preparing:
        return Text('Đang chuẩn bị');
      case OrderStatus.ready:
        return Text('Sẵn sàng phục vụ');
      // ...
    }
  },
  // ...
);
```

**Provider định nghĩa:** `lib/shared/providers/firestore_provider.dart`

```dart
final orderProvider = StreamProvider.family<Order, String>((ref, orderId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getOrder(orderId);
});
```

---

## Chi tiết từng Chức năng và Hàm {#chi-tiết-chức-năng}

### 1. Đăng nhập / Đăng ký

#### 1.1. Login Screen

**File:** `lib/customer/screens/auth/login_screen.dart`

**Chức năng:** Cho phép customer đăng nhập bằng email/password

**Hàm chính:**

```dart
Future<void> _signIn() async {
  // Gọi AuthService.signInWithEmailAndPassword()
  final user = await authService.signInWithEmailAndPassword(
    email: _emailController.text,
    password: _passwordController.text,
  );
  
  // Nếu thành công, authStateProvider tự động cập nhật
  // UI tự động chuyển sang HomeScreen
}
```

**Code lấy từ đâu:**
- `AuthService`: `lib/shared/services/auth_service.dart`
- `authStateProvider`: `lib/shared/providers/auth_provider.dart`

**Code dùng ở đâu:**
- Khi user nhấn nút "Đăng nhập"
- Auth state được watch trong `main_customer.dart`:

```37:38:lib/main_customer.dart
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
```

#### 1.2. Register Screen

**File:** `lib/customer/screens/auth/register_screen.dart`

**Chức năng:** Tạo tài khoản mới cho customer

**Hàm chính:**

```dart
Future<void> _register() async {
  final user = await authService.registerWithEmailAndPassword(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
    role: UserRole.customer,  // Mặc định là customer
  );
}
```

**Code lấy từ đâu:**
- `AuthService.registerWithEmailAndPassword()`: `lib/shared/services/auth_service.dart`

```51:83:lib/shared/services/auth_service.dart
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(user.toJson());

        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
```

**Giải thích:**
1. Tạo user trong Firebase Auth
2. Tạo UserModel object với role = customer
3. Lưu vào Firestore collection 'users'
4. Sử dụng `user.toJson()` để serialize (từ file .g.dart)

---

### 2. Xem Thực đơn

#### 2.1. Menu Screen

**File:** `lib/customer/screens/menu/menu_screen.dart`

**Chức năng:** Hiển thị danh sách categories và menu items

**Hàm chính:**

```dart
@override
Widget build(BuildContext context) {
  // Lấy danh sách categories từ provider
  final categoriesAsync = ref.watch(menuCategoriesProvider);
  
  // Lấy số lượng items trong giỏ hàng
  final cartItemCount = ref.watch(cartItemCountProvider);
  
  return Scaffold(
    // Hiển thị categories và menu items
  );
}
```

**Code lấy từ đâu:**
- `menuCategoriesProvider`: `lib/shared/providers/firestore_provider.dart`

```10:13:lib/shared/providers/firestore_provider.dart
final menuCategoriesProvider = StreamProvider<List<MenuCategory>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMenuCategories();
});
```

- `FirestoreService.getMenuCategories()`: `lib/shared/services/firestore_service.dart`

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

**Giải thích:**
- `collection('menuCategories')`: Truy cập collection menuCategories
- `orderBy('priority')`: Sắp xếp theo priority
- `.snapshots()`: Real-time stream
- `.map(...)`: Convert Firestore docs thành MenuCategory objects
- `MenuCategory.fromJson()`: Deserialize từ JSON (sử dụng file .g.dart)

**Code dùng ở đâu:**
- Hiển thị trong `MenuScreen` để user chọn category
- Real-time cập nhật khi admin thêm/sửa/xóa category

#### 2.2. Menu Items theo Category

**Hàm:**

```dart
// Lấy menu items theo categoryId
final menuItemsAsync = ref.watch(
  availableMenuItemsProvider(_selectedCategoryId)
);
```

**Code lấy từ đâu:**
- `availableMenuItemsProvider`: `lib/shared/providers/firestore_provider.dart`

```21:24:lib/shared/providers/firestore_provider.dart
final availableMenuItemsProvider = StreamProvider.family<List<MenuItem>, String?>((ref, categoryId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAvailableMenuItems(categoryId: categoryId);
});
```

- `FirestoreService.getAvailableMenuItems()`: `lib/shared/services/firestore_service.dart`

```52:64:lib/shared/services/firestore_service.dart
  Stream<List<MenuItem>> getAvailableMenuItems({String? categoryId}) {
    Query query = _firestore
        .collection('menuItems')
        .where('isAvailable', isEqualTo: true);
    
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => MenuItem.fromJson({...doc.data() as Map<String, dynamic>, 'itemId': doc.id}))
        .toList());
  }
```

**Giải thích:**
- Chỉ lấy items có `isAvailable == true`
- Nếu có categoryId, lọc thêm theo category
- Real-time cập nhật khi admin toggle availability

---

### 3. Quản lý Giỏ hàng

#### 3.1. Cart Provider

**File:** `lib/customer/providers/cart_provider.dart`

**Chức năng:** Quản lý state của giỏ hàng (thêm/xóa/sửa)

**Hàm chính:**

```17:29:lib/customer/providers/cart_provider.dart
  void addItem(MenuItem item) {
    final existingIndex = state.indexWhere((cartItem) => cartItem.menuItem.itemId == item.itemId);
    
    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        CartItem(menuItem: state[existingIndex].menuItem, quantity: state[existingIndex].quantity + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, CartItem(menuItem: item, quantity: 1)];
    }
  }
```

**Giải thích:**
- Tìm item đã có trong giỏ
- Nếu có: tăng quantity lên 1
- Nếu chưa có: thêm mới với quantity = 1
- Tạo state mới (immutable)

**Code dùng ở đâu:**
- `MenuScreen`: Khi user nhấn "Thêm vào giỏ"
- `MenuItemDetailScreen`: Khi user chọn số lượng và thêm

**Hàm khác:**

```31:33:lib/customer/providers/cart_provider.dart
  void removeItem(String itemId) {
    state = state.where((item) => item.menuItem.itemId != itemId).toList();
  }
```

```35:49:lib/customer/providers/cart_provider.dart
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final existingIndex = state.indexWhere((item) => item.menuItem.itemId == itemId);
    if (existingIndex >= 0) {
      state = [
        ...state.sublist(0, existingIndex),
        CartItem(menuItem: state[existingIndex].menuItem, quantity: quantity),
        ...state.sublist(existingIndex + 1),
      ];
    }
  }
```

```63:69:lib/customer/providers/cart_provider.dart
  List<OrderItem> toOrderItems() {
    return state.map((cartItem) => OrderItem(
      itemId: cartItem.menuItem.itemId,
      name: cartItem.menuItem.name,
      price: cartItem.menuItem.price,
      quantity: cartItem.quantity,
    )).toList();
  }
```

**Giải thích `toOrderItems()`:**
- Convert CartItem thành OrderItem
- OrderItem được định nghĩa trong `OrderModel` (sử dụng freezed)
- Dùng khi tạo Order từ giỏ hàng

---

### 4. Đặt món

#### 4.1. Cart Screen

**File:** `lib/customer/screens/cart/cart_screen.dart`

**Chức năng:** Hiển thị giỏ hàng và form đặt món

**Hàm chính:**

```33:80:lib/customer/screens/cart/cart_screen.dart
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final uuid = const Uuid();
      final order = Order(
        orderId: uuid.v4(),
        userId: user.uid,
        tableNumber: int.parse(_tableNumberController.text),
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        items: ref.read(cartProvider.notifier).toOrderItems(),
        totalAmount: ref.read(cartTotalProvider),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final firestoreService = FirestoreService();
      final orderId = await firestoreService.createOrder(order);

      if (mounted) {
        ref.read(cartProvider.notifier).clear();
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: orderId),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
```

**Giải thích từng bước:**

1. **Validate form:** Kiểm tra table number đã nhập
2. **Lấy user hiện tại:** Từ `currentUserProvider`
3. **Tạo Order object:**
   - `orderId`: UUID v4 (unique)
   - `userId`: UID của user hiện tại
   - `status`: OrderStatus.pending (mặc định)
   - `items`: Convert từ cart (sử dụng `toOrderItems()`)
   - `totalAmount`: Tổng tiền từ cart
4. **Lưu vào Firestore:** `firestoreService.createOrder(order)`
5. **Xóa giỏ hàng:** `cartProvider.notifier.clear()`
6. **Chuyển màn hình:** Đến OrderTrackingScreen để theo dõi

**Code lấy từ đâu:**
- `FirestoreService.createOrder()`: `lib/shared/services/firestore_service.dart`

```100:103:lib/shared/services/firestore_service.dart
  Future<String> createOrder(Order order) async {
    final docRef = await _firestore.collection('orders').add(Order.toFirestore(order));
    return docRef.id;
  }
```

**Giải thích:**
- `Order.toFirestore(order)`: Convert Order thành Map để lưu vào Firestore
- `collection('orders').add(...)`: Thêm document mới vào collection
- Return document ID

**Code dùng ở đâu:**
- Khi user nhấn nút "Đặt món" trong CartScreen
- Sau khi đặt thành công, real-time update đến Staff app và Admin dashboard

---

### 5. Theo dõi Đơn hàng Real-time

#### 5.1. Order Tracking Screen

**File:** `lib/customer/screens/orders/order_tracking_screen.dart`

**Chức năng:** Hiển thị trạng thái đơn hàng và cập nhật real-time

**Hàm chính:**

```dart
@override
Widget build(BuildContext context) {
  final orderAsync = ref.watch(orderProvider(orderId));
  
  return orderAsync.when(
    data: (order) {
      // Hiển thị trạng thái đơn hàng
      // UI tự động cập nhật khi order.status thay đổi
    },
    loading: () => LoadingIndicator(),
    error: (e, _) => ErrorView(error: e),
  );
}
```

**Code lấy từ đâu:**
- `orderProvider`: Provider định nghĩa trong `firestore_provider.dart` (cần check)

**Cơ chế real-time:**
- `FirestoreService.getOrder()` trả về Stream<Order>
- Mỗi khi staff cập nhật status, Firestore emit event mới
- StreamProvider tự động rebuild UI

**Code dùng ở đâu:**
- Sau khi đặt món thành công
- Khi user xem chi tiết đơn hàng trong OrdersScreen

#### 5.2. Orders Screen (Lịch sử)

**File:** `lib/customer/screens/orders/orders_screen.dart`

**Chức năng:** Hiển thị lịch sử đơn hàng với filter

**Hàm chính:**

```dart
@override
Widget build(BuildContext context) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const SizedBox();
  
  final ordersAsync = ref.watch(userOrdersProvider(user.uid));
  
  return ordersAsync.when(
    data: (orders) {
      // Filter orders theo status
      final filteredOrders = _filterOrders(orders, _selectedFilter);
      // Hiển thị danh sách
    },
    // ...
  );
}
```

**Code lấy từ đâu:**
- `userOrdersProvider`: `lib/shared/providers/firestore_provider.dart`

```37:40:lib/shared/providers/firestore_provider.dart
final userOrdersProvider = StreamProvider.family<List<Order>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getOrdersByUser(userId);
});
```

**Giải thích:**
- StreamProvider.family nhận userId làm tham số
- Trả về Stream<List<Order>> từ FirestoreService
- Real-time cập nhật khi có đơn mới hoặc status thay đổi

**Filter function:**

```dart
List<Order> _filterOrders(List<Order> orders, String filter) {
  switch (filter) {
    case 'active':
      return orders.where((o) => 
        o.status != OrderStatus.completed && 
        o.status != OrderStatus.cancelled
      ).toList();
    case 'completed':
      return orders.where((o) => o.status == OrderStatus.completed).toList();
    case 'cancelled':
      return orders.where((o) => o.status == OrderStatus.cancelled).toList();
    default:
      return orders;
  }
}
```

---

### 6. Hủy Đơn hàng

**Chức năng:** Hủy đơn hàng khi còn pending

**Hàm:**

```dart
Future<void> _cancelOrder(String orderId) async {
  if (order.status != OrderStatus.pending) {
    // Chỉ cho phép hủy khi pending
    return;
  }
  
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
- Chỉ cho phép hủy khi status = pending
- Cập nhật status thành cancelled
- Real-time update đến Staff và Admin

---

## Tóm tắt Luồng Dữ liệu

### Luồng Đặt món:

```
1. Customer chọn món
   ↓ (addItem vào cartProvider)
2. Customer vào giỏ hàng
   ↓ (fill form: table number, notes)
3. Customer nhấn "Đặt món"
   ↓ (createOrder trong Firestore)
4. Firestore emit event mới
   ↓ (Stream update)
5. Staff app nhận đơn mới real-time
6. Admin dashboard cập nhật số liệu
```

### Luồng Theo dõi Đơn:

```
1. Staff cập nhật order status
   ↓ (updateOrderStatus trong Firestore)
2. Firestore emit update event
   ↓ (Stream snapshot mới)
3. Customer app nhận update
   ↓ (orderProvider emit data mới)
4. UI tự động rebuild với status mới
```

---

## Kết luận

Customer Role sử dụng:
- **Freezed & JSON Serializable**: Để tạo immutable models với serialization
- **Firestore Streams**: Để cập nhật real-time
- **Riverpod Providers**: Để quản lý state và streams
- **StateNotifier**: Để quản lý cart state

Tất cả các cập nhật đều real-time, không cần refresh thủ công.


