class AppConstants {
  AppConstants._();

  // ─── API ────────────────────────────────────────────────────────────────────
  /// Base URL backend, truyền khi chạy:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.supermarket-hrm.com/v1',
  );

  /// Không truyền API_BASE_URL → chấm công chạy bằng dữ liệu giả lập (mock) để demo không cần backend.
  static const bool useMockApi = String.fromEnvironment('API_BASE_URL') == '';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ─── Storage keys ───────────────────────────────────────────────────────────
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyEmployeeId = 'employee_id';
  static const String keyUserData = 'user_data';

  // ─── Pagination ─────────────────────────────────────────────────────────────
  static const int pageSize = 20;

  // ─── Route names ────────────────────────────────────────────────────────────
  static const String routeLogin = '/login';
  static const String routeDashboard = '/dashboard';
  static const String routeProfile = '/profile';
  static const String routeSchedules = '/schedules';
  static const String routeScheduleDetail = '/schedules/:id';
  static const String routeAttendanceHistory = '/attendance-history';
}

