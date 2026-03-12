// lib/services/auth_service.dart
// TEMPORARY - No Firebase, just for testing UI

import '../models/user_model.dart';

class AuthService {
  String? get currentUserId => 'test_user_123';

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return null; // null = success
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
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<void> signOut() async {}

  Future<String?> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<UserModel?> getUserProfile(String uid) async {
    return UserModel(
      uid: uid,
      fullName: 'Chisomo Banda',
      email: 'chisomo@mzuni.ac.mw',
      phone: '+265 999 000 000',
      disabilityType: 'blind',
      needsVoiceNavigation: true,
      needsWheelchairRoutes: false,
      studentId: 'STU2024001',
      role: 'student',
      createdAt: DateTime.now(),
    );
  }

  Future<String?> updateProfile(String uid, Map<String, dynamic> data) async {
    return null;
  }
}