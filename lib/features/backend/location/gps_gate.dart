import 'dart:async';

import 'package:flutter/material.dart';

import 'location_service.dart';

/// Chỉ EMPLOYEE bắt buộc GPS khi vào hệ thống; ADMIN, MANAGER, HR dùng trang
/// quản trị không cần GPS.
bool requiresEmployeeGps(String roleCode) => roleCode == 'EMPLOYEE';

/// Màn hình chặn bắt buộc GPS cho tài khoản EMPLOYEE ngay sau khi đăng nhập.
///
/// Chỉ hiển thị [child] (không gian làm việc nhân viên) khi GPS đang bật và đã
/// được cấp quyền vị trí. Nếu chưa có quyền thì tự hỏi quyền; bị từ chối thì
/// giữ người dùng ở màn hình hướng dẫn, không cho vào hệ thống nghiệp vụ.
/// Khi người dùng quay lại từ màn hình cài đặt, gate tự kiểm tra lại.
class EmployeeGpsGate extends StatefulWidget {
  const EmployeeGpsGate({
    super.key,
    required this.child,
    required this.onLogout,
    this.gpsService,
  });

  final Widget child;
  final Future<void> Function() onLogout;

  /// Mặc định là [GpsService.instance]; test truyền service giả.
  final GpsService? gpsService;

  @override
  State<EmployeeGpsGate> createState() => _EmployeeGpsGateState();
}

class _EmployeeGpsGateState extends State<EmployeeGpsGate>
    with WidgetsBindingObserver {
  GpsService get _gps => widget.gpsService ?? GpsService.instance;
  GpsCheckResult? _result;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check(requestPermission: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quay lại từ màn hình cài đặt → kiểm tra lại (không hỏi quyền lần nữa).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !(_result?.isReady ?? false) &&
        !_checking) {
      _check(requestPermission: false);
    }
  }

  Future<void> _check({required bool requestPermission}) async {
    setState(() => _checking = true);
    // Một số trình duyệt không phản hồi lời gọi quyền vị trí (ví dụ khi hộp
    // thoại quyền đã bị chặn). Không để nhân viên bị kẹt mãi ở màn hình chờ.
    final result = await _gps
        .checkReady(requestPermission: requestPermission)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => const GpsCheckResult(
            GpsStatus.error,
            'Yêu cầu quyền vị trí không phản hồi. Hãy cho phép Vị trí trong Chrome rồi bấm “Thử lại”.',
          ),
        );
    if (!mounted) return;
    setState(() {
      _result = result;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null && result.isReady) return widget.child;
    if (result == null) return const _CheckingScreen();
    return _GpsBlockedScreen(
      result: result,
      checking: _checking,
      canOpenSettings: _gps.canOpenSettings,
      onRetry: () => _check(requestPermission: true),
      onOpenLocationSettings: _gps.openLocationSettings,
      onOpenAppSettings: _gps.openAppSettings,
      onLogout: widget.onLogout,
    );
  }
}

class _CheckingScreen extends StatelessWidget {
  const _CheckingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang kiểm tra GPS và quyền vị trí...'),
        ],
      ),
    ),
  );
}

/// Hướng dẫn xử lý theo từng trường hợp: GPS tắt / từ chối quyền / từ chối vĩnh viễn.
class _GpsBlockedScreen extends StatelessWidget {
  const _GpsBlockedScreen({
    required this.result,
    required this.checking,
    required this.canOpenSettings,
    required this.onRetry,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
    required this.onLogout,
  });

  final GpsCheckResult result;
  final bool checking;
  final bool canOpenSettings;
  final VoidCallback onRetry;
  final Future<bool> Function() onOpenLocationSettings;
  final Future<bool> Function() onOpenAppSettings;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final status = result.status;
    final (IconData icon, String title, String hint) = switch (status) {
      GpsStatus.serviceDisabled => (
        Icons.location_off_rounded,
        'Hãy bật GPS',
        GpsMessages.enableHint,
      ),
      GpsStatus.permissionDeniedForever => (
        Icons.lock_outline_rounded,
        'Quyền vị trí đã bị chặn',
        GpsMessages.permissionSettingsHint,
      ),
      GpsStatus.permissionDenied => (
        Icons.location_disabled_rounded,
        'Cần cho phép truy cập vị trí',
        'Bấm "Cho phép vị trí" và chọn "Cho phép khi dùng ứng dụng" trong hộp thoại của hệ thống.',
      ),
      _ => (
        Icons.gps_not_fixed_rounded,
        'Không kiểm tra được GPS',
        'Hãy kiểm tra GPS và thử lại.',
      ),
    };
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu vị trí GPS'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(onPressed: onLogout, child: const Text('Đăng xuất')),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(icon, size: 72, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  title,
                  key: const Key('gps-gate-title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),
                if (status == GpsStatus.serviceDisabled && canOpenSettings) ...[
                  FilledButton.icon(
                    onPressed: onOpenLocationSettings,
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Mở cài đặt vị trí'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (status == GpsStatus.permissionDeniedForever &&
                    canOpenSettings) ...[
                  FilledButton.icon(
                    onPressed: onOpenAppSettings,
                    icon: const Icon(Icons.app_settings_alt_rounded),
                    label: const Text('Mở cài đặt ứng dụng'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (status == GpsStatus.permissionDenied) ...[
                  FilledButton.icon(
                    onPressed: checking ? null : onRetry,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Cho phép vị trí'),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: checking ? null : onRetry,
                  icon: checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(checking ? 'Đang kiểm tra...' : 'Thử lại'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nhân viên bắt buộc bật GPS để vào hệ thống và chấm công. '
                  'Tài khoản quản trị (ADMIN, MANAGER, HR) không cần GPS khi chỉ dùng trang quản trị.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
