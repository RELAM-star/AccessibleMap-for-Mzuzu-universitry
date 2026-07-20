// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  User? get currentUser => FirebaseAuth.instance.currentUser;
  String? get currentUserId => currentUser?.uid;
  final FirestoreService _firestore = FirestoreService();

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String disabilityType,
    required bool needsVoiceNavigation,
    required bool needsWheelchairRoutes,
    required String studentId,
    required String role,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = UserModel(
        uid: credential.user!.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        disabilityType: disabilityType,
        needsVoiceNavigation: needsVoiceNavigation,
        needsWheelchairRoutes: needsWheelchairRoutes,
        studentId: studentId,
        role: role,
        createdAt: DateTime.now(),
      );
      await credential.user?.updateDisplayName(fullName);
      await _firestore.saveUserProfile(user);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    return _firestore.getUserProfile(uid);
  }

  Future<String?> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && data['fullName'] != null) {
        await user.updateDisplayName(data['fullName'] as String);
      }
      await _firestore.updateUserProfile(uid, data);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }
}