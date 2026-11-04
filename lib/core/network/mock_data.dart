import '../../models/employee.dart';
import '../../models/work_schedule.dart';
import '../../models/attendance_record.dart';

class MockData {
  MockData._();

  static Employee currentEmployee = const Employee(
    id: 'emp_001',
    name: 'Nguyễn Văn An',
    email: 'an.nguyen@supermarket.vn',
    phone: '0987654321',
    role: 'Nhân viên thu ngân',
    branch: 'Siêu thị Go! Thăng Long',
    employeeCode: 'NV-2025-089',
    avatarUrl: null,
  );

  static WorkSchedule todaySchedule = WorkSchedule(
    id: 'shift_today_1',
    date: DateTime.now().toIso8601String().substring(0, 10),
    startTime: '08:00',
    endTime: '17:00',
    location: 'Khu vực Thu ngân Tầng 1 (Quầy 05 - 08)',
    status: 'SCHEDULED', // Chưa check-in
    note: 'Ca sáng chính thức',
    checkInTime: null,
    checkOutTime: null,
  );

  static List<WorkSchedule> getSchedules() {
    final now = DateTime.now();
    final tomorrowStr = now.add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

    return [
      todaySchedule,
      WorkSchedule(
        id: 'shift_2',
        date: tomorrowStr,
        startTime: '14:00',
        endTime: '22:00',
        location: 'Khu vực Rau củ & Thực phẩm tươi sống',
        status: 'SCHEDULED',
        note: 'Kiểm tra hàng tồn cuối ngày',
      ),
      WorkSchedule(
        id: 'shift_3',
        date: yesterdayStr,
        startTime: '08:00',
        endTime: '17:00',
        location: 'Khu vực Thu ngân Tầng 1',
        status: 'CHECKED_OUT',
        checkInTime: '07:55',
        checkOutTime: '17:05',
      ),
    ];
  }

  static List<AttendanceRecord> attendanceHistory = [
    AttendanceRecord(
      id: 'att_1',
      date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
      checkIn: '07:55',
      checkOut: '17:05',
      status: 'ON_TIME',
      location: 'Khu vực Thu ngân Tầng 1',
      note: 'Chấm công qua mã QR quầy 05',
    ),
    AttendanceRecord(
      id: 'att_2',
      date: DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
      checkIn: '08:15',
      checkOut: '17:00',
      status: 'LATE',
      location: 'Khu vực Rau củ',
      note: 'Đi muộn 15p do kẹt xe, đã báo quản lý',
    ),
    AttendanceRecord(
      id: 'att_3',
      date: DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10),
      checkIn: '07:50',
      checkOut: '17:00',
      status: 'ON_TIME',
      location: 'Khu vực Thu ngân Tầng 1',
    ),
  ];

  /// Gọi khi mock check-in thành công
  static void performMockCheckIn({required String location, String? photoUrl}) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    todaySchedule = todaySchedule.copyWith(
      status: 'CHECKED_IN',
      checkInTime: timeStr,
      location: location,
    );

    attendanceHistory.insert(
      0,
      AttendanceRecord(
        id: 'att_${now.millisecondsSinceEpoch}',
        date: now.toIso8601String().substring(0, 10),
        checkIn: timeStr,
        checkOut: null,
        status: 'ON_TIME',
        location: location,
        photoUrl: photoUrl,
        note: 'Check-in QR ngẫu nhiên + Ảnh chụp bằng chứng',
      ),
    );
  }
}
