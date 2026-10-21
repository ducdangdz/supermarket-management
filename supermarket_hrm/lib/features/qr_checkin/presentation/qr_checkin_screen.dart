import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/mock_data.dart';

class QrCheckinScreen extends StatefulWidget {
  const QrCheckinScreen({super.key});

  @override
  State<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends State<QrCheckinScreen> {
  // Step 0: Scanning QR with device camera
  // Step 1: Random prompt - Take Selfie Evidence
  // Step 2: GPS verify
  // Step 3: Success
  int _step = 0;
  String? _scannedQrData;
  bool _isProcessing = false;

  // Mobile scanner controller
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // Selfie camera controller
  CameraController? _selfieController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _availableCameras = await availableCameras();
    } catch (_) {}
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _selfieController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || _step != 0) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _isProcessing = true;
        _scannedQrData = code;
        _scannerController.stop();

        // Chuyển sang bước 2: Yêu cầu ngẫu nhiên chụp ảnh selfie làm bằng chứng
        setState(() {
          _step = 1;
        });
        _setupSelfieCamera();
      }
    }
  }

  Future<void> _setupSelfieCamera() async {
    if (_availableCameras.isEmpty) return;

    // Tìm camera trước (front camera)
    final frontCam = _availableCameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _availableCameras.first,
    );

    _selfieController = CameraController(
      frontCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _selfieController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (_) {
      // Fallback nếu không mở được camera trước
    }
  }

  Future<void> _captureEvidenceAndSubmit() async {
    setState(() {
      _step = 2; // GPS verification
    });

    try {
      if (_selfieController != null && _selfieController!.value.isInitialized) {
        final xFile = await _selfieController!.takePicture();
        _capturedImagePath = xFile.path;
      }
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 1500));

    // Thực hiện lưu check-in
    MockData.performMockCheckIn(
      location: 'Khu vực Thu ngân Tầng 1 (Quầy 05)',
      photoUrl: _capturedImagePath ?? 'selfie_evidence.jpg',
    );

    if (mounted) {
      setState(() {
        _step = 3; // Hoàn tất
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(_appBarTitle),
        actions: [
          if (_step == 0)
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () => _scannerController.toggleTorch(),
              tooltip: 'Bật/Tắt đèn Flash',
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildStepContent()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  String get _appBarTitle {
    switch (_step) {
      case 0:
        return 'Quét mã QR tại quầy';
      case 1:
        return 'Chụp ảnh bằng chứng';
      case 2:
        return 'Xác thực GPS';
      default:
        return 'Điểm danh thành công';
    }
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      // Camera quét QR trực tiếp
      return Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Khung ngắm quét mã
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Hướng camera vào mã QR chi nhánh',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      );
    } else if (_step == 1) {
      // Camera trước chụp selfie
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 280,
              height: 360,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.warning, width: 3),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isCameraInitialized && _selfieController != null
                  ? CameraPreview(_selfieController!)
                  : Container(
                      color: Colors.grey.shade900,
                      child: const Center(
                        child: Icon(Icons.face, size: 90, color: Colors.white54),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.warning),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: AppTheme.warning, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Hệ thống yêu cầu: Chụp ảnh khuôn mặt làm bằng chứng',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_step == 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 20),
            const Text(
              'Đang đối soát GPS & Vị trí mặt bằng...',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tọa độ: 21.0031° N, 105.7892° E (Tầng 1 - Quầy 05)',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundColor: AppTheme.success,
              child: Icon(Icons.check, size: 54, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Check-in Thành Công!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã QR: ${_scannedQrData ?? "QR-ST-001"} • Đã lưu ảnh bằng chứng',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBottomBar() {
    if (_step == 1) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: _captureEvidenceAndSubmit,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp ảnh & Xác nhận check-in'),
          ),
        ),
      );
    } else if (_step == 3) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => context.pop(true),
            child: const Text('Quay lại Dashboard'),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
