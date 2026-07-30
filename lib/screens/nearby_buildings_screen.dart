// lib/screens/nearby_buildings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/campus_location.dart';
import '../services/firestore_service.dart';
import '../services/routing_service.dart';
import '../services/navigation_controller.dart';
import '../widgets/navigation_banner.dart';

class NearbyBuildingsScreen extends StatefulWidget {
  const NearbyBuildingsScreen({super.key});

  @override
  State<NearbyBuildingsScreen> createState() => _NearbyBuildingsScreenState();
}

class _NearbyBuildingsScreenState extends State<NearbyBuildingsScreen> {
  final FlutterTts _tts = FlutterTts();
  final FirestoreService _firestoreService = FirestoreService();
  List<CampusLocation> _buildings = CampusLocation.mzuniBuildings;
  List<Map<String, dynamic>> _sorted = [];
  LatLng? _userLocation;
  bool _voiceEnabled = true;
  bool _isLoading = true;

  final NavigationController _navController = NavigationController();
  bool _isNavigating = false;
  CampusLocation? _navDestination;
  RouteStep? _navStep;
  double? _navDistanceToStep;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _loadBuildingsThenNearby();
    _setupNavigation();
  }

  Future<void> _loadBuildingsThenNearby() async {
    try {
      final fetched = await _firestoreService.getLocations();
      if (fetched.isNotEmpty && mounted) {
        setState(() => _buildings = fetched);
      }
    } catch (_) {
      // Keep the hardcoded fallback list.
    }
    await _loadNearby();
  }

  String _formatSpokenDistance(double meters) {
    if (meters < 15) return 'now';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} metres';
    return '${(meters / 1000).toStringAsFixed(1)} kilometres';
  }

  void _setupNavigation() {
    _navController.onPosition = (pos) {
      if (mounted) setState(() => _userLocation = pos);
    };
    _navController.onStepChanged = (step, distance) {
      if (!mounted) return;
      setState(() {
        _navStep = step;
        _navDistanceToStep = distance;
      });
      _tts.speak('${step.instruction}. ${_formatSpokenDistance(distance)}.');
    };
    _navController.onProgress = (distance) {
      if (!mounted) return;
      setState(() => _navDistanceToStep = distance);
    };
    _navController.onPeriodicReminder = (step, distanceToStep, distanceRemaining) {
      if (!mounted) return;
      _tts.speak(
          'Still heading to ${_navDestination?.name ?? 'your destination'}. ${step.instruction}, ${_formatSpokenDistance(distanceToStep)} away. ${_formatSpokenDistance(distanceRemaining)} left overall.');
    };
    _navController.onArrived = () async {
      final name = _navDestination?.name ?? 'your destination';
      await _tts.speak('You have arrived at $name.');
      if (!mounted) return;
      setState(() {
        _isNavigating = false;
        _navDestination = null;
        _navStep = null;
        _navDistanceToStep = null;
      });
    };
    _navController.onOffRoute = () async {
      await _tts.speak('You have gone off route. Recalculating.');
      if (_userLocation != null) await _navController.reroute(_userLocation!);
    };
    _navController.onError = (message) async {
      await _tts.speak(message);
      if (!mounted) return;
      setState(() => _isNavigating = false);
    };
  }

  Future<void> _startNavigation(CampusLocation building) async {
    if (_userLocation == null) {
      await _tts.speak('Your location is not available yet. Please enable location access.');
      return;
    }
    await _tts.speak('Starting navigation to ${building.name}.');
    setState(() => _navDestination = building);
    final started = await _navController.start(_userLocation!, building.coordinates);
    if (!mounted) return;
    setState(() => _isNavigating = started);
    if (!started) setState(() => _navDestination = null);
  }

  void _stopNavigation() {
    _navController.stop();
    setState(() {
      _isNavigating = false;
      _navDestination = null;
      _navStep = null;
      _navDistanceToStep = null;
    });
    _tts.speak('Navigation stopped.');
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
    final accessibility = b.isAccessible ? 'Accessible.' : 'Limited accessibility.';
    await _tts.speak('${b.name}. ${b.description}. ${_distanceText(distance)} to your $dir. $accessibility ${b.accessibilityInfo}');
  }

  @override
  void dispose() {
    _tts.stop();
    _navController.dispose();
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
              if (_voiceEnabled) {
                _tts.speak('Voice on');
              } else {
                _tts.stop();
              }
            },
          )
        ],
      ),
      body: Column(children: [
        if (_isNavigating && _navStep != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: NavigationBanner(
              destinationName: _navDestination?.name ?? 'destination',
              instruction: _navStep!.instruction,
              distanceMeters: _navDistanceToStep,
              onStop: _stopNavigation,
            ),
          ),
        Expanded(
          child: _isLoading
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
                                child: const Icon(Icons.location_on, color: Color(0xFF135C52), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Flexible(child: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                                  if (b.isAccessible) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.accessible, color: Color(0xFF2ECC71), size: 16),
                                  ],
                                ]),
                                Text('${_distanceText(distance)} · $dir', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ])),
                              GestureDetector(
                                onTap: () => _speakBuilding(b),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.volume_up, color: const Color(0xFF135C52).withOpacity(0.7), size: 20),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _startNavigation(b),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFF1A6EBF).withOpacity(0.1), shape: BoxShape.circle),
                                  child: const Icon(Icons.navigation, color: Color(0xFF1A6EBF), size: 20),
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
