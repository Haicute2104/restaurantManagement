import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../shared/providers/firestore_provider.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  ConsumerState<KitchenDisplayScreen> createState() => _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen> {
  String _selectedFilter = 'all';
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

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

  Color _getOrderColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.ready:
        return AppColors.statusReady;
      default:
        return Colors.grey;
    }
  }

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
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 4),
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
        selectedColor: AppColors.staffPrimary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  final Color backgroundColor;

  const _OrderCard({
    required this.order,
    required this.backgroundColor,
  });

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
            const SizedBox(height: AppSpacing.md),
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
          ],
        ),
      ),
    );
  }
}

