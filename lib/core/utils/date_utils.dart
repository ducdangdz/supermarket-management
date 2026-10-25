import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dateFormatter = DateFormat('dd/MM/yyyy', 'vi_VN');
  static final _timeFormatter = DateFormat('HH:mm', 'vi_VN');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'vi_VN');
  static final _monthFormatter = DateFormat('MM/yyyy', 'vi_VN');
  static final _dayOfWeekFormatter = DateFormat('EEEE', 'vi_VN');

  static String formatDate(DateTime date) => _dateFormatter.format(date);

  static String formatTime(DateTime time) => _timeFormatter.format(time);

  static String formatDateTime(DateTime dt) => _dateTimeFormatter.format(dt);

  static String formatMonth(DateTime date) => _monthFormatter.format(date);

  static String formatDayOfWeek(DateTime date) =>
      _dayOfWeekFormatter.format(date);

  /// Trả về "Hôm nay", "Hôm qua", hoặc dd/MM/yyyy
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return _dateFormatter.format(date);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '$m phút';
    return '$h giờ $m phút';
  }
}

