import 'dart:typed_data';

/// Loại thao tác chấm công.
enum AttendanceAction {
  checkIn,
  checkOut;

  /// Tên hiển thị: "Check-in" / "Check-out".
  String get label => this == checkIn ? 'Check-in' : 'Check-out';

  /// Giá trị session_type của QR do backend tạo.
  String get qrSessionType => this == checkIn ? 'CHECK_IN' : 'CHECK_OUT';
}

/// Lịch làm hôm nay kèm yêu cầu chấm công của ca (map từ `GET /attendance/me/today`).
class AttendanceSchedule {
  const AttendanceSchedule({
    required this.scheduleId,
    required this.workDate,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.areaName,
    this.floorName,
    this.allowedLateMinutes = 15,
    this.requireQr = true,
    this.requireLocation = false,
    this.requireEvidence = false,
    this.attendanceStatus,
    this.checkInAt,
    this.checkOutAt,
  });

  final int scheduleId;
  final DateTime workDate;
  final String shiftName;

  /// Giờ bắt đầu/kết thúc dạng "HH:mm".
  final String startTime;
  final String endTime;
  final String areaName;
  final String? floorName;
  final int allowedLateMinutes;
  final bool requireQr;
  final bool requireLocation;
  final bool requireEvidence;

  /// PRESENT / LATE / ... (null nếu chưa check-in).
  final String? attendanceStatus;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  bool get isCheckedIn => checkInAt != null;
  bool get isCheckedOut => checkOutAt != null;

  /// Thời điểm bắt đầu ca (ngày làm + giờ bắt đầu).
  DateTime get shiftStart {
    final parts = startTime.split(':');
    return DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  factory AttendanceSchedule.fromJson(Map<String, dynamic> json) {
    return AttendanceSchedule(
      scheduleId: (json['scheduleId'] as num).toInt(),
      workDate: DateTime.parse(json['workDate'].toString()),
      shiftName: json['shiftName']?.toString() ?? 'Ca làm',
      startTime: _hhmm(json['startTime']),
      endTime: _hhmm(json['endTime']),
      areaName: json['areaName']?.toString() ?? '',
      floorName: json['floorName']?.toString(),
      allowedLateMinutes: (json['allowedLateMinutes'] as num?)?.toInt() ?? 15,
      requireQr: json['requireQr'] != false,
      requireLocation: json['requireLocation'] == true,
      requireEvidence: json['requireEvidence'] == true,
      attendanceStatus: json['attendanceStatus']?.toString(),
      checkInAt: _dateTime(json['checkInAt']),
      checkOutAt: _dateTime(json['checkOutAt']),
    );
  }

  static String _hhmm(Object? value) {
    final text = value?.toString() ?? '00:00';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  static DateTime? _dateTime(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

/// Vị trí GPS lấy được từ thiết bị.
class GpsLocation {
  const GpsLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;

  /// Android báo vị trí đến từ ứng dụng giả lập GPS.
  final bool isMocked;
}

/// Ảnh bằng chứng vừa chụp (giữ bytes để xem trước được trên mọi nền tảng, kể cả web).
class EvidencePhoto {
  const EvidencePhoto({
    required this.bytes,
    required this.capturedAt,
    this.fileName = 'evidence.jpg',
  });

  final Uint8List bytes;
  final DateTime capturedAt;
  final String fileName;
}

/// Kết quả upload ảnh lên backend.
class UploadedEvidence {
  const UploadedEvidence({required this.fileUrl, required this.fileHash});

  final String fileUrl;
  final String fileHash;

  factory UploadedEvidence.fromJson(Map<String, dynamic> json) => UploadedEvidence(
        fileUrl: json['fileUrl']?.toString() ?? '',
        fileHash: json['fileHash']?.toString() ?? '',
      );
}

/// Toàn bộ dữ liệu gửi lên API check-in/check-out.
class AttendanceSubmission {
  const AttendanceSubmission({
    required this.action,
    required this.clientTime,
    required this.deviceInfo,
    this.scheduleId,
    this.qrToken,
    this.location,
    this.evidence,
    this.evidenceCapturedAt,
  });

  final AttendanceAction action;
  final int? scheduleId;
  final String? qrToken;
  final GpsLocation? location;
  final UploadedEvidence? evidence;
  final DateTime? evidenceCapturedAt;

  /// Thời gian hiện tại trên điện thoại (server vẫn dùng giờ server để tính đúng giờ/trễ).
  final DateTime clientTime;
  final String deviceInfo;

  Map<String, dynamic> toJson() => {
        if (scheduleId != null) 'scheduleId': scheduleId,
        'qrToken': qrToken,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'accuracyMeters': location?.accuracyMeters,
        'clientTime': _isoWithOffset(clientTime),
        'deviceInfo': location?.isMocked == true ? '$deviceInfo · GPS giả lập' : deviceInfo,
        if (evidence != null)
          'evidence': {
            'fileHash': evidence!.fileHash,
            'capturedAt': _isoWithOffset(evidenceCapturedAt ?? clientTime),
          },
      };

  /// ISO-8601 kèm múi giờ, ví dụ 2026-10-21T07:55:00.000+07:00.
  static String _isoWithOffset(DateTime time) {
    final offset = time.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final local = time.toIso8601String();
    return '${time.isUtc ? local.replaceFirst('Z', '') : local}$sign$hours:$minutes';
  }
}

/// Kết quả chấm công hiển thị ở trang kết quả (thành công hoặc bị từ chối).
class AttendanceResult {
  const AttendanceResult({
    required this.success,
    required this.action,
    required this.occurredAt,
    required this.message,
    this.attendanceStatus,
    this.lateMinutes = 0,
    this.errorCode,
    this.shiftName,
    this.areaName,
    this.distanceMeters,
    this.evidenceUrl,
  });

  final bool success;
  final AttendanceAction action;
  final DateTime occurredAt;
  final String message;

  /// PRESENT / LATE (khi thành công).
  final String? attendanceStatus;
  final int lateMinutes;

  /// Mã lỗi backend, ví dụ QR_EXPIRED, INVALID_LOCATION (khi thất bại).
  final String? errorCode;
  final String? shiftName;
  final String? areaName;
  final double? distanceMeters;
  final String? evidenceUrl;

  bool get isLate => attendanceStatus == 'LATE';

  factory AttendanceResult.fromJson(Map<String, dynamic> json, AttendanceAction action) {
    return AttendanceResult(
      success: true,
      action: action,
      occurredAt: DateTime.tryParse(json['occurredAt']?.toString() ?? '') ?? DateTime.now(),
      message: json['message']?.toString() ?? '${action.label} thành công.',
      attendanceStatus: json['attendanceStatus']?.toString(),
      lateMinutes: (json['lateMinutes'] as num?)?.toInt() ?? 0,
      shiftName: json['shiftName']?.toString(),
      areaName: json['areaName']?.toString(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      evidenceUrl: json['evidenceUrl']?.toString(),
    );
  }

  factory AttendanceResult.failure({
    required AttendanceAction action,
    required String code,
    required String message,
    DateTime? at,
  }) {
    return AttendanceResult(
      success: false,
      action: action,
      occurredAt: at ?? DateTime.now(),
      message: message,
      errorCode: code,
    );
  }
}
