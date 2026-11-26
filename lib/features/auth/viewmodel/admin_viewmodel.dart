import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import '../repository/user_admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final UserAdminRepository _repo;
  AdminViewModel(this._repo);

  List<UserModel> _users = [];
  bool isLoading = false;
  String? errorMessage;
  String _query = '';

  List<UserModel> get users {
    if (_query.isEmpty) return _users;
    final q = _query.toLowerCase();
    return _users
        .where((u) =>
    u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
  }

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _users = await _repo.fetchUsers();
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not load users';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> setRole({
    required String adminId,
    required UserModel target,
    required UserRole newRole,
  }) async {
    errorMessage = null;
    try {
      await _repo.setRole(adminId: adminId, target: target, newRole: newRole);
      final i = _users.indexWhere((u) => u.id == target.id);
      if (i != -1) {
        _users[i] = UserModel(
            id: target.id, name: target.name, email: target.email, role: newRole);
      }
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (_) {
      errorMessage = 'Could not change the role';
    }
    notifyListeners();
    return false;
  }
}