import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/utils/validators.dart';
import '../../providers/cart_provider.dart';
import '../orders/order_tracking_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tableNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final uuid = const Uuid();
      final order = Order(
        orderId: uuid.v4(),
        userId: user.uid,
        tableNumber: int.parse(_tableNumberController.text),
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
        items: ref.read(cartProvider.notifier).toOrderItems(),
        totalAmount: ref.read(cartTotalProvider),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final firestoreService = FirestoreService();
      final orderId = await firestoreService.createOrder(order);

      if (mounted) {
        ref.read(cartProvider.notifier).clear();
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: orderId),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: AppColors.customerPrimary,
        foregroundColor: Colors.white,
      ),
      body: cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: AppSpacing.md),
                  Text('Giỏ hàng trống', style: AppTextStyles.heading3),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart[index];
                      return _CartItemCard(cartItem: cartItem);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng cộng:', style: AppTextStyles.heading3),
                            Text(
                              Formatters.currency(totalAmount),
                              style: AppTextStyles.heading2.copyWith(
                                color: AppColors.customerPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _tableNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Số bàn',
                            prefixIcon: const Icon(Icons.table_bar),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          validator: Validators.tableNumber,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Ghi chú (tùy chọn)',
                            prefixIcon: const Icon(Icons.note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.customerPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Xác nhận đặt hàng', style: AppTextStyles.button),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  final CartItem cartItem;

  const _CartItemCard({required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: Image.network(
                cartItem.menuItem.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formatters.currency(cartItem.menuItem.price),
                    style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).updateQuantity(
                                cartItem.menuItem.itemId,
                                cartItem.quantity - 1,
                              );
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          cartItem.quantity.toString(),
                          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).updateQuantity(
                                cartItem.menuItem.itemId,
                                cartItem.quantity + 1,
                              );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).removeItem(cartItem.menuItem.itemId);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  Formatters.currency(cartItem.totalPrice),
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
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





