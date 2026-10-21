import '../../../core/network/mock_data.dart';
import '../../../models/attendance_record.dart';
import '../domain/attendance_rules.dart';
import '../models/attendance_models.dart';
import 'attendance_repository.dart';

/// Giờ dùng để chấm công trong chế độ mock (để demo đúng giờ / đi muộn bất kỳ lúc nào).
enum SimulatedClock {
  /// 5 phút trước giờ bắt đầu ca → PRESENT.
  onTime,

  /// 30 phút sau giờ bắt đầu ca → LATE.
  late,

  /// Giờ thực của điện thoại.
  real,
}

/// Các công tắc kịch bản demo, chỉnh trong panel "Chế độ demo" ở màn hình check-in.
class MockAttendanceScenario {
  bool noScheduleToday = false;
  bool requireEvidence = true;
  bool requireLocation = true;

  /// Giả lập GPS ở cách khu vực làm việc ~2.2 km → INVALID_LOCATION.
  bool outsideRadius = false;
  SimulatedClock clock = SimulatedClock.onTime;
}

/// Mã QR demo dùng được trong chế độ mock (chọn nhanh ở màn hình quét QR).
class MockQrCodes {
  MockQrCodes._();

  static const checkIn = 'DEMO-CHECK_IN-CASHIER';
  static const checkOut = 'DEMO-CHECK_OUT-CASHIER';
  static const wrongArea = 'DEMO-CHECK_IN-WAREHOUSE';
  static const expired = 'DEMO-CHECK_IN-EXPIRED';
  static const revoked = 'DEMO-CHECK_IN-REVOKED';

  /// Nhãn hiển thị → mã QR.
  static const Map<String, String> samples = {
    'QR check-in hợp lệ': checkIn,
    'QR check-out hợp lệ': checkOut,
    'QR sai khu vực (Kho hàng)': wrongArea,
    'QR hết hạn': expired,
    'QR bị thu hồi': revoked,
  };
}

/// Giả lập backend chấm công bằng dữ liệu trong [MockData], áp dụng cùng business rule
/// với AttendanceController phía Spring Boot. Dùng để demo khi chưa chạy backend.
class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository({MockAttendanceScenario? scenario, DateTime Function()? now})
      : scenario = scenario ?? sharedScenario,
        _now = now ?? DateTime.now;

  /// Kịch bản dùng chung giữa các màn hình (panel demo chỉnh trực tiếp object này).
  static final MockAttendanceScenario sharedScenario = MockAttendanceScenario();

  static const _scheduleId = 1;
  static const _areaCode = 'CASHIER';
  static const _areaNames = {'CASHIER': 'Quầy thu ngân', 'WAREHOUSE': 'Kho hàng', 'FRESH': 'Quầy thực phẩm tươi'};
  static const _latency = Duration(milliseconds: 500);

  final MockAttendanceScenario scenario;
  final DateTime Function() _now;

  @override
  Future<List<AttendanceSchedule>> getTodaySchedules() async {
    await Future<void>.delayed(_latency);
    final schedule = _currentSchedule();
    return schedule == null ? const [] : [schedule];
  }

  @override
  Future<UploadedEvidence> uploadEvidence(EvidencePhoto photo) async {
    await Future<void>.delayed(_latency);
    final hash = 'mock-${photo.capturedAt.microsecondsSinceEpoch}-${photo.bytes.length}';
    return UploadedEvidence(fileUrl: 'mock://evidence/$hash.jpg', fileHash: hash);
  }

  @override
  Future<AttendanceResult> submit(AttendanceSubmission submission) async {
    await Future<void>.delayed(_latency);
    final action = submission.action;
    final schedule = _currentSchedule();
    final at = _clockFor(action, schedule);
    AttendanceResult reject(String code, String message) =>
        AttendanceResult.failure(action: action, code: code, message: message, at: at);

    // 1. QR: tồn tại, chưa thu hồi, còn hạn, đúng loại, đúng khu vực.
    final token = submission.qrToken?.trim() ?? '';
    final parts = token.split('-');
    if (token.isEmpty) return reject('QR_REQUIRED', 'Ca làm này yêu cầu quét mã QR.');
    if (parts.length != 3 || parts[0] != 'DEMO') {
      return reject('QR_INVALID', 'Mã QR không hợp lệ hoặc không do hệ thống tạo.');
    }
    if (parts[2] == 'REVOKED') return reject('QR_REVOKED', 'Mã QR đã bị quản lý thu hồi.');
    if (parts[2] == 'EXPIRED') return reject('QR_EXPIRED', 'Mã QR đã hết hạn. Hãy yêu cầu quản lý tạo mã mới.');
    if (parts[1] != action.qrSessionType) {
      return reject(
        'QR_WRONG_TYPE',
        action == AttendanceAction.checkIn
            ? 'Đây là mã QR check-out, không dùng để check-in.'
            : 'Đây là mã QR check-in, không dùng để check-out.',
      );
    }

    // 2. Lịch làm + trạng thái check-in/check-out.
    final stateViolation = AttendanceRules.validateScheduleState(action: action, schedule: schedule);
    if (stateViolation != null) return reject(stateViolation.code, stateViolation.message);
    if (parts[2] != _areaCode) {
      return reject(
        'INVALID_LOCATION',
        'Mã QR thuộc khu vực "${_areaNames[parts[2]] ?? parts[2]}" nhưng bạn được phân công ở "${schedule!.areaName}".',
      );
    }

    // 3. GPS: có tọa độ, đủ chính xác, trong bán kính.
    final location = submission.location;
    double? distance;
    if (schedule!.requireLocation) {
      if (location == null) return reject('LOCATION_REQUIRED', 'Ca làm này yêu cầu bật vị trí GPS khi chấm công.');
      if (location.accuracyMeters > AttendanceRules.maxAccuracyMeters) {
        return reject('GPS_INACCURATE', 'Tín hiệu GPS chưa đủ chính xác (sai số ${location.accuracyMeters.toStringAsFixed(0)} m).');
      }
      // Mock không có tọa độ siêu thị: tâm khu vực = vị trí hiện tại, hoặc lệch 0.02° (~2.2 km) khi bật "ngoài bán kính".
      final centerLat = location.latitude + (scenario.outsideRadius ? 0.02 : 0);
      distance = AttendanceRules.distanceMeters(location.latitude, location.longitude, centerLat, location.longitude);
      if (distance > AttendanceRules.defaultRadiusMeters) {
        return reject(
          'INVALID_LOCATION',
          'Bạn đang cách khu vực "${schedule.areaName}" khoảng ${distance.toStringAsFixed(0)} m '
              '(cho phép ${AttendanceRules.defaultRadiusMeters} m).',
        );
      }
    }

    // 4. Ảnh bằng chứng.
    if (schedule.requireEvidence && submission.evidence == null) {
      return reject('EVIDENCE_REQUIRED', 'Ca làm này yêu cầu ảnh bằng chứng. Hãy chụp ảnh trước khi hoàn tất.');
    }

    // 5. Lưu kết quả vào MockData để Dashboard / Lịch sử cập nhật theo.
    final time = _hhmm(at);
    if (action == AttendanceAction.checkIn) {
      final status = AttendanceRules.determineStatus(
        shiftStart: schedule.shiftStart,
        allowedLateMinutes: schedule.allowedLateMinutes,
        checkInAt: at,
      );
      final late = AttendanceRules.lateMinutes(shiftStart: schedule.shiftStart, checkInAt: at);
      MockData.todaySchedule = MockData.todaySchedule.copyWith(
        status: status == 'LATE' ? 'LATE' : 'CHECKED_IN',
        checkInTime: time,
      );
      MockData.attendanceHistory.insert(
        0,
        AttendanceRecord(
          id: 'att_${at.millisecondsSinceEpoch}',
          date: _date(at),
          checkIn: time,
          status: status == 'LATE' ? 'LATE' : 'ON_TIME',
          location: schedule.areaName,
          photoUrl: submission.evidence?.fileUrl,
          note: 'Check-in QR + GPS${submission.evidence != null ? ' + ảnh bằng chứng' : ''} · ${submission.deviceInfo}',
        ),
      );
      return AttendanceResult(
        success: true,
        action: action,
        occurredAt: at,
        attendanceStatus: status,
        lateMinutes: late,
        message: status == 'LATE'
            ? 'Check-in thành công nhưng bạn đi muộn $late phút.'
            : 'Check-in thành công, bạn đến đúng giờ.',
        shiftName: schedule.shiftName,
        areaName: schedule.areaName,
        distanceMeters: distance,
        evidenceUrl: submission.evidence?.fileUrl,
      );
    }

    MockData.todaySchedule = MockData.todaySchedule.copyWith(status: 'CHECKED_OUT', checkOutTime: time);
    final history = MockData.attendanceHistory;
    if (history.isNotEmpty && history.first.date == _date(at) && history.first.checkOut == null) {
      final old = history.first;
      history[0] = AttendanceRecord(
        id: old.id,
        date: old.date,
        checkIn: old.checkIn,
        checkOut: time,
        status: old.status,
        location: old.location,
        photoUrl: old.photoUrl,
        note: old.note,
      );
    }
    return AttendanceResult(
      success: true,
      action: action,
      occurredAt: at,
      attendanceStatus: schedule.attendanceStatus,
      message: 'Check-out thành công.',
      shiftName: schedule.shiftName,
      areaName: schedule.areaName,
      distanceMeters: distance,
      evidenceUrl: submission.evidence?.fileUrl,
    );
  }

  /// Ca hôm nay dựng từ MockData.todaySchedule + công tắc kịch bản.
  AttendanceSchedule? _currentSchedule() {
    if (scenario.noScheduleToday) return null;
    final source = MockData.todaySchedule;
    final today = _now();
    final workDate = DateTime.tryParse(source.date) ?? today;
    return AttendanceSchedule(
      scheduleId: _scheduleId,
      workDate: DateTime(workDate.year, workDate.month, workDate.day),
      shiftName: source.note ?? 'Ca làm',
      startTime: source.startTime,
      endTime: source.endTime,
      areaName: source.location,
      requireQr: true,
      requireLocation: scenario.requireLocation,
      requireEvidence: scenario.requireEvidence,
      attendanceStatus: source.status == 'LATE' ? 'LATE' : (source.checkInTime == null ? null : 'PRESENT'),
      checkInAt: _atTime(workDate, source.checkInTime),
      checkOutAt: _atTime(workDate, source.checkOutTime),
    );
  }

  DateTime _clockFor(AttendanceAction action, AttendanceSchedule? schedule) {
    if (schedule == null || scenario.clock == SimulatedClock.real) return _now();
    if (action == AttendanceAction.checkOut) {
      return _atTime(schedule.workDate, schedule.endTime) ?? _now();
    }
    return scenario.clock == SimulatedClock.onTime
        ? schedule.shiftStart.subtract(const Duration(minutes: 5))
        : schedule.shiftStart.add(const Duration(minutes: 30));
  }

  static DateTime? _atTime(DateTime date, String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    return DateTime(date.year, date.month, date.day, int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
  }

  static String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _date(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
