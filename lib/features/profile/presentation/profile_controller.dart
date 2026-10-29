import 'package:flutter/material.dart';
import '../data/profile_repository.dart';
import '../../../models/employee.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({required ProfileRepository profileRepository})
      : _repository = profileRepository;

  final ProfileRepository _repository;

  Employee? _employee;
  bool _isLoading = false;
  String? _errorMessage;

  Employee? get employee => _employee;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _employee = await _repository.getProfile();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePhone(String newPhone) async {
    _isLoading = true;
    notifyListeners();
    try {
      _employee = await _repository.updatePhone(newPhone);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
