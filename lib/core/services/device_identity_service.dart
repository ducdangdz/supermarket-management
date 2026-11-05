import 'dart:math';

import 'storage_service.dart';

/// A random identifier for this app installation, not a hardware identifier.
/// It lets the server enforce one active session per account without collecting
/// IMEI, MAC address, or the user's device name.
class DeviceIdentityService {
  DeviceIdentityService._();

  static const _storageKey = 'installation_device_id_v1';
  static final Random _random = Random.secure();
  static String? _cached;

  /// App startup persists this value. The fallback also keeps isolated tests
  /// and non-UI clients from emitting an authenticated request without it.
  static String get currentId => _cached ??= _newId();

  static Future<String> getId() async {
    if (_cached != null) return _cached!;
    final saved = await StorageService.getString(_storageKey);
    if (saved != null && RegExp(r'^[a-f0-9]{32}$').hasMatch(saved)) {
      return _cached = saved;
    }
    final value = _newId();
    await StorageService.setString(_storageKey, value);
    return _cached = value;
  }

  static String _newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
