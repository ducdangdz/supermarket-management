import 'dart:html' as html;

class LocationSample {
  const LocationSample(this.latitude, this.longitude, this.accuracyMeters);
  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

Future<LocationSample?> getCurrentLocation() async {
  final position = await html.window.navigator.geolocation.getCurrentPosition(
    enableHighAccuracy: true,
    timeout: const Duration(seconds: 10),
  );
  final coordinates = position.coords;
  if (coordinates == null) {
    throw StateError('Không nhận được dữ liệu GPS từ trình duyệt.');
  }
  return LocationSample(
    coordinates.latitude?.toDouble() ?? 0,
    coordinates.longitude?.toDouble() ?? 0,
    coordinates.accuracy?.toDouble() ?? 0,
  );
}
