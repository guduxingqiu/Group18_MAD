import '../models/user_model.dart';
import 'auth_repository.dart';

class _Account {
  final UserModel user;
  final String password; // MOCK ONLY. A real backend must store a password hash.
  const _Account(this.user, this.password);
}

class MockAuthRepository implements AuthRepository {
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

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // pretend network delay
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthException('Invalid email or password');
    }
    return account.user;
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException('This email is already registered');
    }
    final user = UserModel(
      id: 'u${_accounts.length + 1}',
      name: name.trim(),
      email: key,
      role: UserRole.public, // self-registration is always a public user
    );
    _accounts[key] = _Account(user, password);
    return user;
  }

  @override
  Future<void> logout() async {}
}