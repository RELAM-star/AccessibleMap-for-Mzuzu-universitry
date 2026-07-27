// lib/screens/study_rooms_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class StudyRoom {
  final String id;
  final String name;
  final String building;
  final String floor;
  final int capacity;
  final bool hasProjector;
  final bool hasWhiteboard;
  final bool hasPowerOutlets;
  final bool isQuietZone;
  final String availability;

  StudyRoom({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.hasProjector,
    required this.hasWhiteboard,
    required this.hasPowerOutlets,
    required this.isQuietZone,
    required this.availability,
  });

  static List<StudyRoom> get mzuniStudyRooms => [
    StudyRoom(
      id: 'sr1',
      name: 'Library Silent Study Room A',
      building: 'Mzuni Main Library',
      floor: 'Ground Floor',
      capacity: 12,
      hasProjector: false,
      hasWhiteboard: true,
      hasPowerOutlets: true,
      isQuietZone: true,
      availability: 'Open',
    ),
    StudyRoom(
      id: 'sr2',
      name: 'Library Group Study Room B',
      building: 'Mzuni Main Library',
      floor: 'First Floor',
      capacity: 8,
      hasProjector: true,
      hasWhiteboard: true,
      hasPowerOutlets: true,
      isQuietZone: false,
      availability: 'Open',
    ),
    StudyRoom(
      id: 'sr3',
      name: 'Science Discussion Room',
      building: 'Faculty of Science & Engineering',
      floor: 'Ground Floor',
      capacity: 16,
      hasProjector: true,
      hasWhiteboard: true,
      hasPowerOutlets: true,
      isQuietZone: false,
      availability: 'Open',
    ),
    StudyRoom(
      id: 'sr4',
      name: 'Business Presentation Room',
      building: 'Faculty of Business',
      floor: 'First Floor',
      capacity: 20,
      hasProjector: true,
      hasWhiteboard: false,
      hasPowerOutlets: true,
      isQuietZone: true,
      availability: 'Open',
    ),
    StudyRoom(
      id: 'sr5',
      name: 'Humanities Reading Room',
      building: 'Faculty of Humanities',
      floor: 'Ground Floor',
      capacity: 10,
      hasProjector: false,
      hasWhiteboard: true,
      hasPowerOutlets: true,
      isQuietZone: true,
      availability: 'Open',
    ),
    StudyRoom(
      id: 'sr6',
      name: 'ICT Computer Lab 1',
      building: 'ICT Centre',
      floor: 'Ground Floor',
      capacity: 30,
      hasProjector: true,
      hasWhiteboard: true,
      hasPowerOutlets: true,
      isQuietZone: false,
      availability: 'Open',
    ),
    StudyRoom(
      id: 'sr7',
      name: 'Student Centre Study Corner',
      building: 'Student Centre',
      floor: 'Ground Floor',
      capacity: 6,
      hasProjector: false,
      hasWhiteboard: false,
      hasPowerOutlets: true,
      isQuietZone: true,
      availability: 'Open',
    ),
  ];
}

class StudyRoomsScreen extends StatefulWidget {
  const StudyRoomsScreen({super.key});

  @override
  State<StudyRoomsScreen> createState() => _StudyRoomsScreenState();
}

class _StudyRoomsScreenState extends State<StudyRoomsScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<StudyRoom> _rooms = StudyRoom.mzuniStudyRooms;
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _tts.setErrorHandler((error) {});
  }

  Future<void> _speakRoom(StudyRoom room) async {
    final features = <String>[];
    if (room.hasProjector) features.add('projector');
    if (room.hasWhiteboard) features.add('whiteboard');
    if (room.hasPowerOutlets) features.add('power outlets');
    if (room.isQuietZone) features.add('quiet zone');
    final featureText = features.isNotEmpty ? 'Features include: ${features.join(", ")}.' : '';
    await _tts.speak('${room.name}. Located at ${room.building}, ${room.floor}. Capacity ${room.capacity}. $featureText Status: ${room.availability}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF135C52),
        foregroundColor: Colors.white,
        title: const Text('Study Rooms', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (_voiceEnabled) _tts.speak('Voice on'); else _tts.stop();
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (_, i) {
          final room = _rooms[i];
          return GestureDetector(
            onTap: () => _speakRoom(room),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: const Color(0xFF74C0E8).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.menu_book, color: Color(0xFF74C0E8), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(room.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('${room.building} · ${room.floor}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF2ECC71).withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3))),
                      child: Text(room.availability, style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('${room.capacity} seats', Icons.people, const Color(0xFF1A6EBF)),
                      if (room.hasProjector) _chip('Projector', Icons.slideshow, Colors.purple),
                      if (room.hasWhiteboard) _chip('Whiteboard', Icons.edit, Colors.teal),
                      if (room.hasPowerOutlets) _chip('Power', Icons.power, Colors.orange),
                      if (room.isQuietZone) _chip('Quiet', Icons.volume_down, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
