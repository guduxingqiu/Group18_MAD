import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return await _loadProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = cred.user!;

      try {
        await _db.collection('users').doc(user.uid).set({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'role': UserRole.public.name, // self-registration is always public
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        await user.delete(); // don't leave an account without a profile
        throw const AuthException('Could not create your profile. Please try again.');
      }

      return UserModel(
        id: user.uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        role: UserRole.public,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  Future<UserModel> _loadProfile(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) {
      await _auth.signOut();
      throw const AuthException('Account profile not found');
    }
    return UserModel(
      id: user.uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? user.email ?? '',
      role: UserRole.values.firstWhere(
            (r) => r.name == data['role'],
        orElse: () => UserRole.public,
      ),
    );
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak (at least 6 characters)';
      case 'network-request-failed':
        return 'No internet connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Something went wrong (${e.code})';
    }
  }
}