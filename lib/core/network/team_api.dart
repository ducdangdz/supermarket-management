import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/data/account_auth_api.dart';
import '../../models/employee.dart';
import '../../models/work_schedule.dart';

/// Connection used by the original team screens after real authentication.
class TeamApi {
  TeamApi({required this.employeeId, required this.token, http.Client? client})
    : client = client ?? http.Client();
  static TeamApi? active;
  final int employeeId;
  final String token;
  final http.Client client;
  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final req = http.Request(method, Uri.parse('$accountApiBaseUrl$path'));
    req.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (body != null) req.body = jsonEncode(body);
    late http.Response response;
    try {
      response = await (() async => http.Response.fromStream(
        await client.send(req),
      ))().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AccountApiException(
        'Máy chủ phản hồi chậm. Hãy thử lại sau.',
      );
    } on http.ClientException {
      throw const AccountApiException(
        'Mất kết nối máy chủ. Kiểm tra kết nối rồi thử lại.',
      );
    }
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw const AccountApiException(
        'Máy chủ trả về dữ liệu không hợp lệ. Kiểm tra địa chỉ API.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AccountApiException(
        response.statusCode == 401
            ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất và đăng nhập lại.'
            : data is Map
            ? data['message']?.toString() ?? 'Yêu cầu thất bại.'
            : 'Yêu cầu thất bại.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  Future<Employee> profile() async {
    final p = await request('/employees/$employeeId');
    return Employee(
      id: p['employeeId'].toString(),
      name: p['fullName'] ?? '',
      email: p['email'] ?? '',
      phone: p['phone'] ?? '',
      role: p['roleName'] ?? '',
      branch: p['branchName'] ?? 'Chưa được gán chi nhánh',
      employeeCode: p['employeeCode'] ?? '',
    );
  }

  Future<List<Map<String, dynamic>>> schedules({
    String? from,
    String? to,
  }) async {
    final query = Uri(
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    ).query;
    final rows =
        await request(
              '/employees/$employeeId/schedules${query.isEmpty ? '' : '?$query'}',
            )
            as List;
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static String day(DateTime d) => d.toIso8601String().split('T').first;
  static WorkSchedule schedule(Map<String, dynamic> s) => WorkSchedule(
    id: s['scheduleId'].toString(),
    date: s['workDate'],
    startTime: s['startTime'],
    endTime: s['endTime'],
    location: '${s['areaName'] ?? ''} · ${s['floorName'] ?? ''}',
    status: s['scheduleStatus'] == 'CANCELLED'
        ? 'CANCELLED'
        : s['checkOutAt'] != null
        ? 'CHECKED_OUT'
        : s['checkInAt'] != null
        ? 'CHECKED_IN'
        : 'PENDING',
    checkInTime: time(s['checkInAt']),
    checkOutTime: time(s['checkOutAt']),
  );
  static String? time(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    final t = s.contains('T')
        ? s.split('T').last
        : s.contains(' ')
        ? s.split(' ').last
        : s;
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  void close() {
    if (identical(active, this)) active = null;
    client.close();
  }
}
