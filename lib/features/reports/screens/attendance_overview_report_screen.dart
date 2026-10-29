import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_stat_card.dart';
import '../../../services/mock_data_service.dart';
import '../widgets/role_guard_wrapper.dart';

class AttendanceOverviewReportScreen extends StatefulWidget {
  const AttendanceOverviewReportScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<AttendanceOverviewReportScreen> createState() =>
      _AttendanceOverviewReportScreenState();
}

class _AttendanceOverviewReportScreenState
    extends State<AttendanceOverviewReportScreen> {
  String _timeRange = 'Tuần này';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final scheduled = data.todayScheduledCount;
    final checkedIn = data.todayCheckedInCount;
    return RoleGuardWrapper(
      allowedRoles: const ['ADMIN', 'MANAGER', 'HR'],
      screenTitle: 'Tổng quan báo cáo chấm công',
      child: Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(title: const Text('Tổng quan chấm công')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, dd/MM/yyyy',
                        'vi',
                      ).format(DateTime.now()),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.currentBranch.branchName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text('Vai trò: ${data.currentRoleCode}'),
                  backgroundColor: AppColors.primaryLight,
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppStatGrid(
              children: [
                AppStatCard(
                  label: 'Tổng số nhân viên',
                  value: '${data.totalEmployeesCount}',
                  icon: Icons.people_outline,
                ),
                AppStatCard(
                  label: 'Có lịch hôm nay',
                  value: '$scheduled',
                  icon: Icons.calendar_month_outlined,
                ),
                AppStatCard(
                  label: 'Đã check-in',
                  value: '$checkedIn',
                  icon: Icons.login_rounded,
                  color: AppColors.secondary,
                ),
                AppStatCard(
                  label: 'Chưa check-in',
                  value: '${data.todayNotCheckedInCount}',
                  icon: Icons.pending_actions_outlined,
                ),
                AppStatCard(
                  label: 'Đi muộn',
                  value: '${data.todayLateCount}',
                  icon: Icons.access_time_rounded,
                  color: AppColors.statusLate,
                ),
                AppStatCard(
                  label: 'Đã check-out',
                  value: '${data.todayCheckedOutCount}',
                  icon: Icons.logout_rounded,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tỷ lệ chấm công hôm nay',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: scheduled == 0
                          ? 0
                          : (checkedIn / scheduled).clamp(0, 1),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.secondary,
                      backgroundColor: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$checkedIn / $scheduled nhân viên có lịch đã check-in',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xu hướng chấm công',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Biểu đồ minh họa từ dữ liệu mẫu',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final range in [
                          'Hôm nay',
                          'Tuần này',
                          'Tháng này',
                        ])
                          ChoiceChip(
                            label: Text(range),
                            selected: range == _timeRange,
                            onSelected: (_) =>
                                setState(() => _timeRange = range),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _legend('Có mặt', AppColors.secondary),
                        _legend('Đi muộn', AppColors.statusLate),
                        _legend('Vắng', AppColors.statusAbsent),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _chart(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _chart() {
    final labels = _timeRange == 'Hôm nay'
        ? ['06h', '08h', '10h', '12h', '14h', '16h', '18h']
        : _timeRange == 'Tuần này'
        ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
        : ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
    final present = _timeRange == 'Hôm nay'
        ? [.9, .85, .95, .8, .88, .92, .85]
        : _timeRange == 'Tuần này'
        ? [.85, .92, .88, .8, .95, .9, .82]
        : [.87, .9, .85, .92];
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      width: 20,
                      height: 140,
                      child: Column(
                        children: [
                          Expanded(
                            flex: ((1 - present[i]) * 300).round(),
                            child: const ColoredBox(
                              color: AppColors.statusAbsent,
                              child: SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            flex: ((1 - present[i]) * 700).round(),
                            child: const ColoredBox(
                              color: AppColors.statusLate,
                              child: SizedBox.expand(),
                            ),
                          ),
                          Expanded(
                            flex: (present[i] * 1000).round(),
                            child: const ColoredBox(
                              color: AppColors.secondary,
                              child: SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    child: Text(
                      labels[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
