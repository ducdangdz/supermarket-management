import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';

class AttendanceApprovalPage extends StatefulWidget {
  const AttendanceApprovalPage({super.key});

  @override
  State<AttendanceApprovalPage> createState() => _AttendanceApprovalPageState();
}

class _AttendanceApprovalPageState extends State<AttendanceApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    final pendingRecords =
        data.attendanceRecords.where((r) => r.verificationStatus == 'PENDING').toList();
    final verifiedRecords =
        data.attendanceRecords.where((r) => r.verificationStatus == 'VERIFIED').toList();
    final rejectedRecords =
        data.attendanceRecords.where((r) => r.verificationStatus == 'REJECTED').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phê duyệt chấm công bất thường',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Cần duyệt (${pendingRecords.length})'),
            Tab(text: 'Đã duyệt (${verifiedRecords.length})'),
            Tab(text: 'Từ chối (${rejectedRecords.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecordList(context, pendingRecords, data, isPendingTab: true),
          _buildRecordList(context, verifiedRecords, data, isPendingTab: false),
          _buildRecordList(context, rejectedRecords, data, isPendingTab: false),
        ],
      ),
    );
  }

  Widget _buildRecordList(
    BuildContext context,
    List<AttendanceRecord> records,
    MockDataService data, {
    required bool isPendingTab,
  }) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPendingTab ? Icons.check_circle_outline_rounded : Icons.inbox_rounded,
              size: 54,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              isPendingTab ? 'Tuyệt vời! Không có yêu cầu nào cần duyệt.' : 'Chưa có bản ghi nào.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (ctx, idx) {
        final record = records[idx];
        final emp = data.getEmployeeById(record.employeeId);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              // Header nhân viên & Trạng thái
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(emp?.avatarUrl ?? ''),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp?.fullName ?? 'Chưa rõ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${emp?.employeeCode}  •  ${emp?.email}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(record.attendanceStatus),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Thông tin chấm công chi tiết
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Thời gian check-in: ${record.checkInAt != null ? DateFormat("HH:mm:ss - dd/MM/yyyy").format(record.checkInAt!) : "Chưa có"}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (record.checkInLatitude != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Tọa độ: ${record.checkInLatitude!.toStringAsFixed(5)}, ${record.checkInLongitude!.toStringAsFixed(5)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                    if (record.note != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          'Lý do/Ghi chú: ${record.note}',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],

                    // Ảnh bằng chứng (Nếu có)
                    if (record.evidence != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              record.evidence!.fileUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ảnh bằng chứng chụp tại quầy:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SHA-256: ${record.evidence!.fileHash.substring(0, 16)}...',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                                TextButton(
                                  onPressed: () => _showEvidenceModal(context, record.evidence!),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Phóng to ảnh xem chi tiết >'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Nút phê duyệt / Từ chối nếu ở tab Cần duyệt
              if (isPendingTab) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Từ chối'),
                          onPressed: () => _showRejectDialog(context, record, data),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Duyệt hợp lệ'),
                          onPressed: () {
                            data.approveAttendance(record.attendanceId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã phê duyệt chấm công hợp lệ!')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
      text = 'Sai vị trí GPS';
    } else if (status == 'REJECTED') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade900;
      text = 'Bị từ chối';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  void _showEvidenceModal(BuildContext context, AttendanceEvidence evidence) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ảnh bằng chứng gốc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  evidence.fileUrl,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thời gian chụp: ${evidence.capturedAt != null ? DateFormat("HH:mm:ss dd/MM/yyyy").format(evidence.capturedAt!) : "N/A"}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã băm SHA-256 chống giả mạo:\n${evidence.fileHash}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, AttendanceRecord record, MockDataService data) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lý do từ chối chấm công'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do từ chối (VD: Ảnh không rõ mặt, vị trí ngoài phạm vi cho phép...)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              data.rejectAttendance(record.attendanceId, reason: reasonCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã từ chối lượt chấm công.')),
              );
            },
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
  }
}
