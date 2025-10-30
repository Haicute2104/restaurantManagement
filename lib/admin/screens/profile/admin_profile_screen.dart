import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/utils/constants.dart';
import '../auth/admin_login_screen.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Chưa đăng nhập'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.adminPrimary,
                  child: Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.displayName,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  style: AppTextStyles.body1.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.adminPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Text(
                    'Quản trị viên',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.adminPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ProfileOption(
                  icon: Icons.settings,
                  title: 'Cài đặt',
                  onTap: () {
                    // TODO: Navigate to settings
                  },
                ),
                _ProfileOption(
                  icon: Icons.help,
                  title: 'Hỗ trợ',
                  onTap: () {
                    // TODO: Navigate to support
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                    ),
                    child: const Text('Đăng xuất', style: AppTextStyles.button),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, color: AppColors.adminPrimary),
        title: Text(title, style: AppTextStyles.body1),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}





