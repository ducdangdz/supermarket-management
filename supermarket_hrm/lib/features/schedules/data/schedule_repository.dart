import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/mock_data.dart';
import '../../../models/work_schedule.dart';

class ScheduleRepository {
  Future<List<WorkSchedule>> getSchedules({String? fromDate, String? toDate}) async {
    try {
      final res = await ApiClient.instance.get(
        ApiEndpoints.schedules,
        queryParameters: {
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      );
      final list = res.data as List<dynamic>;
      return list.map((e) => WorkSchedule.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return MockData.getSchedules();
    }
  }

  Future<WorkSchedule> getScheduleDetail(String id) async {
    try {
      final res = await ApiClient.instance.get('${ApiEndpoints.scheduleDetail}/$id');
      return WorkSchedule.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      final list = MockData.getSchedules();
      return list.firstWhere((s) => s.id == id, orElse: () => list.first);
    }
  }
}
