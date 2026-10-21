import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'domain/attendance_rules.dart';
import 'models/attendance_models.dart';

/// Người dùng chọn gì ở trang kết quả.
enum AttendanceResultChoice { retry, home }

/// Trang kết quả sau chấm công: thành công/thất bại, thời gian, đúng giờ/trễ, lý do từ chối.
class AttendanceResultPage extends StatelessWidget {
  const AttendanceResultPage({super.key, required this.result});

  final AttendanceResult result;

  @override
  Widget build(BuildContext context) {
    final color = !result.success
        ? AppTheme.error
        : result.isLate
            ? AppTheme.warning
            : AppTheme.success;
    final icon = !result.success
        ? Icons.cancel
        : result.isLate
            ? Icons.schedule
            : Icons.check_circle;
    final title = result.success ? '${result.action.label} thành công' : '${result.action.label} thất bại';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(result.success ? AttendanceResultChoice.home : AttendanceResultChoice.retry);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kết quả chấm công'),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Icon(icon, size: 96, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    _row(Icons.access_time, 'Thời gian chấm công', _formatDateTime(result.occurredAt)),
                    if (result.success && result.action == AttendanceAction.checkIn)
                      _row(
                        result.isLate ? Icons.warning_amber_rounded : Icons.verified_outlined,
                        'Trạng thái',
                        result.isLate ? 'Đi muộn (LATE) · ${result.lateMinutes} phút' : 'Đúng giờ (PRESENT)',
                        valueColor: color,
                      ),
                    if (!result.success)
                      _row(
                        Icons.report_gmailerrorred,
                        'Lý do từ chối',
                        '${AttendanceRules.titleForCode(result.errorCode)}\nMã lỗi: ${result.errorCode ?? '-'}',
                        valueColor: AppTheme.error,
                      ),
                    if (result.shiftName != null) _row(Icons.event_note, 'Ca làm', result.shiftName!),
                    if (result.areaName != null) _row(Icons.place_outlined, 'Khu vực', result.areaName!),
                    if (result.distanceMeters != null)
                      _row(Icons.my_location, 'Khoảng cách tới khu vực', '${result.distanceMeters!.toStringAsFixed(0)} m'),
                    if (result.evidenceUrl != null) _row(Icons.photo_camera_outlined, 'Ảnh bằng chứng', 'Đã lưu'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!result.success) ...[
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(AttendanceResultChoice.retry),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(AttendanceResultChoice.home),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Về trang chủ'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary),
      ),
    );
  }

  static String _formatDateTime(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)} · ${two(t.day)}/${two(t.month)}/${t.year}';
  }
}
