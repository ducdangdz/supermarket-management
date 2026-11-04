import '../../../core/network/team_api.dart';
import '../../../models/employee.dart';
import 'account_auth_api.dart';

/// Legacy employee navigation delegates authentication to the same real account API.
class AuthRepository {
  Future<Employee> signInWithCredentials({
    required String username,
    required String password,
  }) async {
    final auth = AccountAuthApi();
    try {
      final session = await auth.login(username, password);
      TeamApi.active?.close();
      final api = TeamApi(
        employeeId: (session.user['employeeId'] as num).toInt(),
        token: session.token,
      );
      TeamApi.active = api;
      return await api.profile();
    } finally {
      auth.close();
    }
  }

  Future<Employee> signInWithGoogle() async {
    throw StateError('Vui lòng dùng nút Google trên màn đăng nhập chung.');
  }

  Future<Employee?> checkAuthStatus() async {
    final api = TeamApi.active;
    if (api == null) return null;
    await api.request('/auth/me');
    return api.profile();
  }

  Future<void> signOut() async {
    final api = TeamApi.active;
    if (api == null) return;
    final auth = AccountAuthApi();
    try {
      await auth.logout(api.token);
    } finally {
      auth.close();
      api.close();
    }
  }
}
