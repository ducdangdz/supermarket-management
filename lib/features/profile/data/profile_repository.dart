import '../../../core/network/team_api.dart';
import '../../../models/employee.dart';

class ProfileRepository {
  Future<Employee> getProfile() => TeamApi.active!.profile();
  Future<Employee> updatePhone(String phone) async {
    final api = TeamApi.active!;
    await api.request(
      '/employees/${api.employeeId}/phone',
      method: 'PATCH',
      body: {'phone': phone},
    );
    return api.profile();
  }
}
