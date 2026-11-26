import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_repository.dart'; // for AuthException
import 'user_admin_repository.dart';

class FirebaseUserAdminRepository implements UserAdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthException _friendly(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const AuthException('You do not have permission to do that');
      case 'unavailable':
        return const AuthException('No internet connection');
      default:
        return AuthException('Server error (${e.code})');
    }
  }

  @override
  Future<List<UserModel>> fetchUsers() async {
    try {
      final snap = await _db.collection('users').get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return UserModel(
          id: doc.id,
          name: d['name'] as String? ?? '',
          email: d['email'] as String? ?? '',
          role: UserRole.values.firstWhere(
                (r) => r.name == d['role'],
            orElse: () => UserRole.public,
          ),
        );
      }).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> setRole({
    required String adminId,
    required UserModel target,
    required UserRole newRole,
  }) async {
    if (target.id == adminId) {
      throw const AuthException('You cannot change your own role');
    }
    try {
      final batch = _db.batch();
      batch.update(_db.collection('users').doc(target.id), {'role': newRole.name});
      batch.set(_db.collection('audit_logs').doc(), {
        'reportId': target.id, // for role changes this holds the target user's ID
        'action': 'role_changed',
        'performedBy': adminId,
        'reason': '${target.email}: ${target.role.name} -> ${newRole.name}',
        'timestamp': FieldValue.serverTimestamp(),
      });
      await batch.commit().timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const AuthException('No connection. Please try again when you are online.');
    } on FirebaseException catch (e) {
      throw _friendly(e);
    }
  }
}