import 'package:flutter/material.dart';
import '../data/dashboard_repository.dart';
import '../../../models/employee.dart';
import '../../../models/work_schedule.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({required DashboardRepository dashboardRepository})
      : _repository = dashboardRepository;

  final DashboardRepository _repository;

  Employee? _employee;
  WorkSchedule? _todaySchedule;
  bool _isLoading = false;
  String? _errorMessage;

  Employee? get employee => _employee;
  WorkSchedule? get todaySchedule => _todaySchedule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getEmployeeProfile(),
        _repository.getTodaySchedule(),
      ]);
      _employee = results[0] as Employee;
      _todaySchedule = results[1] as WorkSchedule?;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
