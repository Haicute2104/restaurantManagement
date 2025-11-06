# 👨‍🍳 Tài liệu Chi tiết - Staff Role (Nhân viên)

## Mục lục
1. [Tổng quan về Staff Role](#tổng-quan)
2. [Cấu trúc File và Thư mục](#cấu-trúc-file)
3. [Giải thích File .g và .freeze](#file-g-và-freeze)
4. [Cơ chế Real-time](#cơ-chế-real-time)
5. [Chi tiết từng Chức năng và Hàm](#chi-tiết-chức-năng)

---

## Tổng quan {#tổng-quan}

Staff Role là ứng dụng dành cho nhân viên nhà bếp/phục vụ, cho phép:
- Xem đơn hàng mới real-time (Kitchen Display System)
- Cập nhật trạng thái đơn hàng (pending → confirmed → preparing → ready → completed)
- Filter đơn hàng theo trạng thái
- Xem thông tin chi tiết đơn hàng (bàn, món ăn, ghi chú)

**Entry Point:** `lib/main_staff.dart`

---

## Cấu trúc File và Thư mục {#cấu-trúc-file}

```
lib/
├── main_staff.dart                      # Entry point cho Staff app
├── staff/
│   ├── screens/
│   │   ├── auth/
│   │   │   └── staff_login_screen.dart   # Màn hình đăng nhập Staff
│   │   ├── home/
│   │   │   └── staff_home_screen.dart   # Màn hình chính (Bottom Nav)
│   │   ├── orders/
│   │   │   └── kitchen_display_screen.dart # Kitchen Display System
│   │   └── profile/
│   │       └── staff_profile_screen.dart # Thông tin tài khoản
└── shared/                              # Code dùng chung
    ├── models/                          # Data models (Order, OrderItem)
    ├── services/                         # FirestoreService
    └── providers/                        # Riverpod providers
```

---

## Giải thích File .g và .freeze {#file-g-và-freeze}

### File .freezed.dart

**Mục đích:** Tương tự như Customer role, file được generate bởi `freezed` để tạo immutable classes.

**Sử dụng trong Staff Role:**

Staff role chủ yếu làm việc với `Order` và `OrderItem` models:

```dart
// Order model sử dụng freezed
@freezed
class Order with _$Order {
  const factory Order({
    required String orderId,
    required String userId,
    required int tableNumber,
    required DateTime createdAt,
    required OrderStatus status,
    required List<OrderItem> items,
    required double totalAmount,
    String? notes,
  }) = _Order;
}
```

**Ví dụ sử dụng:**

```dart
// Trong KitchenDisplayScreen
final order = Order(...);

// Copy với status mới (immutable)
final updatedOrder = order.copyWith(status: OrderStatus.confirmed);
```

**Code lấy từ đâu:**
- `lib/shared/models/order_model.dart` - Định nghĩa Order model
- `lib/shared/models/order_model.freezed.dart` - Generated file (không sửa trực tiếp)

**Code dùng ở đâu:**
- `kitchen_display_screen.dart`: Hiển thị và cập nhật orders
- `firestore_service.dart`: Convert Order ↔ Firestore document

### File .g.dart

**Mục đích:** Serialize/Deserialize Order objects với JSON

**Sử dụng trong Staff Role:**

```dart
// Convert Order thành Map để lưu Firestore
Map<String, dynamic> orderMap = order.toJson();

// Convert Firestore document thành Order
Order order = Order.fromJson(doc.data()!);
```

**Code lấy từ đâu:**
- `lib/shared/models/order_model.g.dart` - Generated file

**Code dùng ở đâu:**
- `FirestoreService.updateOrderStatus()`: Cập nhật order trong Firestore
- `FirestoreService.getActiveOrders()`: Đọc orders từ Firestore

---

## Cơ chế Real-time {#cơ-chế-real-time}

### Tổng quan

Staff app sử dụng **Firestore Streams** để nhận đơn hàng mới và cập nhật real-time:

```
Customer đặt món
    ↓ (createOrder trong Firestore)
Firestore emit event mới
    ↓ (Stream update)
Staff app nhận đơn mới ngay lập tức
    ↓ (activeOrdersProvider)
UI tự động hiển thị đơn mới
```

### Cơ chế hoạt động

#### 1. Active Orders Stream

**Định nghĩa:** `lib/shared/services/firestore_service.dart`

```122:134:lib/shared/services/firestore_service.dart
  Stream<List<Order>> getActiveOrders() {
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['pending', 'confirmed', 'preparing', 'ready'])
        // .orderBy('createdAt', descending: false)  // Bỏ để tránh cần index
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
          // Sort in memory instead
          orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return orders;
        });
  }
```

**Giải thích:**
- `where('status', whereIn: [...])`: Chỉ lấy orders có status active (pending, confirmed, preparing, ready)
- `.snapshots()`: Stream lắng nghe thay đổi real-time
- `.map(...)`: Convert Firestore docs thành Order objects
- `orders.sort(...)`: Sắp xếp theo thời gian tạo (cũ nhất trước)

**Khi nào cập nhật:**
- Khi customer đặt món mới (status = pending)
- Khi staff cập nhật status
- Khi order chuyển sang completed/cancelled (tự động biến mất khỏi list)

#### 2. Riverpod StreamProvider

**Định nghĩa:** `lib/shared/providers/firestore_provider.dart`

```27:30:lib/shared/providers/firestore_provider.dart
final activeOrdersProvider = StreamProvider<List<Order>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getActiveOrders();
});
```

**Sử dụng trong UI:** `lib/staff/screens/orders/kitchen_display_screen.dart`

```59:103:lib/staff/screens/orders/kitchen_display_screen.dart
    final ordersAsync = ref.watch(activeOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display System'),
        backgroundColor: AppColors.staffPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            color: Colors.grey[100],
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                _FilterChip(
                  label: 'Đơn mới',
                  isSelected: _selectedFilter == 'pending',
                  onTap: () => setState(() => _selectedFilter = 'pending'),
                  badgeColor: AppColors.statusPending,
                ),
                _FilterChip(
                  label: 'Đang làm',
                  isSelected: _selectedFilter == 'preparing',
                  onTap: () => setState(() => _selectedFilter = 'preparing'),
                  badgeColor: AppColors.statusPreparing,
                ),
                _FilterChip(
                  label: 'Sẵn sàng',
                  isSelected: _selectedFilter == 'ready',
                  onTap: () => setState(() => _selectedFilter = 'ready'),
                  badgeColor: AppColors.statusReady,
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final filteredOrders = _filterOrders(orders);
```

**Luồng cập nhật real-time:**

```
1. Customer đặt món → Firestore tạo order mới với status = pending
   ↓
2. Firestore emit snapshot mới qua stream
   ↓
3. FirestoreService.getActiveOrders() nhận snapshot
   ↓
4. activeOrdersProvider emit List<Order> mới
   ↓
5. KitchenDisplayScreen tự động rebuild với đơn mới
   ↓
6. UI hiển thị đơn mới ngay lập tức (không cần refresh)
```

**Khi Staff cập nhật status:**

```
1. Staff nhấn "XÁC NHẬN" → updateOrderStatus(orderId, confirmed)
   ↓
2. Firestore update document
   ↓
3. Stream emit snapshot mới
   ↓
4. UI tự động cập nhật:
   - Đơn chuyển từ "Đơn mới" sang "Đang làm"
   - Nút "XÁC NHẬN" biến mất, nút "CHUẨN BỊ" xuất hiện
   - Customer app cũng cập nhật real-time
```

---

## Chi tiết từng Chức năng và Hàm {#chi-tiết-chức-năng}

### 1. Đăng nhập Staff

#### 1.1. Staff Login Screen

**File:** `lib/staff/screens/auth/staff_login_screen.dart`

**Chức năng:** Cho phép staff đăng nhập với role staff

**Hàm chính:**

```dart
Future<void> _signIn() async {
  final authService = ref.read(authServiceProvider);
  final user = await authService.signInWithEmailAndPassword(
    email: _emailController.text,
    password: _passwordController.text,
  );
  
  // Kiểm tra role phải là staff hoặc admin
  if (user != null && (user.role == UserRole.staff || user.role == UserRole.admin)) {
    // Đăng nhập thành công
  } else {
    // Hiển thị lỗi: "Tài khoản không phải Staff"
  }
}
```

**Code lấy từ đâu:**
- `AuthService.signInWithEmailAndPassword()`: `lib/shared/services/auth_service.dart`

```13:48:lib/shared/services/auth_service.dart
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        var userData = await getUserData(userCredential.user!.uid);
        
        // Nếu không có data trong Firestore, tạo mới với role customer mặc định
        if (userData == null) {
          userData = UserModel(
            uid: userCredential.user!.uid,
            email: email,
            displayName: userCredential.user!.displayName ?? email.split('@')[0],
            role: UserRole.customer, // Default role
            createdAt: DateTime.now(),
          );
          
          await _firestore
              .collection('users')
              .doc(userData.uid)
              .set(userData.toJson());
        }
        
        return userData;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
```

**Giải thích:**
- Đăng nhập qua Firebase Auth
- Lấy user data từ Firestore collection 'users'
- Nếu chưa có data, tạo mới với role customer (nhưng Staff app sẽ kiểm tra role)

**Code dùng ở đâu:**
- Khi staff nhấn nút "Đăng nhập"
- Auth state được watch trong `main_staff.dart`:

```37:38:lib/main_staff.dart
      home: authState.when(
        data: (user) => user != null ? const StaffHomeScreen() : const StaffLoginScreen(),
```

---

### 2. Kitchen Display System

#### 2.1. Kitchen Display Screen

**File:** `lib/staff/screens/orders/kitchen_display_screen.dart`

**Chức năng:** Hiển thị đơn hàng active và cho phép cập nhật trạng thái

**Hàm chính:**

```58:161:lib/staff/screens/orders/kitchen_display_screen.dart
  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(activeOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display System'),
        backgroundColor: AppColors.staffPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            color: Colors.grey[100],
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                _FilterChip(
                  label: 'Đơn mới',
                  isSelected: _selectedFilter == 'pending',
                  onTap: () => setState(() => _selectedFilter = 'pending'),
                  badgeColor: AppColors.statusPending,
                ),
                _FilterChip(
                  label: 'Đang làm',
                  isSelected: _selectedFilter == 'preparing',
                  onTap: () => setState(() => _selectedFilter = 'preparing'),
                  badgeColor: AppColors.statusPreparing,
                ),
                _FilterChip(
                  label: 'Sẵn sàng',
                  isSelected: _selectedFilter == 'ready',
                  onTap: () => setState(() => _selectedFilter = 'ready'),
                  badgeColor: AppColors.statusReady,
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final filteredOrders = _filterOrders(orders);
                
                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'Chưa có đơn hàng',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Đơn hàng mới sẽ hiện ở đây',
                          style: AppTextStyles.body1.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          '💡 Để test:',
                          style: AppTextStyles.body1,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '1. Mở Customer App\n2. Đặt món\n3. Đơn sẽ hiện ở đây ngay lập tức',
                          style: AppTextStyles.body2.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return _OrderCard(
                      order: filteredOrders[index],
                      backgroundColor: _getOrderColor(filteredOrders[index].status),
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(message: 'Lỗi: $error'),
            ),
          ),
        ],
      ),
    );
  }
```

**Code lấy từ đâu:**
- `activeOrdersProvider`: `lib/shared/providers/firestore_provider.dart`
- Real-time stream từ Firestore

**Giải thích:**
- `ref.watch(activeOrdersProvider)`: Lắng nghe stream của active orders
- `ordersAsync.when(...)`: Xử lý 3 trạng thái: data, loading, error
- `_filterOrders(orders)`: Filter theo status đã chọn
- UI tự động rebuild khi có đơn mới hoặc status thay đổi

#### 2.2. Filter Orders

**Hàm:**

```29:40:lib/staff/screens/orders/kitchen_display_screen.dart
  List<Order> _filterOrders(List<Order> orders) {
    switch (_selectedFilter) {
      case 'pending':
        return orders.where((o) => o.status == OrderStatus.pending).toList();
      case 'preparing':
        return orders.where((o) => o.status == OrderStatus.preparing).toList();
      case 'ready':
        return orders.where((o) => o.status == OrderStatus.ready).toList();
      default:
        return orders;
    }
  }
```

**Giải thích:**
- Filter orders theo status đã chọn
- Return danh sách orders đã được lọc
- Dùng trong UI để hiển thị orders theo tab

---

### 3. Cập nhật Trạng thái Đơn hàng

#### 3.1. Update Order Status

**Hàm:** `_updateOrderStatus()` trong `_OrderCard` widget

**File:** `lib/staff/screens/orders/kitchen_display_screen.dart`

```219:236:lib/staff/screens/orders/kitchen_display_screen.dart
  Future<void> _updateOrderStatus(BuildContext context, WidgetRef ref, OrderStatus newStatus) async {
    try {
      final firestoreService = FirestoreService();
      await firestoreService.updateOrderStatus(order.orderId, newStatus);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
```

**Code lấy từ đâu:**
- `FirestoreService.updateOrderStatus()`: `lib/shared/services/firestore_service.dart`

```144:148:lib/shared/services/firestore_service.dart
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
    });
  }
```

**Giải thích:**
- Cập nhật field `status` trong Firestore document
- `status.name`: Convert enum thành string (ví dụ: `OrderStatus.pending` → `"pending"`)
- Firestore tự động emit update event qua stream
- UI tự động rebuild với status mới

**Code dùng ở đâu:**
- Khi staff nhấn các nút:
  - "XÁC NHẬN" (pending → confirmed)
  - "CHUẨN BỊ" (confirmed → preparing)
  - "SẴN SÀNG" (preparing → ready)
  - "ĐÃ PHỤC VỤ" (ready → completed)

#### 3.2. Order Card với Action Buttons

**File:** `lib/staff/screens/orders/kitchen_display_screen.dart`

**Hàm:** `_OrderCard` widget hiển thị order và action buttons

```365:432:lib/staff/screens/orders/kitchen_display_screen.dart
            // Action buttons
            Row(
              children: [
                if (order.status == OrderStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(context, ref, OrderStatus.confirmed),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                      ),
                      child: const Text('XÁC NHẬN', style: AppTextStyles.button),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.confirmed) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(context, ref, OrderStatus.preparing),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.staffPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                      ),
                      child: const Text('CHUẨN BỊ', style: AppTextStyles.button),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.preparing) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(context, ref, OrderStatus.ready),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusReady,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                      ),
                      child: const Text('SẴN SÀNG', style: AppTextStyles.button),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.ready) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(context, ref, OrderStatus.completed),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusCompleted,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                      ),
                      child: const Text('ĐÃ PHỤC VỤ', style: AppTextStyles.button),
                    ),
                  ),
                ],
              ],
            ),
```

**Giải thích:**
- Hiển thị button tương ứng với status hiện tại
- Mỗi button chuyển order sang status tiếp theo
- UI tự động cập nhật sau khi update (do stream)

**Luồng Status:**

```
pending (Đơn mới)
  ↓ [XÁC NHẬN]
confirmed (Đã xác nhận)
  ↓ [CHUẨN BỊ]
preparing (Đang chuẩn bị)
  ↓ [SẴN SÀNG]
ready (Sẵn sàng phục vụ)
  ↓ [ĐÃ PHỤC VỤ]
completed (Hoàn thành)
  → Tự động biến mất khỏi activeOrdersProvider
```

---

### 4. Hiển thị Chi tiết Đơn hàng

#### 4.1. Order Card Layout

**File:** `lib/staff/screens/orders/kitchen_display_screen.dart`

**Hàm:** `_OrderCard` widget hiển thị thông tin đơn hàng

```240:363:lib/staff/screens/orders/kitchen_display_screen.dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAgo = Formatters.timeAgo(order.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: order.status == OrderStatus.pending ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        side: BorderSide(
          color: backgroundColor,
          width: order.status == OrderStatus.pending ? 3 : 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          color: order.status == OrderStatus.pending 
              ? backgroundColor.withOpacity(0.1) 
              : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Text(
                    'BÀN ${order.tableNumber}',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo,
                      style: AppTextStyles.body1.copyWith(
                        color: order.status == OrderStatus.pending ? Colors.red : Colors.grey[600],
                        fontWeight: order.status == OrderStatus.pending ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      Formatters.time(order.createdAt),
                      style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            // Order items
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: backgroundColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.body1.copyWith(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                )),
            // Notes
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GHI CHÚ:',
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.notes!,
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.red[900],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
```

**Giải thích:**
- Hiển thị table number, thời gian đặt, danh sách món ăn
- Highlight đơn pending với màu sắc và elevation cao hơn
- Hiển thị ghi chú nếu có (màu đỏ để nổi bật)
- Mỗi item hiển thị quantity và tên món

**Code lấy từ đâu:**
- `Formatters.timeAgo()`: Format thời gian relative (ví dụ: "2 phút trước")
- `Formatters.time()`: Format thời gian cụ thể (ví dụ: "14:30")
- `order.items`: List OrderItem từ Order model

---

## Tóm tắt Luồng Dữ liệu

### Luồng Nhận Đơn Mới:

```
1. Customer đặt món trong Customer app
   ↓ (createOrder trong Firestore)
2. Firestore tạo document mới với status = pending
   ↓ (Stream emit snapshot mới)
3. activeOrdersProvider nhận update
   ↓ (ref.watch trong KitchenDisplayScreen)
4. UI tự động hiển thị đơn mới
   ↓ (Pending orders được highlight)
5. Staff thấy đơn mới ngay lập tức
```

### Luồng Cập nhật Status:

```
1. Staff nhấn "XÁC NHẬN" (pending → confirmed)
   ↓ (updateOrderStatus trong Firestore)
2. Firestore update document
   ↓ (Stream emit update event)
3. activeOrdersProvider nhận update
   ↓ (UI rebuild)
4. Staff app: Đơn chuyển sang tab "Đang làm"
   Customer app: Status cập nhật real-time
   Admin dashboard: Số liệu cập nhật
```

### Luồng Hoàn thành Đơn:

```
1. Staff nhấn "ĐÃ PHỤC VỤ" (ready → completed)
   ↓ (updateOrderStatus)
2. Firestore update status = completed
   ↓ (Stream filter)
3. Order không còn trong activeOrdersProvider
   ↓ (where('status', whereIn: [...]))
4. Order tự động biến mất khỏi Kitchen Display
   ↓ (Chỉ hiển thị active orders)
5. Cloud Function onOrderCompleted trigger
   ↓ (functions/index.js)
6. Tự động cập nhật dailyReports và itemReports
```

---

## Kết luận

Staff Role sử dụng:
- **Firestore Streams**: Để nhận đơn hàng mới và cập nhật real-time
- **Riverpod StreamProvider**: Để quản lý stream trong UI
- **Order Model (Freezed)**: Để đảm bảo immutability
- **Status Workflow**: Pending → Confirmed → Preparing → Ready → Completed

Tất cả cập nhật đều real-time, không cần refresh thủ công. Khi staff cập nhật status, customer và admin đều thấy ngay lập tức.


