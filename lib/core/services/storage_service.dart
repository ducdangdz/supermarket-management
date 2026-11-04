import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    assert(_prefs != null, 'StorageService chưa được khởi tạo. Gọi StorageService.init() trước.');
    return _prefs!;
  }

  // ─── String ────────────────────────────────────────────────────────────────
  static Future<bool> setString(String key, String value) =>
      _instance.setString(key, value);

  static Future<String?> getString(String key) async =>
      _instance.getString(key);

  // ─── Bool ──────────────────────────────────────────────────────────────────
  static Future<bool> setBool(String key, bool value) =>
      _instance.setBool(key, value);

  static bool? getBool(String key) => _instance.getBool(key);

  // ─── Remove / Clear ────────────────────────────────────────────────────────
  static Future<bool> remove(String key) => _instance.remove(key);

  static Future<bool> clear() => _instance.clear();
}

