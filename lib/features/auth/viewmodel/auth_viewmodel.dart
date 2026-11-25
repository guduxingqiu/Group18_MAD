import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // MOCK DATA ONLY. Replace with a real API/Firebase call once the backend is chosen.
  static const _mockUsers = {
    'public@wth.com': UserModel(
        id: 'u1', name: 'Aisyah', email: 'public@wth.com', role: UserRole.public),
    'officer@wth.com': UserModel(
        id: 'u2', name: 'Officer Lim', email: 'officer@wth.com', role: UserRole.healthOfficer),
    'admin@wth.com': UserModel(
        id: 'u3', name: 'System Admin', email: 'admin@wth.com', role: UserRole.admin),
  };
  static const _mockPassword = '123456';

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // pretend network delay

    final user = _mockUsers[email.trim().toLowerCase()];
    if (user != null && password == _mockPassword) {
      _currentUser = user;
    } else {
      _errorMessage = 'Invalid email or password';
    }

    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}