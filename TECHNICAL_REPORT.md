# 📋 Báo cáo kỹ thuật - Restaurant Management System

## 📁 Cấu trúc thư mục và chức năng

### 1. `/lib/` - Thư mục mã nguồn chính

#### 1.1. `/lib/shared/` - Code dùng chung

##### `/lib/shared/models/`
Chứa các data models (19 files)

**Chức năng:** Định nghĩa cấu trúc dữ liệu cho toàn bộ app

| File | Chức năng | Thuộc tính chính |
|------|-----------|------------------|
| `order_model.dart` | Model đơn hàng | orderId, userId, status, items[], totalAmount, tableNumber, createdAt |
| `order_item_model.dart` | Model món trong đơn | itemId, name, price, quantity |
| `order_status_enum.dart` | Enum trạng thái đơn | pending, confirmed, preparing, ready, completed, cancelled |
| `menu_item_model.dart` | Model món ăn | itemId, name, categoryId, price, imageUrl, isAvailable |
| `menu_category_model.dart` | Model danh mục | categoryId, name, priority |
| `user_model.dart` | Model người dùng | uid, email, role, displayName |
| `user_role_enum.dart` | Enum vai trò | customer, staff, admin |
| `daily_report_model.dart` | Model báo cáo ngày | date, totalRevenue, totalOrders, hourlyRevenue, itemSalesCount |

**Luồng sử dụng:**
```
1. Firestore document → Model.fromFirestore() → Dart Object
2. Dart Object → Model.toFirestore() → Firestore document
3. Models được dùng trong UI, Services, Providers
```

##### `/lib/shared/services/`

**`firestore_service.dart`** - Service quản lý Firestore
```dart
Chức năng:
- CRUD operations cho tất cả collections
- Real-time streams cho orders, menu
- Query và filter dữ liệu
- Tính toán thống kê

Methods chính:
// Menu
- getMenuCategories() → Stream<List<MenuCategory>>
- getMenuItems() → Stream<List<MenuItem>>
- addMenuItem(), updateMenuItem(), deleteMenuItem()

// Orders
- createOrder(Order) → Future<String>
- getActiveOrders() → Stream<List<Order>>
- getAllOrders() → Stream<List<Order>>
- getOrdersByUser(userId) → Stream<List<Order>>
- updateOrderStatus(orderId, status) → Future<void>

// Statistics
- streamMonthlyStatistics(year, month) → Stream<Map>
- streamDailyStatistics(date) → Stream<Map>
```

**`auth_service.dart`** - Service xác thực
```dart
Chức năng:
- Đăng ký/đăng nhập Firebase Auth
- Quản lý session
- Lấy thông tin user từ Firestore

Methods chính:
- signInWithEmailPassword(email, pass) → Future<User?>
- signUpWithEmailPassword(email, pass, role) → Future<User?>
- signOut() → Future<void>
- getCurrentUser() → User?
- getUserRole(uid) → Future<String?>
```

##### `/lib/shared/providers/`

**`firestore_provider.dart`** - Riverpod providers
```dart
Chức năng: Provide Firestore data cho UI (reactive)

Providers:
- firestoreServiceProvider → Provider<FirestoreService>
- menuCategoriesProvider → StreamProvider<List<MenuCategory>>
- menuItemsProvider → StreamProvider<List<MenuItem>>
- activeOrdersProvider → StreamProvider<List<Order>>
- allOrdersProvider → StreamProvider<List<Order>>
- userOrdersProvider(userId) → StreamProvider<List<Order>>
```

**`auth_provider.dart`** - Auth state management
```dart
Chức năng: Quản lý trạng thái authentication

Providers:
- authStateProvider → StreamProvider<User?>
- currentUserProvider → Provider<User?>
```

##### `/lib/shared/widgets/`

| Widget | Chức năng |
|--------|-----------|
| `loading_indicator.dart` | Hiển thị loading spinner |
| `error_view.dart` | Hiển thị lỗi với message |

##### `/lib/shared/utils/`

**`constants.dart`** - Hằng số toàn app
```dart
Classes:
- AppConstants: minPasswordLength, maxTableNumber, timeouts
- AppColors: màu sắc cho 3 apps, status colors
- AppTextStyles: heading1-3, body1-2, caption, button
- AppSpacing: xs, sm, md, lg, xl, xxl
- AppBorderRadius: sm, md, lg, xl, round
```

**`validators.dart`** - Validate input
```dart
Functions:
- validateEmail(email) → String?
- validatePassword(password) → String?
- validateTableNumber(number) → String?
```

**`formatters.dart`** - Format dữ liệu hiển thị
```dart
Functions:
- currency(amount) → "100,000₫"
- date(DateTime) → "01/01/2024"
- time(DateTime) → "14:30"
- dateTime(DateTime) → "01/01/2024 14:30"
- timeAgo(DateTime) → "5 phút trước"
- orderStatus(status) → "Đang chuẩn bị"
```

---

#### 1.2. `/lib/customer/` - Customer App

##### `/lib/customer/screens/`

**Auth Screens:**
- `login_screen.dart`: Đăng nhập customer
- `register_screen.dart`: Đăng ký tài khoản mới

**Home & Navigation:**
- `home_screen.dart`: Bottom navigation (Menu, Orders, Profile)

**Menu Screens:**
- `menu_screen.dart`: Hiển thị danh sách món ăn theo category
  - Tabs filter theo category
  - Grid/List view món ăn
  - Tap món → Thêm vào giỏ

**Cart Screens:**
- `cart_screen.dart`: Giỏ hàng
  - Hiển thị items đã chọn
  - Tăng/giảm quantity
  - Nhập số bàn
  - Thêm ghi chú
  - Button "Đặt món"

**Orders Screens:**
- `orders_screen.dart`: Lịch sử đơn hàng
  - Filter: Tất cả, Đang xử lý, Hoàn thành, Đã hủy
  - List orders với status badges
  - Tap → OrderTrackingScreen
  
- `order_tracking_screen.dart`: Theo dõi đơn hàng chi tiết
  - Status stepper (5 bước)
  - Thông tin đơn hàng
  - Danh sách món
  - Nút "Hủy đơn" (chỉ pending)

**Profile Screens:**
- `profile_screen.dart`: Thông tin tài khoản, đăng xuất

##### `/lib/customer/providers/`
- `cart_provider.dart`: Quản lý state giỏ hàng (thêm/xóa/update items)

---

#### 1.3. `/lib/staff/` - Staff App

##### `/lib/staff/screens/`

**Auth:**
- `login_screen.dart`: Đăng nhập staff

**Orders:**
- `kitchen_display_screen.dart`: Kitchen Display System
  - Stream orders real-time (pending, confirmed, preparing, ready)
  - Filter tabs: Tất cả, Đơn mới, Đang làm, Sẵn sàng
  - Cards hiển thị đơn hàng với:
    - Số bàn
    - Thời gian đặt (timeAgo)
    - Danh sách món
    - Ghi chú (nếu có)
    - Nút cập nhật trạng thái
  - Flow buttons:
    - pending → "XÁC NHẬN" → confirmed
    - confirmed → "CHUẨN BỊ" → preparing
    - preparing → "SẴN SÀNG" → ready
    - ready → "ĐÃ PHỤC VỤ" → completed

---

#### 1.4. `/lib/admin/` - Admin App

##### `/lib/admin/screens/`

**Home:**
- `admin_home_screen.dart`: Bottom nav (Dashboard, Menu, Orders, Users)

**Dashboard:**
- `dashboard_screen.dart`: Trang tổng quan
  - **Thống kê tháng:**
    - Doanh thu tháng
    - Đơn hoàn thành
    - Đơn đã hủy
    - Tổng đơn hàng
  - **Thống kê hôm nay:**
    - Doanh thu hôm nay
    - Đơn hàng hôm nay
    - Đơn đang xử lý
    - Đơn chờ xác nhận
  - **Biểu đồ doanh thu theo giờ** (BarChart)
  - **Top 5 món bán chạy hôm nay**

**Menu Management:**
- `menu_management_screen.dart`: Quản lý thực đơn
  - Tabs theo categories
  - List món ăn với:
    - Tên, giá
    - Toggle isAvailable
    - Nút Edit, Delete
  - Floating button "Thêm món"
  
- `add_menu_item_screen.dart`: Thêm món mới
  - Form: name, category, price, imageUrl
  - Validate input
  - Save to Firestore

- `edit_menu_item_screen.dart`: Sửa món
  - Load existing data
  - Update fields
  - Save changes

**Orders Management:**
- `orders_management_screen.dart`: Quản lý đơn hàng
  - Filter: Tất cả, Đang xử lý, Hoàn thành, Đã hủy
  - List all orders với status
  - Tap → Xem chi tiết
  - Action: Hủy đơn (nếu cần)

**User Management:**
- `user_management_screen.dart`: Quản lý users
  - List users với role badges
  - Filter by role
  - View user info

##### `/lib/admin/utils/`
- `admin_helpers.dart`: Helper functions cho admin

---

#### 1.5. Entry Points

| File | Chức năng |
|------|-----------|
| `main.dart` | Entry point chính (default → customer) |
| `main_customer.dart` | Entry point Customer App |
| `main_staff.dart` | Entry point Staff App |
| `main_admin.dart` | Entry point Admin App |

**Setup mỗi entry point:**
```dart
1. Initialize Firebase
2. Setup Riverpod ProviderScope
3. Check authentication
4. Route to Login or Home
```

---

### 2. `/android/` - Android Native Code

```
android/
├── app/
│   ├── build.gradle.kts        # Build config
│   ├── google-services.json    # Firebase config
│   └── src/main/
│       ├── AndroidManifest.xml # Permissions, activities
│       └── kotlin/...           # Native Android code
```

---

### 3. `/ios/` - iOS Native Code

```
ios/
├── Runner/
│   ├── Info.plist              # iOS config
│   ├── GoogleService-Info.plist # Firebase config
│   └── AppDelegate.swift       # iOS entry point
```

---

### 4. Root Files

| File | Chức năng |
|------|-----------|
| `pubspec.yaml` | Dependencies, assets config |
| `analysis_options.yaml` | Linter rules |
| `firebase.json` | Firebase project config |
| `firestore.rules` | Firestore security rules |
| `firestore.indexes.json` | Firestore composite indexes |
| `storage.rules` | Firebase Storage rules |

---

## 🔄 Luồng hoạt động chi tiết

### Feature 1: Customer đặt món

```
┌─────────────────────────────────────────────────────────────┐
│ CUSTOMER ĐẶT MÓN                                            │
└─────────────────────────────────────────────────────────────┘

1. Customer mở app
   ├─ main_customer.dart → Initialize Firebase
   ├─ AuthStateProvider check auth
   └─ Route: Chưa login → LoginScreen
              Đã login → HomeScreen

2. Customer đăng nhập/đăng ký
   ├─ LoginScreen → Form email/password
   ├─ Tap "Đăng nhập"
   ├─ AuthService.signInWithEmailPassword()
   │   ├─ Firebase Auth authenticate
   │   ├─ Get user doc from Firestore users/{uid}
   │   └─ Check role = 'customer'
   └─ Success → Navigate HomeScreen

3. Xem menu
   ├─ HomeScreen → MenuScreen (bottom nav index 0)
   ├─ MenuScreen build:
   │   ├─ Watch menuCategoriesProvider (Stream)
   │   ├─ Watch availableMenuItemsProvider(categoryId) (Stream)
   │   └─ UI: TabBar categories + GridView items
   ├─ Firestore auto-updates:
   │   └─ menuItems collection → StreamProvider → UI rebuild
   └─ Display: Tên món, giá, hình ảnh, available badge

4. Thêm món vào giỏ
   ├─ Tap món → Show quantity selector dialog
   ├─ Chọn số lượng → Tap "Thêm vào giỏ"
   ├─ CartProvider.addItem(menuItem, quantity)
   │   ├─ Check item đã có trong cart?
   │   │   ├─ Có: Tăng quantity
   │   │   └─ Không: Thêm mới vào cart
   │   └─ Update state (Riverpod StateProvider)
   └─ Show SnackBar "Đã thêm vào giỏ"

5. Xem giỏ hàng
   ├─ Floating Action Button "Giỏ hàng (n)"
   ├─ Navigate → CartScreen
   ├─ CartScreen build:
   │   ├─ Watch cartProvider
   │   ├─ Display items với +/- quantity buttons
   │   ├─ Calculate totalAmount
   │   └─ Form: tableNumber, notes
   └─ Actions:
       ├─ Increase/Decrease quantity
       ├─ Remove item
       └─ Clear cart

6. Đặt món
   ├─ Tap "Đặt món" button
   ├─ Validate:
   │   ├─ Cart không rỗng?
   │   ├─ TableNumber valid (1-100)?
   │   └─ User đã login?
   ├─ Create Order object:
   │   ├─ orderId: auto-generated
   │   ├─ userId: currentUser.uid
   │   ├─ items: cart.items
   │   ├─ totalAmount: calculated
   │   ├─ tableNumber: input
   │   ├─ notes: input
   │   ├─ status: OrderStatus.pending
   │   └─ createdAt: DateTime.now()
   ├─ FirestoreService.createOrder(order)
   │   ├─ Convert: Order → Map (toFirestore)
   │   ├─ Firestore: orders.add(data)
   │   └─ Return: orderId
   ├─ CartProvider.clear()
   ├─ Show success dialog
   └─ Navigate → OrderTrackingScreen(orderId)

7. Real-time trigger
   ├─ Firestore: new order document created
   ├─ activeOrdersProvider (Staff App) receives update
   └─ Kitchen Display shows new order instantly
```

---

### Feature 2: Staff xử lý đơn hàng

```
┌─────────────────────────────────────────────────────────────┐
│ STAFF XỬ LÝ ĐƠN HÀNG (Kitchen Display)                     │
└─────────────────────────────────────────────────────────────┘

1. Staff mở app
   ├─ main_staff.dart → Initialize Firebase
   └─ Route: Login → KitchenDisplayScreen

2. Kitchen Display Screen
   ├─ Build:
   │   ├─ Watch activeOrdersProvider
   │   │   └─ FirestoreService.getActiveOrders()
   │   │       └─ Query: status IN [pending, confirmed, preparing, ready]
   │   │       └─ Stream → Real-time updates
   │   ├─ Filter state: 'all' | 'pending' | 'preparing' | 'ready'
   │   └─ UI: Filter tabs + ListView orders
   └─ Display mỗi order:
       ├─ Card với border color theo status
       ├─ Bàn số X (large heading)
       ├─ Time ago (5 phút trước) - RED nếu pending
       ├─ List món với quantity badges
       ├─ Ghi chú (highlighted nếu có)
       └─ Action button theo status

3. Flow cập nhật trạng thái
   ┌─────────────────────────────────────────────────────┐
   │ Status: PENDING                                     │
   ├─────────────────────────────────────────────────────┤
   │ - Card: Orange border, elevation 8                  │
   │ - Time: Red, bold                                   │
   │ - Button: "XÁC NHẬN" (Green)                       │
   │                                                     │
   │ Tap "XÁC NHẬN":                                     │
   │   ├─ _updateOrderStatus(context, ref, confirmed)   │
   │   ├─ FirestoreService.updateOrderStatus()          │
   │   │   └─ orders/{orderId}.update({status: confirmed})│
   │   └─ Firestore triggers stream update              │
   │       └─ UI rebuilds với status mới                │
   └─────────────────────────────────────────────────────┘
   
   ┌─────────────────────────────────────────────────────┐
   │ Status: CONFIRMED                                   │
   ├─────────────────────────────────────────────────────┤
   │ - Card: Blue border                                 │
   │ - Button: "CHUẨN BỊ" (Cyan)                        │
   │                                                     │
   │ Tap "CHUẨN BỊ" → status: preparing                 │
   └─────────────────────────────────────────────────────┘
   
   ┌─────────────────────────────────────────────────────┐
   │ Status: PREPARING                                   │
   ├─────────────────────────────────────────────────────┤
   │ - Card: Orange border                               │
   │ - Button: "SẴN SÀNG" (Green)                       │
   │                                                     │
   │ Tap "SẴN SÀNG" → status: ready                     │
   └─────────────────────────────────────────────────────┘
   
   ┌─────────────────────────────────────────────────────┐
   │ Status: READY                                       │
   ├─────────────────────────────────────────────────────┤
   │ - Card: Green border                                │
   │ - Button: "ĐÃ PHỤC VỤ" (Purple)                   │
   │                                                     │
   │ Tap "ĐÃ PHỤC VỤ":                                  │
   │   ├─ status → completed                            │
   │   ├─ Order biến mất khỏi activeOrders              │
   │   │   (không match query nữa)                      │
   │   └─ Customer thấy completed trong lịch sử         │
   └─────────────────────────────────────────────────────┘

4. Real-time updates
   ├─ Mỗi khi staff update status
   ├─ Firestore document changes
   ├─ Triggers stream listeners:
   │   ├─ Staff: activeOrdersProvider → UI update
   │   ├─ Customer: userOrdersProvider → UI update
   │   └─ Admin: allOrdersProvider → UI update
   └─ All apps sync instantly (no refresh needed)
```

---

### Feature 3: Customer theo dõi đơn hàng

```
┌─────────────────────────────────────────────────────────────┐
│ CUSTOMER THEO DÕI ĐƠN HÀNG                                  │
└─────────────────────────────────────────────────────────────┘

1. Vào tab Đơn hàng
   ├─ HomeScreen → OrdersScreen (bottom nav index 1)
   ├─ Watch: userOrdersProvider(currentUser.uid)
   │   └─ Query: orders where userId == currentUser.uid
   │       orderBy createdAt DESC
   └─ Display: List orders (mới nhất trên cùng)

2. Filter đơn hàng
   ├─ Filter chips: Tất cả | Đang xử lý | Hoàn thành | Đã hủy
   ├─ Tap filter → setState(_selectedFilter)
   └─ _filterOrders():
       ├─ 'all': return all orders
       ├─ 'active': where status NOT IN [completed, cancelled]
       ├─ 'completed': where status == completed
       └─ 'cancelled': where status == cancelled

3. Card đơn hàng hiển thị
   ├─ Icon status (màu sắc tương ứng)
   ├─ Bàn số X + Mã đơn
   ├─ Status badge
   ├─ Preview 2 món đầu + "x món khác"
   ├─ Thời gian đặt
   └─ Tổng tiền

4. Xem chi tiết đơn
   ├─ Tap card → Navigate OrderTrackingScreen
   ├─ OrderTrackingScreen:
   │   ├─ StreamBuilder<Order>
   │   │   └─ FirestoreService.getOrder(orderId)
   │   │       └─ Real-time stream từ orders/{orderId}
   │   ├─ _OrderStatusStepper:
   │   │   ├─ 5 steps visual indicator
   │   │   ├─ Highlight completed steps (green)
   │   │   ├─ Gray out future steps
   │   │   └─ Steps:
   │   │       1. Đã gửi (pending)
   │   │       2. Đã xác nhận (confirmed)
   │   │       3. Đang chuẩn bị (preparing)
   │   │       4. Sẵn sàng (ready)
   │   │       5. Hoàn thành (completed)
   │   ├─ _OrderInfoCard:
   │   │   └─ Mã đơn, số bàn, thời gian, trạng thái, ghi chú
   │   ├─ _OrderItemsList:
   │   │   └─ List items với quantity và giá
   │   └─ Nút "HỦY ĐƠN HÀNG" (chỉ khi pending)
   └─ Real-time: Status tự động update khi staff thay đổi

5. Hủy đơn (nếu pending)
   ├─ Tap "HỦY ĐƠN HÀNG"
   ├─ Show confirmation dialog
   ├─ Confirm → _cancelOrder():
   │   ├─ FirestoreService.cancelOrder(orderId)
   │   │   └─ updateOrderStatus(orderId, cancelled)
   │   ├─ Show success snackbar
   │   └─ Navigate back
   └─ Order hiển thị trong filter "Đã hủy"
```

---

### Feature 4: Admin xem thống kê

```
┌─────────────────────────────────────────────────────────────┐
│ ADMIN DASHBOARD - THỐNG KÊ                                  │
└─────────────────────────────────────────────────────────────┘

1. Admin mở Dashboard
   ├─ AdminHomeScreen → DashboardScreen
   └─ DashboardScreen build()

2. Thống kê tháng này
   ├─ StreamBuilder<Map>
   │   └─ FirestoreService.streamMonthlyStatistics(year, month)
   ├─ Implementation:
   │   ├─ Calculate firstDay, lastDay of month
   │   ├─ Query: orders where createdAt BETWEEN firstDay AND lastDay
   │   ├─ Stream real-time updates
   │   └─ Calculate in-memory:
   │       ├─ completedOrders = where status == completed
   │       ├─ cancelledOrders = where status == cancelled
   │       ├─ totalRevenue = sum(completedOrders.totalAmount)
   │       └─ totalOrders = all orders count
   └─ Display 4 stat cards:
       ├─ Doanh thu tháng (Green)
       ├─ Đơn hoàn thành (Purple)
       ├─ Đơn đã hủy (Gray)
       └─ Tổng đơn hàng (Blue)

3. Thống kê hôm nay
   ├─ StreamBuilder<Map>
   │   └─ FirestoreService.streamDailyStatistics(todayDate)
   ├─ Implementation:
   │   ├─ Parse date: "YYYY-MM-DD"
   │   ├─ Calculate startOfDay 00:00:00, endOfDay 23:59:59
   │   ├─ Query: orders where createdAt BETWEEN start AND end
   │   ├─ Filter: completedOrders only
   │   ├─ Calculate:
   │   │   ├─ totalRevenue = sum amounts
   │   │   ├─ totalOrders = count
   │   │   ├─ hourlyRevenue = group by hour, sum amounts
   │   │   │   Example: {"08": 500000, "12": 800000, ...}
   │   │   └─ itemSalesCount = count items by name
   │   │       Example: {"Phở bò": 15, "Cà phê": 20, ...}
   │   └─ Stream updates when new orders completed
   └─ Display 2 stat cards + 2 cards từ activeOrders

4. Biểu đồ doanh thu theo giờ
   ├─ _HourlyRevenueChart widget
   ├─ Data: hourlyRevenue Map<hour, revenue>
   ├─ fl_chart package - BarChart:
   │   ├─ X-axis: Hours (00-23)
   │   ├─ Y-axis: Revenue (formatted với k suffix)
   │   └─ Bars: màu admin primary
   └─ Updates real-time khi có đơn mới completed

5. Top 5 món bán chạy
   ├─ Data: itemSalesCount Map<itemName, quantity>
   ├─ Sort: descending by quantity
   ├─ Take: top 5
   └─ Display: ListView
       ├─ CircleAvatar với rank (1-5)
       ├─ Item name
       └─ "X đã bán"

6. Real-time updates
   ├─ Khi order mới completed:
   │   ├─ streamMonthlyStatistics emits new data
   │   ├─ streamDailyStatistics emits new data
   │   ├─ Dashboard auto-rebuilds
   │   └─ Charts/Stats update instantly
   └─ No manual refresh needed
```

---

### Feature 5: Admin quản lý menu

```
┌─────────────────────────────────────────────────────────────┐
│ ADMIN QUẢN LÝ MENU                                          │
└─────────────────────────────────────────────────────────────┘

1. Vào trang quản lý menu
   ├─ AdminHomeScreen → MenuManagementScreen
   ├─ Watch providers:
   │   ├─ menuCategoriesProvider
   │   └─ menuItemsProvider
   └─ Display: TabBar categories + List items

2. Xem danh sách món
   ├─ Filter by category (tabs)
   ├─ Each item card:
   │   ├─ Image (if available)
   │   ├─ Name, Price
   │   ├─ Category badge
   │   ├─ Available toggle switch
   │   └─ Actions: Edit icon, Delete icon
   └─ Floating Action Button "+"

3. Toggle availability
   ├─ Tap switch on item
   ├─ _toggleAvailability(item):
   │   ├─ FirestoreService.updateMenuItemAvailability()
   │   │   └─ menuItems/{itemId}.update({isAvailable: !current})
   │   └─ Show snackbar
   ├─ Firestore triggers stream
   ├─ menuItemsProvider updates
   └─ Both Admin & Customer apps see change instantly

4. Thêm món mới
   ├─ Tap FAB → Navigate AddMenuItemScreen
   ├─ Form fields:
   │   ├─ TextField: name (required)
   │   ├─ Dropdown: category (required)
   │   ├─ TextField: price (required, number)
   │   ├─ TextField: imageUrl (optional)
   │   └─ Checkbox: isAvailable (default true)
   ├─ Tap "Thêm món":
   │   ├─ Validate: name not empty, price > 0
   │   ├─ Generate itemId (UUID)
   │   ├─ Create MenuItem object
   │   ├─ FirestoreService.addMenuItem(item)
   │   │   └─ menuItems/{itemId}.set(item.toJson())
   │   ├─ Show success snackbar
   │   └─ Navigate back
   └─ New item appears in list instantly

5. Sửa món
   ├─ Tap Edit icon → Navigate EditMenuItemScreen(item)
   ├─ Form pre-filled với existing data
   ├─ Modify fields
   ├─ Tap "Lưu thay đổi":
   │   ├─ Validate
   │   ├─ FirestoreService.updateMenuItem(updatedItem)
   │   │   └─ menuItems/{itemId}.update(data)
   │   └─ Navigate back
   └─ Changes reflect immediately

6. Xóa món
   ├─ Tap Delete icon
   ├─ Show confirmation dialog
   ├─ Confirm → _deleteMenuItem():
   │   ├─ FirestoreService.deleteMenuItem(itemId)
   │   │   └─ menuItems/{itemId}.delete()
   │   └─ Show success snackbar
   └─ Item disappears from list

7. Real-time sync
   ├─ Admin thay đổi → Firestore update
   ├─ menuItemsProvider (StreamProvider) detects change
   ├─ Triggers rebuild in:
   │   ├─ Admin: MenuManagementScreen
   │   └─ Customer: MenuScreen
   └─ All users see latest menu without refresh
```

---

## 🔐 Security & Permissions

### Firestore Rules Flow

```
Request từ app
  ↓
Firebase Authentication
  ├─ Check: User logged in?
  └─ Get: auth.uid
  ↓
Firestore Rules
  ├─ Get user role từ users/{uid}
  ├─ Check permissions:
  │   ├─ Customer: 
  │   │   - Read own orders
  │   │   - Create orders (với userId = auth.uid)
  │   │   - Read menu (public)
  │   ├─ Staff:
  │   │   - Read all orders
  │   │   - Update order status
  │   │   - Read menu
  │   └─ Admin:
  │       - Full access tất cả
  └─ Allow/Deny request
```

---

## 📊 Data Flow Summary

```
╔══════════════════════════════════════════════════════════╗
║                    FIRESTORE DATABASE                     ║
║  ┌─────────────┬─────────────┬─────────────────────┐    ║
║  │   users     │ menuItems   │      orders         │    ║
║  └─────────────┴─────────────┴─────────────────────┘    ║
╚══════════════════════════════════════════════════════════╝
          ↑                ↑                ↑
          │ Real-time     │ Real-time     │ Real-time
          │ Streams       │ Streams       │ Streams
          ↓                ↓                ↓
╔══════════════════════════════════════════════════════════╗
║              RIVERPOD PROVIDERS (State)                   ║
║  ┌─────────────┬─────────────┬─────────────────────┐    ║
║  │  authState  │  menuItems  │   activeOrders      │    ║
║  └─────────────┴─────────────┴─────────────────────┘    ║
╚══════════════════════════════════════════════════════════╝
          ↓                ↓                ↓
╔══════════════════════════════════════════════════════════╗
║                    UI SCREENS                             ║
║  ┌──────────────┬──────────────┬──────────────────┐     ║
║  │  Customer    │    Staff     │      Admin       │     ║
║  │  MenuScreen  │   Kitchen    │   Dashboard      │     ║
║  └──────────────┴──────────────┴──────────────────┘     ║
╚══════════════════════════════════════════════════════════╝

User Action → UI → Provider → Service → Firestore
                    ↓
            Real-time Stream
                    ↓
Firestore Change → Provider Update → UI Rebuild
```

---

## 📝 Tổng kết

### Điểm mạnh của kiến trúc:

1. **Real-time**: Tất cả dữ liệu sync ngay lập tức qua Firestore streams
2. **Modular**: Code tách biệt rõ ràng (shared/customer/staff/admin)
3. **Reusable**: Models, services, widgets dùng chung
4. **Type-safe**: Strongly typed với Dart, ít lỗi runtime
5. **Reactive**: Riverpod providers tự động rebuild UI khi data thay đổi
6. **Scalable**: Dễ thêm features mới, không ảnh hưởng code cũ

### Quy trình phát triển:

```
1. Định nghĩa Model → shared/models/
2. Thêm method vào Service → shared/services/
3. Tạo Provider (nếu cần) → shared/providers/
4. Build UI Screen → [role]/screens/
5. Wire up với Providers → watch/read trong build()
6. Test → Chạy app, verify real-time updates
```



