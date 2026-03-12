// lib/screens/toilets_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AccessibleToilet {
  final String id;
  final String name;
  final String building;
  final String floor;
  final String directions;
  final LatLng coordinates;
  final bool hasGrabRails;
  final bool hasAudioCue;
  final bool isGenderNeutral;

  AccessibleToilet({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.directions,
    required this.coordinates,
    required this.hasGrabRails,
    required this.hasAudioCue,
    required this.isGenderNeutral,
  });

  static List<AccessibleToilet> get mzuniToilets => [
    AccessibleToilet(
      id: 't1',
      name: 'Admin Block Accessible Toilet',
      building: 'Main Administration Block',
      floor: 'Ground Floor',
      directions: 'Enter the main admin block through the front ramp. Turn left at the reception desk. The accessible toilet is the third door on your right. It has a blue accessibility sign on the door.',
      coordinates: LatLng(-11.4648, 34.0194),
      hasGrabRails: true,
      hasAudioCue: false,
      isGenderNeutral: true,
    ),
    AccessibleToilet(
      id: 't2',
      name: 'Library Accessible Toilet',
      building: 'Mzuni Main Library',
      floor: 'Ground Floor',
      directions: 'Enter the library through the east entrance ramp. Walk straight past the front desk. The accessible toilet is at the end of the corridor on your left, before the study rooms.',
      coordinates: LatLng(-11.4655, 34.0201),
      hasGrabRails: true,
      hasAudioCue: true,
      isGenderNeutral: true,
    ),
    AccessibleToilet(
      id: 't3',
      name: 'Student Centre Accessible Toilet',
      building: 'Student Centre',
      floor: 'Ground Floor',
      directions: 'Enter the student centre through the main wide entrance. Walk past the noticeboard. The accessible toilet is on your right side, next to the cafeteria entrance. Look for the large blue door.',
      coordinates: LatLng(-11.4658, 34.0206),
      hasGrabRails: true,
      hasAudioCue: false,
      isGenderNeutral: true,
    ),
    AccessibleToilet(
      id: 't4',
      name: 'Faculty of Humanities Toilet',
      building: 'Faculty of Humanities',
      floor: 'Ground Floor',
      directions: 'Enter the Faculty of Humanities through the north ramp entrance. Turn right immediately after entering. The accessible toilet is the second door on your left down the short corridor.',
      coordinates: LatLng(-11.4660, 34.0189),
      hasGrabRails: true,
      hasAudioCue: false,
      isGenderNeutral: false,
    ),
    AccessibleToilet(
      id: 't5',
      name: 'Health Centre Toilet',
      building: 'University Health Centre',
      floor: 'Ground Floor',
      directions: 'Enter the health centre through the main door. Speak to the receptionist and they will guide you. The accessible toilet is directly behind the waiting area on the left wall.',
      coordinates: LatLng(-11.4650, 34.0174),
      hasGrabRails: true,
      hasAudioCue: false,
      isGenderNeutral: true,
    ),
    AccessibleToilet(
      id: 't6',
      name: "Chancellor's Hostel Toilet",
      building: "Chancellor's Hostel",
      floor: 'Ground Floor',
      directions: "Enter Chancellor's Hostel through the main entrance. The accessible toilet is immediately to your left after the entrance, before the staircase. It is clearly marked.",
      coordinates: LatLng(-11.4638, 34.0187),
      hasGrabRails: true,
      hasAudioCue: false,
      isGenderNeutral: false,
    ),
    AccessibleToilet(
      id: 't7',
      name: 'Female Hostel Accessible Toilet',
      building: 'Female Hostel',
      floor: 'Ground Floor',
      directions: 'Enter the female hostel through the ramp at the front entrance. Turn right and walk about ten steps. The accessible toilet is the first door on your right with a blue handle.',
      coordinates: LatLng(-11.4640, 34.0204),
      hasGrabRails: true,
      hasAudioCue: false,
      isGenderNeutral: false,
    ),
    AccessibleToilet(
      id: 't8',
      name: 'ICT Centre Toilet',
      building: 'ICT Centre',
      floor: 'Ground Floor',
      directions: 'Enter the ICT Centre through the ground floor entrance. Walk past the reception. The accessible toilet is at the back left corner of the ground floor, near the printer room.',
      coordinates: LatLng(-11.4648, 34.0207),
      hasGrabRails: false,
      hasAudioCue: false,
      isGenderNeutral: true,
    ),
  ];
}

class ToiletsScreen extends StatefulWidget {
  const ToiletsScreen({super.key});

  @override
  State<ToiletsScreen> createState() => _ToiletsScreenState();
}

class _ToiletsScreenState extends State<ToiletsScreen> {
  final FlutterTts _tts = FlutterTts();
  final MapController _mapController = MapController();
  static const LatLng _mzuniCenter = LatLng(-11.4653, 34.0199);

  final List<AccessibleToilet> _toilets = AccessibleToilet.mzuniToilets;
  AccessibleToilet? _selectedToilet;
  LatLng? _userLocation;
  bool _voiceEnabled = true;
  bool _showMap = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _getUserLocation();
    // Auto-announce on open
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_voiceEnabled) {
        _speak('Accessible Toilets screen. There are ${_toilets.length} accessible toilets on campus. Tap any toilet to hear detailed directions.');
      }
    });
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _userLocation = LatLng(position.latitude, position.longitude));
    } catch (_) {}
  }

  String _getDistanceText(AccessibleToilet toilet) {
    if (_userLocation == null) return '';
    double dist = Geolocator.distanceBetween(
      _userLocation!.latitude, _userLocation!.longitude,
      toilet.coordinates.latitude, toilet.coordinates.longitude,
    );
    if (dist < 1000) return '${dist.toStringAsFixed(0)}m away';
    return '${(dist / 1000).toStringAsFixed(1)}km away';
  }

  String _getDirection(AccessibleToilet toilet) {
    if (_userLocation == null) return '';
    double dLat = toilet.coordinates.latitude - _userLocation!.latitude;
    double dLng = toilet.coordinates.longitude - _userLocation!.longitude;
    if (dLat.abs() > dLng.abs()) return dLat > 0 ? 'north' : 'south';
    return dLng > 0 ? 'east' : 'west';
  }

  void _selectToilet(AccessibleToilet toilet) {
    setState(() => _selectedToilet = toilet);
    if (_voiceEnabled) {
      String distInfo = _userLocation != null
          ? 'It is ${_getDistanceText(toilet)} to your ${_getDirection(toilet)}. '
          : '';
      _speak('${toilet.name}. Located at ${toilet.building}, ${toilet.floor}. '
          '$distInfo'
          'Directions: ${toilet.directions}');
    }
    if (_showMap) _mapController.move(toilet.coordinates, 19);
  }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A6EBF),
        foregroundColor: Colors.white,
        title: const Text('Accessible Toilets', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
centerTitle: true,
        actions: [
          // Map/List toggle
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
            tooltip: _showMap ? 'Show list' : 'Show map',
          ),
          // Voice toggle
          IconButton(
            icon: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              if (_voiceEnabled) _speak('Voice on'); else _tts.stop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Speaking indicator
          if (_isSpeaking)
            Container(
              color: const Color(0xFF1A6EBF),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.graphic_eq, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Speaking directions...', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),

          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A6EBF).withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF1A6EBF).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.wc, color: Color(0xFF1A6EBF), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${8} accessible toilets found', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('Tap a toilet to hear voice directions', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                // Read all button
                GestureDetector(
                  onTap: () => _speak('There are 8 accessible toilets on campus. They are located at: Main Administration Block, Main Library, Student Centre, Faculty of Humanities, Health Centre, Chancellors Hostel, Female Hostel, and ICT Centre. Tap any toilet card for detailed step by step directions.'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF1A6EBF), borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [Icon(Icons.volume_up, color: Colors.white, size: 16), SizedBox(width: 4), Text('Read All', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
                  ),
                ),
              ],
            ),
          ),

          // Main content - Map or List
          Expanded(
            child: _showMap ? _buildMap() : _buildList(),
          ),

          // Selected toilet detail card
          if (_selectedToilet != null) _buildDetailCard(),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _toilets.length,
      itemBuilder: (_, i) {
        final AccessibleToilet t = _toilets[i];
        bool isSelected = _selectedToilet?.id == t.id;
        String distText = _getDistanceText(t);
        return GestureDetector(
          onTap: () => _selectToilet(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF1A6EBF) : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
              boxShadow: [BoxShadow(color: isSelected ? const Color(0xFF1A6EBF).withOpacity(0.15) : Colors.black.withOpacity(0.06), blurRadius: isSelected ? 12 : 6)],
            ),
            child: Row(
              children: [
                // Toilet icon
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1A6EBF) : const Color(0xFF1A6EBF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.wc, color: isSelected ? Colors.white : const Color(0xFF1A6EBF), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(t.building, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 6),
                      // Feature chips
                      Wrap(
                        spacing: 6,
                        children: [
                          if (distText.isNotEmpty) _chip(distText, Icons.near_me, const Color(0xFF1A6EBF)),
                          _chip(t.floor, Icons.layers, Colors.teal),
                          if (t.hasGrabRails) _chip('Grab Rails', Icons.accessible, const Color(0xFF2ECC71)),
                          if (t.isGenderNeutral) _chip('Gender Neutral', Icons.people, Colors.purple),
                          if (t.hasAudioCue) _chip('Audio Cue', Icons.volume_up, Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                // Voice button
                GestureDetector(
                  onTap: () => _selectToilet(t),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A6EBF) : const Color(0xFF1A6EBF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.volume_up, color: isSelected ? Colors.white : const Color(0xFF1A6EBF), size: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _mzuniCenter, initialZoom: 16),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.accessmap.mzuni',
        ),
        MarkerLayer(
          markers: _toilets.map<Marker>((AccessibleToilet t) {
            bool isSelected = _selectedToilet?.id == t.id;
            return Marker(
              point: t.coordinates,
              width: isSelected ? 52 : 42,
              height: isSelected ? 52 : 42,
              child: GestureDetector(
                onTap: () => _selectToilet(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1A6EBF) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A6EBF), width: 2),
                    boxShadow: [BoxShadow(color: const Color(0xFF1A6EBF).withOpacity(0.4), blurRadius: isSelected ? 12 : 4)],
                  ),
                  child: Icon(Icons.wc, color: isSelected ? Colors.white : const Color(0xFF1A6EBF), size: isSelected ? 28 : 22),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailCard() {
    final AccessibleToilet t = _selectedToilet!;
    String distInfo = _userLocation != null ? '${_getDistanceText(t)} to your ${_getDirection(t)}' : 'Location unavailable';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF1A6EBF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.wc, color: Color(0xFF1A6EBF))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text('$distInfo · ${t.floor}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () { setState(() => _selectedToilet = null); _tts.stop(); }),
          ]),
          const SizedBox(height: 12),
          // Directions box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF1A6EBF).withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1A6EBF).withOpacity(0.2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.directions_walk, color: Color(0xFF1A6EBF), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(t.directions, style: const TextStyle(fontSize: 13, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _speak('Directions to ${t.name}. ${t.directions}'),
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('Hear Directions'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6EBF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _speak('To reach ${t.name}, head ${_getDirection(t)} for ${_getDistanceText(t)}.'),
                icon: const Icon(Icons.near_me, size: 18),
                label: const Text('Distance'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A6EBF), side: const BorderSide(color: Color(0xFF1A6EBF)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}