import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/menu_category_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/daily_report_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== Menu Categories =====
  Stream<List<MenuCategory>> getMenuCategories() {
    return _firestore
        .collection('menuCategories')
        .orderBy('priority')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuCategory.fromJson({...doc.data(), 'categoryId': doc.id}))
            .toList());
  }

  Future<void> addMenuCategory(MenuCategory category) async {
    await _firestore
        .collection('menuCategories')
        .doc(category.categoryId)
        .set(category.toJson());
  }

  Future<void> updateMenuCategory(MenuCategory category) async {
    await _firestore
        .collection('menuCategories')
        .doc(category.categoryId)
        .update(category.toJson());
  }

  Future<void> deleteMenuCategory(String categoryId) async {
    await _firestore.collection('menuCategories').doc(categoryId).delete();
  }

  // ===== Menu Items =====
  Stream<List<MenuItem>> getMenuItems({String? categoryId}) {
    Query query = _firestore.collection('menuItems');
    
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => MenuItem.fromJson({...doc.data() as Map<String, dynamic>, 'itemId': doc.id}))
        .toList());
  }

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

  Future<MenuItem?> getMenuItem(String itemId) async {
    final doc = await _firestore.collection('menuItems').doc(itemId).get();
    if (doc.exists) {
      return MenuItem.fromJson({...doc.data()!, 'itemId': doc.id});
    }
    return null;
  }

  Future<void> addMenuItem(MenuItem item) async {
    await _firestore
        .collection('menuItems')
        .doc(item.itemId)
        .set(item.toJson());
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await _firestore
        .collection('menuItems')
        .doc(item.itemId)
        .update(item.toJson());
  }

  Future<void> updateMenuItemAvailability(String itemId, bool isAvailable) async {
    await _firestore
        .collection('menuItems')
        .doc(itemId)
        .update({'isAvailable': isAvailable});
  }

  Future<void> deleteMenuItem(String itemId) async {
    await _firestore.collection('menuItems').doc(itemId).delete();
  }

  // ===== Orders =====
  Future<String> createOrder(Order order) async {
    final docRef = await _firestore.collection('orders').add(Order.toFirestore(order));
    return docRef.id;
  }

  Stream<Order> getOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => Order.fromFirestore(doc));
  }

  Stream<List<Order>> getOrdersByUser(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

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

  Stream<List<Order>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
    });
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  // ===== Daily Reports =====
  Future<DailyReport?> getDailyReport(String date) async {
    final doc = await _firestore.collection('dailyReports').doc(date).get();
    if (doc.exists) {
      return DailyReport.fromJson({...doc.data()!, 'date': doc.id});
    }
    return null;
  }

  Stream<DailyReport?> streamDailyReport(String date) {
    return _firestore
        .collection('dailyReports')
        .doc(date)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return DailyReport.fromJson({...doc.data()!, 'date': doc.id});
          }
          return null;
        });
  }

  Future<List<DailyReport>> getDailyReportsRange(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('dailyReports')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: _formatDate(start))
        .where(FieldPath.documentId, isLessThanOrEqualTo: _formatDate(end))
        .get();

    return snapshot.docs
        .map((doc) => DailyReport.fromJson({...doc.data(), 'date': doc.id}))
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ===== Monthly Statistics =====
  Future<Map<String, dynamic>> getMonthlyStatistics(int year, int month) async {
    // Get first and last day of the month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);

    // Query orders in this month
    final snapshot = await _firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: firstDay)
        .where('createdAt', isLessThanOrEqualTo: lastDay)
        .get();

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
  }

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

  // ===== Daily Statistics (từ orders) =====
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
}

