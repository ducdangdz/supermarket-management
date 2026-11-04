import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../services/storage_service.dart';

class ApiClient {
  ApiClient._();

  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor());

    return dio;
  }

  static void reset() => _dio = null;
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.getString(AppConstants.keyAuthToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token hết hạn → clear storage (AuthBloc sẽ xử lý logout)
      StorageService.remove(AppConstants.keyAuthToken);
    }
    handler.next(err);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioError(DioException e) {
    return ApiException(
      message:
          e.response?.data?['message'] as String? ??
          e.message ??
          'Lỗi kết nối, vui lòng thử lại.',
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
