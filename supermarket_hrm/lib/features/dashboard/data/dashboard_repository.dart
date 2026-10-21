import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/mock_data.dart';
import '../../../models/employee.dart';
import '../../../models/work_schedule.dart';

class DashboardRepository {
  Future<Employee> getEmployeeProfile() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.profile);
      return Employee.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return MockData.currentEmployee;
    }
  }

  Future<WorkSchedule?> getTodaySchedule() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.dashboard);
      return WorkSchedule.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return MockData.todaySchedule;
    }
  }
}
