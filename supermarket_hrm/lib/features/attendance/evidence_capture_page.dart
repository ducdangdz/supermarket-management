import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'models/attendance_models.dart';

/// Chụp ảnh bằng chứng check-in/check-out bằng camera (mặc định camera trước).
/// Sau khi chụp hiển thị ảnh xem trước; "Dùng ảnh này" trả về [EvidencePhoto] qua Navigator.pop.
class EvidenceCapturePage extends StatefulWidget {
  const EvidenceCapturePage({super.key, required this.action});

  final AttendanceAction action;

  @override
  State<EvidenceCapturePage> createState() => _EvidenceCapturePageState();
}

class _EvidenceCapturePageState extends State<EvidenceCapturePage> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _error;
  EvidencePhoto? _photo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// Giải phóng camera khi app vào nền, mở lại khi quay lại (khuyến nghị của package camera).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      setState(() => _controller = null);
      controller.dispose();
    } else if (state == AppLifecycleState.resumed && _photo == null) {
      _openCamera(_cameraIndex);
    }
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _error = 'Không tìm thấy camera trên thiết bị.';
        });
        return;
      }
      final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      await _openCamera(front >= 0 ? front : 0);
    } on CameraException catch (e) {
      _showCameraError(e);
    }
  }

  Future<void> _openCamera(int index) async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    final old = _controller;
    _controller = null;
    await old?.dispose();

    final controller = CameraController(_cameras[index], ResolutionPreset.medium, enableAudio: false);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraIndex = index;
        _isInitializing = false;
      });
    } on CameraException catch (e) {
      await controller.dispose();
      _showCameraError(e);
    }
  }

  void _showCameraError(CameraException e) {
    if (!mounted) return;
    final denied = e.code.contains('AccessDenied') || e.code.contains('Permission');
    setState(() {
      _isInitializing = false;
      _error = denied
          ? 'Ứng dụng chưa được cấp quyền camera. Hãy cho phép quyền camera trong Cài đặt để chụp ảnh bằng chứng.'
          : 'Không mở được camera: ${e.description ?? e.code}';
    });
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = EvidencePhoto(
          bytes: bytes,
          capturedAt: DateTime.now(),
          fileName: '${widget.action.qrSessionType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      });
    } on CameraException catch (e) {
      _showCameraError(e);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _retake() {
    setState(() => _photo = null);
    if (_controller == null) _openCamera(_cameraIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Ảnh bằng chứng ${widget.action.label}'),
        actions: [
          if (_photo == null && _cameras.length > 1)
            IconButton(
              tooltip: 'Đổi camera',
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: _isInitializing ? null : () => _openCamera((_cameraIndex + 1) % _cameras.length),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _buildPreview())),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(_photo!.bytes, fit: BoxFit.contain),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 56),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _setup, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
          ],
        ),
      );
    }
    final controller = _controller;
    if (_isInitializing || controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: CameraPreview(controller));
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: _photo == null
            ? ElevatedButton.icon(
                onPressed: _controller == null || _isCapturing ? null : _capture,
                icon: _isCapturing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt),
                label: const Text('Chụp ảnh'),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Chụp lại'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      onPressed: () => Navigator.of(context).pop(_photo),
                      icon: const Icon(Icons.check),
                      label: const Text('Dùng ảnh này'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
