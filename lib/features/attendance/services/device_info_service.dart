import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Mô tả ngắn thiết bị gửi kèm dữ liệu chấm công (lưu vào attendance_evidence.device_info).
abstract class DeviceInfoService {
  Future<String> describe();
}

class PlatformDeviceInfoService implements DeviceInfoService {
  PlatformDeviceInfoService({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;
  String? _cached;

  @override
  Future<String> describe() async {
    if (_cached != null) return _cached!;
    try {
      _cached = await _read();
    } catch (_) {
      _cached = 'Không xác định (${defaultTargetPlatform.name})';
    }
    return _cached!;
  }

  Future<String> _read() async {
    if (kIsWeb) {
      final web = await _plugin.webBrowserInfo;
      return 'Web · ${web.browserName.name} · ${web.platform ?? ''}'.trim();
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = await _plugin.androidInfo;
        return 'Android ${android.version.release} (SDK ${android.version.sdkInt}) · '
            '${android.manufacturer} ${android.model}${android.isPhysicalDevice ? '' : ' · máy ảo'}';
      case TargetPlatform.iOS:
        final ios = await _plugin.iosInfo;
        return '${ios.systemName} ${ios.systemVersion} · ${ios.utsname.machine}'
            '${ios.isPhysicalDevice ? '' : ' · máy ảo'}';
      case TargetPlatform.windows:
        final windows = await _plugin.windowsInfo;
        return 'Windows · ${windows.computerName}';
      default:
        return defaultTargetPlatform.name;
    }
  }
}
