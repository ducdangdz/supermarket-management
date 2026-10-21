import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';
import '../widgets/attendance_detail_modal.dart';

/// MÀN 4: Màn hình lịch sử chấm công chi tiết
/// Ai dùng:
/// - EMPLOYEE: chỉ xem lịch sử của chính mình.
/// - MANAGER, HR, ADMIN: xem lịch sử của nhiều nhân viên.
class DetailedAttendanceHistoryScreen extends StatefulWidget {
  const DetailedAttendanceHistoryScreen({super.key});

  @override
  State<DetailedAttendanceHistoryScreen> createState() =>
      _DetailedAttendanceHistoryScreenState();
}

class _DetailedAttendanceHistoryScreenState
    extends State<DetailedAttendanceHistoryScreen> {
  int? _managerSelectedEmployeeId; // Chỉ dùng khi vai trò là ADMIN/MANAGER/HR

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final isEmployeeRole = data.currentRoleCode == 'EMPLOYEE';

    // Nếu là EMPLOYEE -> Chỉ lấy đúng ID của nhân viên đang đăng nhập
    // Nếu là MANAGER/HR/ADMIN -> Lấy theo dropdown hoặc tất cả
    final effectiveEmpId =
        isEmployeeRole ? data.currentLoggedInEmployeeId : _managerSelectedEmployeeId;

    final historyRows = data.filterDetailedRecords(
      employeeId: effectiveEmpId,
    );

    final currentEmpInfo = data.getEmployeeById(data.currentLoggedInEmployeeId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '4. Lịch sử chấm công chi tiết',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // PHẦN BANNER PHÂN QUYỀN & CHỌN NHÂN VIÊN
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEmployeeRole) ...[
                  // Giao diện khi là EMPLOYEE (Khóa xem của chính mình)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              NetworkImage(currentEmpInfo?.avatarUrl ?? ''),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currentEmpInfo?.fullName} (Chính bạn)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '${currentEmpInfo?.employeeCode}  •  Vai trò: EMPLOYEE (Chỉ xem lịch sử cá nhân)',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock_outline_rounded,
                            size: 18, color: Colors.green),
                      ],
                    ),
                  ),
                ] else ...[
                  // Giao diện khi là ADMIN / MANAGER / HR (Có quyền chọn bất kỳ nhân viên nào)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.currentRoleCode,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Xem lịch sử nhân viên:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _managerSelectedEmployeeId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      hintText: 'Tất cả nhân viên',
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Tất cả nhân viên')),
                      ...data.employees.map((e) => DropdownMenuItem(
                          value: e.employeeId,
                          child: Text('${e.fullName} (${e.employeeCode})'))),
                    ],
                    onChanged: (val) {
                      setState(() => _managerSelectedEmployeeId = val);
                    },
                  ),
                ],
              ],
            ),
          ),

          // TIÊU ĐỀ DANH SÁCH & HƯỚNG DẪN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primaryLight,
            child: const Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Chạm một dòng để xem: Giờ in/out, QR, GPS accuracy, ảnh minh chứng',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // DANH SÁCH LỊCH SỬ CHẤM CÔNG CHI TIẾT
          Expanded(
            child: historyRows.isEmpty
                ? const Center(
                    child: Text('Chưa có dữ liệu chấm công cho mục này.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: historyRows.length,
                    itemBuilder: (ctx, idx) {
                      final item = historyRows[idx];
                      final emp = item['employee'] as Employee?;
                      final shift = item['shift'] as Shift?;
                      final area = item['area'] as WorkArea?;
                      final schedule = item['schedule'] as WorkSchedule;
                      final record = item['record'] as AttendanceRecord?;

                      return _buildHistoryCard(
                          context, emp, shift, area, schedule, record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    Employee? emp,
    Shift? shift,
    WorkArea? area,
    WorkSchedule schedule,
    AttendanceRecord? record,
  ) {
    final checkIn = record?.checkInAt;
    final checkOut = record?.checkOutAt;
    final status = record?.attendanceStatus ?? 'NOT_CHECKED_IN';
    final hasEvidence = record?.evidence != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Chạm để xem modal chi tiết: QR, GPS, ảnh, độ chính xác
            AttendanceDetailModal.show(
              context,
              employee: emp,
              shift: shift,
              area: area,
              schedule: schedule,
              record: record,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Tên NV & Ngày & Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(emp?.avatarUrl ?? ''),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          emp?.fullName ?? 'Chưa rõ NV',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 8),

                // Ngày & Ca & Khu vực
                Text(
                  '${DateFormat("EEEE, dd/MM/yyyy", "vi").format(schedule.workDate)} • ${shift?.shiftName ?? ""} • ${area?.areaName ?? ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Hộp tóm tắt GPS & QR
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.login_rounded, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Vào: ${checkIn != null ? DateFormat("HH:mm:ss").format(checkIn) : "--:--"}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.logout_rounded, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Ra: ${checkOut != null ? DateFormat("HH:mm:ss").format(checkOut) : "--:--"}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.gps_fixed_rounded, size: 13, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Độ chính xác: ±${record?.checkInAccuracyMeters ?? 3.5}m',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (hasEvidence) ...[
                                const Icon(Icons.photo_camera_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                const Text('Có ảnh', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                              ],
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = AppColors.primaryLight;
    Color fg = AppColors.primary;
    String text = status;

    if (status == 'PRESENT') {
      bg = const Color(0xFFDCFCE7);
      fg = Colors.green.shade800;
      text = 'Đúng giờ';
    } else if (status == 'LATE') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      text = 'Đi muộn';
    } else if (status == 'INVALID_LOCATION') {
      bg = const Color(0xFFFFE4E6);
      fg = Colors.red.shade800;
      text = 'Sai vị trí';
    } else if (status == 'NOT_CHECKED_IN') {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      text = 'Chưa check-in';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

