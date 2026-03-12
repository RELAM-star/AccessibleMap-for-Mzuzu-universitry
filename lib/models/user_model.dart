// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String disabilityType; // blind, wheelchair, deaf, other
  final bool needsVoiceNavigation;
  final bool needsWheelchairRoutes;
  final String studentId; // Mzuni student/staff ID
  final String role; // student, staff, visitor
  final DateTime createdAt;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.disabilityType,
    required this.needsVoiceNavigation,
    required this.needsWheelchairRoutes,
    required this.studentId,
    required this.role,
    required this.createdAt,
    this.photoUrl,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'disabilityType': disabilityType,
      'needsVoiceNavigation': needsVoiceNavigation,
      'needsWheelchairRoutes': needsWheelchairRoutes,
      'studentId': studentId,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  // Create from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      disabilityType: map['disabilityType'] ?? 'other',
      needsVoiceNavigation: map['needsVoiceNavigation'] ?? false,
      needsWheelchairRoutes: map['needsWheelchairRoutes'] ?? false,
      studentId: map['studentId'] ?? '',
      role: map['role'] ?? 'student',
      createdAt: DateTime.parse(map['createdAt']),
      photoUrl: map['photoUrl'],
    );
  }
}