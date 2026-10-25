import '../../../core/network/team_api.dart';
import '../../../models/employee.dart';
import '../../../models/work_schedule.dart';

class DashboardRepository {
  TeamApi get api => TeamApi.active!;
  Future<Employee> getEmployeeProfile() => api.profile();
  Future<WorkSchedule?> getTodaySchedule() async {
    final day = TeamApi.day(DateTime.now());
    final rows = await api.schedules(from: day, to: day);
    final active = rows
        .where((s) => s['scheduleStatus'] != 'CANCELLED')
        .toList();
    return active.isEmpty ? null : TeamApi.schedule(active.first);
  }
}
