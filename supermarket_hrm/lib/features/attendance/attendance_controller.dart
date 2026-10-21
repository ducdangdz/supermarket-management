import 'package:flutter/foundation.dart';

import 'data/attendance_repository.dart';
import 'domain/attendance_rules.dart';
import 'models/attendance_models.dart';
import 'services/device_info_service.dart';
import 'services/location_service.dart';

/// State của luồng chấm công (Provider / ChangeNotifier):
/// chọn ca → quét QR → lấy GPS → chụp ảnh (nếu ca yêu cầu) → gửi lên backend.
class AttendanceController extends ChangeNotifier {
  AttendanceController({
    required this.action,
    AttendanceRepository? repository,
    LocationService? locationService,
    DeviceInfoService? deviceInfoService,
    DateTime Function()? clock,
  })  : repository = repository ?? AttendanceRepository.create(),
        locationService = locationService ?? const GeolocatorLocationService(),
        _deviceInfoService = deviceInfoService ?? PlatformDeviceInfoService(),
        _clock = clock ?? DateTime.now;

  final AttendanceAction action;
  final AttendanceRepository repository;
  final LocationService locationService;
  final DeviceInfoService _deviceInfoService;
  final DateTime Function() _clock;

  // ─── Lịch làm ──────────────────────────────────────────────────────────────
  bool _isLoadingSchedules = false;
  String? _scheduleError;
  List<AttendanceSchedule> _schedules = const [];
  AttendanceSchedule? _selectedSchedule;

  // ─── Dữ liệu chấm công ─────────────────────────────────────────────────────
  String? _qrToken;
  bool _isLocating = false;
  LocationResult? _locationResult;
  EvidencePhoto? _evidence;
  bool _isSubmitting = false;
  bool _disposed = false;

  bool get isLoadingSchedules => _isLoadingSchedules;
  String? get scheduleError => _scheduleError;
  List<AttendanceSchedule> get schedules => _schedules;
  AttendanceSchedule? get selectedSchedule => _selectedSchedule;
  String? get qrToken => _qrToken;
  bool get isLocating => _isLocating;
  LocationResult? get locationResult => _locationResult;
  GpsLocation? get location => _locationResult?.location;
  EvidencePhoto? get evidence => _evidence;
  bool get isSubmitting => _isSubmitting;

  /// Vi phạm về lịch làm (không có lịch, chưa check-in...) → chặn cả luồng.
  AttendanceViolation? get scheduleViolation => _isLoadingSchedules || _scheduleError != null
      ? null
      : AttendanceRules.validateScheduleState(action: action, schedule: _selectedSchedule);

  /// Vi phạm đầu tiên còn thiếu trước khi được bấm "Hoàn tất".
  AttendanceViolation? get pendingViolation => AttendanceRules.validateBeforeSubmit(
        action: action,
        schedule: _selectedSchedule,
        qrToken: _qrToken,
        location: location,
        evidence: _evidence,
      );

  bool get canSubmit =>
      !_isSubmitting && !_isLoadingSchedules && _scheduleError == null && pendingViolation == null;

  /// Tải lịch hôm nay và lấy GPS song song khi mở màn hình.
  Future<void> initialize() async {
    await Future.wait([loadSchedules(), fetchLocation()]);
  }

  Future<void> loadSchedules() async {
    _isLoadingSchedules = true;
    _scheduleError = null;
    _notify();
    try {
      _schedules = await repository.getTodaySchedules();
      // Giữ ca đang chọn nếu vẫn còn, không thì chọn ca phù hợp nhất với thao tác.
      final keep = _schedules.where((s) => s.scheduleId == _selectedSchedule?.scheduleId);
      _selectedSchedule = keep.isNotEmpty ? keep.first : _pickDefault(_schedules);
    } on AttendanceApiException catch (e) {
      _scheduleError = e.message;
    } catch (e) {
      _scheduleError = 'Không tải được lịch làm hôm nay: $e';
    } finally {
      _isLoadingSchedules = false;
      _notify();
    }
  }

  AttendanceSchedule? _pickDefault(List<AttendanceSchedule> list) {
    if (list.isEmpty) return null;
    final open = list.where((s) => action == AttendanceAction.checkIn
        ? !s.isCheckedIn
        : s.isCheckedIn && !s.isCheckedOut);
    return open.isNotEmpty ? open.first : list.first;
  }

  void selectSchedule(AttendanceSchedule schedule) {
    _selectedSchedule = schedule;
    _notify();
  }

  void setQrToken(String? token) {
    final value = token?.trim();
    _qrToken = value == null || value.isEmpty ? null : value;
    _notify();
  }

  Future<void> fetchLocation() async {
    _isLocating = true;
    _notify();
    _locationResult = await locationService.getCurrentLocation();
    _isLocating = false;
    _notify();
  }

  void setEvidence(EvidencePhoto? photo) {
    _evidence = photo;
    _notify();
  }

  /// Gửi chấm công. Luôn trả về kết quả (thành công hoặc lý do từ chối) để hiện trang kết quả.
  Future<AttendanceResult> submit() async {
    final violation = pendingViolation;
    if (violation != null) {
      return AttendanceResult.failure(action: action, code: violation.code, message: violation.message, at: _clock());
    }
    _isSubmitting = true;
    _notify();
    try {
      UploadedEvidence? uploaded;
      if (_evidence != null) {
        uploaded = await repository.uploadEvidence(_evidence!);
      }
      final result = await repository.submit(AttendanceSubmission(
        action: action,
        scheduleId: _selectedSchedule?.scheduleId,
        qrToken: _qrToken,
        location: location,
        evidence: uploaded,
        evidenceCapturedAt: _evidence?.capturedAt,
        clientTime: _clock(),
        deviceInfo: await _deviceInfoService.describe(),
      ));
      // Thành công thì màn hình đóng lại và Dashboard tự tải lại, không cần tải lịch ở đây.
      if (!result.success && result.errorCode?.startsWith('QR_') == true) {
        // QR hết hạn / bị thu hồi / sai loại → bắt quét lại.
        _qrToken = null;
      }
      return result;
    } on AttendanceApiException catch (e) {
      return AttendanceResult.failure(action: action, code: e.code, message: e.message, at: _clock());
    } catch (e) {
      return AttendanceResult.failure(action: action, code: 'UNKNOWN', message: 'Có lỗi xảy ra: $e', at: _clock());
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
