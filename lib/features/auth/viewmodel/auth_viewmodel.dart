import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class _Account {
  final UserModel user;
  final String password; // MOCK ONLY. A real backend must store a password hash, never plain text.
  const _Account(this.user, this.password);
}

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // MOCK DATA ONLY. Replace with the real backend later.
  final Map<String, _Account> _accounts = {
    'public@wth.com': const _Account(
      UserModel(id: 'u1', name: 'Aisyah', email: 'public@wth.com', role: UserRole.public),
      '123456',
    ),
    'officer@wth.com': const _Account(
      UserModel(id: 'u2', name: 'Officer Lim', email: 'officer@wth.com', role: UserRole.healthOfficer),
      '123456',
    ),
    'admin@wth.com': const _Account(
      UserModel(id: 'u3', name: 'System Admin', email: 'admin@wth.com', role: UserRole.admin),
      '123456',
    ),
  };

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // pretend network delay

    final account = _accounts[email.trim().toLowerCase()];
    if (account != null && account.password == password) {
      _currentUser = account.user;
    } else {
      _errorMessage = 'Invalid email or password';
    }

    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // pretend network delay

    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      _errorMessage = 'This email is already registered';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final user = UserModel(
      id: 'u${_accounts.length + 1}',
      name: name.trim(),
      email: key,
      role: UserRole.public, // self-registration is always a public user
    );
    _accounts[key] = _Account(user, password);
    _currentUser = user; // log in straight after registering

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}