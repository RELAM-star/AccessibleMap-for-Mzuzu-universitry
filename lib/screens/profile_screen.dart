import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? userProfile;
  const ProfileScreen({super.key, this.userProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late bool _needsVoice;
  late bool _needsWheelchair;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _needsVoice = widget.userProfile?.needsVoiceNavigation ?? false;
    _needsWheelchair = widget.userProfile?.needsWheelchairRoutes ?? false;
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    String? uid = _authService.currentUserId;
    if (uid != null) {
      await _authService.updateProfile(uid, {
        'needsVoiceNavigation': _needsVoice,
        'needsWheelchairRoutes': _needsWheelchair,
      });
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved!'),
        backgroundColor: Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    UserModel? u = widget.userProfile;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A6EBF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        u?.fullName.isNotEmpty == true
                            ? u!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    u?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(u?.email ?? '',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _infoRow(Icons.badge_outlined, 'Mzuni ID', u?.studentId ?? '-'),
            _infoRow(Icons.phone_outlined, 'Phone', u?.phone ?? '-'),
            _infoRow(Icons.person_outline, 'Role',
                (u?.role ?? 'student').toUpperCase()),
            const SizedBox(height: 20),
            _toggle(
              Icons.volume_up_outlined,
              'Voice Navigation',
              _needsVoice,
              (v) => setState(() => _needsVoice = v),
            ),
            const SizedBox(height: 10),
            _toggle(
              Icons.accessible_outlined,
              'Wheelchair Routes',
              _needsWheelchair,
              (v) => setState(() => _needsWheelchair = v),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A6EBF)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggle(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A6EBF)),
          const SizedBox(width: 14),
          Expanded(child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w500))),
          Switch(value: value, onChanged: onChanged,
              activeColor: const Color(0xFF1A6EBF)),
        ],
      ),
    );
  }
}