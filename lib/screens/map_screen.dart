// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import '../services/report_service.dart';
import '../services/routing_service.dart';
import '../services/firestore_service.dart';
import '../services/navigation_controller.dart';
import '../services/voice_assistant_service.dart';
import '../services/destination_resolver.dart';
import '../services/obstacle_detection_service.dart';
import '../models/campus_location.dart';
import '../widgets/navigation_banner.dart';
import '../widgets/voice_assistant_widget.dart';

class MapScreen extends StatefulWidget {
  final CampusLocation? initialDestination;

  const MapScreen({super.key, this.initialDestination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final FlutterTts _tts = FlutterTts();
  final ReportService _reportService = ReportService();
  final TextEditingController _searchController = TextEditingController();
  final List<CampusLocation> _localBuildings = CampusLocation.mzuniBuildings;
  static const LatLng _mzuniCenter = LatLng(-11.4653, 34.0199);
  // Keeps the map from being panned or zoomed out past the Mzuzu University
  // campus and its immediate surroundings, rather than the whole world.
  static final LatLngBounds _mzuniBounds = LatLngBounds(
    const LatLng(-11.475, 34.012),
    const LatLng(-11.458, 34.028),
  );
  CampusLocation? _selectedLocation;
  bool _voiceEnabled = true;
  LatLng? _userLocation;
  List<ReportModel> _locationReports = [];
  List<CampusLocation> _buildings = [];
  List<CampusLocation> _filtered = [];

  final NavigationController _navController = NavigationController();
  final VoiceAssistantService _voiceAssistant = VoiceAssistantService();
  final ObstacleDetectionService _obstacleService = ObstacleDetectionService();
  bool _isNavigating = false;
  bool _autoStartHandled = false;
  bool _obstacleAlertsEnabled = false;
  // Whether obstacle alerts were auto-started by navigation (as opposed to
  // the manual toggle), so ending navigation only turns them off if it
  // was the one that turned them on.
  bool _obstacleAlertsStartedByNavigation = false;
  CampusLocation? _navDestination;
  RouteStep? _navStep;
  double? _navDistanceToStep;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupTts();
    _getUserLocation();
    _loadLocations();
    _searchController.addListener(_onSearchChanged);
    _setupNavigation();
    _setupObstacleDetection();
    _voiceAssistant.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_obstacleService.isRunning) _obstacleService.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_obstacleAlertsEnabled && !_obstacleService.isRunning) _obstacleService.start();
    }
  }

  void _setupObstacleDetection() {
    _obstacleService.onObstacle = (alert) async {
      if (!mounted) return;
      final dirText = alert.direction == ObstacleDirection.left
          ? 'to your left'
          : alert.direction == ObstacleDirection.right
              ? 'to your right'
              : 'ahead';
      final urgent = alert.urgency == ObstacleUrgency.veryClose;
      _vibrate(urgent ? 400 : 150);
      await _tts.speak(urgent ? 'Stop! Obstacle very close $dirText.' : 'Caution, obstacle $dirText.');
    };
    _obstacleService.onError = (message) {
      if (!mounted) return;
      setState(() => _obstacleAlertsEnabled = false);
      _tts.speak(message);
    };
  }

  Future<void> _vibrate(int durationMs) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) Vibration.vibrate(duration: durationMs);
    } catch (_) {}
  }

  Future<void> _toggleObstacleAlerts() async {
    if (_obstacleAlertsEnabled) {
      _obstacleAlertsStartedByNavigation = false;
      await _obstacleService.stop();
      if (!mounted) return;
      setState(() => _obstacleAlertsEnabled = false);
      await _tts.speak('Obstacle alerts turned off.');
      return;
    }
    await _tts.speak(
        'Turning on obstacle alerts. Hold your phone with the camera facing forward as you walk. This is a supplementary aid, not a replacement for your cane.');
    final started = await _obstacleService.start();
    if (!mounted) return;
    setState(() => _obstacleAlertsEnabled = started);
    if (!started) {
      await _tts.speak('Could not start obstacle alerts on this device.');
    }
  }

  void _maybeAutoStartInitialDestination() {
    if (_autoStartHandled) return;
    final destination = widget.initialDestination;
    if (destination == null || _userLocation == null) return;
    _autoStartHandled = true;
    setState(() => _selectedLocation = destination);
    _mapController.move(destination.coordinates, 16);
    _startNavigation(destination);
  }

  Future<void> _handleVoiceDestination(String query) async {
    await _voiceAssistant.speak('Looking for $query.');
    final resolved = await DestinationResolver.resolve(query);
    if (!mounted) return;
    if (resolved == null) {
      await _voiceAssistant.speak('Sorry, I could not find $query. Please try a different name.');
      return;
    }
    setState(() => _selectedLocation = resolved.location);
    _mapController.move(resolved.location.coordinates, 16);
    await _voiceAssistant.speak(resolved.wasGeocoded
        ? 'Found ${resolved.location.name}. Starting navigation.'
        : 'Navigating to ${resolved.location.name}.');
    if (!mounted) return;
    await _startNavigation(resolved.location);
  }

  String _formatDistance(double meters) {
    if (meters < 15) return 'now';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} metres';
    return '${(meters / 1000).toStringAsFixed(1)} kilometres';
  }

  void _setupNavigation() {
    _navController.onPosition = (pos) {
      if (!mounted) return;
      setState(() => _userLocation = pos);
      final zoom = _mapController.camera.zoom;
      _mapController.move(pos, zoom < 17 ? 17 : zoom);
    };
    _navController.onStepChanged = (step, distance) {
      if (!mounted) return;
      setState(() {
        _navStep = step;
        _navDistanceToStep = distance;
      });
      _tts.speak('${step.instruction}. ${_formatDistance(distance)}.');
    };
    _navController.onProgress = (distance) {
      if (!mounted) return;
      setState(() => _navDistanceToStep = distance);
    };
    _navController.onPeriodicReminder = (step, distanceToStep, distanceRemaining) {
      if (!mounted) return;
      _tts.speak(
          'Still heading to ${_navDestination?.name ?? 'your destination'}. ${step.instruction}, ${_formatDistance(distanceToStep)} away. ${_formatDistance(distanceRemaining)} left overall.');
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
      await _stopObstacleAlertsForNavigation();
    };
    _navController.onOffRoute = () async {
      await _tts.speak('You have gone off route. Recalculating.');
      if (_userLocation != null) await _navController.reroute(_userLocation!);
    };
    _navController.onError = (message) async {
      await _tts.speak(message);
      if (!mounted) return;
      setState(() => _isNavigating = false);
      await _stopObstacleAlertsForNavigation();
    };
  }

  Future<void> _startNavigation(CampusLocation loc) async {
    if (_userLocation == null) {
      await _tts.speak('Your location is not available yet. Please enable location access.');
      return;
    }
    await _tts.speak('Starting navigation to ${loc.name}.');
    setState(() => _navDestination = loc);
    final started = await _navController.start(_userLocation!, loc.coordinates);
    if (!mounted) return;
    setState(() => _isNavigating = started);
    if (!started) {
      setState(() => _navDestination = null);
      return;
    }
    await _startObstacleAlertsForNavigation();
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
    _stopObstacleAlertsForNavigation();
  }

  Future<void> _startObstacleAlertsForNavigation() async {
    if (_obstacleAlertsEnabled) return;
    final started = await _obstacleService.start();
    if (!mounted) return;
    if (started) {
      _obstacleAlertsStartedByNavigation = true;
      setState(() => _obstacleAlertsEnabled = true);
    }
  }

  Future<void> _stopObstacleAlertsForNavigation() async {
    if (!_obstacleAlertsStartedByNavigation) return;
    _obstacleAlertsStartedByNavigation = false;
    await _obstacleService.stop();
    if (!mounted) return;
    setState(() => _obstacleAlertsEnabled = false);
  }

  Future<void> _loadLocations() async {
    try {
      final service = FirestoreService();
      final locations = <CampusLocation>[];
      final fetched = await service.getLocations();
      if (fetched.isNotEmpty) {
        locations.addAll(fetched);
      }
      if (mounted) {
        setState(() {
          _buildings = locations.isNotEmpty ? locations : _localBuildings;
          _filtered = List.from(_buildings);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _buildings = _localBuildings;
          _filtered = List.from(_buildings);
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? List.from(_buildings)
          : _buildings.where((b) => b.name.toLowerCase().contains(query) || b.description.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _tts.setErrorHandler((error) {});
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showError('Location services are disabled. Enable them in settings.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showError('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showError('Location permission permanently denied. Enable it in settings.');
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _userLocation = LatLng(position.latitude, position.longitude));
      _maybeAutoStartInitialDestination();
    } catch (e) {
      if (mounted) _showError('Failed to get location: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFD35400)),
    );
  }

  Future<void> _onLocationTapped(CampusLocation location) async {
    setState(() => _selectedLocation = location);
    _mapController.move(location.coordinates, 18);
    // Load reports for this location from database
    final reports = await _reportService.getReportsByLocation(location.name);
    setState(() => _locationReports = reports);
    if (_voiceEnabled) await _speakLocation(location);
  }

  static const String _customPinId = 'custom_pin';

  Future<void> _onMapLongPress(LatLng point) async {
    final pin = CampusLocation(
      id: _customPinId,
      name: 'Dropped Pin',
      description: 'A custom location you selected on the map.',
      coordinates: point,
      type: LocationType.facility,
      accessibilityInfo:
          'Exact coordinates: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}.',
    );
    setState(() {
      _selectedLocation = pin;
      _locationReports = [];
    });
    _mapController.move(point, 18);
    if (_voiceEnabled) {
      await _tts.speak('Pin dropped. Tap Navigate to walk there, or Read Aloud for the coordinates.');
    }
  }

  Future<void> _speakLocation(CampusLocation location) async {
    await _tts.stop();
    String speech =
        '${location.name}. ${location.description}. ${location.accessibilityInfo}';
    if (_userLocation != null) {
      double distance = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        location.coordinates.latitude,
        location.coordinates.longitude,
      );
      String dir = _getDirection(_userLocation!, location.coordinates);
      String distText = distance < 1000
          ? '${distance.toStringAsFixed(0)} metres'
          : '${(distance / 1000).toStringAsFixed(1)} kilometres';
      speech += ' This place is $distText to your $dir.';
      if (_locationReports.isNotEmpty) {
        speech +=
            ' Warning: ${_locationReports.length} accessibility issue${_locationReports.length > 1 ? 's' : ''} reported here.';
      }
    }
    await _tts.speak(speech);
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
    _searchController.dispose();
    _navController.dispose();
    _voiceAssistant.dispose();
    _obstacleService.dispose();
    super.dispose();
  }

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
              minZoom: 14,
              maxZoom: 19,
              cameraConstraint: CameraConstraint.contain(bounds: _mzuniBounds),
              onTap: (_, __) {
                setState(() {
                  _selectedLocation = null;
                  _locationReports = [];
                });
                _tts.stop();
              },
              onLongPress: (_, point) => _onMapLongPress(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.accessmap.mzuni',
              ),
              if (_isNavigating && _navController.routePolyline.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: _navController.routePolyline, strokeWidth: 5, color: const Color(0xFF1A6EBF)),
                ]),
              if (_userLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _userLocation!,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 8)
                        ],
                      ),
                    ),
                  ),
                ]),
              if (_selectedLocation != null && _selectedLocation!.id == _customPinId)
                MarkerLayer(markers: [
                  Marker(
                    point: _selectedLocation!.coordinates,
                    width: 46,
                    height: 46,
                    child: GestureDetector(
                      onTap: () => _onLocationTapped(_selectedLocation!),
                      child: const Icon(Icons.location_on, color: Color(0xFFE74C3C), size: 46),
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
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  _getTypeColor(loc.type).withOpacity(0.5),
                              blurRadius: isSelected ? 12 : 6,
                            )
                          ],
                        ),
                        child: Icon(_getTypeIcon(loc.type),
                            color: Colors.white,
                            size: isSelected ? 26 : 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),
          if (_isNavigating && _navStep != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: NavigationBanner(
                destinationName: _navDestination?.name ?? 'destination',
                instruction: _navStep!.instruction,
                distanceMeters: _navDistanceToStep,
                onStop: _stopNavigation,
              ),
            ),
          Positioned(
            bottom: _selectedLocation != null ? 230 : 20,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedLocation == null && !_isNavigating)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tip: tap the mic and say "navigate to the library" — or long-press the map to drop a pin',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF135C52),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1A7A6E).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: VoiceAssistantWidget(
                      assistant: _voiceAssistant,
                      onNavigateTo: _handleVoiceDestination,
                      onStopNavigation: _stopNavigation,
                      onEnableObstacleAlerts: () {
                        if (!_obstacleAlertsEnabled) _toggleObstacleAlerts();
                      },
                      onDisableObstacleAlerts: () {
                        if (_obstacleAlertsEnabled) _toggleObstacleAlerts();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: _selectedLocation != null ? 230 : 110,
            right: 16,
            child: _buildControls(),
          ),
          Positioned(
            bottom: _selectedLocation != null ? 230 : 110,
            left: 16,
            child: _buildLegend(),
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildLocationCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
          ),
          child: const Icon(Icons.arrow_back, color: Color(0xFF1A6EBF)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search buildings...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Color(0xFF1A6EBF), size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => _showBuildingsList(),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: () async {
          setState(() => _voiceEnabled = !_voiceEnabled);
          if (_voiceEnabled) {
            await _tts.speak('Voice navigation on');
          } else {
            await _tts.stop();
          }
        },
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _voiceEnabled ? const Color(0xFF1A6EBF) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
          ),
          child: Icon(
            _voiceEnabled ? Icons.volume_up : Icons.volume_off,
            color: _voiceEnabled ? Colors.white : Colors.grey,
            size: 20,
          ),
        ),
      ),
    ]);
  }

  Widget _buildControls() {
    return Column(children: [
      _btn(Icons.school, () => _mapController.move(_mzuniCenter, 16)),
      const SizedBox(height: 8),
      _btn(Icons.my_location, () {
        if (_userLocation != null) {
          _mapController.move(_userLocation!, 18);
        } else {
          _getUserLocation();
        }
      }),
      const SizedBox(height: 8),
      _btn(Icons.add, () => _mapController.move(
          _mapController.camera.center, _mapController.camera.zoom + 1)),
      const SizedBox(height: 8),
      _btn(Icons.remove, () => _mapController.move(
          _mapController.camera.center, _mapController.camera.zoom - 1)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _toggleObstacleAlerts,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _obstacleAlertsEnabled ? const Color(0xFFE74C3C) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
          ),
          child: Icon(
            _obstacleAlertsEnabled ? Icons.sensors : Icons.sensors_off,
            color: _obstacleAlertsEnabled ? Colors.white : const Color(0xFF1A6EBF),
            size: 20,
          ),
        ),
      ),
    ]);
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
        ),
        child: Icon(icon, color: const Color(0xFF1A6EBF), size: 20),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildLocationCard() {
    final CampusLocation loc = _selectedLocation!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _getTypeColor(loc.type).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getTypeIcon(loc.type), color: _getTypeColor(loc.type)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(loc.type.name.toUpperCase(),
                style: TextStyle(fontSize: 11, color: _getTypeColor(loc.type), fontWeight: FontWeight.w600)),
          ])),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              setState(() {
                _selectedLocation = null;
                _locationReports = [];
              });
              _tts.stop();
            },
          ),
        ]),
        const SizedBox(height: 10),
        Text(loc.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2ECC71).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.accessible, color: Color(0xFF2ECC71), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(loc.accessibilityInfo, style: const TextStyle(fontSize: 12))),
          ]),
        ),

        // Reports warning badge
        if (_locationReports.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD35400).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD35400).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: Color(0xFFD35400), size: 18),
              const SizedBox(width: 8),
              Text(
                '${_locationReports.length} report${_locationReports.length > 1 ? 's' : ''} submitted here',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD35400),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _speakLocation(loc),
              icon: const Icon(Icons.volume_up, size: 18),
              label: const Text('Read Aloud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6EBF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _startNavigation(loc),
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navigate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A6EBF),
                side: const BorderSide(color: Color(0xFF1A6EBF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  void _showBuildingsList() {
    final query = _searchController.text.trim().toLowerCase();
    final results = query.isEmpty ? _buildings : _filtered;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, sc) => Column(children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(query.isEmpty ? 'Mzuni Buildings' : 'Results for "$query"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          const SizedBox(height: 10),
          Expanded(child: ListView.builder(
            controller: sc, itemCount: results.length,
            itemBuilder: (_, i) {
              final CampusLocation loc = results[i];
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