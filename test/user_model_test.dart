import 'package:flutter_test/flutter_test.dart';
import 'package:accessmap_mzuni/models/user_model.dart';

void main() {
  test('UserModel fromMap and toMap round trip', () {
    final user = UserModel(
      uid: 'uid123',
      fullName: 'Test User',
      email: 'test@example.com',
      phone: '+265 999 000 000',
      disabilityType: 'blind',
      needsVoiceNavigation: true,
      needsWheelchairRoutes: false,
      studentId: 'STU2024001',
      role: 'student',
      createdAt: DateTime(2024, 1, 1),
    );
    final map = user.toMap();
    final restored = UserModel.fromMap(map);
    expect(restored.uid, user.uid);
    expect(restored.fullName, user.fullName);
    expect(restored.email, user.email);
    expect(restored.disabilityType, user.disabilityType);
    expect(restored.needsVoiceNavigation, user.needsVoiceNavigation);
  });
}
