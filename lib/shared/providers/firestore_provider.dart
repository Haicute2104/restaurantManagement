import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_category_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Menu Categories
final menuCategoriesProvider = StreamProvider<List<MenuCategory>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMenuCategories();
});

// Menu Items
final menuItemsProvider = StreamProvider<List<MenuItem>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getMenuItems();
});

final availableMenuItemsProvider = StreamProvider.family<List<MenuItem>, String?>((ref, categoryId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAvailableMenuItems(categoryId: categoryId);
});

// Orders
final activeOrdersProvider = StreamProvider<List<Order>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getActiveOrders();
});

final allOrdersProvider = StreamProvider<List<Order>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllOrders();
});

final userOrdersProvider = StreamProvider.family<List<Order>, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getOrdersByUser(userId);
});










