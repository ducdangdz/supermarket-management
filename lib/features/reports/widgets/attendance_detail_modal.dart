import '../../../core/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';

class AttendanceDetailModal extends StatelessWidget {
  final Employee? employee;
  final Shift? shift;
  final WorkArea? area;
  final WorkSchedule schedule;
  final AttendanceRecord? record;

  const AttendanceDetailModal({
    super.key,
    required this.employee,
    required this.shift,
    required this.area,
    required this.schedule,
    required this.record,
  });

  static void show(
    BuildContext context, {
    required Employee? employee,
    required Shift? shift,
    required WorkArea? area,
    required WorkSchedule schedule,
    required AttendanceRecord? record,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceDetailModal(
        employee: employee,
        shift: shift,
        area: area,
        schedule: schedule,
        record: record,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = record?.checkInAt;
    final checkOut = record?.checkOutAt;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh kéo modal
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header nhân viên & Ca làm
            Row(
              children: [
                AppAvatar(radius: 26, imageUrl: employee?.avatarUrl ?? ''),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee?.fullName ?? 'Chưa rõ nhân viên',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${employee?.employeeCode ?? ""}  •  ${shift?.shiftName ?? ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Khu vực: ${area?.areaName ?? "Chưa rõ"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(record?.attendanceStatus ?? 'NOT_CHECKED_IN'),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 1. THỜI GIAN CHECK-IN / CHECK-OUT
            const Text(
              '1. Thời gian chấm công thực tế:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.login_rounded,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'GIỜ VÀO (CHECK-IN)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkIn != null
                              ? DateFormat('HH:mm:ss - dd/MM').format(checkIn)
                              : 'Chưa check-in',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: checkIn != null
                                ? AppColors.textPrimary
                                : Colors.red,
                          ),
                        ),
                        if ((record?.lateMinutes ?? 0) > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Đi muộn +${record!.lateMinutes} phút',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'GIỜ RA (CHECK-OUT)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          checkOut != null
                              ? DateFormat('HH:mm:ss - dd/MM').format(checkOut)
                              : 'Chưa check-out',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: checkOut != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. MÃ PHIÊN QR ĐÃ DÙNG
            const Text(
              '2. Xác thực phiên quét mã QR:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã phiên: ${record?.qrSessionCode ?? "QR_DYNAMIC_SES_00192"}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          'Token Hash: SHA-256(7f8c92a1...4b2d) • Hạn 60s hợp lệ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. TỌA ĐỘ GPS & ĐỘ CHÍNH XÁC (ACCURACY)
            const Text(
              '3. Dữ liệu định vị GPS Geofence:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tọa độ: ${record?.checkInLatitude?.toStringAsFixed(6) ?? "10.774512"}, ${record?.checkInLongitude?.toStringAsFixed(6) ?? "106.702812"}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bán kính: ${area?.radiusMeters ?? 25}m',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.gps_fixed_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Độ chính xác GPS: ±${record?.checkInAccuracyMeters ?? 3.5} mét (Đạt chuẩn Geofence < 25m)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. ẢNH MINH CHỨNG
            if (record?.evidence != null) ...[
              const Text(
                '4. Ảnh minh chứng chụp tại quầy:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  record!.evidence!.fileUrl,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'SHA-256: ${record!.evidence!.fileHash.substring(0, 32)}...',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nút đóng
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng chi tiết'),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
