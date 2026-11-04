import '../../../core/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';

class ScheduleManagementPage extends StatefulWidget {
  const ScheduleManagementPage({super.key});

  @override
  State<ScheduleManagementPage> createState() => _ScheduleManagementPageState();
}

class _ScheduleManagementPageState extends State<ScheduleManagementPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    // Lọc lịch làm theo ngày được chọn
    final daySchedules = data.workSchedules
        .where(
          (s) =>
              s.workDate.year == _selectedDate.year &&
              s.workDate.month == _selectedDate.month &&
              s.workDate.day == _selectedDate.day,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Phân công lịch làm việc',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Bộ chọn ngày
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'EEEE, dd/MM/yyyy',
                              'vi',
                            ).format(_selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // Tổng quan số lượng phân công
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primaryLight,
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng: ${daySchedules.length} lượt phân công',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Chi nhánh: ${data.currentBranch.branchCode}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Danh sách phân công
          Expanded(
            child: daySchedules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có lịch làm việc nào vào ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(),
                          icon: const Icon(Icons.add),
                          label: const Text('Phân công ngay'),
                          onPressed: () =>
                              _showAssignScheduleDialog(context, data),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: daySchedules.length,
                    itemBuilder: (ctx, idx) {
                      final schedule = daySchedules[idx];
                      final emp = data.getEmployeeById(schedule.employeeId);
                      final shift = data.getShiftById(schedule.shiftId);
                      final area = data.getWorkAreaById(schedule.workAreaId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            AppAvatar(
                              radius: 20,
                              imageUrl: emp?.avatarUrl ?? '',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    emp?.fullName ?? 'Chưa rõ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${shift?.shiftName ?? ""}  (${shift?.startTime.substring(0, 5)} - ${shift?.endTime.substring(0, 5)})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.place_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          area?.areaName ?? 'Chưa rõ khu vực',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Đã xếp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Xếp lịch làm'),
        onPressed: () => _showAssignScheduleDialog(context, data),
      ),
    );
  }

  void _showAssignScheduleDialog(BuildContext context, MockDataService data) {
    int? selectedEmpId = data.employees.firstOrNull?.employeeId;
    int? selectedShiftId = data.shifts.firstOrNull?.shiftId;
    int? selectedAreaId = data.workAreas.firstOrNull?.workAreaId;
    DateTime scheduleDate = _selectedDate;
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text(
              'Phân công ca làm việc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Chọn nhân viên:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: selectedEmpId,
                    isExpanded: true,
                    items: data.employees.where((e) => e.isActive).map((emp) {
                      return DropdownMenuItem(
                        value: emp.employeeId,
                        child: Text('${emp.fullName} (${emp.employeeCode})'),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedEmpId = val),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    '2. Chọn ca làm:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: selectedShiftId,
                    isExpanded: true,
                    items: data.shifts.where((s) => s.isActive).map((shift) {
                      return DropdownMenuItem(
                        value: shift.shiftId,
                        child: Text(shift.shiftName),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedShiftId = val),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    '3. Chọn khu vực làm việc (Trực quan):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: selectedAreaId,
                    isExpanded: true,
                    items: data.workAreas.map((area) {
                      return DropdownMenuItem(
                        value: area.workAreaId,
                        child: Text(
                          '${area.areaName} (Tối đa: ${area.maxEmployees ?? "∞"})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedAreaId = val),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    '4. Ngày làm việc:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: Text(DateFormat('dd/MM/yyyy').format(scheduleDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: scheduleDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 7),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setModalState(() => scheduleDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú phân công (tùy chọn)',
                      hintText: 'VD: Hỗ trợ kiểm kê quầy 3...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(),
                onPressed: () async {
                  try {
                    if (selectedEmpId == null ||
                        selectedShiftId == null ||
                        selectedAreaId == null) {
                      return;
                    }

                    // Gọi nghiệp vụ kiểm tra ràng buộc (Business Rules)
                    final (success, message) = await data.assignSchedule(
                      employeeId: selectedEmpId!,
                      shiftId: selectedShiftId!,
                      workAreaId: selectedAreaId!,
                      date: scheduleDate,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );

                    if (!success) {
                      // Vi phạm ràng buộc (vd: trùng lịch làm hoặc vượt max_employees)
                      showDialog(
                        context: context,
                        builder: (alertCtx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text('Lỗi phân công'),
                            ],
                          ),
                          content: Text(message),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(alertCtx),
                              child: const Text('Đã hiểu'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Xác nhận phân công'),
              ),
            ],
          );
        },
      ),
    );
  }
}
