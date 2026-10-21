import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/mock_data.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/employee.dart';

class ProfileRepository {
  Future<Employee> getProfile() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.profile);
      final employee = Employee.fromJson(res.data as Map<String, dynamic>);
      await StorageService.setString(AppConstants.keyUserData, jsonEncode(employee.toJson()));
      return employee;
    } catch (_) {
      final cached = await StorageService.getString(AppConstants.keyUserData);
      if (cached != null) {
        return Employee.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      return MockData.currentEmployee;
    }
  }

  Future<Employee> updatePhone(String newPhone) async {
    try {
      final res = await ApiClient.instance.patch(
        ApiEndpoints.updateProfile,
        data: {'phone': newPhone},
      );
      final employee = Employee.fromJson(res.data as Map<String, dynamic>);
      await StorageService.setString(AppConstants.keyUserData, jsonEncode(employee.toJson()));
      return employee;
    } catch (_) {
      final updated = MockData.currentEmployee.copyWith(phone: newPhone);
      MockData.currentEmployee = updated;
      await StorageService.setString(AppConstants.keyUserData, jsonEncode(updated.toJson()));
      return updated;
    }
  }
}
