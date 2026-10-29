import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../models/attendance_record.dart';
import '../data/attendance_repository.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final _repository = AttendanceRepository();
  List<AttendanceRecord> _records = [];
  bool _isLoading = true;
  String? _filterDate;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await _repository.getAttendanceHistory(fromDate: _filterDate);
    if (mounted) {
      setState(() {
        _records = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final str = picked.toIso8601String().substring(0, 10);
      setState(() => _filterDate = str);
      _loadHistory();
    }
  }

  void _clearFilter() {
    setState(() => _filterDate = null);
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chấm công'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _pickFilterDate,
            tooltip: 'Lọc theo ngày',
          ),
          if (_filterDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilter,
              tooltip: 'Xóa bộ lọc',
            ),
        ],
      ),
      body: _isLoading
          ? const AppLoading()
          : _records.isEmpty
              ? EmptyState(
                  icon: Icons.history_outlined,
                  message: _filterDate != null
                      ? 'Không có dữ liệu chấm công ngày $_filterDate'
                      : 'Chưa có dữ liệu chấm công nào.',
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final item = _records[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.date,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  _statusBadge(item.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _timeInfo('Vào:', item.checkIn ?? '--:--', AppTheme.success),
                                  const SizedBox(width: 24),
                                  _timeInfo('Ra:', item.checkOut ?? '--:--', AppTheme.textSecondary),
                                ],
                              ),
                              if (item.location != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.location!,
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.note != null && item.note!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Ghi chú: ${item.note!}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _timeInfo(String label, String time, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(width: 4),
        Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'ON_TIME':
        bg = AppTheme.success.withValues(alpha: 0.12);
        fg = AppTheme.success;
        label = 'Đúng giờ';
        break;
      case 'LATE':
        bg = AppTheme.warning.withValues(alpha: 0.12);
        fg = AppTheme.warning;
        label = 'Đi muộn';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
