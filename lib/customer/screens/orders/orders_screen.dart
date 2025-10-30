import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/firestore_provider.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _selectedFilter = 'all';

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.ready:
        return AppColors.statusReady;
      case OrderStatus.completed:
        return AppColors.statusCompleted;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  List<Order> _filterOrders(List<Order> orders) {
    switch (_selectedFilter) {
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: ErrorView(message: 'Vui lòng đăng nhập'),
      );
    }

    final ordersAsync = ref.watch(userOrdersProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: AppColors.customerPrimary,
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
                  label: 'Xử lý',
                  isSelected: _selectedFilter == 'active',
                  onTap: () => setState(() => _selectedFilter = 'active'),
                  badgeColor: AppColors.warning,
                ),
                _FilterChip(
                  label: 'Hoàn thành',
                  isSelected: _selectedFilter == 'completed',
                  onTap: () => setState(() => _selectedFilter = 'completed'),
                  badgeColor: AppColors.statusCompleted,
                ),
                _FilterChip(
                  label: 'Đã hủy',
                  isSelected: _selectedFilter == 'cancelled',
                  onTap: () => setState(() => _selectedFilter = 'cancelled'),
                  badgeColor: AppColors.statusCancelled,
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
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _selectedFilter == 'all' 
                              ? 'Chưa có đơn hàng nào'
                              : 'Không có đơn hàng',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _selectedFilter == 'all'
                              ? 'Hãy đặt món đầu tiên của bạn!'
                              : 'Không có đơn hàng trong danh mục này',
                          style: AppTextStyles.body1.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderTrackingScreen(orderId: order.orderId),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    ),
                                    child: Icon(
                                      _getStatusIcon(order.status),
                                      color: _getStatusColor(order.status),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bàn ${order.tableNumber}',
                                          style: AppTextStyles.heading3,
                                        ),
                                        Text(
                                          'Mã: ${order.orderId.substring(0, 8).toUpperCase()}',
                                          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                    ),
                                    child: Text(
                                      Formatters.orderStatus(order.status.name),
                                      style: AppTextStyles.body2.copyWith(
                                        color: _getStatusColor(order.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Divider(),
                              const SizedBox(height: AppSpacing.sm),
                              // Show first 2 items
                              ...order.items.take(2).map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                child: Row(
                                  children: [
                                    Text(
                                      'x${item.quantity}',
                                      style: AppTextStyles.body2.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: AppTextStyles.body2,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                              if (order.items.length > 2)
                                Text(
                                  '+ ${order.items.length - 2} món khác',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.customerPrimary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              const Divider(),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        Formatters.dateTime(order.createdAt),
                                        style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text('Tổng:', style: AppTextStyles.body1),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        Formatters.currency(order.totalAmount),
                                        style: AppTextStyles.heading3.copyWith(
                                          color: AppColors.customerPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? badgeColor;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.customerPrimary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}




