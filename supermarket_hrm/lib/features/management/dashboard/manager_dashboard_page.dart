import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';

class ManagerDashboardPage extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const ManagerDashboardPage({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header chi nhánh
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.currentBranch.branchName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.currentBranch.address,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickHeaderStat('Tổng nhân sự', '${data.totalEmployeesCount}', Icons.people_outline),
                        Container(width: 1, height: 28, color: Colors.white24),
                        _buildQuickHeaderStat('Ca hôm nay', '${data.todayScheduledCount}', Icons.calendar_today_outlined),
                        Container(width: 1, height: 28, color: Colors.white24),
                        _buildQuickHeaderStat('Cần duyệt', '${data.pendingApprovalCount}', Icons.notifications_active_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nội dung chính
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Thẻ trực quan hóa mặt bằng (Call to action nổi bật nhất)
                _buildFloorPlanBanner(context),
                const SizedBox(height: 20),

                // Thống kê chuyên cần hôm nay
                const Text(
                  'Tình hình chuyên cần hôm nay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Đúng giờ',
                        count: '${data.todayPresentCount}',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.statusPresent,
                        bgTint: const Color(0xFFE6F8F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Đi muộn',
                        count: '${data.todayLateCount}',
                        icon: Icons.access_time_rounded,
                        color: AppColors.statusLate,
                        bgTint: const Color(0xFFFFF4E5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Sai vị trí',
                        count: '${data.todayInvalidLocationCount}',
                        icon: Icons.location_off_rounded,
                        color: AppColors.statusInvalid,
                        bgTint: const Color(0xFFFFEBEE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Chờ duyệt',
                        count: '${data.pendingApprovalCount}',
                        icon: Icons.hourglass_top_rounded,
                        color: Colors.purple,
                        bgTint: const Color(0xFFF3E8FF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Danh sách ca làm việc hôm nay
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ca làm việc hôm nay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigateToTab(3), // Chuyển sang Quản lý ca
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...data.shifts.map((shift) => _buildShiftCard(shift, data)),

                const SizedBox(height: 20),

                // Chấm công cần duyệt gấp
                if (data.pendingApprovalCount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cần phê duyệt bất thường',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onNavigateToTab(5), // Chuyển sang Duyệt chấm công
                        child: const Text('Xử lý ngay'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildPendingApprovalBanner(context, data),
                ],

                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloorPlanBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1E6091)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onNavigateToTab(1), // Tab 1: Sơ đồ mặt bằng
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.map_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sơ đồ mặt bằng 2D trực quan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Xem vị trí thực tế của nhân viên tại các quầy thu ngân, kho & thực phẩm.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgTint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(Shift shift, MockDataService data) {
    final assignedCount = data.workSchedules
        .where((s) => s.shiftId == shift.shiftId && s.workDate.day == DateTime.now().day)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work_history_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.shiftName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)}  •  Cho phép trễ: ${shift.allowedLateMinutes}p',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$assignedCount NV',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalBanner(BuildContext context, MockDataService data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57F17), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Có ${data.pendingApprovalCount} trường hợp cần xem xét!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF57F17),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Chấm công đi muộn hoặc ngoài bán kính GPS kèm ảnh bằng chứng.',
                  style: TextStyle(color: Colors.brown, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
