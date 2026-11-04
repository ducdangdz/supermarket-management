import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_hrm/features/attendance/domain/attendance_rules.dart';
import 'package:supermarket_hrm/features/attendance/models/attendance_models.dart';

/// Unit test cho business rule chấm công (không cần Flutter UI).
void main() {
  final shiftStart = DateTime(2026, 10, 21, 8, 0);

  AttendanceSchedule schedule({
    bool requireQr = true,
    bool requireLocation = true,
    bool requireEvidence = true,
    DateTime? checkInAt,
    DateTime? checkOutAt,
  }) => AttendanceSchedule(
    scheduleId: 1,
    workDate: DateTime(2026, 10, 21),
    shiftName: 'Ca sáng',
    startTime: '08:00',
    endTime: '17:00',
    areaName: 'Quầy thu ngân',
    requireQr: requireQr,
    requireLocation: requireLocation,
    requireEvidence: requireEvidence,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt,
  );

  final gps = GpsLocation(
    latitude: 10.7769,
    longitude: 106.7009,
    accuracyMeters: 12,
    capturedAt: shiftStart,
  );
  final photo = EvidencePhoto(
    bytes: Uint8List.fromList([1, 2, 3]),
    capturedAt: shiftStart,
  );

  group('determineStatus - PRESENT / LATE', () {
    test('vào trước giờ bắt đầu ca → PRESENT', () {
      expect(
        AttendanceRules.determineStatus(
          shiftStart: shiftStart,
          allowedLateMinutes: 15,
          checkInAt: shiftStart.subtract(const Duration(minutes: 5)),
        ),
        'PRESENT',
      );
    });

    test('trễ đúng bằng số phút cho phép → vẫn PRESENT', () {
      expect(
        AttendanceRules.determineStatus(
          shiftStart: shiftStart,
          allowedLateMinutes: 15,
          checkInAt: shiftStart.add(const Duration(minutes: 15)),
        ),
        'PRESENT',
      );
    });

    test('trễ quá số phút cho phép → LATE', () {
      expect(
        AttendanceRules.determineStatus(
          shiftStart: shiftStart,
          allowedLateMinutes: 15,
          checkInAt: shiftStart.add(const Duration(minutes: 16)),
        ),
        'LATE',
      );
    });

    test('lateMinutes không âm khi đến sớm', () {
      expect(
        AttendanceRules.lateMinutes(
          shiftStart: shiftStart,
          checkInAt: shiftStart.subtract(const Duration(minutes: 3)),
        ),
        0,
      );
      expect(
        AttendanceRules.lateMinutes(
          shiftStart: shiftStart,
          checkInAt: shiftStart.add(const Duration(minutes: 30)),
        ),
        30,
      );
    });
  });

  group('distanceMeters - Haversine', () {
    test('cùng một điểm → 0 m', () {
      expect(
        AttendanceRules.distanceMeters(10.7769, 106.7009, 10.7769, 106.7009),
        closeTo(0, 0.001),
      );
    });

    test('lệch 0.01 độ vĩ ≈ 1.11 km', () {
      expect(
        AttendanceRules.distanceMeters(10.0, 106.0, 10.01, 106.0),
        closeTo(1112, 5),
      );
    });
  });

  group('validateBeforeSubmit - các rule cần demo', () {
    test('Không có lịch làm → không cho check-in', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: null,
        qrToken: 'qr',
        location: gps,
        evidence: photo,
      );
      expect(v?.code, 'NO_SCHEDULE');
    });

    test('Chưa check-in → không thể check-out', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkOut,
        schedule: schedule(),
        qrToken: 'qr',
        location: gps,
        evidence: photo,
      );
      expect(v?.code, 'NOT_CHECKED_IN');
    });

    test('Ca yêu cầu ảnh nhưng chưa có ảnh → không hoàn tất', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: schedule(),
        qrToken: 'qr',
        location: gps,
        evidence: null,
      );
      expect(v?.code, 'EVIDENCE_REQUIRED');
    });

    test('Ca không yêu cầu ảnh → không cần ảnh', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: schedule(requireEvidence: false),
        qrToken: 'qr',
        location: gps,
        evidence: null,
      );
      expect(v, isNull);
    });

    test('Ca yêu cầu GPS nhưng không có vị trí → LOCATION_REQUIRED', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: schedule(),
        qrToken: 'qr',
        location: null,
        evidence: photo,
      );
      expect(v?.code, 'LOCATION_REQUIRED');
    });

    test('GPS sai số quá lớn → GPS_INACCURATE', () {
      final weak = GpsLocation(
        latitude: 10,
        longitude: 106,
        accuracyMeters: 250,
        capturedAt: shiftStart,
      );
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: schedule(),
        qrToken: 'qr',
        location: weak,
        evidence: photo,
      );
      expect(v?.code, 'GPS_INACCURATE');
    });

    test('Chưa quét QR → QR_REQUIRED', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: schedule(),
        qrToken: '  ',
        location: gps,
        evidence: photo,
      );
      expect(v?.code, 'QR_REQUIRED');
    });

    test('Đã check-in rồi → không check-in lại', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: schedule(checkInAt: shiftStart),
        qrToken: 'qr',
        location: gps,
        evidence: photo,
      );
      expect(v?.code, 'ALREADY_CHECKED_IN');
    });

    test('Đủ dữ liệu → hợp lệ', () {
      final v = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkOut,
        schedule: schedule(checkInAt: shiftStart),
        qrToken: 'qr',
        location: gps,
        evidence: photo,
      );
      expect(v, isNull);
    });
  });

  test('AttendanceSchedule.fromJson đọc đúng dữ liệu backend', () {
    final s = AttendanceSchedule.fromJson({
      'scheduleId': 4,
      'workDate': '2026-10-21',
      'shiftName': 'Ca sáng',
      'startTime': '07:00:00',
      'endTime': '15:00:00',
      'allowedLateMinutes': 10,
      'areaName': 'Quầy thu ngân',
      'requireQr': true,
      'requireLocation': true,
      'requireEvidence': false,
      'checkInAt': '2026-10-21T07:05:00',
      'checkOutAt': null,
    });
    expect(s.startTime, '07:00');
    expect(s.shiftStart, DateTime(2026, 10, 21, 7, 0));
    expect(s.isCheckedIn, isTrue);
    expect(s.isCheckedOut, isFalse);
    expect(s.requireEvidence, isFalse);
  });
}
