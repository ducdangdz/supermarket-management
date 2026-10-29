import '../../../core/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';
import '../widgets/attendance_detail_modal.dart';
import '../widgets/role_guard_wrapper.dart';

/// MÀN 2: Màn hình báo cáo chấm công theo nhân viên
/// Ai dùng: ADMIN, MANAGER, HR
class EmployeeAttendanceReportScreen extends StatefulWidget {
  const EmployeeAttendanceReportScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<EmployeeAttendanceReportScreen> createState() =>
      _EmployeeAttendanceReportScreenState();
}

class _EmployeeAttendanceReportScreenState
    extends State<EmployeeAttendanceReportScreen> {
  int? _selectedEmployeeId; // null = Tất cả
  DateTimeRange? _selectedDateRange;
  int? _selectedShiftId; // null = Tất cả
  int? _selectedWorkAreaId; // null = Tất cả
  String _selectedStatus =
      'ALL'; // ALL, PRESENT, LATE, NOT_CHECKED_IN, CHECKED_OUT

  @override
  Widget build(BuildContext context) {
    return RoleGuardWrapper(
      allowedRoles: const ['ADMIN', 'MANAGER', 'HR'],
      screenTitle: 'Báo cáo chấm công theo nhân viên',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          primary: !widget.embedded,
          toolbarHeight: widget.embedded ? 0 : 64,
          automaticallyImplyLeading: !widget.embedded,
          title: widget.embedded
              ? null
              : const Text(
                  'Báo cáo chấm công theo nhân viên',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
          elevation: 0,
        ),
        body: Consumer<MockDataService>(
          builder: (context, data, _) {
            // Lấy danh sách bản ghi theo 5 tiêu chí lọc
            final rows = data.filterDetailedRecords(
              employeeId: _selectedEmployeeId,
              dateRange: _selectedDateRange,
              shiftId: _selectedShiftId,
              workAreaId: _selectedWorkAreaId,
              statusFilter: _selectedStatus,
            );

            return Column(
              children: [
                // KHU VỰC BỘ LỌC (FILTERS)
                _buildFilterHeader(context, data),

                // TIÊU ĐỀ BẢNG DÒNG
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppColors.primaryLight,
                  child: Row(
                    children: [
                      Text(
                        'Kết quả: ${rows.length} lượt chấm công',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedEmployeeId != null ||
                          _selectedDateRange != null ||
                          _selectedShiftId != null ||
                          _selectedWorkAreaId != null ||
                          _selectedStatus != 'ALL')
                        GestureDetector(
                          onTap: _resetFilters,
                          child: const Row(
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Xóa bộ lọc',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // DANH SÁCH DÒNG BÁO CÁO (Tên NV | Ngày | Ca | Khu vực | Check-in | Check-out | Trạng thái)
                Expanded(
                  child: rows.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.filter_list_off_rounded,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Không tìm thấy bản ghi nào khớp với bộ lọc',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: _resetFilters,
                                child: const Text('Đặt lại bộ lọc'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: rows.length,
                          itemBuilder: (ctx, idx) {
                            final row = rows[idx];
                            final emp = row['employee'] as Employee?;
                            final shift = row['shift'] as Shift?;
                            final area = row['area'] as WorkArea?;
                            final schedule = row['schedule'] as WorkSchedule;
                            final record = row['record'] as AttendanceRecord?;

                            return _buildAttendanceRowCard(
                              context,
                              emp,
                              shift,
                              area,
                              schedule,
                              record,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedEmployeeId = null;
      _selectedDateRange = null;
      _selectedShiftId = null;
      _selectedWorkAreaId = null;
      _selectedStatus = 'ALL';
    });
  }

  Widget _buildFilterHeader(BuildContext context, MockDataService data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Dòng 1: Chọn Nhân viên & Chọn Khoảng ngày
          Row(
            children: [
              // Chọn Nhân viên
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedEmployeeId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Nhân viên',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả nhân viên'),
                    ),
                    ...data.employees.map(
                      (e) => DropdownMenuItem(
                        value: e.employeeId,
                        child: Text(e.fullName),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedEmployeeId = val),
                ),
              ),
              const SizedBox(width: 8),
              // Chọn Khoảng ngày
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Khoảng ngày'
                        : '${DateFormat("dd/MM").format(_selectedDateRange!.start)} - ${DateFormat("dd/MM").format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                      initialDateRange:
                          _selectedDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(
                              const Duration(days: 7),
                            ),
                            end: DateTime.now(),
                          ),
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dòng 2: Ca làm & Khu vực & Trạng thái
          Row(
            children: [
              // Ca làm
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedShiftId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Ca làm',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả ca'),
                    ),
                    ...data.shifts.map(
                      (s) => DropdownMenuItem(
                        value: s.shiftId,
                        child: Text(s.shiftName),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedShiftId = val),
                ),
              ),
              const SizedBox(width: 8),
              // Khu vực
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedWorkAreaId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Khu vực',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả khu vực'),
                    ),
                    ...data.workAreas.map(
                      (a) => DropdownMenuItem(
                        value: a.workAreaId,
                        child: Text(a.areaName),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedWorkAreaId = val),
                ),
              ),
              const SizedBox(width: 8),
              // Trạng thái
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'PRESENT', child: Text('Đúng giờ')),
                    DropdownMenuItem(value: 'LATE', child: Text('Đi muộn')),
                    DropdownMenuItem(
                      value: 'NOT_CHECKED_IN',
                      child: Text('Chưa vào'),
                    ),
                    DropdownMenuItem(
                      value: 'CHECKED_OUT',
                      child: Text('Đã check-out'),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedStatus = val ?? 'ALL'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRowCard(
    BuildContext context,
    Employee? emp,
    Shift? shift,
    WorkArea? area,
    WorkSchedule schedule,
    AttendanceRecord? record,
  ) {
    final checkIn = record?.checkInAt;
    final checkOut = record?.checkOutAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AttendanceDetailModal.show(
          context,
          employee: emp,
          shift: shift,
          area: area,
          schedule: schedule,
          record: record,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(radius: 16, imageUrl: emp?.avatarUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      emp?.fullName ?? 'Chưa rõ nhân viên',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStatusChip(
                record?.attendanceStatus ?? 'NOT_CHECKED_IN',
                isCheckedOut: checkOut != null,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(schedule.workDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    shift?.shiftName ?? 'Ca làm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    area?.areaName ?? 'Chưa rõ khu vực',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Text(
                    'Vào: ${checkIn == null ? "--:--:--" : DateFormat("HH:mm:ss").format(checkIn)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Ra: ${checkOut == null ? "--:--:--" : DateFormat("HH:mm:ss").format(checkOut)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, {bool isCheckedOut = false}) {
    Color bg = AppColors.primaryLight;
    Color fg = AppColors.primary;
    String text = status;

    if (isCheckedOut) {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF4338CA);
      text = 'Đã check-out';
    } else if (status == 'PRESENT') {
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
