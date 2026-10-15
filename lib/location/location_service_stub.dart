class LocationSample {
  const LocationSample(this.latitude, this.longitude, this.accuracyMeters);
  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

Future<LocationSample?> getCurrentLocation() async => null;
