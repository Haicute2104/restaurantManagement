import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/menu_item_model.dart';
import '../../shared/models/order_model.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get totalPrice => menuItem.price * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

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

  void removeItem(String itemId) {
    state = state.where((item) => item.menuItem.itemId != itemId).toList();
  }

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

  void clear() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  List<OrderItem> toOrderItems() {
    return state.map((cartItem) => OrderItem(
      itemId: cartItem.menuItem.itemId,
      name: cartItem.menuItem.name,
      price: cartItem.menuItem.price,
      quantity: cartItem.quantity,
    )).toList();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.totalPrice);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});





