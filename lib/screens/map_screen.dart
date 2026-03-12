// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';

enum LocationType { academic, admin, library, hostel, facility, transport }

class CampusLocation {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final LocationType type;
  final String accessibilityInfo;

  CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.type,
    required this.accessibilityInfo,
  });

  static List<CampusLocation> get mzuniBuildings => [
    CampusLocation(id: 'main_admin', name: 'Main Administration Block', description: 'Central admin offices, Registry, and Student Affairs', coordinates: LatLng(-11.4648, 34.0195), type: LocationType.admin, accessibilityInfo: 'Ramp access at main entrance. Wide corridors.'),
    CampusLocation(id: 'library', name: 'Mzuni Main Library', description: 'University library with study rooms and computer lab', coordinates: LatLng(-11.4655, 34.0202), type: LocationType.library, accessibilityInfo: 'Step-free entrance on east side. Braille materials available.'),
    CampusLocation(id: 'foh', name: 'Faculty of Humanities', description: 'Arts, Social Sciences and Languages', coordinates: LatLng(-11.4660, 34.0190), type: LocationType.academic, accessibilityInfo: 'Ground floor fully accessible. Ramp at north entrance.'),
    CampusLocation(id: 'fose', name: 'Faculty of Science & Engineering', description: 'Science labs, engineering workshops and lecture rooms', coordinates: LatLng(-11.4645, 34.0210), type: LocationType.academic, accessibilityInfo: 'Accessible entrance on south side. Ground floor wheelchair friendly.'),
    CampusLocation(id: 'fob', name: 'Faculty of Business', description: 'Business, Economics and Management lecture halls', coordinates: LatLng(-11.4652, 34.0185), type: LocationType.academic, accessibilityInfo: 'Step-free access at main door. Wide corridors throughout.'),
    CampusLocation(id: 'foe', name: 'Faculty of Education', description: 'Education department offices and lecture rooms', coordinates: LatLng(-11.4665, 34.0198), type: LocationType.academic, accessibilityInfo: 'Ramp at main entrance. All classrooms on ground floor accessible.'),
    CampusLocation(id: 'student_centre', name: 'Student Centre', description: 'Student union, cafeteria, and recreation facilities', coordinates: LatLng(-11.4658, 34.0207), type: LocationType.facility, accessibilityInfo: 'Fully accessible. Accessible toilet inside. Wide entrance doors.'),
    CampusLocation(id: 'chapel', name: 'University Chapel', description: 'Multi-faith worship space for students and staff', coordinates: LatLng(-11.4642, 34.0200), type: LocationType.facility, accessibilityInfo: 'Level access at all entrances. Reserved seating for wheelchair users.'),
    CampusLocation(id: 'sports', name: 'Sports Complex', description: 'Football field, basketball courts and gym', coordinates: LatLng(-11.4670, 34.0215), type: LocationType.facility, accessibilityInfo: 'Paved pathway from main road. Viewing area for wheelchair users.'),
    CampusLocation(id: 'chancellor_hostel', name: "Chancellor's Hostel", description: 'Male student residence block', coordinates: LatLng(-11.4638, 34.0188), type: LocationType.hostel, accessibilityInfo: 'Ground floor rooms for disabled students. Accessible bathroom available.'),
    CampusLocation(id: 'female_hostel', name: 'Female Hostel', description: 'Female student residence block', coordinates: LatLng(-11.4640, 34.0205), type: LocationType.hostel, accessibilityInfo: 'Ramp at entrance. Accessible rooms available on request.'),
    CampusLocation(id: 'health_centre', name: 'University Health Centre', description: 'Campus clinic for students and staff', coordinates: LatLng(-11.4650, 34.0175), type: LocationType.facility, accessibilityInfo: 'Fully accessible. Priority service for disabled students.'),
    CampusLocation(id: 'bus_stop', name: 'Main Campus Bus Stop', description: 'Minibus transport to Mzuzu city centre', coordinates: LatLng(-11.4635, 34.0195), type: LocationType.transport, accessibilityInfo: 'Covered waiting area. Low-floor minibuses on some routes.'),
    CampusLocation(id: 'cafeteria', name: 'Main Cafeteria', description: 'University dining hall serving all meals', coordinates: LatLng(-11.4656, 34.0193), type: LocationType.facility, accessibilityInfo: 'Step-free entrance. Wide aisles. Staff available to assist.'),
    CampusLocation(id: 'ict_centre', name: 'ICT Centre', description: 'Computer labs and internet access for students', coordinates: LatLng(-11.4648, 34.0208), type: LocationType.academic, accessibilityInfo: 'Ground floor accessible. Screen reader software available.'),
  ];
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FlutterTts _tts = FlutterTts();
  static const LatLng _mzuniCenter = LatLng(-11.4653, 34.0199);
  CampusLocation? _selectedLocation;
  bool _voiceEnabled = true;
  LatLng? _userLocation;
  final List<CampusLocation> _buildings = CampusLocation.mzuniBuildings;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _getUserLocation();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
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

  Future<void> _onLocationTapped(CampusLocation location) async {
    setState(() => _selectedLocation = location);
    _mapController.move(location.coordinates, 18);
    if (_voiceEnabled) await _speakLocation(location);
  }

  Future<void> _speakLocation(CampusLocation location) async {
    await _tts.stop();
    String speech = '${location.name}. ${location.description}. ${location.accessibilityInfo}';
    if (_userLocation != null) {
      double distance = Geolocator.distanceBetween(_userLocation!.latitude, _userLocation!.longitude, location.coordinates.latitude, location.coordinates.longitude);
      String dir = _getDirection(_userLocation!, location.coordinates);
      String distText = distance < 1000 ? '${distance.toStringAsFixed(0)} metres' : '${(distance / 1000).toStringAsFixed(1)} kilometres';
      speech += ' This place is $distText to your $dir.';
    }
    await _tts.speak(speech);
  }

  Future<void> _speakDirections(CampusLocation loc) async {
    await _tts.stop();
    if (_userLocation == null) {
      await _tts.speak('Your location is not available. Please enable location access.');
      return;
    }
    double distance = Geolocator.distanceBetween(_userLocation!.latitude, _userLocation!.longitude, loc.coordinates.latitude, loc.coordinates.longitude);
    String dir = _getDirection(_userLocation!, loc.coordinates);
    String distText = distance < 1000 ? '${distance.toStringAsFixed(0)} metres' : '${(distance / 1000).toStringAsFixed(1)} kilometres';
    await _tts.speak('To reach ${loc.name}, head $dir for $distText. ${loc.accessibilityInfo}');
  }

  String _getDirection(LatLng from, LatLng to) {
    double dLat = to.latitude - from.latitude;
    double dLng = to.longitude - from.longitude;
    if (dLat.abs() > dLng.abs()) return dLat > 0 ? 'north' : 'south';
    return dLng > 0 ? 'east' : 'west';
  }

  Color _getTypeColor(LocationType type) {
    if (type == LocationType.academic) return const Color(0xFF1A6EBF);
    if (type == LocationType.admin) return const Color(0xFFE74C3C);
    if (type == LocationType.library) return const Color(0xFF8E44AD);
    if (type == LocationType.hostel) return const Color(0xFFE67E22);
    if (type == LocationType.facility) return const Color(0xFF2ECC71);
    return const Color(0xFFF39C12);
  }

  IconData _getTypeIcon(LocationType type) {
    if (type == LocationType.academic) return Icons.school;
    if (type == LocationType.admin) return Icons.business;
    if (type == LocationType.library) return Icons.local_library;
    if (type == LocationType.hostel) return Icons.hotel;
    if (type == LocationType.facility) return Icons.sports;
    return Icons.directions_bus;
  }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mzuniCenter,
              initialZoom: 16,
              onTap: (_, __) { setState(() => _selectedLocation = null); _tts.stop(); },
            ),
            children: [
              // FREE OpenStreetMap - no API key needed!
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.accessmap.mzuni',
              ),
              if (_userLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _userLocation!,
                    width: 20, height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)],
                      ),
                    ),
                  ),
                ]),
              MarkerLayer(
                markers: _buildings.map<Marker>((CampusLocation loc) {
                  bool isSelected = _selectedLocation?.id == loc.id;
                  return Marker(
                    point: loc.coordinates,
                    width: isSelected ? 52 : 42,
                    height: isSelected ? 52 : 42,
                    child: GestureDetector(
                      onTap: () => _onLocationTapped(loc),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: _getTypeColor(loc.type),
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: isSelected ? 3 : 0),
                          boxShadow: [BoxShadow(color: _getTypeColor(loc.type).withOpacity(0.5), blurRadius: isSelected ? 12 : 6)],
                        ),
                        child: Icon(_getTypeIcon(loc.type), color: Colors.white, size: isSelected ? 26 : 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, child: _buildTopBar()),
          Positioned(bottom: _selectedLocation != null ? 230 : 110, right: 16, child: _buildControls()),
          Positioned(bottom: _selectedLocation != null ? 230 : 110, left: 16, child: _buildLegend()),
          if (_selectedLocation != null) Positioned(bottom: 0, left: 0, right: 0, child: _buildLocationCard()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]), child: const Icon(Icons.arrow_back, color: Color(0xFF1A6EBF))),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GestureDetector(
          onTap: _showBuildingsList,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]),
            child: const Row(children: [Icon(Icons.search, color: Color(0xFF1A6EBF), size: 20), SizedBox(width: 8), Text('Search buildings...', style: TextStyle(color: Colors.grey, fontSize: 14))]),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: () async { setState(() => _voiceEnabled = !_voiceEnabled); if (_voiceEnabled) await _tts.speak('Voice navigation on'); else await _tts.stop(); },
        child: Container(width: 44, height: 44, decoration: BoxDecoration(color: _voiceEnabled ? const Color(0xFF1A6EBF) : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]), child: Icon(_voiceEnabled ? Icons.volume_up : Icons.volume_off, color: _voiceEnabled ? Colors.white : Colors.grey, size: 20)),
      ),
    ]);
  }

  Widget _buildControls() {
    return Column(children: [
      _btn(Icons.school, () => _mapController.move(_mzuniCenter, 16)),
      const SizedBox(height: 8),
      _btn(Icons.my_location, () { if (_userLocation != null) _mapController.move(_userLocation!, 18); else _getUserLocation(); }),
      const SizedBox(height: 8),
      _btn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
      const SizedBox(height: 8),
      _btn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
    ]);
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]), child: Icon(icon, color: const Color(0xFF1A6EBF), size: 20)));
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _legendRow(const Color(0xFF1A6EBF), 'Academic'),
        _legendRow(const Color(0xFFE74C3C), 'Admin'),
        _legendRow(const Color(0xFF8E44AD), 'Library'),
        _legendRow(const Color(0xFFE67E22), 'Hostel'),
        _legendRow(const Color(0xFF2ECC71), 'Facility'),
        _legendRow(const Color(0xFFF39C12), 'Transport'),
      ]),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))]));
  }

  Widget _buildLocationCard() {
    final CampusLocation loc = _selectedLocation!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4))]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: _getTypeColor(loc.type).withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(_getTypeIcon(loc.type), color: _getTypeColor(loc.type))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(loc.type.name.toUpperCase(), style: TextStyle(fontSize: 11, color: _getTypeColor(loc.type), fontWeight: FontWeight.w600)),
          ])),
          IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () { setState(() => _selectedLocation = null); _tts.stop(); }),
        ]),
        const SizedBox(height: 10),
        Text(loc.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF2ECC71).withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3))),
          child: Row(children: [const Icon(Icons.accessible, color: Color(0xFF2ECC71), size: 18), const SizedBox(width: 8), Expanded(child: Text(loc.accessibilityInfo, style: const TextStyle(fontSize: 12)))]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: () => _speakLocation(loc), icon: const Icon(Icons.volume_up, size: 18), label: const Text('Read Aloud'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6EBF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: () => _speakDirections(loc), icon: const Icon(Icons.directions_walk, size: 18), label: const Text('Directions'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A6EBF), side: const BorderSide(color: Color(0xFF1A6EBF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ]),
      ]),
    );
  }

  void _showBuildingsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.6, maxChildSize: 0.9,
        builder: (_, sc) => Column(children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Mzuni Buildings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          const SizedBox(height: 10),
          Expanded(child: ListView.builder(
            controller: sc, itemCount: _buildings.length,
            itemBuilder: (_, i) {
              final CampusLocation loc = _buildings[i];
              return ListTile(
                leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: _getTypeColor(loc.type).withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(_getTypeIcon(loc.type), color: _getTypeColor(loc.type), size: 22)),
                title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(loc.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () { Navigator.pop(context); _onLocationTapped(loc); },
              );
            },
          )),
        ]),
      ),
    );
  }
}