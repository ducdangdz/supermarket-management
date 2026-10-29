import '../../../core/network/team_api.dart';
import '../../../models/attendance_record.dart';

class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceHistory({
    int page = 1,
    int limit = 20,
    String? fromDate,
    String? toDate,
  }) async {
    final api = TeamApi.active!;
    final rows =
        await api.request('/attendance/employees/${api.employeeId}/history')
            as List;
    final result = rows
        .where(
          (r) =>
              (fromDate == null ||
                  r['work_date'].toString().compareTo(fromDate) >= 0) &&
              (toDate == null ||
                  r['work_date'].toString().compareTo(toDate) <= 0),
        )
        .map(
          (r) => AttendanceRecord(
            id: r['attendance_id'].toString(),
            date: r['work_date'].toString(),
            checkIn: TeamApi.time(r['check_in_at']),
            checkOut: TeamApi.time(r['check_out_at']),
            status: r['attendance_status'] == 'PRESENT'
                ? 'ON_TIME'
                : r['attendance_status'] ?? 'PENDING',
            location: r['area_name'],
          ),
        )
        .toList();
    return result.skip((page - 1) * limit).take(limit).toList();
  }
}
