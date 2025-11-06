import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/services/firestore_service.dart';
import '../../../shared/providers/firestore_provider.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/utils/constants.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/loading_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDate = _getTodayDate();
    final firestoreService = FirestoreService();
    final activeOrdersAsync = ref.watch(activeOrdersProvider);

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Stats Title
            Text(
              'Thống kê tháng ${currentMonth}/${currentYear}',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Monthly Stats Cards
            StreamBuilder<Map<String, dynamic>>(
              stream: firestoreService.streamMonthlyStatistics(currentYear, currentMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                final stats = snapshot.data ?? {};
                final monthlyRevenue = (stats['totalRevenue'] ?? 0.0) as double;
                final completedOrders = stats['completedOrders'] ?? 0;
                final cancelledOrders = stats['cancelledOrders'] ?? 0;
                final totalOrders = stats['totalOrders'] ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.attach_money,
                            title: 'Doanh thu tháng này',
                            value: Formatters.currency(monthlyRevenue),
                            subtitle: 'Từ $completedOrders đơn hoàn thành',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle,
                            title: 'Đơn hoàn thành',
                            value: completedOrders.toString(),
                            subtitle: 'Tổng $totalOrders đơn',
                            color: AppColors.statusCompleted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.cancel,
                            title: 'Đơn đã hủy',
                            value: cancelledOrders.toString(),
                            subtitle: 'Trong tháng này',
                            color: AppColors.statusCancelled,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long,
                            title: 'Tổng đơn hàng',
                            value: totalOrders.toString(),
                            subtitle: 'Tất cả trạng thái',
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            
            // Today Stats Title
            Text(
              'Thống kê hôm nay',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Today Stats Cards
            StreamBuilder<Map<String, dynamic>>(
              stream: firestoreService.streamDailyStatistics(todayDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                final stats = snapshot.data ?? {};
                final totalRevenue = (stats['totalRevenue'] ?? 0.0) as double;
                final totalOrders = stats['totalOrders'] ?? 0;
                final hasData = totalOrders > 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.attach_money,
                            title: 'Doanh thu hôm nay',
                            value: Formatters.currency(totalRevenue),
                            subtitle: hasData ? null : 'Chưa có đơn hoàn thành',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt,
                            title: 'Đơn hàng hôm nay',
                            value: totalOrders.toString(),
                            subtitle: hasData ? null : 'Đơn hoàn thành: 0',
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    activeOrdersAsync.when(
                      data: (orders) => Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.pending_actions,
                              title: 'Đơn đang xử lý',
                              value: orders.length.toString(),
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.pending,
                              title: 'Đơn chờ xác nhận',
                              value: orders.where((o) => o.status == OrderStatus.pending).length.toString(),
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // Revenue Chart
            const Text(
              'Doanh thu theo giờ',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<Map<String, dynamic>>(
              stream: firestoreService.streamDailyStatistics(todayDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: LoadingIndicator());
                }

                final stats = snapshot.data ?? {};
                final hourlyRevenue = (stats['hourlyRevenue'] ?? {}) as Map<String, double>;
                
                if (hourlyRevenue.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('Chưa có dữ liệu')),
                  );
                }

                return _HourlyRevenueChart(hourlyRevenue: hourlyRevenue);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // Top Selling Items
            const Text(
              'Top 5 món bán chạy hôm nay',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<Map<String, dynamic>>(
              stream: firestoreService.streamDailyStatistics(todayDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                final stats = snapshot.data ?? {};
                final itemSalesCount = (stats['itemSalesCount'] ?? {}) as Map<String, int>;
                
                if (itemSalesCount.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Chưa có dữ liệu'),
                    ),
                  );
                }

                final sortedItems = itemSalesCount.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final top5 = sortedItems.take(5).toList();

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: top5.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = top5[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.adminPrimary,
                          foregroundColor: Colors.white,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(entry.key),
                        trailing: Text(
                          '${entry.value} đã bán',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(color: color),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HourlyRevenueChart extends StatelessWidget {
  final Map<String, double> hourlyRevenue;

  const _HourlyRevenueChart({required this.hourlyRevenue});

  @override
  Widget build(BuildContext context) {
    final sortedHours = hourlyRevenue.keys.toList()..sort();
    final maxRevenue = hourlyRevenue.values.isEmpty ? 100.0 : hourlyRevenue.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxRevenue * 1.2,
              barGroups: sortedHours.asMap().entries.map((entry) {
                final hour = entry.value;
                final revenue = hourlyRevenue[hour] ?? 0;
                return BarChartGroupData(
                  x: int.parse(hour),
                  barRods: [
                    BarChartRodData(
                      toY: revenue,
                      color: AppColors.adminPrimary,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}h',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }
}

