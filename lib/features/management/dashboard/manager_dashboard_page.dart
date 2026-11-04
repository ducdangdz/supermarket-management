import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../services/mock_data_service.dart';

class ManagerDashboardPage extends StatelessWidget {
  const ManagerDashboardPage({super.key, required this.onNavigateToTab});
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan chi nhánh')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            data.currentBranch.branchName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppStatGrid(
            children: [
              AppStatCard(
                label: 'Có mặt hôm nay',
                value: '${data.todayPresentCount}',
                icon: Icons.how_to_reg_outlined,
                color: AppColors.secondary,
              ),
              AppStatCard(
                label: 'Đi muộn',
                value: '${data.todayLateCount}',
                icon: Icons.access_time_rounded,
                color: AppColors.statusLate,
              ),
              AppStatCard(
                label: 'Sai vị trí',
                value: '${data.todayInvalidLocationCount}',
                icon: Icons.location_off_outlined,
                color: AppColors.statusInvalid,
              ),
              AppStatCard(
                label: 'Chờ phê duyệt',
                value: '${data.pendingApprovalCount}',
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (data.pendingApprovalCount > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cần bạn xem xét',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Có ${data.pendingApprovalCount} bản ghi chấm công đang chờ phê duyệt.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => onNavigateToTab(6),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Xem bản ghi chờ duyệt'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Ca làm việc hôm nay',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () => onNavigateToTab(4),
                label: const Text('Xếp lịch làm việc'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final shift in data.shifts)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(
                  Icons.work_history_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  shift.shiftName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${shift.startTime} – ${shift.endTime}'),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
                onTap: () => onNavigateToTab(3),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Công việc thường dùng',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => onNavigateToTab(2),
                icon: const Icon(Icons.people_outline),
                label: const Text('Nhân viên'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigateToTab(1),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Mặt bằng'),
              ),
              OutlinedButton.icon(
                onPressed: () => onNavigateToTab(5),
                icon: const Icon(Icons.insights_outlined),
                label: const Text('Báo cáo'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
