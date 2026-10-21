import 'dart:async';

import 'package:geolocator/geolocator.dart';

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
  unknown,
}

/// Kết quả lấy vị trí: có [location] hoặc có [failure].
class LocationResult {
  const LocationResult.success(GpsLocation this.location)
      : failure = null,
        message = null;

  const LocationResult.failure(LocationFailure this.failure, this.message) : location = null;

  final GpsLocation? location;
  final LocationFailure? failure;
  final String? message;

  bool get isSuccess => location != null;
}

abstract class LocationService {
  /// Xin quyền (nếu cần) và lấy vị trí hiện tại: latitude, longitude, accuracy.
  Future<LocationResult> getCurrentLocation();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}

/// Lấy GPS bằng package geolocator (Android, iOS, web).
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({this.timeout = const Duration(seconds: 15)});

  final Duration timeout;

  @override
  Future<LocationResult> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(
          LocationFailure.serviceDisabled,
          'GPS trên thiết bị đang tắt. Hãy bật dịch vụ vị trí rồi thử lại.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(
          LocationFailure.permissionDenied,
          'Bạn đã từ chối quyền vị trí. Ứng dụng cần vị trí để xác nhận bạn đang ở siêu thị.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          LocationFailure.permissionDeniedForever,
          'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy mở Cài đặt → Quyền → Vị trí để cho phép.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
      );
      return LocationResult.success(GpsLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: DateTime.now(),
        isMocked: position.isMocked,
      ));
    } on TimeoutException {
      return const LocationResult.failure(
        LocationFailure.timeout,
        'Không nhận được tín hiệu GPS. Hãy ra chỗ thoáng và thử lại.',
      );
    } catch (error) {
      return LocationResult.failure(LocationFailure.unknown, 'Không lấy được vị trí: $error');
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {
      // Web không hỗ trợ mở cài đặt.
    }
  }

  @override
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }
}
