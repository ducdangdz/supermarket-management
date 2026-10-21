import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_hrm/features/attendance/attendance_controller.dart';
import 'package:supermarket_hrm/features/attendance/attendance_result_page.dart';
import 'package:supermarket_hrm/features/attendance/check_in_page.dart';
import 'package:supermarket_hrm/features/attendance/check_out_page.dart';
import 'package:supermarket_hrm/features/attendance/data/attendance_repository.dart';
import 'package:supermarket_hrm/features/attendance/models/attendance_models.dart';
import 'package:supermarket_hrm/features/attendance/services/device_info_service.dart';
import 'package:supermarket_hrm/features/attendance/services/location_service.dart';

// ─── Service giả để test UI không cần GPS/camera/backend thật ─────────────────

class FakeRepository implements AttendanceRepository {
  FakeRepository(this.schedules);

  final List<AttendanceSchedule> schedules;
  AttendanceSubmission? lastSubmission;

  @override
  Future<List<AttendanceSchedule>> getTodaySchedules() async => schedules;

  @override
  Future<UploadedEvidence> uploadEvidence(EvidencePhoto photo) async =>
      const UploadedEvidence(fileUrl: '/uploads/evidence/x.jpg', fileHash: 'x');

  @override
  Future<AttendanceResult> submit(AttendanceSubmission submission) async {
    lastSubmission = submission;
    return AttendanceResult(
      success: true,
      action: submission.action,
      occurredAt: DateTime(2026, 10, 21, 7, 55),
      attendanceStatus: 'PRESENT',
      message: 'Check-in thành công, bạn đến đúng giờ.',
      shiftName: 'Ca sáng',
      areaName: 'Quầy thu ngân',
    );
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  final LocationResult result;

  @override
  Future<LocationResult> getCurrentLocation() async => result;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

class FakeDeviceInfo implements DeviceInfoService {
  @override
  Future<String> describe() async => 'Test device';
}

void main() {
  final schedule = AttendanceSchedule(
    scheduleId: 1,
    workDate: DateTime(2026, 10, 21),
    shiftName: 'Ca sáng',
    startTime: '08:00',
    endTime: '17:00',
    areaName: 'Quầy thu ngân',
    requireQr: true,
    requireLocation: true,
    requireEvidence: true,
  );
  final gpsOk = LocationResult.success(
    GpsLocation(latitude: 10.7769, longitude: 106.7009, accuracyMeters: 8, capturedAt: DateTime(2026, 10, 21)),
  );
  // Ảnh PNG 1x1 hợp lệ để Image.memory hiển thị được trong test.
  final photo = EvidencePhoto(
    bytes: base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII='),
    capturedAt: DateTime(2026, 10, 21, 7, 54),
  );

  AttendanceController controller(
    AttendanceAction action, {
    List<AttendanceSchedule>? schedules,
    LocationResult? location,
    FakeRepository? repository,
  }) =>
      AttendanceController(
        action: action,
        repository: repository ?? FakeRepository(schedules ?? [schedule]),
        locationService: FakeLocationService(location ?? gpsOk),
        deviceInfoService: FakeDeviceInfo(),
      );

  ElevatedButton submitButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byKey(const Key('attendance-submit')));

  testWidgets('Ca yêu cầu ảnh: chưa có ảnh thì không thể hoàn tất check-in', (tester) async {
    final repo = FakeRepository([schedule]);
    final ctrl = controller(AttendanceAction.checkIn, repository: repo);
    await tester.pumpWidget(MaterialApp(home: CheckInPage(controller: ctrl)));
    await tester.pumpAndSettle();

    // Có lịch, hiện đủ 3 bước, GPS đã lấy được.
    expect(find.text('Quét mã QR'), findsOneWidget);
    expect(find.text('Vị trí GPS'), findsOneWidget);
    expect(find.textContaining('Sai số: ±8 m'), findsOneWidget);

    // Đã quét QR nhưng chưa chụp ảnh → nút bị khóa, hiện nhắc chụp ảnh.
    ctrl.setQrToken('TOKEN-QR-DEMO-123456');
    await tester.pump();
    expect(find.textContaining('yêu cầu ảnh bằng chứng'), findsWidgets);
    expect(submitButton(tester).onPressed, isNull);

    // Có ảnh → bấm được, gửi đủ dữ liệu và mở trang kết quả.
    ctrl.setEvidence(photo);
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('attendance-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Check-in thành công'), findsOneWidget);
    expect(find.text('Đúng giờ (PRESENT)'), findsOneWidget);
    expect(repo.lastSubmission?.qrToken, 'TOKEN-QR-DEMO-123456');
    expect(repo.lastSubmission?.location?.latitude, 10.7769);
    expect(repo.lastSubmission?.evidence?.fileHash, 'x');
    expect(repo.lastSubmission?.deviceInfo, 'Test device');
  });

  testWidgets('Không có lịch làm: chặn check-in', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CheckInPage(controller: controller(AttendanceAction.checkIn, schedules: []))));
    await tester.pumpAndSettle();

    expect(find.text('Hôm nay bạn không có lịch làm nên không thể check-in.'), findsOneWidget);
    expect(find.text('Quét mã QR'), findsNothing);
    expect(submitButton(tester).onPressed, isNull);
  });

  testWidgets('Chưa check-in: chặn check-out', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CheckOutPage(controller: controller(AttendanceAction.checkOut))));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa check-in nên không thể check-out.'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);
  });

  testWidgets('Từ chối quyền vị trí: hiển thị rõ lý do', (tester) async {
    const denied = LocationResult.failure(
      LocationFailure.permissionDeniedForever,
      'Quyền vị trí đã bị từ chối vĩnh viễn.',
    );
    await tester.pumpWidget(
        MaterialApp(home: CheckInPage(controller: controller(AttendanceAction.checkIn, location: denied))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Quyền vị trí đã bị từ chối vĩnh viễn.'), findsOneWidget);
    expect(find.text('Mở cài đặt ứng dụng'), findsOneWidget);
  });

  testWidgets('Trang kết quả: đi muộn hiển thị LATE và số phút', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AttendanceResultPage(
        result: AttendanceResult(
          success: true,
          action: AttendanceAction.checkIn,
          occurredAt: DateTime(2026, 10, 21, 8, 30, 5),
          attendanceStatus: 'LATE',
          lateMinutes: 30,
          message: 'Check-in thành công nhưng bạn đi muộn 30 phút.',
        ),
      ),
    ));

    expect(find.text('Check-in thành công'), findsOneWidget);
    expect(find.text('Đi muộn (LATE) · 30 phút'), findsOneWidget);
    expect(find.text('08:30:05 · 21/10/2026'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('Trang kết quả: thất bại hiển thị lý do từ chối', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AttendanceResultPage(
        result: AttendanceResult.failure(
          action: AttendanceAction.checkIn,
          code: 'INVALID_LOCATION',
          message: 'Mã QR thuộc khu vực "Kho hàng" nhưng bạn được phân công ở "Quầy thu ngân".',
        ),
      ),
    ));

    expect(find.text('Check-in thất bại'), findsOneWidget);
    expect(find.textContaining('Sai khu vực (INVALID_LOCATION)'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
}
