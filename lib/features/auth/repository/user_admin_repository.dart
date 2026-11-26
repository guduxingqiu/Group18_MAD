import '../models/user_model.dart';

abstract class UserAdminRepository {
  Future<List<UserModel>> fetchUsers();

  /// Changes a role and records it in the audit trail.
  Future<void> setRole({
    required String adminId,
    required UserModel target,
    required UserRole newRole,
  });
}