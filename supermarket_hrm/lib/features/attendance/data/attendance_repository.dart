import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/attendance_models.dart';
import 'mock_attendance_repository.dart';

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
  /// Chọn mock khi không truyền API_BASE_URL (xem [AppConstants.useMockApi]).
  factory AttendanceRepository.create() =>
      AppConstants.useMockApi ? MockAttendanceRepository() : RemoteAttendanceRepository();

  /// Các ca hôm nay của nhân viên đang đăng nhập.
  Future<List<AttendanceSchedule>> getTodaySchedules();

  /// Upload ảnh bằng chứng, trả về hash để gửi kèm khi chấm công.
  Future<UploadedEvidence> uploadEvidence(EvidencePhoto photo);

  /// Gửi check-in/check-out. Bị từ chối thì trả về [AttendanceResult] với success = false (không ném lỗi).
  Future<AttendanceResult> submit(AttendanceSubmission submission);
}

/// Gọi Spring Boot backend (`backend/attendance-api.md`).
class RemoteAttendanceRepository implements AttendanceRepository {
  RemoteAttendanceRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  @override
  Future<List<AttendanceSchedule>> getTodaySchedules() async {
    try {
      final response = await _dio.get(ApiEndpoints.attendanceToday);
      final list = response.data as List<dynamic>;
      return list.map((e) => AttendanceSchedule.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<UploadedEvidence> uploadEvidence(EvidencePhoto photo) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(photo.bytes, filename: photo.fileName),
      });
      final response = await _dio.post(ApiEndpoints.attendanceEvidence, data: form);
      return UploadedEvidence.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<AttendanceResult> submit(AttendanceSubmission submission) async {
    final path = submission.action == AttendanceAction.checkIn
        ? ApiEndpoints.attendanceCheckIn
        : ApiEndpoints.attendanceCheckOut;
    try {
      final response = await _dio.post(path, data: submission.toJson());
      return AttendanceResult.fromJson(response.data as Map<String, dynamic>, submission.action);
    } on DioException catch (e) {
      final error = _toException(e);
      return AttendanceResult.failure(action: submission.action, code: error.code, message: error.message);
    }
  }

  /// Đọc {code, message} từ body lỗi của backend; không có response → lỗi mạng.
  AttendanceApiException _toException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return AttendanceApiException(
        data['code']?.toString() ?? 'HTTP_${e.response?.statusCode}',
        data['message'].toString(),
      );
    }
    if (e.response == null) {
      return const AttendanceApiException('NETWORK_ERROR', 'Không kết nối được máy chủ. Kiểm tra mạng và API_BASE_URL.');
    }
    return AttendanceApiException('HTTP_${e.response?.statusCode}', 'Yêu cầu thất bại (${e.response?.statusCode}).');
  }
}
