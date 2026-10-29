import 'shift_qr_dialog.dart';
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
        title: const Text(
          'Quản lý ca làm việc',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Thêm ca làm'),
        onPressed: () => _showAddShiftDialog(context, data),
      ),
    );
  }

  Widget _buildShiftCard(
    BuildContext context,
    Shift shift,
    MockDataService data,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_history_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shift.shiftName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: shift.isActive,
                onChanged: (_) async {
                  try {
                    await data.toggleShiftActive(shift.shiftId);
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                '${shift.startTime.substring(0, 5)} – ${shift.endTime.substring(0, 5)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Cho phép trễ: ${shift.allowedLateMinutes} phút',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildConstraintBadge(
                'Quét QR',
                shift.requireQr,
                Icons.qr_code_scanner_rounded,
              ),
              _buildConstraintBadge(
                'Ảnh bằng chứng',
                shift.requireEvidence,
                Icons.camera_alt_outlined,
              ),
              _buildConstraintBadge(
                'Kiểm tra GPS',
                shift.requireLocation,
                Icons.location_on_outlined,
              ),
            ],
          ),
          if (data.isRemote &&
              ['ADMIN', 'MANAGER'].contains(data.currentRoleCode)) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: shift.isActive
                  ? () => showDialog<void>(
                      context: context,
                      builder: (_) => ShiftQrDialog(shift: shift),
                    )
                  : null,
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Tạo QR chấm công'),
            ),
          ],
        ],
      ),
    ),
  );
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
            title: const Text(
              'Thêm ca làm việc mới',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên ca làm (VD: Ca Trưa Phụ Trợ) *',
                    ),
                  ),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mã ca (VD: CA_TRUA) *',
                    ),
                  ),
                  TextField(
                    controller: lateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số phút cho phép trễ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );
                            if (picked != null)
                              setModalState(() => startTime = picked);
                          },
                          child: Text('Giờ vào: ${startTime.format(context)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                            );
                            if (picked != null)
                              setModalState(() => endTime = picked);
                          },
                          child: Text('Giờ ra: ${endTime.format(context)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(
                      'Bắt buộc quét mã QR',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: reqQr,
                    onChanged: (v) => setModalState(() => reqQr = v),
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Bắt buộc chụp ảnh bằng chứng',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: reqEvidence,
                    onChanged: (v) => setModalState(() => reqEvidence = v),
                    dense: true,
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Bắt buộc vị trí GPS',
                      style: TextStyle(fontSize: 13),
                    ),
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
                style: ElevatedButton.styleFrom(),
                onPressed: () async {
                  try {
                    if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên và mã ca'),
                        ),
                      );
                      return;
                    }

                    String formatTime(TimeOfDay t) =>
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

                    await data.addShift(
                      Shift(
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
                      ),
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã tạo ca làm ${nameCtrl.text}')),
                    );
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
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
