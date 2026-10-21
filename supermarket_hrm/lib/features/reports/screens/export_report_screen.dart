import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../widgets/role_guard_wrapper.dart';

/// MÀN 5: Màn hình xuất báo cáo
/// Ai dùng: ADMIN, MANAGER, HR
class ExportReportScreen extends StatefulWidget {
  const ExportReportScreen({super.key});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  int? _selectedEmployeeId; // null = Toàn bộ nhân viên
  String _reportType = 'SUMMARY'; // SUMMARY, LATE_ABSENT, BY_AREA
  bool _includeEvidencePhotos = true;
  bool _includeGpsCoordinates = true;

  @override
  Widget build(BuildContext context) {
    return RoleGuardWrapper(
      allowedRoles: const ['ADMIN', 'MANAGER', 'HR'],
      screenTitle: 'Xuất báo cáo chấm công',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            '5. Xuất báo cáo chấm công',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<MockDataService>(
          builder: (context, data, _) {
            final empName = _selectedEmployeeId == null
                ? 'Toàn bộ nhân viên (${data.employees.length} người)'
                : data.getEmployeeById(_selectedEmployeeId!)?.fullName ?? 'Chưa rõ';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // THẺ CẤU HÌNH THÔNG SỐ XUẤT
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cấu hình bộ lọc xuất dữ liệu',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 16),

                        // 1. CHỌN KHOẢNG THỜI GIAN
                        const Text('1. Khoảng thời gian xuất:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.date_range_rounded, size: 18),
                          label: Text(
                            'Từ ${DateFormat("dd/MM/yyyy").format(_dateRange.start)} đến ${DateFormat("dd/MM/yyyy").format(_dateRange.end)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                              initialDateRange: _dateRange,
                            );
                            if (picked != null) setState(() => _dateRange = picked);
                          },
                        ),

                        const SizedBox(height: 16),

                        // 2. CHỌN NHÂN VIÊN
                        const Text('2. Đối tượng nhân sự:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int?>(
                          value: _selectedEmployeeId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Toàn bộ nhân viên siêu thị (Tất cả)')),
                            ...data.employees.map((e) => DropdownMenuItem(
                                value: e.employeeId, child: Text('${e.fullName} (${e.employeeCode})'))),
                          ],
                          onChanged: (val) => setState(() => _selectedEmployeeId = val),
                        ),

                        const SizedBox(height: 16),

                        // 3. LOẠI BÁO CÁO
                        const Text('3. Loại báo cáo cần xuất:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _reportType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'SUMMARY', child: Text('Báo cáo tổng hợp chuyên cần & công tháng')),
                            DropdownMenuItem(value: 'LATE_ABSENT', child: Text('Báo cáo chuyên đề: Đi muộn & Vắng mặt')),
                            DropdownMenuItem(value: 'BY_AREA', child: Text('Báo cáo phân bổ nhân sự theo từng khu vực')),
                          ],
                          onChanged: (val) => setState(() => _reportType = val ?? 'SUMMARY'),
                        ),

                        const SizedBox(height: 16),

                        // TÙY CHỌN DỮ LIỆU ĐÍNH KÈM
                        const Text('4. Tùy chọn dữ liệu đính kèm:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Bao gồm tọa độ GPS & độ chính xác Geofence', style: TextStyle(fontSize: 13)),
                          value: _includeGpsCoordinates,
                          onChanged: (v) => setState(() => _includeGpsCoordinates = v ?? true),
                        ),
                        CheckboxListTile(
                          dense: true,
                          title: const Text('Bao gồm link ảnh minh chứng & mã SHA-256', style: TextStyle(fontSize: 13)),
                          value: _includeEvidencePhotos,
                          onChanged: (v) => setState(() => _includeEvidencePhotos = v ?? true),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TÓM TẮT DỮ LIỆU CHUẨN BỊ XUẤT
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sẵn sàng xuất file cho: $empName\nThời gian: ${DateFormat("dd/MM/yyyy").format(_dateRange.start)} - ${DateFormat("dd/MM/yyyy").format(_dateRange.end)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // HAI NÚT XUẤT: XUẤT EXCEL & XUẤT PDF
                  Row(
                    children: [
                      // Nút Xuất Excel
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF107C41), // Excel Green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.table_view_rounded),
                          label: const Text('Xuất Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _handleExportFile(context, 'Excel', '.xlsx'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Xuất PDF
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48), // PDF Red
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Xuất PDF (.pdf)', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _handleExportFile(context, 'PDF', '.pdf'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleExportFile(BuildContext context, String fileType, String extension) {
    final fileName = 'BaoCao_ChamCong_SmartMarket_${DateFormat("yyyyMMdd").format(DateTime.now())}$extension';

    // 1. Hiển thị dialog đang tạo và trích xuất file
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  fileType == 'Excel' ? const Color(0xFF107C41) : const Color(0xFFE11D48),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Đang tạo tệp $fileType...',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'Đang tổng hợp dữ liệu GPS, mã QR và lịch sử chấm công...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 2. Giả lập quá trình tạo file sau 1.2s và hiển thị hộp thoại tải về máy thành công
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || !context.mounted) return;
      navigator.pop(); // Đóng loading dialog

      showDialog(
        context: context,
        builder: (successCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.download_done_rounded, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 8),
              const Text('Tải file thành công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Báo cáo $fileType đã được xuất thành công và lưu vào bộ nhớ máy tính/thiết bị của bạn:',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      fileType == 'Excel' ? Icons.description_rounded : Icons.picture_as_pdf_rounded,
                      color: fileType == 'Excel' ? Colors.green : Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '📁 Đường dẫn: Downloads/$fileName',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(successCtx),
              child: const Text('Đóng'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Mở file'),
              onPressed: () {
                Navigator.pop(successCtx);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Đang mở file $fileName...')),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
