// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _needsVoice = true;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _user = null;
          _needsVoice = true;
          _isLoading = false;
        });
      }
      return;
    }

    final profile = await _authService.getUserProfile(uid);
    if (mounted) {
      setState(() {
        _user = profile;
        _needsVoice = profile?.needsVoiceNavigation ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final uid = _authService.currentUserId;
    if (uid != null) {
      await _authService.updateProfile(uid, {
        'needsVoiceNavigation': _needsVoice,
      });
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Preferences saved!'),
      backgroundColor: const Color(0xFF135C52),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF135C52)))
          : CustomScrollView(
              slivers: [
                // Curved teal header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A7A6E), Color(0xFF135C52)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Column(
                          children: [
                            // Top bar
                            Row(children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back, color: Colors.white),
                              ),
                              const Spacer(),
                              const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              GestureDetector(
                                onTap: _logout,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                  child: const Row(children: [
                                    Icon(Icons.logout, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Logout', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 24),

                            // Avatar
                            Container(
                              width: 88, height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
                              ),
                              child: Center(
                                child: Text(
                                  _user?.fullName.isNotEmpty == true ? _user!.fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF135C52)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(_user?.fullName ?? 'Student', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(_user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text((_user?.disabilityType ?? 'blind').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Info section
                        _sectionTitle('Personal Information'),
                        const SizedBox(height: 10),
                        _infoCard(Icons.badge_outlined, 'Student ID', _user?.studentId ?? 'STU2024001'),
                        _infoCard(Icons.phone_outlined, 'Phone', _user?.phone ?? '+265 999 000 000'),
                        _infoCard(Icons.person_outline, 'Role', (_user?.role ?? 'student').toUpperCase()),
                        _infoCard(Icons.accessibility_new, 'Disability Type', (_user?.disabilityType ?? 'blind').toUpperCase()),

                        const SizedBox(height: 20),

                        // Accessibility preferences
                        _sectionTitle('Accessibility Preferences'),
                        const SizedBox(height: 10),
                        _toggleCard(
                          Icons.volume_up_outlined,
                          'Voice Navigation',
                          'App speaks directions and info aloud',
                          _needsVoice,
                          (v) => setState(() => _needsVoice = v),
                        ),
                        const SizedBox(height: 10),

                        const SizedBox(height: 24),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _savePreferences,
                            icon: _isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save_outlined, size: 20),
                            label: Text(_isSaving ? 'Saving...' : 'Save Preferences', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF135C52),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF135C52),
                              side: const BorderSide(color: Color(0xFF135C52)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A3C38)));
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF135C52).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF135C52), size: 20)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ]),
    );
  }

  Widget _toggleCard(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF135C52).withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF135C52), size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF135C52)),
      ]),
    );
  }
}