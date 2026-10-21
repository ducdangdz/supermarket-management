import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../management/manager_main_screen.dart';
import '../management/floor_plan/floor_plan_page.dart';
import '../management/shifts/shift_management_page.dart';
import '../management/schedules/schedule_management_page.dart';
import '../management/attendance_approval/attendance_approval_page.dart';
import '../management/employees/employee_management_page.dart';
import '../reports/screens/attendance_overview_report_screen.dart';
import '../reports/screens/employee_attendance_report_screen.dart';
import '../reports/screens/late_absent_report_screen.dart';
import '../reports/screens/detailed_attendance_history_screen.dart';
import '../reports/screens/export_report_screen.dart';

/// Màn hình chọn chạy ĐỘC LẬP từng chức năng của Thành viên 4
/// Giúp người dùng/giáo viên kiểm tra và chấm điểm riêng từng màn hình một cách rõ ràng.
class FeatureLauncherScreen extends StatelessWidget {
  const FeatureLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<MockDataService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'SMARTMARKET HRM - CHỌN CHỨC NĂNG CHẠY RIÊNG',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner giới thiệu & Role Switcher
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Chạy độc lập từng màn hình (Thành viên 4)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bấm vào từng nút bên dưới để mở RIÊNG BIỆT từng màn hình độc lập. Mỗi màn hình đều có nút quay lại (Back) để bạn thử màn khác.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Text(
                            'Vai trò đang thử nghiệm: ',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: dataService.currentRoleCode == 'EMPLOYEE'
                                  ? Colors.grey.shade200
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dataService.currentRoleCode,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: dataService.currentRoleCode == 'EMPLOYEE'
                                    ? Colors.grey.shade800
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRoleChip(context, dataService, 'ADMIN', '👑 Quản trị viên'),
                            const SizedBox(width: 8),
                            _buildRoleChip(context, dataService, 'MANAGER', '👔 Quản lý'),
                            const SizedBox(width: 8),
                            _buildRoleChip(context, dataService, 'HR', '📋 Nhân sự'),
                            const SizedBox(width: 8),
                            _buildRoleChip(context, dataService, 'EMPLOYEE', '👷 Nhân viên'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 1: 5 MÀN HÌNH BÁO CÁO MỚI CỦA THÀNH VIÊN 4
                _buildSectionHeader('📊 5 MÀN HÌNH BÁO CÁO RIÊNG BIỆT (YÊU CẦU MỚI)'),
                const SizedBox(height: 10),

                _buildFeatureCard(
                  context,
                  badge: 'Màn 1',
                  title: 'Tổng quan báo cáo chấm công',
                  description: 'Thống kê 6 chỉ số KPI, tỷ lệ có mặt, đi muộn & biểu đồ cột theo Ngày/Tuần/Tháng.',
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF0284C7),
                  roles: 'ADMIN, MANAGER, HR',
                  targetScreen: const AttendanceOverviewReportScreen(),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Màn 2',
                  title: 'Báo cáo chấm công theo nhân viên',
                  description: 'Lọc 5 tiêu chí: Nhân viên, Khoảng ngày, Ca, Khu vực, Trạng thái. Bảng dữ liệu chi tiết.',
                  icon: Icons.badge_rounded,
                  color: const Color(0xFF0D9488),
                  roles: 'ADMIN, MANAGER, HR',
                  targetScreen: const EmployeeAttendanceReportScreen(),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Màn 3',
                  title: 'Báo cáo đi muộn / vắng mặt',
                  description: 'Danh sách đi muộn kèm số phút trễ, người vắng mặt & bảng xếp hạng (Leaderboard).',
                  icon: Icons.alarm_off_rounded,
                  color: const Color(0xFFEA580C),
                  roles: 'ADMIN, MANAGER, HR',
                  targetScreen: const LateAbsentReportScreen(),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Màn 4',
                  title: 'Lịch sử chấm công chi tiết (GPS, QR, Ảnh)',
                  description: 'Xem tọa độ GPS, độ chính xác ±m, mã QR và ảnh bằng chứng. Tự khóa dữ liệu nếu là EMPLOYEE.',
                  icon: Icons.history_edu_rounded,
                  color: const Color(0xFF7C3AED),
                  roles: 'TẤT CẢ (EMPLOYEE chỉ xem của mình)',
                  targetScreen: const DetailedAttendanceHistoryScreen(),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Màn 5',
                  title: 'Màn hình xuất báo cáo',
                  description: 'Chọn khoảng thời gian, chọn nhân sự, xuất tệp Excel (.xlsx) hoặc PDF (.pdf) về máy.',
                  icon: Icons.file_download_rounded,
                  color: const Color(0xFF059669),
                  roles: 'ADMIN, MANAGER, HR',
                  targetScreen: const ExportReportScreen(),
                ),

                const SizedBox(height: 24),

                // SECTION 2: CÁC CHỨC NĂNG QUẢN LÝ SIÊU THỊ ĐÃ LÀM
                _buildSectionHeader('🏢 CÁC CHỨC NĂNG QUẢN LÝ KHÁC (CHẠY RIÊNG LẺ)'),
                const SizedBox(height: 10),

                _buildFeatureCard(
                  context,
                  badge: 'Tính năng',
                  title: 'Sơ đồ mặt bằng 2D siêu thị trực quan',
                  description: 'Sơ đồ tương tác zoom/pan 6 khu vực, quầy thu ngân, kho hàng và vị trí nhân sự thời gian thực.',
                  icon: Icons.map_rounded,
                  color: AppColors.primary,
                  roles: 'MANAGER, ADMIN',
                  targetScreen: Scaffold(
                    appBar: AppBar(
                      title: const Text('Sơ đồ mặt bằng 2D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    body: const FloorPlanPage(),
                  ),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Tính năng',
                  title: 'Quản lý danh sách ca làm việc',
                  description: 'Thêm, sửa, cấu hình giờ ca sáng/chiều/đêm, thời gian cho phép trễ, yêu cầu GPS/QR.',
                  icon: Icons.work_history_rounded,
                  color: const Color(0xFF2563EB),
                  roles: 'MANAGER, ADMIN',
                  targetScreen: Scaffold(
                    appBar: AppBar(
                      title: const Text('Quản lý Ca làm việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    body: const ShiftManagementPage(),
                  ),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Tính năng',
                  title: 'Phân ca làm việc (Xếp lịch)',
                  description: 'Xếp ca theo ngày, kiểm tra Business Rule chống trùng ca và chống quá tải khu vực.',
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF4F46E5),
                  roles: 'MANAGER, ADMIN',
                  targetScreen: Scaffold(
                    appBar: AppBar(
                      title: const Text('Phân ca làm việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    body: const ScheduleManagementPage(),
                  ),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Tính năng',
                  title: 'Phê duyệt chấm công bất thường',
                  description: 'Xem xét và duyệt các trường hợp đi muộn, sai vị trí GPS kèm xem ảnh bằng chứng quầy.',
                  icon: Icons.fact_check_rounded,
                  color: const Color(0xFFD97706),
                  roles: 'MANAGER, ADMIN',
                  targetScreen: Scaffold(
                    appBar: AppBar(
                      title: const Text('Phê duyệt chấm công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    body: const AttendanceApprovalPage(),
                  ),
                ),

                _buildFeatureCard(
                  context,
                  badge: 'Tính năng',
                  title: 'Quản lý nhân viên chi nhánh',
                  description: 'Tìm kiếm, lọc vai trò, thêm nhân viên mới và khóa/mở khóa tài khoản nhân sự.',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF475569),
                  roles: 'MANAGER, HR, ADMIN',
                  targetScreen: Scaffold(
                    appBar: AppBar(
                      title: const Text('Quản lý nhân viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    body: const EmployeeManagementPage(),
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION 3: MỞ GIAO DIỆN GỘP CHUNG (TOÀN BỘ HỆ THỐNG)
                _buildSectionHeader('🌐 GIAO DIỆN TỔNG HỢP (FULL HỆ THỐNG)'),
                const SizedBox(height: 10),

                _buildFeatureCard(
                  context,
                  badge: 'Gộp chung',
                  title: 'Xem toàn bộ ứng dụng gộp (Manager Dashboard)',
                  description: 'Giao diện tích hợp tất cả các tab điều hướng dưới đáy (Tổng quan, Mặt bằng, Nhân viên, Ca làm, Xếp lịch, Báo cáo).',
                  icon: Icons.grid_view_rounded,
                  color: const Color(0xFF1E293B),
                  roles: 'TẤT CẢ TÍCH HỢP',
                  targetScreen: const ManagerMainScreen(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRoleChip(
      BuildContext context, MockDataService data, String roleCode, String label) {
    final isSelected = data.currentRoleCode == roleCode;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      onSelected: (_) => data.setCurrentRole(roleCode),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String badge,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String roles,
    required Widget targetScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => targetScreen),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '👤 Quyền truy cập: $roles',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

