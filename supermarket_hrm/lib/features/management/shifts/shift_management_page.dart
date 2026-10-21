import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';

class ShiftManagementPage extends StatelessWidget {
  const ShiftManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý ca làm việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.shifts.length,
        itemBuilder: (ctx, idx) {
          final shift = data.shifts[idx];
          return _buildShiftCard(context, shift, data);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Thêm ca làm'),
        onPressed: () => _showAddShiftDialog(context, data),
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context, Shift shift, MockDataService data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    shift.shiftName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Switch(
                value: shift.isActive,
                activeColor: AppColors.primary,
                onChanged: (_) {
                  data.toggleShiftActive(shift.shiftId);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Giờ làm & cho phép đi muộn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${shift.startTime.substring(0, 5)} - ${shift.endTime.substring(0, 5)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  'Cho phép trễ: ${shift.allowedLateMinutes} phút',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Các ràng buộc (QR, GPS, Evidence)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildConstraintBadge('Quét QR', shift.requireQr, Icons.qr_code_scanner_rounded),
              _buildConstraintBadge('Ảnh bằng chứng', shift.requireEvidence, Icons.camera_alt_rounded),
              _buildConstraintBadge('Kiểm tra GPS', shift.requireLocation, Icons.location_on_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConstraintBadge(String label, bool isRequired, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRequired ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRequired ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isRequired ? Colors.green.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isRequired ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddShiftDialog(BuildContext context, MockDataService data) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final lateCtrl = TextEditingController(text: '15');
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 16, minute: 0);
    bool reqQr = true;
    bool reqEvidence = true;
    bool reqLocation = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Thêm ca làm việc mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên ca làm (VD: Ca Trưa Phụ Trợ) *'),
                  ),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Mã ca (VD: CA_TRUA) *'),
                  ),
                  TextField(
                    controller: lateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số phút cho phép trễ'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: startTime);
                            if (picked != null) setModalState(() => startTime = picked);
                          },
                          child: Text('Giờ vào: ${startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: endTime);
                            if (picked != null) setModalState(() => endTime = picked);
                          },
                          child: Text('Giờ ra: ${endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Bắt buộc quét mã QR', style: TextStyle(fontSize: 13)),
                    value: reqQr,
                    onChanged: (v) => setModalState(() => reqQr = v),
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text('Bắt buộc chụp ảnh bằng chứng', style: TextStyle(fontSize: 13)),
                    value: reqEvidence,
                    onChanged: (v) => setModalState(() => reqEvidence = v),
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text('Bắt buộc vị trí GPS', style: TextStyle(fontSize: 13)),
                    value: reqLocation,
                    onChanged: (v) => setModalState(() => reqLocation = v),
                    dense: true,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập tên và mã ca')),
                    );
                    return;
                  }

                  String formatTime(TimeOfDay t) =>
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

                  data.addShift(Shift(
                    shiftId: 0,
                    branchId: data.currentBranch.branchId,
                    shiftCode: codeCtrl.text.trim(),
                    shiftName: nameCtrl.text.trim(),
                    startTime: formatTime(startTime),
                    endTime: formatTime(endTime),
                    allowedLateMinutes: int.tryParse(lateCtrl.text) ?? 15,
                    requireQr: reqQr,
                    requireEvidence: reqEvidence,
                    requireLocation: reqLocation,
                  ));

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã tạo ca làm ${nameCtrl.text}')),
                  );
                },
                child: const Text('Tạo ca làm'),
              ),
            ],
          );
        },
      ),
    );
  }
}
