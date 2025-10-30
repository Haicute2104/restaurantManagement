import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_view.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  bool _isCancelling = false;

  Future<void> _cancelOrder(BuildContext context, Order order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    setState(() => _isCancelling = true);

    try {
      final firestoreService = FirestoreService();
      await firestoreService.cancelOrder(widget.orderId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng thành công')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi đơn hàng'),
        backgroundColor: AppColors.customerPrimary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<Order>(
        stream: firestoreService.getOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return ErrorView(message: 'Lỗi: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return const ErrorView(message: 'Không tìm thấy đơn hàng');
          }

          final order = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OrderStatusStepper(status: order.status),
                const SizedBox(height: AppSpacing.xl),
                _OrderInfoCard(order: order),
                const SizedBox(height: AppSpacing.lg),
                _OrderItemsList(order: order),
                const SizedBox(height: AppSpacing.lg),
                // Cancel button (only for pending orders)
                if (order.status == OrderStatus.pending)
                  ElevatedButton(
                    onPressed: _isCancelling ? null : () => _cancelOrder(context, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('HỦY ĐỠN HÀNG', style: AppTextStyles.button),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderStatusStepper extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusStepper({required this.status});

  int _getStepIndex() {
    switch (status) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.completed:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  Color _getStepColor(int index) {
    final currentStep = _getStepIndex();
    if (status == OrderStatus.cancelled) {
      return AppColors.statusCancelled;
    }
    return index <= currentStep ? AppColors.success : Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Card(
        color: AppColors.statusCancelled.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.cancel_outlined,
                size: 64,
                color: AppColors.statusCancelled,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Đơn hàng đã bị hủy',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.statusCancelled,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = [
      {'icon': Icons.check_circle, 'label': 'Đã gửi'},
      {'icon': Icons.verified, 'label': 'Đã xác nhận'},
      {'icon': Icons.restaurant, 'label': 'Đang chuẩn bị'},
      {'icon': Icons.done_all, 'label': 'Sẵn sàng'},
      {'icon': Icons.celebration, 'label': 'Hoàn thành'},
    ];

    final currentStep = _getStepIndex();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStepColor(i),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[i]['icon'] as IconData,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      steps[i]['label'] as String,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: i <= currentStep ? FontWeight.bold : FontWeight.normal,
                        color: i <= currentStep ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                  if (i <= currentStep)
                    Icon(
                      Icons.check,
                      color: AppColors.success,
                    ),
                ],
              ),
              if (i < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    width: 2,
                    height: 40,
                    color: _getStepColor(i + 1),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  final Order order;

  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin đơn hàng', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
              label: 'Mã đơn hàng',
              value: order.orderId.substring(0, 8).toUpperCase(),
            ),
            _InfoRow(
              label: 'Số bàn',
              value: order.tableNumber.toString(),
            ),
            _InfoRow(
              label: 'Thời gian',
              value: Formatters.dateTime(order.createdAt),
            ),
            _InfoRow(
              label: 'Trạng thái',
              value: Formatters.orderStatus(order.status.name),
            ),
            if (order.notes != null) ...[
              const SizedBox(height: AppSpacing.sm),
              const Text('Ghi chú:', style: AppTextStyles.body2),
              Text(
                order.notes!,
                style: AppTextStyles.body1.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body1.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _OrderItemsList extends StatelessWidget {
  final Order order;

  const _OrderItemsList({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chi tiết đơn hàng', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.md),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x ${item.quantity}',
                          style: AppTextStyles.body1,
                        ),
                      ),
                      Text(
                        Formatters.currency(item.price * item.quantity),
                        style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:', style: AppTextStyles.heading3),
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
      ),
    );
  }
}





