import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../models/work_schedule.dart';
import '../data/schedule_repository.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final _repository = ScheduleRepository();
  WorkSchedule? _schedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() async {
    final s = await _repository.getScheduleDetail(widget.id);
    if (mounted) {
      setState(() {
        _schedule = s;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ca làm việc'),
      ),
      body: _isLoading
          ? const AppLoading()
          : _schedule == null
              ? const Center(child: Text('Không tìm thấy thông tin ca làm'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _row(Icons.calendar_today, 'Ngày làm việc', _schedule!.date),
                          const Divider(height: 24),
                          _row(Icons.access_time, 'Thời gian ca', '${_schedule!.startTime} - ${_schedule!.endTime}'),
                          const Divider(height: 24),
                          _row(Icons.location_on_outlined, 'Vị trí phân công', _schedule!.location),
                          const Divider(height: 24),
                          _row(Icons.flag_outlined, 'Trạng thái ca', _schedule!.status),
                          if (_schedule!.checkInTime != null) ...[
                            const Divider(height: 24),
                            _row(Icons.login, 'Giờ Check-in', _schedule!.checkInTime!),
                          ],
                          if (_schedule!.checkOutTime != null) ...[
                            const Divider(height: 24),
                            _row(Icons.logout, 'Giờ Check-out', _schedule!.checkOutTime!),
                          ],
                          if (_schedule!.note != null && _schedule!.note!.isNotEmpty) ...[
                            const Divider(height: 24),
                            _row(Icons.notes, 'Ghi chú', _schedule!.note!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
