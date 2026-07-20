// lib/screens/nearby_buildings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/campus_location.dart';

class NearbyBuildingsScreen extends StatefulWidget {
  const NearbyBuildingsScreen({super.key});

  @override
  State<NearbyBuildingsScreen> createState() => _NearbyBuildingsScreenState();
}

class _NearbyBuildingsScreenState extends State<NearbyBuildingsScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<CampusLocation> _buildings = CampusLocation.mzuniBuildings;
  List<Map<String, dynamic>> _sorted = [];
  LatLng? _userLocation;
  bool _voiceEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _loadNearby();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _tts.setErrorHandler((error) {});
  }

  Future<void> _loadNearby() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLatLng = LatLng(position.latitude, position.longitude);
      final items = <Map<String, dynamic>>[];
      for (final b in _buildings) {
        final distance = Geolocator.distanceBetween(
          userLatLng.latitude,
          userLatLng.longitude,
          b.coordinates.latitude,
          b.coordinates.longitude,
        );
        items.add({'building': b, 'distance': distance});
      }
      items.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
          _sorted = items;
          _isLoading = false;
        });
      }
      if (_voiceEnabled && mounted) {
        await _tts.speak('Found ${_sorted.length} buildings nearby. The nearest is ${_sorted.first['building'].name}.');
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _distanceText(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _direction(LatLng from, LatLng to) {
    final dLat = to.latitude - from.latitude;
    final dLng = to.longitude - from.longitude;
    if (dLat.abs() > dLng.abs()) return dLat > 0 ? 'north' : 'south';
    return dLng > 0 ? 'east' : 'west';
  }

  Future<void> _speakBuilding(CampusLocation b) async {
    if (_userLocation == null) return;
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      b.coordinates.latitude,
      b.coordinates.longitude,
    );
    final dir = _direction(_userLocation!, b.coordinates);
    await _tts.speak('${b.name}. ${b.description}. ${_distanceText(distance)} to your $dir. ${b.accessibilityInfo}');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF135C52),
        foregroundColor: Colors.white,
        title: const Text('Nearby Buildings', style: TextStyle(fontWeight: FontWeight.w700)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF135C52)))
          : _userLocation == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.location_off, size: 64, color: Color(0xFF135C52)),
                      const SizedBox(height: 16),
                      Text('Location unavailable', style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Enable location services to see nearby buildings.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                    ]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sorted.length,
                  itemBuilder: (_, i) {
                    final item = _sorted[i];
                    final b = item['building'] as CampusLocation;
                    final distance = item['distance'] as double;
                    final dir = _direction(_userLocation!, b.coordinates);
                    return GestureDetector(
                      onTap: () => _speakBuilding(b),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                        ),
                        child: Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF135C52).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.location_on, color: const Color(0xFF135C52), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${_distanceText(distance)} · $dir', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ])),
                          Icon(Icons.volume_up, color: const Color(0xFF135C52).withOpacity(0.7), size: 20),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
