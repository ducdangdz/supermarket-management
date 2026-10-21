import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/mock_data.dart';
import '../../../models/attendance_record.dart';

class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceHistory({
    int page = 1,
    int limit = 20,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final res = await ApiClient.instance.get(
        ApiEndpoints.attendance,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
      );
      final list = res.data['records'] as List<dynamic>? ?? res.data as List<dynamic>;
      return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      final all = MockData.attendanceHistory;
      if (fromDate != null) {
        return all.where((a) => a.date == fromDate).toList();
      }
      return all;
    }
  }
}
