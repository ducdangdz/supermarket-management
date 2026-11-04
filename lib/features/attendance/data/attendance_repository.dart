import '../../../core/network/team_api.dart';
import '../../../features/auth/data/account_auth_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/attendance_models.dart';

/// Lỗi có mã (giống mã backend) khi gọi API chấm công.
class AttendanceApiException implements Exception {
  const AttendanceApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AttendanceApiException($code): $message';
}

/// Nguồn dữ liệu chấm công. Có 2 cài đặt: gọi backend thật và mock để demo.
abstract class AttendanceRepository {
  /// Always uses the real authenticated connection; tests inject their own repository.
  factory AttendanceRepository.create() => RemoteAttendanceRepository();

  /// Các ca hôm nay của nhân viên đang đăng nhập.
  Future<List<AttendanceSchedule>> getTodaySchedules();

  /// Upload ảnh bằng chứng, trả về hash để gửi kèm khi chấm công.
  Future<UploadedEvidence> uploadEvidence(EvidencePhoto photo);

  /// Gửi check-in/check-out. Bị từ chối thì trả về [AttendanceResult] với success = false (không ném lỗi).
  Future<AttendanceResult> submit(AttendanceSubmission submission);
}

/// Gọi Spring Boot backend (`backend/attendance-api.md`).
class RemoteAttendanceRepository implements AttendanceRepository {
  RemoteAttendanceRepository();
  TeamApi get api =>
      TeamApi.active ??
      (throw const AttendanceApiException(
        'UNAUTHENTICATED',
        'Vui lòng đăng nhập lại.',
      ));
  @override
  Future<List<AttendanceSchedule>> getTodaySchedules() async {
    try {
      final list = await api.request('/attendance/me/today') as List;
      return list
          .map((e) => AttendanceSchedule.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw _error(e);
    }
  }

  @override
  Future<UploadedEvidence> uploadEvidence(EvidencePhoto photo) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$accountApiBaseUrl/attendance/evidence'),
      );
      request.headers['Authorization'] = 'Bearer ${api.token}';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          photo.bytes,
          filename: photo.fileName,
        ),
      );
      final response = await (() async => http.Response.fromStream(
        await api.client.send(request),
      ))().timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300)
        throw AttendanceApiException(
          data['code']?.toString() ?? 'HTTP_${response.statusCode}',
          data['message']?.toString() ?? 'Không tải được ảnh bằng chứng.',
        );
      return UploadedEvidence.fromJson(data);
    } catch (e) {
      throw _error(e);
    }
  }

  @override
  Future<AttendanceResult> submit(AttendanceSubmission submission) async {
    try {
      final path = submission.action == AttendanceAction.checkIn
          ? 'check-in'
          : 'check-out';
      final result = await api.request(
        '/attendance/$path',
        method: 'POST',
        body: submission.toJson(),
      );
      return AttendanceResult.fromJson(
        Map<String, dynamic>.from(result),
        submission.action,
      );
    } catch (e) {
      final err = _error(e);
      return AttendanceResult.failure(
        action: submission.action,
        code: err.code,
        message: err.message,
      );
    }
  }

  AttendanceApiException _error(Object e) {
    if (e is AttendanceApiException) return e;
    if (e is AccountApiException)
      return AttendanceApiException(
        e.code ??
            (e.statusCode == null ? 'NETWORK_ERROR' : 'HTTP_${e.statusCode}'),
        e.message,
      );
    return AttendanceApiException('REQUEST_FAILED', e.toString());
  }
}
