// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'toilets_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../services/voice_assistant_service.dart';
import '../widgets/voice_assistant_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final VoiceAssistantService _assistant = VoiceAssistantService();
  String _firstName = 'Chisomo';
  String _role = 'STUDENT';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initAssistant();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getUserProfile('test_user_123');
    if (mounted && profile != null) {
      setState(() {
        _firstName = profile.fullName.split(' ').first;
        _role = profile.role.toUpperCase();
      });
    }
  }

  Future<void> _initAssistant() async {
    await _assistant.init();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _assistant.speak(
        'Welcome to AccessMap, $_firstName. Tap the microphone button and tell me what you need. Say help for a list of commands.');
  }

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Campus Map', 'color': Color(0xFF57CC99), 'ready': true},
    {'title': 'Toilets', 'color': Color.fromARGB(255, 64, 68, 88), 'ready': true},
    {'title': 'Report', 'color': Color(0xFFF4A261), 'ready': true},
    {'title': 'Nearby Buildings', 'color': Color(0xFFE76F6F), 'ready': false},
    {'title': 'Rooms', 'color': Color(0xFF74C0E8), 'ready': false},
  ];

  final List<Map<String, dynamic>> _features = [
    {'title': 'Campus Map', 'icon': Icons.map, 'color': Color(0xFFB8C9F5), 'ready': true},
    {'title': 'Accessible Toilets', 'icon': Icons.wc, 'color': Color(0xFF57CC99), 'ready': true},
    {'title': 'Report Problem', 'icon': Icons.report_problem, 'color': Color(0xFFF4A261), 'ready': true},
    {'title': 'Nearby Buildings', 'icon': Icons.location_city, 'color': Color(0xFFE76F6F), 'ready': false},
    {'title': 'Study Rooms', 'icon': Icons.menu_book, 'color': Color(0xFF74C0E8), 'ready': false},
    {'title': 'My Profile', 'icon': Icons.person, 'color': Color(0xFFD4A8F0), 'ready': true},
  ];

  void _openMap() => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
  void _openToilets() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToiletsScreen()));
  void _openReport() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
  void _openProfile() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));

  // ── Category pill tap handler ──
  void _onCategoryTap(Map<String, dynamic> c) {
    if (!(c['ready'] as bool)) {
      _assistant.speak('${c['title']} is coming soon.');
      return;
    }
    if (c['title'] == 'Campus Map') _openMap();
    if (c['title'] == 'Toilets') _openToilets();
    if (c['title'] == 'Report') _openReport();
  }

  // ── Feature card tap handler ──
  void _onFeatureTap(Map<String, dynamic> f) {
    if (!(f['ready'] as bool)) {
      _assistant.speak('${f['title']} is coming soon.');
      return;
    }
    if (f['title'] == 'Campus Map') _openMap();
    if (f['title'] == 'Accessible Toilets') _openToilets();
    if (f['title'] == 'Report Problem') _openReport();
    if (f['title'] == 'My Profile') _openProfile();
  }

  @override
  void dispose() {
    _assistant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Curved teal header ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A7A6E), Color(0xFF2AA99A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false),
                        child: const Icon(Icons.logout, color: Colors.white, size: 22),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10)]),
                        child: const Icon(Icons.person, color: Color(0xFF1A7A6E), size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_firstName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                          Row(children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 13),
                            const SizedBox(width: 3),
                            Text('Mzuzu University',
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                          ]),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                        child: Text(_role,
                            style: const TextStyle(
                                color: Color(0xFF1A7A6E), fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    Row(children: [
                      _stat('2', 'Features Open'),
                      _vDivider(),
                      _stat('15', 'Buildings'),
                      _vDivider(),
                      _stat('8', 'Toilets'),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ── Category pills ──
          const Padding(
            padding: EdgeInsets.only(left: 22),
            child: Text('Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A3C38))),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final c = _categories[i];
                bool ready = c['ready'] as bool;
                return GestureDetector(
                  onTap: () => _onCategoryTap(c), // ← NOW CLICKABLE
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ready
                          ? (c['color'] as Color)
                          : (c['color'] as Color).withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: ready
                          ? [BoxShadow(
                              color: (c['color'] as Color).withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Text(c['title'] as String,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        if (!ready) ...[
                          const SizedBox(width: 4),
                          Text('(soon)',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Features label ──
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text('Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A3C38))),
          ),
          const SizedBox(height: 10),

          // ── Feature cards grid ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: _features.length,
                itemBuilder: (_, i) {
                  final f = _features[i];
                  bool ready = f['ready'] as bool;
                  Color color = f['color'] as Color;
                  return GestureDetector(
                    onTap: () => _onFeatureTap(f),
                    child: Container(
                      decoration: BoxDecoration(
                        color: ready ? color : color.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: ready
                            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))]
                            : [],
                      ),
                      child: Stack(children: [
                        Positioned(
                            top: -16,
                            right: -16,
                            child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12), shape: BoxShape.circle))),
                        Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(f['icon'] as IconData, color: Colors.white, size: 28),
                            const SizedBox(height: 8),
                            Text(f['title'] as String,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    height: 1.2),
                                textAlign: TextAlign.center),
                            if (!ready)
                              Text('Coming Soon',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // ── Floating voice assistant button ──
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF135C52),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1A7A6E).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))
          ],
        ),
        child: VoiceAssistantWidget(
          assistant: _assistant,
          onOpenMap: _openMap,
          onOpenToilets: _openToilets,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
        child: Column(children: [
      Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 1),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
    ]));
  }

  Widget _vDivider() =>
      Container(width: 1, height: 26, color: Colors.white.withOpacity(0.3));
}