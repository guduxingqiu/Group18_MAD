import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
}