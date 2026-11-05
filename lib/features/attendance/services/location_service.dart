import '../../backend/location/location_service.dart';
import '../models/attendance_models.dart';

/// Lý do không lấy được vị trí, để UI hiển thị rõ ràng và gợi ý cách xử lý.
enum LocationFailure {
  /// Thiết bị đang tắt GPS / dịch vụ vị trí.
  serviceDisabled,

  /// Người dùng từ chối quyền (còn có thể hỏi lại).
  permissionDenied,

  /// Người dùng từ chối vĩnh viễn → phải mở cài đặt ứng dụng.
  permissionDeniedForever,

  /// Quá thời gian chờ tín hiệu GPS.
  timeout,

  /// Sai số GPS quá lớn.
  inaccurate,

  /// Thiết bị báo vị trí giả lập.
  mocked,

  /// Thiết bị chỉ trả về vị trí cũ.
  stale,
  unknown,
}

/// Kết quả lấy vị trí: có [location] hoặc có [failure] kèm mã lỗi GPS.
class LocationResult {
  const LocationResult.success(GpsLocation this.location)
    : failure = null,
      message = null,
      code = null;

  const LocationResult.failure(
    LocationFailure this.failure,
    this.message, {
    this.code = 'LOCATION_REQUIRED',
  }) : location = null;

  final GpsLocation? location;
  final LocationFailure? failure;
  final String? message;

  /// Mã lỗi giống backend: GPS_DISABLED, GPS_PERMISSION_DENIED, GPS_MOCKED...
  final String? code;

  bool get isSuccess => location != null;
}

abstract class LocationService {
  /// Xin quyền (nếu cần) và đo vị trí MỚI: latitude, longitude, accuracy, thời gian đo.
  Future<LocationResult> getCurrentLocation();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}

/// Dùng [GpsService] chung của app (lib/features/backend/location) để mọi màn hình
/// chấm công cùng một logic GPS bắt buộc.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({this.gpsService});

  final GpsService? gpsService;

  GpsService get _gps => gpsService ?? GpsService.instance;

  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      final sample = await _gps.getFreshLocation();
      return LocationResult.success(
        GpsLocation(
          latitude: sample.latitude,
          longitude: sample.longitude,
          accuracyMeters: sample.accuracyMeters,
          capturedAt: sample.capturedAt,
          isMocked: sample.isMocked,
        ),
      );
    } on GpsException catch (e) {
      return LocationResult.failure(
        _failureFor(e.code),
        e.message,
        code: e.code,
      );
    } catch (e) {
      return LocationResult.failure(
        LocationFailure.unknown,
        'Không lấy được vị trí: $e',
        code: 'GPS_UNAVAILABLE',
      );
    }
  }

  static LocationFailure _failureFor(String code) => switch (code) {
    'GPS_DISABLED' => LocationFailure.serviceDisabled,
    'GPS_PERMISSION_DENIED' => LocationFailure.permissionDenied,
    'GPS_PERMISSION_DENIED_FOREVER' => LocationFailure.permissionDeniedForever,
    'GPS_TIMEOUT' => LocationFailure.timeout,
    'GPS_INACCURATE' => LocationFailure.inaccurate,
    'GPS_MOCKED' => LocationFailure.mocked,
    'GPS_STALE' => LocationFailure.stale,
    _ => LocationFailure.unknown,
  };

  @override
  Future<void> openAppSettings() => _gps.openAppSettings();

  @override
  Future<void> openLocationSettings() => _gps.openLocationSettings();
}
