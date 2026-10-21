import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_error.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController(
        profileRepository: ProfileRepository(),
      )..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  void _showEditPhoneDialog(BuildContext context, String currentPhone) {
    final controller = TextEditingController(text: currentPhone);
    final profCtrl = context.read<ProfileController>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cập nhật số điện thoại'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại mới',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty) {
                Navigator.pop(dialogCtx);
                final success = await profCtrl.updatePhone(newPhone);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Cập nhật số điện thoại thành công!' : 'Cập nhật thất bại'),
                      backgroundColor: success ? AppTheme.success : AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthController>().signOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profCtrl = context.watch<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ nhân viên'),
      ),
      body: Builder(
        builder: (_) {
          if (profCtrl.isLoading && profCtrl.employee == null) {
            return const AppLoading(message: 'Đang tải hồ sơ...');
          }

          if (profCtrl.errorMessage != null && profCtrl.employee == null) {
            return AppError(
              message: profCtrl.errorMessage!,
              onRetry: () => profCtrl.loadProfile(),
            );
          }

          final emp = profCtrl.employee;
          if (emp == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Center(
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  emp.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${emp.role} • ${emp.branch}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // Info card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined, color: AppTheme.primary),
                        title: const Text('Mã nhân viên'),
                        subtitle: Text(emp.employeeCode),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined, color: AppTheme.primary),
                        title: const Text('Email công việc'),
                        subtitle: Text(emp.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined, color: AppTheme.primary),
                        title: const Text('Số điện thoại'),
                        subtitle: Text(emp.phone.isNotEmpty ? emp.phone : 'Chưa cập nhật'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: AppTheme.primary),
                          onPressed: () => _showEditPhoneDialog(context, emp.phone),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.storefront_outlined, color: AppTheme.primary),
                        title: const Text('Chi nhánh phân công'),
                        subtitle: Text(emp.branch),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _showLogoutConfirmDialog(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
