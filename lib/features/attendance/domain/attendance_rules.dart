import 'dart:math' as math;

import '../models/attendance_models.dart';

/// Một vi phạm business rule: mã lỗi (trùng với mã backend trả về) + thông báo.
class AttendanceViolation {
  const AttendanceViolation(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AttendanceViolation($code): $message';
}

/// Business rule chấm công dùng chung cho app (kiểm tra trước khi gửi) và mock backend.
/// Backend Spring Boot kiểm tra lại toàn bộ các rule này; app chỉ kiểm tra sớm để báo lỗi nhanh.
class AttendanceRules {
  AttendanceRules._();

  /// Bán kính mặc định (mét) khi khu vực chưa cấu hình bán kính.
  static const int defaultRadiusMeters = 100;

  /// Sai số GPS lớn hơn ngưỡng này bị coi là không đáng tin cậy.
  static const double maxAccuracyMeters = 100;

  /// Khoảng cách (mét) giữa hai tọa độ theo công thức Haversine.
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earthRadius * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double degree) => degree * math.pi / 180;

  /// PRESENT nếu vào trước hoặc đúng (giờ bắt đầu + số phút cho phép trễ), ngược lại LATE.
  static String determineStatus({
    required DateTime shiftStart,
    required int allowedLateMinutes,
    required DateTime checkInAt,
  }) {
    final deadline = shiftStart.add(Duration(minutes: allowedLateMinutes));
    return checkInAt.isAfter(deadline) ? 'LATE' : 'PRESENT';
  }

  /// Số phút trễ so với giờ bắt đầu ca (0 nếu đến sớm).
  static int lateMinutes({
    required DateTime shiftStart,
    required DateTime checkInAt,
  }) {
    final minutes = checkInAt.difference(shiftStart).inMinutes;
    return minutes > 0 ? minutes : 0;
  }

  /// Rule về trạng thái lịch làm: có lịch hay không, đã check-in/check-out chưa.
  static AttendanceViolation? validateScheduleState({
    required AttendanceAction action,
    required AttendanceSchedule? schedule,
  }) {
    if (schedule == null) {
      return AttendanceViolation(
        'NO_SCHEDULE',
        'Hôm nay bạn không có lịch làm nên không thể ${action.label.toLowerCase()}.',
      );
    }
    if (action == AttendanceAction.checkIn && schedule.isCheckedIn) {
      return const AttendanceViolation(
        'ALREADY_CHECKED_IN',
        'Bạn đã check-in ca làm này rồi.',
      );
    }
    if (action == AttendanceAction.checkOut && !schedule.isCheckedIn) {
      return const AttendanceViolation(
        'NOT_CHECKED_IN',
        'Bạn chưa check-in nên không thể check-out.',
      );
    }
    if (action == AttendanceAction.checkOut && schedule.isCheckedOut) {
      return const AttendanceViolation(
        'ALREADY_CHECKED_OUT',
        'Bạn đã check-out ca làm này rồi.',
      );
    }
    return null;
  }

  /// Kiểm tra đủ dữ liệu trước khi gửi: trạng thái lịch, QR, GPS, ảnh bằng chứng.
  static AttendanceViolation? validateBeforeSubmit({
    required AttendanceAction action,
    required AttendanceSchedule? schedule,
    required String? qrToken,
    required GpsLocation? location,
    required EvidencePhoto? evidence,
  }) {
    final stateViolation = validateScheduleState(
      action: action,
      schedule: schedule,
    );
    if (stateViolation != null) return stateViolation;
    if (schedule!.requireQr && (qrToken == null || qrToken.trim().isEmpty)) {
      return const AttendanceViolation(
        'QR_REQUIRED',
        'Hãy quét mã QR tại khu vực làm việc.',
      );
    }
    if (schedule.requireLocation && location == null) {
      return const AttendanceViolation(
        'LOCATION_REQUIRED',
        'Ca làm này yêu cầu vị trí GPS. Hãy bật và cấp quyền vị trí.',
      );
    }
    if (schedule.requireLocation &&
        location!.accuracyMeters > maxAccuracyMeters) {
      return AttendanceViolation(
        'GPS_INACCURATE',
        'Tín hiệu GPS chưa đủ chính xác (sai số ${location.accuracyMeters.toStringAsFixed(0)} m). Hãy lấy lại vị trí.',
      );
    }
    if (schedule.requireEvidence && evidence == null) {
      return const AttendanceViolation(
        'EVIDENCE_REQUIRED',
        'Ca làm này yêu cầu ảnh bằng chứng. Hãy chụp ảnh trước khi hoàn tất.',
      );
    }
    return null;
  }

  /// Tiêu đề ngắn cho từng mã lỗi, hiển thị ở trang kết quả.
  static String titleForCode(String? code) {
    switch (code) {
      case 'NO_SCHEDULE':
        return 'Không có lịch làm';
      case 'QR_EXPIRED':
        return 'Mã QR đã hết hạn';
      case 'QR_REVOKED':
        return 'Mã QR đã bị thu hồi';
      case 'QR_INVALID':
        return 'Mã QR không hợp lệ';
      case 'QR_WRONG_TYPE':
        return 'Sai loại mã QR';
      case 'QR_REQUIRED':
        return 'Chưa quét mã QR';
      case 'WRONG_SHIFT':
        return 'Sai ca làm';
      case 'INVALID_LOCATION':
        return 'Sai khu vực (INVALID_LOCATION)';
      case 'LOCATION_REQUIRED':
        return 'Thiếu vị trí GPS';
      case 'GPS_INACCURATE':
        return 'GPS không chính xác';
      case 'CHECK_IN_TOO_EARLY':
        return 'Chưa đến giờ check-in';
      case 'ALREADY_CHECKED_IN':
        return 'Đã check-in';
      case 'ALREADY_CHECKED_OUT':
        return 'Đã check-out';
      case 'NOT_CHECKED_IN':
        return 'Chưa check-in';
      case 'EVIDENCE_REQUIRED':
        return 'Thiếu ảnh bằng chứng';
      case 'EVIDENCE_REUSED':
      case 'EVIDENCE_NOT_FOUND':
      case 'EVIDENCE_INVALID_TYPE':
      case 'EVIDENCE_TOO_LARGE':
        return 'Ảnh bằng chứng không hợp lệ';
      case 'NETWORK_ERROR':
        return 'Lỗi kết nối';
      default:
        return 'Chấm công bị từ chối';
    }
  }
}
