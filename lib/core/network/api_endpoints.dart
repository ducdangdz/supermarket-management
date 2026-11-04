class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  static const String profile = '/employees/me';
  static const String updateProfile = '/employees/me';
  static const String dashboard = '/employees/me/dashboard';
  static const String schedules = '/employees/me/schedules';
  static const String scheduleDetail = '/schedules';
  static const String attendance = '/employees/me/attendance';
  static const String checkIn = '/employees/me/check-in';

  // ─── Chấm công QR + GPS + ảnh (khớp với backend/attendance-api.md) ──────────
  static const String attendanceToday = '/attendance/me/today';
  static const String attendanceEvidence = '/attendance/evidence';
  static const String attendanceCheckIn = '/attendance/check-in';
  static const String attendanceCheckOut = '/attendance/check-out';
}
