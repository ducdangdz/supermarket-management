import '../../../core/network/team_api.dart';
import '../../../models/work_schedule.dart';

class ScheduleRepository {
  Future<List<WorkSchedule>> getSchedules({
    String? fromDate,
    String? toDate,
  }) async {
    final now = DateTime.now();
    return (await TeamApi.active!.schedules(
      from: fromDate ?? TeamApi.day(now.subtract(const Duration(days: 90))),
      to: toDate ?? TeamApi.day(now.add(const Duration(days: 90))),
    )).map(TeamApi.schedule).toList();
  }

  Future<WorkSchedule> getScheduleDetail(String id) async {
    final rows = await getSchedules();
    return rows.firstWhere(
      (s) => s.id == id,
      orElse: () => throw StateError('Không tìm thấy lịch làm việc.'),
    );
  }
}
