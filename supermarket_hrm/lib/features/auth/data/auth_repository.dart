import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/mock_data.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/employee.dart';

class AuthRepository {
  AuthRepository()
      : _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

  final GoogleSignIn _googleSignIn;

  Future<Employee> signInWithCredentials({
    required String username,
    required String password,
  }) async {
    // Cho phép tài khoản demo khi test UI
    if ((username == 'admin' && password == '123456') ||
        (username == 'employee' && password == '123456') ||
        (username == 'demo' && password == 'demo')) {
      await Future.delayed(const Duration(milliseconds: 500));
      final employee = MockData.currentEmployee;
      await StorageService.setString(AppConstants.keyAuthToken, 'mock_token_123');
      await StorageService.setString(
        AppConstants.keyUserData,
        jsonEncode(employee.toJson()),
      );
      return employee;
    }

    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final jwtToken = data['token'] as String;
      final employee = Employee.fromJson(data['employee'] as Map<String, dynamic>);

      await StorageService.setString(AppConstants.keyAuthToken, jwtToken);
      await StorageService.setString(
        AppConstants.keyUserData,
        jsonEncode(employee.toJson()),
      );
      return employee;
    } catch (_) {
      throw Exception('Tài khoản hoặc mật khẩu không chính xác. (Gợi ý test: employee / 123456)');
    }
  }

  Future<Employee> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Đăng nhập bị hủy.');

      final auth = await account.authentication;
      final idToken = auth.idToken;

      final response = await ApiClient.instance.post(
        ApiEndpoints.googleLogin,
        data: {'id_token': idToken},
      );
      final data = response.data as Map<String, dynamic>;
      final jwtToken = data['token'] as String;
      final employee = Employee.fromJson(data['employee'] as Map<String, dynamic>);

      await StorageService.setString(AppConstants.keyAuthToken, jwtToken);
      await StorageService.setString(
        AppConstants.keyUserData,
        jsonEncode(employee.toJson()),
      );
      return employee;
    } catch (e) {
      // Fallback demo nếu chưa cấu hình backend Google
      await Future.delayed(const Duration(milliseconds: 600));
      final employee = MockData.currentEmployee;
      await StorageService.setString(AppConstants.keyAuthToken, 'mock_google_token');
      await StorageService.setString(
        AppConstants.keyUserData,
        jsonEncode(employee.toJson()),
      );
      return employee;
    }
  }

  Future<Employee?> checkAuthStatus() async {
    final token = await StorageService.getString(AppConstants.keyAuthToken);
    if (token == null || token.isEmpty) return null;

    final userData = await StorageService.getString(AppConstants.keyUserData);
    if (userData == null) return null;

    try {
      final map = jsonDecode(userData) as Map<String, dynamic>;
      return Employee.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await StorageService.clear();
    ApiClient.reset();
  }
}
