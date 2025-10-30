# 🏗️ Kiến trúc hệ thống

## 1. Tổng quan kiến trúc

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Apps (Dart)                      │
├──────────────┬──────────────────┬──────────────────────────┤
│  Customer    │     Staff        │        Admin             │
│   App        │     App          │         App              │
└──────────────┴──────────────────┴──────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│                  Shared Business Logic                       │
│  ┌───────────┬────────────┬────────────┬─────────────┐     │
│  │  Models   │  Services  │ Providers  │   Widgets   │     │
│  └───────────┴────────────┴────────────┴─────────────┘     │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│                   Firebase Backend                           │
│  ┌──────────┬──────────────┬────────────┬────────────┐     │
│  │   Auth   │  Firestore   │  Storage   │ Functions  │     │
│  └──────────┴──────────────┴────────────┴────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Kiến trúc Frontend (Flutter)

### 2.1. Clean Architecture + Feature-first

```
lib/
├── admin/              # Admin feature module
│   ├── screens/
│   └── utils/
├── customer/           # Customer feature module
│   ├── screens/
│   └── providers/
├── staff/              # Staff feature module
│   └── screens/
└── shared/             # Shared code
    ├── models/         # Domain models
    ├── services/       # Business logic
    ├── providers/      # State management
    ├── widgets/        # Reusable UI
    └── utils/          # Helpers
```

### 2.2. State Management: Riverpod

**Provider Types:**
- `Provider` - Immutable data
- `StateProvider` - Simple state
- `StreamProvider` - Real-time streams
- `FutureProvider` - Async operations

**Example:**
```dart
// Provide Firestore service
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService()
);

// Stream active orders
final activeOrdersProvider = StreamProvider<List<Order>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getActiveOrders();
});
```

### 2.3. Models

**Data Models:**
- `Order` - Đơn hàng
- `MenuItem` - Món ăn
- `MenuCategory` - Danh mục
- `OrderItem` - Item trong đơn
- `User` - Người dùng
- `DailyReport` - Báo cáo ngày

**Serialization:**
```dart
class Order {
  final String orderId;
  final OrderStatus status;
  
  // From Firestore
  factory Order.fromFirestore(DocumentSnapshot doc) { ... }
  
  // To Firestore
  static Map<String, dynamic> toFirestore(Order order) { ... }
}
```

---

## 3. Kiến trúc Backend (Firebase)

### 3.1. Firebase Services

#### Authentication
```
- Email/Password authentication
- User roles: customer, staff, admin
- Session management
```

#### Cloud Firestore
```
Collections:
- users: User profiles và roles
- menuCategories: Danh mục thực đơn
- menuItems: Món ăn
- orders: Đơn hàng (real-time)
- dailyReports: Thống kê ngày
```

#### Security Rules
```javascript
// Staff và Admin có thể update orders
allow update: if isSignedIn() && (
  getUserRole() in ['staff', 'admin'] || 
  request.auth.uid == resource.data.userId
);
```

### 3.2. Firestore Data Structure

```
firestore/
│
├── users/
│   └── {userId}
│       ├── uid: string
│       ├── email: string
│       ├── role: 'customer' | 'staff' | 'admin'
│       └── displayName: string
│
├── menuCategories/
│   └── {categoryId}
│       ├── name: string
│       └── priority: number
│
├── menuItems/
│   └── {itemId}
│       ├── name: string
│       ├── categoryId: string
│       ├── price: number
│       ├── imageUrl: string
│       └── isAvailable: boolean
│
├── orders/
│   └── {orderId}
│       ├── userId: string
│       ├── tableNumber: number
│       ├── status: OrderStatus
│       ├── items: OrderItem[]
│       ├── totalAmount: number
│       ├── notes: string
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
└── dailyReports/
    └── {YYYY-MM-DD}
        ├── totalRevenue: number
        ├── totalOrders: number
        ├── hourlyRevenue: Map<hour, revenue>
        └── itemSalesCount: Map<itemId, count>
```

---

## 4. Design Patterns

### 4.1. Repository Pattern
```dart
class FirestoreService {
  final FirebaseFirestore _firestore;
  
  // Abstraction layer for Firestore operations
  Stream<List<Order>> getActiveOrders() { ... }
  Future<void> updateOrderStatus(...) { ... }
}
```

### 4.2. Provider Pattern (Dependency Injection)
```dart
// Inject services via Riverpod providers
final firestoreService = ref.watch(firestoreServiceProvider);
```

### 4.3. Observer Pattern
```dart
// Real-time listeners via Firestore streams
StreamBuilder<List<Order>>(
  stream: firestoreService.getActiveOrders(),
  builder: (context, snapshot) { ... }
)
```

---

## 5. Real-time Architecture

### 5.1. Data Flow

**Order Creation:**
```
Customer App
  ↓ create order
Firestore (orders collection)
  ↓ stream listener
Staff App (instant update)
Admin Dashboard (instant update)
```

**Order Status Update:**
```
Staff App
  ↓ update status
Firestore (orders collection)
  ↓ stream listener
Customer App (instant update)
Admin Dashboard (instant update)
```

### 5.2. Stream Architecture
```dart
// Provider setup
final activeOrdersProvider = StreamProvider<List<Order>>((ref) {
  return FirestoreService().getActiveOrders(); // Returns Stream
});

// UI consumption
final ordersAsync = ref.watch(activeOrdersProvider);
ordersAsync.when(
  data: (orders) => ListView(...),
  loading: () => LoadingIndicator(),
  error: (e, _) => ErrorView(error: e),
);
```

---

## 6. Security Architecture

### 6.1. Authentication Flow
```
1. User login → Firebase Auth
2. Get user document from Firestore
3. Check role (customer/staff/admin)
4. Route to appropriate app
5. Apply role-based access control
```

### 6.2. Firestore Security
```javascript
function getUserRole() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
}

match /orders/{orderId} {
  allow read: if isSignedIn();
  allow create: if isSignedIn();
  allow update: if getUserRole() in ['staff', 'admin'];
  allow delete: if getUserRole() == 'admin';
}
```

---

## 7. Scalability Considerations

### 7.1. Database Indexing
```
Composite indexes for:
- orders: (status + createdAt)
- orders: (userId + createdAt)
```

### 7.2. Query Optimization
```dart
// Filter in memory instead of complex Firestore queries
final activeOrders = await orders
  .where('status', whereIn: ['pending', 'confirmed', 'preparing', 'ready'])
  .get();
  
// Then sort in memory
orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
```

### 7.3. Pagination (Future)
```dart
// Implement pagination for large order lists
query.limit(20).startAfter(lastDoc);
```

---

## 8. Performance Optimization

### 8.1. Widget Optimization
```dart
// Use const constructors
const LoadingIndicator()

// Use keys for list items
ListView.builder(
  itemBuilder: (context, index) {
    return Card(key: ValueKey(order.orderId), ...);
  }
)
```

### 8.2. Stream Optimization
```dart
// Use StreamProvider for caching
// Riverpod automatically caches stream data
final ordersAsync = ref.watch(activeOrdersProvider);
```

### 8.3. Image Optimization
```dart
// Use cached_network_image for menu images
CachedNetworkImage(
  imageUrl: menuItem.imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
)
```

---

## 9. Error Handling

### 9.1. Try-Catch Pattern
```dart
try {
  await firestoreService.updateOrderStatus(...);
  showSuccessMessage();
} catch (e) {
  showErrorMessage(e.toString());
}
```

### 9.2. Stream Error Handling
```dart
ordersAsync.when(
  data: (orders) => buildList(orders),
  loading: () => LoadingIndicator(),
  error: (error, stackTrace) => ErrorView(error: error),
);
```

---

## 10. Testing Architecture (Future)

### 10.1. Unit Tests
```dart
test('Order total amount calculation', () {
  final order = Order(...);
  expect(order.totalAmount, equals(100000));
});
```

### 10.2. Widget Tests
```dart
testWidgets('Menu screen displays items', (tester) async {
  await tester.pumpWidget(MenuScreen());
  expect(find.byType(MenuItemCard), findsWidgets);
});
```

### 10.3. Integration Tests
```dart
// Test full user flow
testWidgets('Complete order flow', (tester) async {
  // Login → Select items → Place order → Verify
});
```


