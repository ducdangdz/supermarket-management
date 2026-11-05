import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/device_identity_service.dart';

String get accountApiBaseUrl {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured.replaceFirst(RegExp(r'/+$'), '');
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8081/api'
      : 'http://localhost:8081/api';
}

class AccountSession {
  const AccountSession({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
  factory AccountSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['user'];
    if (token is! String ||
        token.isEmpty ||
        user is! Map ||
        user['employeeId'] is! num ||
        !const {
          'EMPLOYEE',
          'ADMIN',
          'MANAGER',
          'HR',
        }.contains(user['roleCode'])) {
      throw const AccountApiException(
        'Máy chủ trả về thông tin đăng nhập chưa hợp lệ.',
      );
    }
    return AccountSession(token: token, user: Map<String, dynamic>.from(user));
  }
}

class AccountApiException implements Exception {
  const AccountApiException(this.message, {this.statusCode, this.code});
  final String? code;
  final int? statusCode;
  final String message;
  @override
  String toString() => message;
}

class AccountAuthApi {
  AccountAuthApi({
    http.Client? client,
    String? baseUrl,
    Future<String> Function()? deviceIdProvider,
  })
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? accountApiBaseUrl,
      _deviceIdProvider = deviceIdProvider ?? DeviceIdentityService.getId;
  final http.Client _client;
  final String _baseUrl;
  final Future<String> Function() _deviceIdProvider;

  Future<AccountSession> login(String username, String password) async {
    final deviceId = await _deviceIdProvider();
    return AccountSession.fromJson(
      await _post('/auth/login', {
        'username': username.trim(),
        'password': password,
        'deviceId': deviceId,
      }),
    );
  }

  Future<String> register(
    String fullName,
    String email,
    String password,
  ) async => _challenge(
    await _post('/auth/register', {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
    }),
  );

  Future<AccountSession> verifyRegistration(String challengeId, String code) async {
    final deviceId = await _deviceIdProvider();
    return AccountSession.fromJson(
      await _post('/auth/verify-registration', {
        'challengeId': challengeId,
        'code': code,
        'deviceId': deviceId,
      }),
    );
  }

  Future<String> forgotPassword(String email) async =>
      _challenge(await _post('/auth/forgot-password', {'email': email.trim()}));

  Future<void> resetPassword(
    String challengeId,
    String code,
    String password,
  ) async {
    await _post('/auth/reset-password', {
      'challengeId': challengeId,
      'code': code,
      'password': password,
    });
  }

  Future<void> logout(String token) async {
    await _post('/auth/logout', {}, token: token);
  }

  String _challenge(Map<String, dynamic> json) {
    final id = json['challengeId'];
    if (id is! String || id.isEmpty)
      throw const AccountApiException(
        'Chưa nhận được yêu cầu xác nhận từ máy chủ.',
      );
    return id;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final deviceId = token == null ? null : await _deviceIdProvider();
      final response = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
              if (deviceId != null) 'X-Device-Id': deviceId,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      } on FormatException {
        /* Use the status-based fallback for HTML/gateway errors. */
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AccountApiException(
          data['message'] is String
              ? data['message'] as String
              : 'Yêu cầu chưa thành công. Vui lòng thử lại.',
        );
      }
      return data;
    } on TimeoutException {
      throw const AccountApiException(
        'Máy chủ phản hồi chậm. Vui lòng thử lại.',
      );
    } on http.ClientException {
      throw const AccountApiException(
        'Không kết nối được máy chủ. Kiểm tra backend và kết nối mạng.',
      );
    }
  }

  void close() => _client.close();
}
