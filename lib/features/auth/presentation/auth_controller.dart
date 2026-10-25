import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../../../models/employee.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    Employee? initialEmployee,
    this.onSessionLogout,
  }) : _authRepository = authRepository,
       _currentEmployee = initialEmployee;

  final Future<void> Function()? onSessionLogout;

  final AuthRepository _authRepository;

  Employee? _currentEmployee;
  bool _isLoading = false;
  String? _errorMessage;

  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentEmployee != null;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentEmployee = await _authRepository.checkAuthStatus();
    } catch (_) {
      _currentEmployee = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentEmployee = await _authRepository.signInWithCredentials(
        username: username,
        password: password,
      );
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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentEmployee = await _authRepository.signInWithGoogle();
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

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    if (onSessionLogout != null) {
      await onSessionLogout!();
      return;
    }
    await _authRepository.signOut();
    _currentEmployee = null;
    _isLoading = false;
    notifyListeners();
  }
}
