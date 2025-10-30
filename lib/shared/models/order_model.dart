import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

part 'order_model.freezed.dart';
part 'order_model.g.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  completed,
  cancelled,
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String itemId,
    required String name,
    required double price,
    required int quantity,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

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

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  // Helper method for Firestore conversion
  static Order fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      orderId: doc.id,
      userId: data['userId'] ?? '',
      tableNumber: data['tableNumber'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      items: (data['items'] as List)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      notes: data['notes'],
    );
  }

  static Map<String, dynamic> toFirestore(Order order) {
    return {
      'userId': order.userId,
      'tableNumber': order.tableNumber,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'status': order.status.name,
      'items': order.items.map((item) => item.toJson()).toList(),
      'totalAmount': order.totalAmount,
      'notes': order.notes,
    };
  }
}

