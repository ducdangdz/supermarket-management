import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_brand.dart';
import '../../services/mock_data_service.dart';
import '../backend/backend_workspace.dart';
import '../management/manager_main_screen.dart';
import '../reports/reports_main_screen.dart';

/// Home for all workspaces; business data remains owned by the original modules.
class FeatureLauncherScreen extends StatelessWidget {
  const FeatureLauncherScreen({
    super.key,
    this.userName,
    this.roleName,
    this.onLogout,
    this.onRefresh,
    this.onOpenEmployee,
  });
  final String? userName, roleName;
  final Future<void> Function()? onLogout;
  final VoidCallback? onOpenEmployee;
  final VoidCallback? onRefresh;

  void _open(BuildContext context, Widget screen) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MockDataService>(),
        child: screen,
      ),
    ),
  );

  Widget _moduleFrame(String title, Widget child) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: child,
  );

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    return Scaffold(
      appBar: AppBar(
        title: const AppBrand(),
        toolbarHeight: 80,
        actions: [
          if (onRefresh != null)
            IconButton(
              tooltip: 'Làm mới dữ liệu',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          if (onLogout != null)
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Tooltip(
              message: 'Trang chủ các không gian làm việc',
              child: Icon(Icons.apps_rounded),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Không gian làm việc',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn chức năng để bắt đầu ngày làm việc của bạn.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  if (userName != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, $userName',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('Vai trò: $roleName'),
                            const SizedBox(height: 8),
                            const Text(
                              'Dữ liệu được kết nối với hệ thống. Chọn chức năng bên dưới để làm việc.',
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _SystemBanner(
                      onOpen: () => _open(
                        context,
                        _moduleFrame(
                          'Kết nối hệ thống',
                          const SmartMarketApp(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  const _SectionTitle(
                    title: 'Các phân hệ chức năng',
                    subtitle: 'Chọn phân hệ phù hợp với công việc của bạn.',
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 600
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 16) / columns;
                      final modules = [
                        _ModuleCard(
                          title: 'Ứng dụng nhân viên',
                          badge: userName == null
                              ? 'Tài khoản nhân viên'
                              : 'Dữ liệu hệ thống',
                          description:
                              'Lịch làm việc, chấm công và hồ sơ cá nhân.',
                          icon: Icons.badge_outlined,
                          details: 'Lịch làm · Quét QR · Hồ sơ',
                          action: 'Vào không gian nhân viên',
                          onTap:
                              onOpenEmployee ??
                              () => _open(
                                context,
                                _moduleFrame(
                                  'Ứng dụng nhân viên',
                                  const SmartMarketApp(),
                                ),
                              ),
                        ),
                        if (!data.isRemote ||
                            data.currentRoleCode != 'EMPLOYEE')
                          _ModuleCard(
                            badge: data.isRemote
                                ? 'Dữ liệu hệ thống'
                                : 'Dữ liệu mẫu',
                            title: 'Quản lý vận hành',
                            description:
                                'Điều phối đội ngũ và quản lý công việc tại chi nhánh.',
                            icon: Icons.space_dashboard_outlined,
                            details: 'Nhân sự · Phân ca · Phê duyệt',
                            action: 'Vào không gian quản lý',
                            onTap: () =>
                                _open(context, const ManagerMainScreen()),
                          ),
                        if (!data.isRemote ||
                            data.currentRoleCode != 'EMPLOYEE')
                          _ModuleCard(
                            badge: data.isRemote
                                ? 'Dữ liệu hệ thống'
                                : 'Dữ liệu mẫu',
                            title: 'Báo cáo & thống kê',
                            description:
                                'Theo dõi chấm công và tổng hợp kết quả làm việc.',
                            icon: Icons.insights_outlined,
                            details: 'Tổng quan · Lịch sử · Xuất báo cáo',
                            action: 'Mở trung tâm báo cáo',
                            onTap: () =>
                                _open(context, const ReportsMainScreen()),
                          ),
                      ];
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final module in modules)
                            SizedBox(width: width, child: module),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.isRemote
                              ? 'Vai trò tài khoản'
                              : 'Vai trò trải nghiệm',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.isRemote
                              ? 'Quyền được xác định từ tài khoản trong hệ thống.'
                              : 'Áp dụng cho dữ liệu mẫu ở phần quản lý và báo cáo.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final role in const {
                              'ADMIN': 'Quản trị viên',
                              'MANAGER': 'Quản lý',
                              'HR': 'Nhân sự',
                              'EMPLOYEE': 'Nhân viên',
                            }.entries)
                              ChoiceChip(
                                label: Text(role.value),
                                selected: data.currentRoleCode == role.key,
                                onSelected: data.isRemote
                                    ? null
                                    : (_) => data.setCurrentRole(role.key),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!data.isRemote || data.currentRoleCode != 'EMPLOYEE')
                    const _SectionTitle(
                      title: 'Truy cập nhanh',
                      subtitle: 'Mở trực tiếp công việc cần thực hiện.',
                    ),
                  const SizedBox(height: 16),
                  if (!data.isRemote || data.currentRoleCode != 'EMPLOYEE')
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns;
                        final shortcuts = [
                          ('Nhân viên', Icons.people_outline_rounded, 2),
                          (
                            'Xếp lịch làm việc',
                            Icons.calendar_month_outlined,
                            4,
                          ),
                          ('Phê duyệt chấm công', Icons.fact_check_outlined, 6),
                          ('Sơ đồ mặt bằng', Icons.map_outlined, 1),
                          ('Ca làm việc', Icons.work_history_outlined, 3),
                          ('Tổng quan chi nhánh', Icons.dashboard_outlined, 0),
                        ];
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final (label, icon, index) in shortcuts)
                              SizedBox(
                                width: width,
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    leading: Icon(
                                      icon,
                                      color: AppColors.primary,
                                    ),
                                    title: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                    onTap: () => _open(
                                      context,
                                      ManagerMainScreen(initialIndex: index),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'SmartMarket HRM · Kết nối đội ngũ, đồng bộ vận hành',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 5),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    ],
  );
}

class _SystemBanner extends StatelessWidget {
  const _SystemBanner({required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 650;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFFA7F3D0),
                  size: 16,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'HỆ THỐNG TRỰC TUYẾN',
                    style: TextStyle(
                      color: Color(0xFFA7F3D0),
                      letterSpacing: 1.2,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Cùng đội ngũ, vận hành tốt hơn.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Đăng nhập Google để làm việc với dữ liệu của chi nhánh.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ],
        );
        final button = FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
          ),
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text('Kết nối hệ thống'),
        );
        return wide
            ? Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: 32),
                  button,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [content, const SizedBox(height: 24), button],
              );
      },
    ),
  );
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.details,
    required this.action,
    required this.onTap,
    this.badge = 'Dữ liệu mẫu',
  });
  final String title, description, details, action;
  final String badge;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 26),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              details,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    action,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
