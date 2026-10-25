import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/dashboard_repository.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          DashboardController(dashboardRepository: DashboardRepository())
            ..loadDashboard(),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ctrl.loadDashboard(),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Quét QR Chấm Công'),
        onPressed: () async {
          final updated = await context.push<bool>('/qr-checkin');
          if (updated == true) {
            ctrl.loadDashboard();
          }
        },
      ),
      body: Builder(
        builder: (_) {
          if (ctrl.isLoading && ctrl.employee == null) {
            return const AppLoading(message: 'Đang tải thông tin ca làm...');
          }

          if (ctrl.errorMessage != null && ctrl.employee == null) {
            return AppError(
              message: ctrl.errorMessage!,
              onRetry: () => ctrl.loadDashboard(),
            );
          }

          final employee = ctrl.employee;
          final schedule = ctrl.todaySchedule;

          return RefreshIndicator(
            onRefresh: () => ctrl.loadDashboard(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // 1. Employee Header Card
                if (employee != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              employee.name.isNotEmpty
                                  ? employee.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${employee.role} • ${employee.employeeCode}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  employee.branch,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                const Text(
                  'Ca làm hôm nay',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Today Shift Card
                if (schedule == null)
                  const EmptyState(
                    icon: Icons.calendar_today_outlined,
                    message: 'Hôm nay bạn không có lịch ca làm.',
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${schedule.startTime} - ${schedule.endTime}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              _buildStatusBadge(schedule.status),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  schedule.location,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (schedule.checkInTime != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.login,
                                  size: 16,
                                  color: AppTheme.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Giờ vào: ${schedule.checkInTime}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (schedule.checkOutTime != null) ...[
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.logout,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Giờ ra: ${schedule.checkOutTime}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                const Text(
                  'Trạng thái điểm danh',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Status explanation card
                Card(
                  child: ListTile(
                    leading: Icon(
                      schedule?.status == 'CHECKED_IN'
                          ? Icons.check_circle
                          : Icons.access_time,
                      color: schedule?.status == 'CHECKED_IN'
                          ? AppTheme.success
                          : AppTheme.warning,
                      size: 32,
                    ),
                    title: Text(
                      schedule == null
                          ? 'Chưa có ca làm hôm nay'
                          : schedule.status == 'CHECKED_OUT'
                          ? 'Đã hoàn thành ca làm'
                          : schedule.status == 'CHECKED_IN'
                          ? 'Đang trong ca làm'
                          : 'Chưa vào ca',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      schedule?.status == 'CHECKED_IN'
                          ? 'Giờ vào ca đã được lưu trên hệ thống.'
                          : schedule == null
                          ? 'Lịch được cập nhật sau khi quản lý phân công.'
                          : schedule.status == 'CHECKED_OUT'
                          ? 'Giờ vào và ra ca đã được ghi nhận.'
                          : 'Quét QR do quản lý cấp để bắt đầu ca làm.',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'CHECKED_IN':
        bg = AppTheme.success.withValues(alpha: 0.12);
        fg = AppTheme.success;
        label = '✓ Đã check-in';
        break;
      case 'CHECKED_OUT':
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = '✓ Đã check-out';
        break;
      case 'LATE':
        bg = AppTheme.warning.withValues(alpha: 0.12);
        fg = AppTheme.warning;
        label = '⚠ Đi muộn';
        break;
      default:
        bg = AppTheme.primary.withValues(alpha: 0.10);
        fg = AppTheme.primary;
        label = '📅 Chưa check-in';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
