import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_service_stub.dart'
    if (dart.library.js_interop) 'location_service_web.dart'
    as platform;

/// Sai số GPS tối đa (mét) được chấp nhận khi chấm công. Phải khớp với
/// MAX_ACCURACY_METERS trong AttendanceController phía backend.
const double maxGpsAccuracyMeters = 100;

/// Vị trí được lấy mới tại thời điểm gọi, không dùng vị trí cũ đã lưu.
const Duration maxGpsAge = Duration(seconds: 30);

/// Tình trạng sẵn sàng GPS của thiết bị.
enum GpsStatus {
  /// GPS đang bật và ứng dụng đã được cấp quyền vị trí.
  ready,

  /// Dịch vụ vị trí (GPS) của thiết bị đang tắt.
  serviceDisabled,

  /// Người dùng từ chối quyền (còn có thể hỏi lại).
  permissionDenied,

  /// Người dùng từ chối vĩnh viễn → chỉ có thể bật lại trong cài đặt ứng dụng.
  permissionDeniedForever,

  /// Lỗi không xác định khi kiểm tra GPS.
  error,
}

/// Một lần đo vị trí GPS gửi lên server khi chấm công.
class LocationSample {
  const LocationSample(
    this.latitude,
    this.longitude,
    this.accuracyMeters, {
    required this.capturedAt,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;

  /// Thời điểm thiết bị đo được vị trí này.
  final DateTime capturedAt;

  /// Android báo vị trí đến từ ứng dụng giả lập GPS.
  final bool isMocked;

  /// Dữ liệu GPS theo đúng tên trường backend nhận.
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
    'locationCapturedAt': isoWithOffset(capturedAt),
    'isMocked': isMocked,
  };
}

/// Lỗi GPS kèm mã (trùng với mã backend) và thông báo tiếng Việt cho người dùng.
class GpsException implements Exception {
  const GpsException(this.code, this.message, {this.status});

  /// GPS_DISABLED, GPS_PERMISSION_DENIED, GPS_PERMISSION_DENIED_FOREVER,
  /// GPS_TIMEOUT, GPS_STALE, GPS_INACCURATE, GPS_MOCKED, GPS_UNAVAILABLE.
  final String code;
  final String message;

  /// Tình trạng GPS gây ra lỗi (để màn hình biết nên hiện nút nào).
  final GpsStatus? status;

  @override
  String toString() => message;
}

/// Kết quả kiểm tra GPS: [status] và câu hướng dẫn hiển thị cho người dùng.
class GpsCheckResult {
  const GpsCheckResult(this.status, this.message);

  final GpsStatus status;
  final String message;

  bool get isReady => status == GpsStatus.ready;
}

/// Thông báo tiếng Việt cho từng tình trạng GPS.
class GpsMessages {
  GpsMessages._();

  static const disabled =
      'GPS trên thiết bị đang tắt. Nhân viên bắt buộc bật vị trí để vào hệ thống và chấm công.';
  static const denied =
      'Bạn đã từ chối quyền vị trí. Nhân viên bắt buộc cho phép vị trí để vào hệ thống và chấm công.';
  static const deniedForever =
      'Quyền vị trí đã bị từ chối vĩnh viễn nên ứng dụng không thể hỏi lại.';
  static const timeout =
      'Không nhận được tín hiệu GPS. Hãy ra chỗ thoáng, kiểm tra GPS đã bật và thử lại.';
  static const stale =
      'Không lấy được vị trí mới (thiết bị trả về vị trí cũ). Hãy thử lại sau vài giây.';
  static const mocked =
      'Phát hiện vị trí GPS giả lập. Hãy tắt ứng dụng giả lập vị trí (Mock location) rồi thử lại.';

  static String inaccurate(double accuracy) =>
      'Tín hiệu GPS chưa đủ chính xác (sai số ${accuracy.toStringAsFixed(0)} m, '
      'cho phép tối đa ${maxGpsAccuracyMeters.toStringAsFixed(0)} m). Hãy ra chỗ thoáng và thử lại.';

  /// Hướng dẫn theo nền tảng (điện thoại hay trình duyệt).
  static String get enableHint => platform.platformEnableGpsHint;
  static String get permissionSettingsHint =>
      platform.platformPermissionSettingsHint;
}

/// Dịch vụ GPS dùng chung: kiểm tra GPS bật, xin quyền, lấy vị trí mới.
abstract class GpsService {
  /// Service dùng trong app; test có thể gán service giả.
  static GpsService instance = GeolocatorGpsService();

  /// Trình duyệt không mở được cài đặt hệ thống → ẩn các nút "Mở cài đặt".
  bool get canOpenSettings => platform.platformCanOpenSettings;

  /// Kiểm tra GPS đang bật và quyền vị trí. Nếu [requestPermission] = true và
  /// chưa có quyền thì hỏi người dùng cấp quyền.
  Future<GpsCheckResult> checkReady({bool requestPermission = true});

  /// Luôn đo vị trí mới (không dùng vị trí cũ). Ném [GpsException] với thông báo
  /// tiếng Việt nếu GPS tắt, chưa có quyền, quá lâu, vị trí cũ, sai số lớn hoặc giả lập.
  Future<LocationSample> getFreshLocation();

  Future<bool> openLocationSettings();

  Future<bool> openAppSettings();
}

/// Cài đặt bằng package geolocator (Android, iOS, web).
class GeolocatorGpsService extends GpsService {
  GeolocatorGpsService({
    this.timeout = const Duration(seconds: 20),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration timeout;
  final DateTime Function() _clock;

  @override
  Future<GpsCheckResult> checkReady({bool requestPermission = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const GpsCheckResult(
          GpsStatus.serviceDisabled,
          GpsMessages.disabled,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return const GpsCheckResult(GpsStatus.ready, 'GPS đã sẵn sàng.');
        case LocationPermission.deniedForever:
          return const GpsCheckResult(
            GpsStatus.permissionDeniedForever,
            GpsMessages.deniedForever,
          );
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return const GpsCheckResult(
            GpsStatus.permissionDenied,
            GpsMessages.denied,
          );
      }
    } catch (error) {
      return GpsCheckResult(GpsStatus.error, 'Không kiểm tra được GPS: $error');
    }
  }

  @override
  Future<LocationSample> getFreshLocation() async {
    final ready = await checkReady();
    if (!ready.isReady) throw _fromStatus(ready);

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: timeout,
        ),
      );
    } on TimeoutException {
      throw const GpsException('GPS_TIMEOUT', GpsMessages.timeout);
    } on LocationServiceDisabledException {
      throw const GpsException(
        'GPS_DISABLED',
        GpsMessages.disabled,
        status: GpsStatus.serviceDisabled,
      );
    } on PermissionDeniedException {
      throw const GpsException(
        'GPS_PERMISSION_DENIED',
        GpsMessages.denied,
        status: GpsStatus.permissionDenied,
      );
    } catch (error) {
      throw GpsException(
        'GPS_UNAVAILABLE',
        'Không lấy được vị trí GPS: $error',
      );
    }

    final sample = LocationSample(
      position.latitude,
      position.longitude,
      position.accuracy,
      capturedAt: position.timestamp.toLocal(),
      isMocked: position.isMocked,
    );
    return validateForAttendance(sample, now: _clock());
  }

  @override
  Future<bool> openLocationSettings() async {
    if (!canOpenSettings) return false;
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    if (!canOpenSettings) return false;
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  static GpsException _fromStatus(GpsCheckResult result) =>
      switch (result.status) {
        GpsStatus.serviceDisabled => GpsException(
          'GPS_DISABLED',
          result.message,
          status: result.status,
        ),
        GpsStatus.permissionDenied => GpsException(
          'GPS_PERMISSION_DENIED',
          result.message,
          status: result.status,
        ),
        GpsStatus.permissionDeniedForever => GpsException(
          'GPS_PERMISSION_DENIED_FOREVER',
          result.message,
          status: result.status,
        ),
        _ => GpsException(
          'GPS_UNAVAILABLE',
          result.message,
          status: result.status,
        ),
      };
}

/// Chặn sớm ở app các vị trí backend chắc chắn sẽ từ chối: giả lập, quá cũ, sai số lớn.
LocationSample validateForAttendance(
  LocationSample sample, {
  required DateTime now,
}) {
  if (sample.isMocked)
    throw const GpsException('GPS_MOCKED', GpsMessages.mocked);
  if (now.difference(sample.capturedAt) > maxGpsAge) {
    throw const GpsException('GPS_STALE', GpsMessages.stale);
  }
  if (sample.accuracyMeters > maxGpsAccuracyMeters) {
    throw GpsException(
      'GPS_INACCURATE',
      GpsMessages.inaccurate(sample.accuracyMeters),
    );
  }
  return sample;
}

/// ISO-8601 kèm múi giờ, ví dụ 2026-11-05T07:55:00.000+07:00 (backend đọc được bằng OffsetDateTime).
String isoWithOffset(DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return '${local.toIso8601String()}$sign$hours:$minutes';
}
