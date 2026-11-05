import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_hrm/features/attendance/attendance_controller.dart';
import 'package:supermarket_hrm/features/attendance/data/attendance_repository.dart';
import 'package:supermarket_hrm/features/attendance/domain/attendance_rules.dart';
import 'package:supermarket_hrm/features/attendance/models/attendance_models.dart';
import 'package:supermarket_hrm/features/attendance/services/device_info_service.dart';
import 'package:supermarket_hrm/features/attendance/services/location_service.dart';
import 'package:supermarket_hrm/features/backend/location/gps_gate.dart';
import 'package:supermarket_hrm/features/backend/location/location_service.dart';

/// GpsService giả: trả về tình trạng GPS cho trước và ghi lại các lần gọi.
class FakeGpsService extends GpsService {
  FakeGpsService(this.results);

  /// Lần gọi checkReady thứ i trả về results[i] (hết danh sách thì giữ phần tử cuối).
  final List<GpsCheckResult> results;
  int checks = 0;
  int openedLocationSettings = 0;
  int openedAppSettings = 0;

  @override
  bool get canOpenSettings => true;

  @override
  Future<GpsCheckResult> checkReady({bool requestPermission = true}) async =>
      results[checks++ < results.length ? checks - 1 : results.length - 1];

  @override
  Future<LocationSample> getFreshLocation() async => throw UnimplementedError();

  @override
  Future<bool> openLocationSettings() async {
    openedLocationSettings++;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    openedAppSettings++;
    return true;
  }
}

/// LocationService giả: mỗi lần gọi trả về một vị trí khác để kiểm tra "lấy GPS mới".
class CountingLocationService implements LocationService {
  CountingLocationService(this.results);
  final List<LocationResult> results;
  int calls = 0;

  @override
  Future<LocationResult> getCurrentLocation() async =>
      results[calls++ < results.length ? calls - 1 : results.length - 1];

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class RecordingRepository implements AttendanceRepository {
  RecordingRepository(this.schedule);
  final AttendanceSchedule schedule;
  AttendanceSubmission? last;

  @override
  Future<List<AttendanceSchedule>> getTodaySchedules() async => [schedule];

  @override
  Future<UploadedEvidence> uploadEvidence(EvidencePhoto photo) async =>
      const UploadedEvidence(fileUrl: 'x', fileHash: 'x');

  @override
  Future<AttendanceResult> submit(AttendanceSubmission submission) async {
    last = submission;
    return AttendanceResult(
      success: true,
      action: submission.action,
      occurredAt: DateTime(2026, 11, 5, 8),
      message: 'OK',
    );
  }
}

class FakeDevice implements DeviceInfoService {
  @override
  Future<String> describe() async => 'Test device';
}

void main() {
  const child = Text('KHÔNG GIAN NHÂN VIÊN');

  Future<FakeGpsService> pumpGate(
    WidgetTester tester,
    List<GpsCheckResult> results,
  ) async {
    final gps = FakeGpsService(results);
    await tester.pumpWidget(
      MaterialApp(
        home: EmployeeGpsGate(
          gpsService: gps,
          onLogout: () async {},
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return gps;
  }

  group('Cổng GPS sau khi đăng nhập', () {
    test('Chỉ EMPLOYEE bắt buộc GPS, ADMIN/MANAGER/HR thì không', () {
      expect(requiresEmployeeGps('EMPLOYEE'), isTrue);
      expect(requiresEmployeeGps('ADMIN'), isFalse);
      expect(requiresEmployeeGps('MANAGER'), isFalse);
      expect(requiresEmployeeGps('HR'), isFalse);
    });

    testWidgets('GPS bật + có quyền → vào màn hình làm việc', (tester) async {
      await pumpGate(tester, [const GpsCheckResult(GpsStatus.ready, 'ok')]);
      expect(find.text('KHÔNG GIAN NHÂN VIÊN'), findsOneWidget);
    });

    testWidgets(
      'GPS tắt → hướng dẫn bật GPS, có "Mở cài đặt vị trí" và "Thử lại"',
      (tester) async {
        final gps = await pumpGate(tester, [
          const GpsCheckResult(GpsStatus.serviceDisabled, GpsMessages.disabled),
          const GpsCheckResult(GpsStatus.ready, 'ok'),
        ]);
        expect(find.text('KHÔNG GIAN NHÂN VIÊN'), findsNothing);
        expect(find.text('Hãy bật GPS'), findsOneWidget);
        expect(find.text(GpsMessages.disabled), findsOneWidget);

        await tester.tap(find.text('Mở cài đặt vị trí'));
        await tester.pump();
        expect(gps.openedLocationSettings, 1);

        // Bật GPS xong bấm "Thử lại" → được vào hệ thống.
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(find.text('KHÔNG GIAN NHÂN VIÊN'), findsOneWidget);
      },
    );

    testWidgets('Từ chối quyền → không cho vào, có nút xin lại quyền', (
      tester,
    ) async {
      await pumpGate(tester, [
        const GpsCheckResult(GpsStatus.permissionDenied, GpsMessages.denied),
      ]);
      expect(find.text('KHÔNG GIAN NHÂN VIÊN'), findsNothing);
      expect(find.text(GpsMessages.denied), findsOneWidget);
      expect(find.text('Cho phép vị trí'), findsOneWidget);
    });

    testWidgets('Từ chối vĩnh viễn → có nút "Mở cài đặt ứng dụng"', (
      tester,
    ) async {
      final gps = await pumpGate(tester, [
        const GpsCheckResult(
          GpsStatus.permissionDeniedForever,
          GpsMessages.deniedForever,
        ),
      ]);
      expect(find.text('KHÔNG GIAN NHÂN VIÊN'), findsNothing);
      await tester.tap(find.text('Mở cài đặt ứng dụng'));
      await tester.pump();
      expect(gps.openedAppSettings, 1);
    });
  });

  group('Xác thực vị trí trước khi gửi', () {
    final now = DateTime(2026, 11, 5, 8);
    LocationSample sample({
      double accuracy = 10,
      Duration age = Duration.zero,
      bool mocked = false,
    }) => LocationSample(
      10.7769,
      106.7009,
      accuracy,
      capturedAt: now.subtract(age),
      isMocked: mocked,
    );

    test('Vị trí mới, sai số nhỏ → hợp lệ', () {
      expect(validateForAttendance(sample(), now: now).latitude, 10.7769);
    });

    test('GPS giả lập → GPS_MOCKED', () {
      expect(
        () => validateForAttendance(sample(mocked: true), now: now),
        throwsA(
          isA<GpsException>().having((e) => e.code, 'code', 'GPS_MOCKED'),
        ),
      );
    });

    test('Sai số lớn → GPS_INACCURATE', () {
      expect(
        () => validateForAttendance(sample(accuracy: 250), now: now),
        throwsA(
          isA<GpsException>().having((e) => e.code, 'code', 'GPS_INACCURATE'),
        ),
      );
    });

    test('Vị trí cũ → GPS_STALE', () {
      expect(
        () => validateForAttendance(
          sample(age: const Duration(minutes: 5)),
          now: now,
        ),
        throwsA(isA<GpsException>().having((e) => e.code, 'code', 'GPS_STALE')),
      );
    });

    test(
      'Gửi đủ latitude, longitude, accuracy, thời gian lấy GPS, isMocked',
      () {
        final json = sample().toJson();
        expect(
          json.keys,
          containsAll([
            'latitude',
            'longitude',
            'accuracyMeters',
            'locationCapturedAt',
            'isMocked',
          ]),
        );
        expect(
          json['locationCapturedAt'],
          startsWith('2026-11-05T08:00:00.000'),
        );
      },
    );

    test('Ca không đánh dấu require_location vẫn bắt buộc GPS', () {
      final schedule = AttendanceSchedule(
        scheduleId: 1,
        workDate: DateTime(2026, 11, 5),
        shiftName: 'Ca sáng',
        startTime: '08:00',
        endTime: '17:00',
        areaName: 'Quầy thu ngân',
        requireLocation: false,
      );
      final violation = AttendanceRules.validateBeforeSubmit(
        action: AttendanceAction.checkIn,
        schedule: schedule,
        qrToken: 'qr',
        location: null,
        evidence: null,
      );
      expect(violation?.code, 'LOCATION_REQUIRED');
    });
  });

  group('Check-in luôn lấy GPS mới', () {
    final schedule = AttendanceSchedule(
      scheduleId: 1,
      workDate: DateTime(2026, 11, 5),
      shiftName: 'Ca sáng',
      startTime: '08:00',
      endTime: '17:00',
      areaName: 'Quầy thu ngân',
    );
    GpsLocation at(double lat) => GpsLocation(
      latitude: lat,
      longitude: 106.7009,
      accuracyMeters: 8,
      capturedAt: DateTime(2026, 11, 5, 8),
    );

    test('Khi gửi, đo lại GPS và gửi vị trí mới nhất', () async {
      final location = CountingLocationService([
        LocationResult.success(at(10.0001)), // lúc mở màn hình
        LocationResult.success(at(10.0002)), // lúc bấm Hoàn tất
      ]);
      final repo = RecordingRepository(schedule);
      final ctrl = AttendanceController(
        action: AttendanceAction.checkIn,
        repository: repo,
        locationService: location,
        deviceInfoService: FakeDevice(),
      );
      await ctrl.initialize();
      ctrl.setQrToken('QR');
      final result = await ctrl.submit();

      expect(result.success, isTrue);
      expect(location.calls, 2);
      expect(repo.last?.location?.latitude, 10.0002);
      expect(repo.last?.toJson()['locationCapturedAt'], isNotNull);
    });

    test('GPS bị tắt lúc gửi → không gửi chấm công, báo lỗi rõ ràng', () async {
      final location = CountingLocationService([
        LocationResult.success(at(10.0001)),
        const LocationResult.failure(
          LocationFailure.serviceDisabled,
          GpsMessages.disabled,
          code: 'GPS_DISABLED',
        ),
      ]);
      final repo = RecordingRepository(schedule);
      final ctrl = AttendanceController(
        action: AttendanceAction.checkIn,
        repository: repo,
        locationService: location,
        deviceInfoService: FakeDevice(),
      );
      await ctrl.initialize();
      ctrl.setQrToken('QR');
      final result = await ctrl.submit();

      expect(result.success, isFalse);
      expect(result.errorCode, 'GPS_DISABLED');
      expect(result.message, GpsMessages.disabled);
      expect(repo.last, isNull);
    });
  });
}
