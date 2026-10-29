import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'data/mock_attendance_repository.dart';
import 'models/attendance_models.dart';

/// Màn hình quét mã QR chấm công bằng camera.
/// Trả về chuỗi token trong QR qua `Navigator.pop(token)`, hoặc null nếu người dùng hủy.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key, required this.action});

  final AttendanceAction action;

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Chặn trường hợp camera nhận nhiều khung hình liên tiếp → pop nhiều lần.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value == null || value.isEmpty) continue;
      _finish(value);
      return;
    }
  }

  void _finish(String token) {
    if (_handled) return;
    _handled = true;
    _controller.stop();
    Navigator.of(context).pop(token);
  }

  /// Nhập mã thủ công: dùng khi camera lỗi, chạy trên máy ảo, hoặc QR hiển thị ngay trên máy này.
  Future<void> _enterManually() async {
    final textController = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nhập mã QR'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Dán chuỗi mã do quản lý cung cấp',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (token != null && token.trim().isNotEmpty) _finish(token.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Quét QR ${widget.action.label}'),
        actions: [
          IconButton(
            tooltip: 'Bật/tắt đèn flash',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Đổi camera',
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) =>
                  _ScannerError(error: error, onManual: _enterManually),
              // Khung ngắm chỉ vẽ khi camera đang chạy (không đè lên thông báo lỗi).
              overlayBuilder: (context, constraints) => const _ScanFrame(),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _enterManually,
                    icon: const Icon(Icons.keyboard_outlined),
                    label: const Text('Nhập mã thủ công'),
                  ),
                  if (AppConstants.useMockApi) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Chế độ demo: chọn nhanh một mã QR mẫu',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: MockQrCodes.samples.entries
                          .map(
                            (e) => ActionChip(
                              label: Text(e.key),
                              onPressed: () => _finish(e.value),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung ngắm + hướng dẫn vẽ đè lên hình camera.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Đưa mã QR tại khu vực làm việc vào khung',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiển thị lỗi camera (thường gặp nhất: chưa cấp quyền camera).
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onManual});

  final MobileScannerException error;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Ứng dụng chưa được cấp quyền camera. Hãy cho phép quyền camera trong Cài đặt để quét QR.',
      MobileScannerErrorCode.unsupported =>
        'Thiết bị này không hỗ trợ quét QR bằng camera.',
      _ =>
        'Không mở được camera: ${error.errorDetails?.message ?? error.errorCode.name}',
    };
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white70,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onManual,
            icon: const Icon(Icons.keyboard),
            label: const Text('Nhập mã thủ công'),
          ),
        ],
      ),
    );
  }
}
