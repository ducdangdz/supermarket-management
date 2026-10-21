import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _timeFilter = 'Hôm nay';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    final totalScheduled = data.todayScheduledCount == 0 ? 1 : data.todayScheduledCount;
    final presentPercent = (data.todayPresentCount / totalScheduled * 100).toInt();
    final latePercent = (data.todayLateCount / totalScheduled * 100).toInt();
    final invalidPercent = (data.todayInvalidLocationCount / totalScheduled * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê chuyên cần',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bộ lọc thời gian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kỳ báo cáo: ${DateFormat("dd/MM/yyyy").format(DateTime.now())}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                DropdownButton<String>(
                  value: _timeFilter,
                  items: const [
                    DropdownMenuItem(value: 'Hôm nay', child: Text('Hôm nay')),
                    DropdownMenuItem(value: 'Tuần này', child: Text('Tuần này')),
                    DropdownMenuItem(value: 'Tháng này', child: Text('Tháng này')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _timeFilter = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tỷ lệ đi làm tổng thể
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Tỷ lệ chuyên cần toàn chi nhánh',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$presentPercent%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            _buildProgressRow('Đúng giờ', presentPercent, AppColors.statusPresent),
                            const SizedBox(height: 8),
                            _buildProgressRow('Đi muộn', latePercent, AppColors.statusLate),
                            const SizedBox(height: 8),
                            _buildProgressRow('Bất thường GPS', invalidPercent, AppColors.statusInvalid),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Thống kê chi tiết theo từng khu vực
            const Text(
              'Tỷ lệ nhân sự theo khu vực siêu thị',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...data.workAreas.map((area) {
              final staffList = data.getEmployeesAssignedToArea(area.workAreaId);
              final maxCap = area.maxEmployees ?? 1;
              final capRatio = (staffList.length / maxCap).clamp(0.0, 1.0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          area.areaName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${staffList.length}/${area.maxEmployees ?? "∞"} nhân viên',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: staffList.length > (area.maxEmployees ?? 99)
                                ? Colors.red
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: capRatio,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          capRatio >= 1.0 ? Colors.orange : AppColors.secondary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mã quầy: ${area.areaCode}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'GPS Geofence: ${area.radiusMeters ?? 25}m',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
            // Nút xuất báo cáo PDF / Excel
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Xuất báo cáo tổng hợp (PDF / Excel)'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang trích xuất dữ liệu báo cáo chuyên cần...')),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('$percent%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
