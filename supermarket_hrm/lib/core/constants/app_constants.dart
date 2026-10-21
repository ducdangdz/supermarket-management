class AppConstants {
  AppConstants._();

  // ─── API ────────────────────────────────────────────────────────────────────
  /// Thay bằng base URL thực của nhóm
  static const String baseUrl = 'https://api.supermarket-hrm.com/v1';
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

