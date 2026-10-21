import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../widgets/role_guard_wrapper.dart';

/// MÀN 1: Màn hình tổng quan báo cáo chấm công
/// Ai dùng: ADMIN, MANAGER, HR
class AttendanceOverviewReportScreen extends StatefulWidget {
  const AttendanceOverviewReportScreen({super.key});

  @override
  State<AttendanceOverviewReportScreen> createState() =>
      _AttendanceOverviewReportScreenState();
}

class _AttendanceOverviewReportScreenState
    extends State<AttendanceOverviewReportScreen> {
  String _timeRange = 'Tuần này'; // 'Hôm nay', 'Tuần này', 'Tháng này'

  @override
  Widget build(BuildContext context) {
    return RoleGuardWrapper(
      allowedRoles: const ['ADMIN', 'MANAGER', 'HR'],
      screenTitle: 'Tổng quan báo cáo chấm công',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            '1. Tổng quan báo cáo chấm công',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<MockDataService>(
          builder: (context, data, _) {
            final totalEmployees = data.totalEmployeesCount;
            final scheduledToday = data.todayScheduledCount;
            final checkedIn = data.todayCheckedInCount;
            final notCheckedIn = data.todayNotCheckedInCount;
            final lateCount = data.todayLateCount;
            final checkedOut = data.todayCheckedOutCount;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header ngày tháng & thông tin chi nhánh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            data.currentBranch.branchName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Vai trò: ${data.currentRoleCode}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // LƯỚI 6 THẺ THỐNG KÊ THEO ĐỀ BÀI
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard(
                        title: 'Tổng số nhân viên',
                        count: '$totalEmployees',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primary,
                        bgColor: const Color(0xFFEFF6FF),
                      ),
                      _buildMetricCard(
                        title: 'Có lịch làm hôm nay',
                        count: '$scheduledToday',
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                      _buildMetricCard(
                        title: 'Đã check-in',
                        count: '$checkedIn',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green.shade700,
                        bgColor: const Color(0xFFDCFCE7),
                      ),
                      _buildMetricCard(
                        title: 'Chưa check-in',
                        count: '$notCheckedIn',
                        icon: Icons.pending_actions_rounded,
                        color: Colors.red.shade700,
                        bgColor: const Color(0xFFFFE4E6),
                      ),
                      _buildMetricCard(
                        title: 'Đi muộn',
                        count: '$lateCount',
                        icon: Icons.access_time_filled_rounded,
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                      ),
                      _buildMetricCard(
                        title: 'Đã check-out',
                        count: '$checkedOut',
                        icon: Icons.exit_to_app_rounded,
                        color: Colors.purple.shade700,
                        bgColor: const Color(0xFFF3E8FF),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // KHU VỰC BIỂU ĐỒ CHẤM CÔNG THEO NGÀY / TUẦN / THÁNG
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Biểu đồ chuyên cần',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            // Bộ chuyển Ngày / Tuần / Tháng
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: ['Hôm nay', 'Tuần này', 'Tháng này'].map((tab) {
                                  final isSelected = _timeRange == tab;
                                  return GestureDetector(
                                    onTap: () => setState(() => _timeRange = tab),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        tab,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Chú giải biểu đồ
                        Row(
                          children: [
                            _buildChartLegend(Colors.green, 'Đúng giờ (85%)'),
                            const SizedBox(width: 14),
                            _buildChartLegend(Colors.orange, 'Đi muộn (10%)'),
                            const SizedBox(width: 14),
                            _buildChartLegend(Colors.red, 'Vắng mặt (5%)'),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Vẽ biểu đồ cột trực quan
                        _buildAttendanceBarChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAttendanceBarChart() {
    final days = _timeRange == 'Hôm nay'
        ? ['06:00', '08:00', '10:00', '12:00', '14:00', '16:00', '18:00']
        : _timeRange == 'Tuần này'
            ? ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN']
            : ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];

    final presentRatios = _timeRange == 'Hôm nay'
        ? [0.9, 0.85, 0.95, 0.8, 0.88, 0.92, 0.85]
        : _timeRange == 'Tuần này'
            ? [0.85, 0.92, 0.88, 0.8, 0.95, 0.9, 0.82]
            : [0.87, 0.9, 0.85, 0.92];

    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(days.length, (idx) {
          final presentRatio = presentRatios[idx];
          final lateRatio = (1.0 - presentRatio) * 0.7;
          final absentRatio = 1.0 - presentRatio - lateRatio;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cột xếp chồng tỷ lệ
              Container(
                width: 20,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Absent
                    Container(
                      height: 140 * absentRatio,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    // Late
                    Container(
                      height: 140 * lateRatio,
                      color: Colors.orange,
                    ),
                    // Present
                    Container(
                      height: 140 * presentRatio,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                days[idx],
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          );
        }),
      ),
    );
  }
}

