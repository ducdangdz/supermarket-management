import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_hrm/core/network/mock_data.dart';
import 'package:supermarket_hrm/features/attendance/data/mock_attendance_repository.dart';
import 'package:supermarket_hrm/features/attendance/models/attendance_models.dart';
import 'package:supermarket_hrm/models/work_schedule.dart';

/// Unit test luồng chấm công đầy đủ trên mock backend: 6 business rule cần demo.
void main() {
  late MockAttendanceScenario scenario;
  late MockAttendanceRepository repo;
  final now = DateTime.now();
  final today =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final gps = GpsLocation(
    latitude: 10.7769,
    longitude: 106.7009,
    accuracyMeters: 10,
    capturedAt: now,
  );
  const evidence = UploadedEvidence(fileUrl: 'mock://e.jpg', fileHash: 'abc');

  AttendanceSubmission submission(
    AttendanceAction action,
    String qr, {
    GpsLocation? location,
    UploadedEvidence? photo = evidence,
  }) => AttendanceSubmission(
    action: action,
    qrToken: qr,
    location: location ?? gps,
    evidence: photo,
    clientTime: now,
    deviceInfo: 'test',
  );

  setUp(() {
    // Reset dữ liệu mock dùng chung trước mỗi test.
    MockData.todaySchedule = WorkSchedule(
      id: 'shift_today_1',
      date: today,
      startTime: '08:00',
      endTime: '17:00',
      location: 'Quầy thu ngân',
      status: 'SCHEDULED',
    );
    scenario = MockAttendanceScenario();
    repo = MockAttendanceRepository(scenario: scenario);
  });

  test('Check-in hợp lệ, đúng giờ → PRESENT và cập nhật dashboard', () async {
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.checkIn),
    );
    expect(result.success, isTrue);
    expect(result.attendanceStatus, 'PRESENT');
    expect(MockData.todaySchedule.checkInTime, isNotNull);
  });

  test('Đi muộn → LATE', () async {
    scenario.clock = SimulatedClock.late;
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.checkIn),
    );
    expect(result.success, isTrue);
    expect(result.attendanceStatus, 'LATE');
    expect(result.lateMinutes, 30);
  });

  test('Không có lịch làm → không cho check-in', () async {
    scenario.noScheduleToday = true;
    expect(await repo.getTodaySchedules(), isEmpty);
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.checkIn),
    );
    expect(result.success, isFalse);
    expect(result.errorCode, 'NO_SCHEDULE');
  });

  test('QR hết hạn → từ chối', () async {
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.expired),
    );
    expect(result.errorCode, 'QR_EXPIRED');
  });

  test('QR bị thu hồi → từ chối', () async {
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.revoked),
    );
    expect(result.errorCode, 'QR_REVOKED');
  });

  test('Quét QR sai khu vực → INVALID_LOCATION', () async {
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.wrongArea),
    );
    expect(result.errorCode, 'INVALID_LOCATION');
  });

  test('GPS ngoài bán kính → INVALID_LOCATION', () async {
    scenario.outsideRadius = true;
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.checkIn),
    );
    expect(result.errorCode, 'INVALID_LOCATION');
  });

  test('Ca yêu cầu ảnh nhưng chưa có ảnh → không hoàn tất', () async {
    final result = await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.checkIn, photo: null),
    );
    expect(result.errorCode, 'EVIDENCE_REQUIRED');
    expect(MockData.todaySchedule.checkInTime, isNull);
  });

  test('Chưa check-in → không thể check-out', () async {
    final result = await repo.submit(
      submission(AttendanceAction.checkOut, MockQrCodes.checkOut),
    );
    expect(result.errorCode, 'NOT_CHECKED_IN');
  });

  test('Dùng QR check-in để check-out → QR_WRONG_TYPE', () async {
    await repo.submit(
      submission(AttendanceAction.checkIn, MockQrCodes.checkIn),
    );
    final result = await repo.submit(
      submission(AttendanceAction.checkOut, MockQrCodes.checkIn),
    );
    expect(result.errorCode, 'QR_WRONG_TYPE');
  });

  test(
    'Check-in rồi check-out → thành công, không check-in lại được',
    () async {
      await repo.submit(
        submission(AttendanceAction.checkIn, MockQrCodes.checkIn),
      );
      final again = await repo.submit(
        submission(AttendanceAction.checkIn, MockQrCodes.checkIn),
      );
      expect(again.errorCode, 'ALREADY_CHECKED_IN');

      final out = await repo.submit(
        submission(AttendanceAction.checkOut, MockQrCodes.checkOut),
      );
      expect(out.success, isTrue);
      expect(MockData.todaySchedule.checkOutTime, isNotNull);
    },
  );
}
