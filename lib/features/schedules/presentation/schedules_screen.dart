import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/work_schedule.dart';
import '../data/schedule_repository.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  final _repository = ScheduleRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<WorkSchedule> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    final list = await _repository.getSchedules();
    if (mounted) {
      setState(() {
        _schedules = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayStr = _selectedDay.toIso8601String().substring(0, 10);
    final filtered = _schedules.where((s) => s.date == selectedDayStr).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch làm việc'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 60)),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selDay, focDay) {
              setState(() {
                _selectedDay = selDay;
                _focusedDay = focDay;
              });
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Ca làm ngày $selectedDayStr',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                Text('${filtered.length} ca', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_busy_outlined,
                        message: 'Không có ca làm việc nào được phân công trong ngày này.',
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE3F2FD),
                                child: Icon(Icons.schedule, color: AppTheme.primary),
                              ),
                              title: Text(
                                '${item.startTime} - ${item.endTime}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(item.location),
                              trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
                              onTap: () {
                                context.push('/schedules/${item.id}');
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
