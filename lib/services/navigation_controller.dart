import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

/// Drives a live, GPS-tracked walking navigation session: fetches a route,
/// watches the device's position, announces steps as the user reaches them,
/// keeps talking with periodic progress reminders on long stretches,
/// detects when the user has wandered off the path, and can reroute.
class NavigationController {
  static const double _stepArrivalRadiusMeters = 15;
  static const double _destinationArrivalRadiusMeters = 12;
  static const double _offRouteThresholdMeters = 35;
  static const Duration _rerouteCooldown = Duration(seconds: 8);

  final Duration periodicReminderInterval;

  NavigationController({this.periodicReminderInterval = const Duration(seconds: 20)});

  RouteResult? _route;
  int _currentStepIndex = 0;
  LatLng? _destination;
  LatLng? _lastKnownPosition;
  DateTime? _lastAnnouncementAt;
  DateTime? _lastRerouteAt;
  StreamSubscription<Position>? _positionSub;
  Timer? _reminderTimer;

  void Function(LatLng position)? onPosition;
  void Function(RouteStep step, double distanceToStep)? onStepChanged;
  void Function(double distanceToNextStep)? onProgress;
  void Function(RouteStep step, double distanceToStep, double distanceRemainingTotal)? onPeriodicReminder;
  void Function()? onArrived;
  void Function()? onOffRoute;
  void Function(String message)? onError;

  bool get isNavigating => _positionSub != null;
  RouteStep? get currentStep =>
      (_route != null && _currentStepIndex < _route!.steps.length) ? _route!.steps[_currentStepIndex] : null;
  List<LatLng> get routePolyline => _route?.polyline ?? const [];

  /// The point the user is currently walking towards: the next maneuver,
  /// or the destination itself once on the final leg.
  LatLng? get _currentTarget {
    final route = _route;
    final destination = _destination;
    if (route == null || destination == null) return null;
    return _currentStepIndex < route.steps.length - 1
        ? route.steps[_currentStepIndex + 1].maneuverLocation
        : destination;
  }

  /// Calculates a route from [from] to [destination] and starts tracking
  /// live position updates against it. Returns false if no route could be
  /// found.
  Future<bool> start(LatLng from, LatLng destination) async {
    final route = await RoutingService.getRoute(from, destination);
    if (route == null) {
      onError?.call('Could not calculate a route to this destination right now.');
      return false;
    }

    _route = route;
    _destination = destination;
    _currentStepIndex = 0;
    _lastKnownPosition = from;
    _lastRerouteAt = null;

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 3),
    ).listen(_onPosition, onError: (_) {});

    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(periodicReminderInterval, (_) => _speakPeriodicReminder());

    _announceStep(route.steps[0], from);
    return true;
  }

  /// Recalculates the route from [from] to the current destination without
  /// stopping the live position stream.
  Future<void> reroute(LatLng from) async {
    final destination = _destination;
    if (destination == null) return;
    final route = await RoutingService.getRoute(from, destination);
    if (route == null) {
      onError?.call('Lost the route. Still trying to reconnect.');
      return;
    }
    _route = route;
    _currentStepIndex = 0;
    _announceStep(route.steps[0], from);
  }

  void _announceStep(RouteStep step, LatLng from) {
    _lastAnnouncementAt = DateTime.now();
    final target = _currentTarget;
    onStepChanged?.call(step, target == null ? 0 : _distance(from, target));
  }

  void _onPosition(Position position) {
    final route = _route;
    final destination = _destination;
    if (route == null || destination == null) return;
    final current = LatLng(position.latitude, position.longitude);
    _lastKnownPosition = current;
    onPosition?.call(current);

    final distanceToDestination = _distance(current, destination);
    if (distanceToDestination <= _destinationArrivalRadiusMeters) {
      onArrived?.call();
      stop();
      return;
    }

    // Advance while we've reached the upcoming maneuver point(s).
    while (_currentStepIndex < route.steps.length - 1) {
      final nextManeuver = route.steps[_currentStepIndex + 1].maneuverLocation;
      if (_distance(current, nextManeuver) <= _stepArrivalRadiusMeters) {
        _currentStepIndex++;
        _announceStep(route.steps[_currentStepIndex], current);
      } else {
        break;
      }
    }

    final target = _currentTarget;
    if (target != null) onProgress?.call(_distance(current, target));

    final offRoute = _distanceToPolyline(current, route.polyline) > _offRouteThresholdMeters;
    if (offRoute) {
      final now = DateTime.now();
      if (_lastRerouteAt == null || now.difference(_lastRerouteAt!) > _rerouteCooldown) {
        _lastRerouteAt = now;
        onOffRoute?.call();
      }
    }
  }

  void _speakPeriodicReminder() {
    final route = _route;
    final position = _lastKnownPosition;
    if (route == null || position == null) return;
    // Don't talk over a turn-by-turn announcement that just happened.
    final since = _lastAnnouncementAt == null ? null : DateTime.now().difference(_lastAnnouncementAt!);
    if (since != null && since < const Duration(seconds: 8)) return;

    final step = route.steps[_currentStepIndex];
    final target = _currentTarget;
    final distanceToStep = target == null ? 0.0 : _distance(position, target);
    onPeriodicReminder?.call(step, distanceToStep, _remainingRouteDistance(position));
  }

  double _remainingRouteDistance(LatLng current) {
    final route = _route;
    final target = _currentTarget;
    if (route == null || target == null) return 0;
    double total = _distance(current, target);
    for (var i = _currentStepIndex + 1; i < route.steps.length - 1; i++) {
      total += route.steps[i].distanceMeters;
    }
    return total;
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _reminderTimer?.cancel();
    _reminderTimer = null;
    _route = null;
    _currentStepIndex = 0;
    _destination = null;
    _lastKnownPosition = null;
    _lastAnnouncementAt = null;
    _lastRerouteAt = null;
  }

  void dispose() => stop();

  double _distance(LatLng a, LatLng b) =>
      Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);

  double _distanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.length < 2) return 0;
    double best = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final d = _distanceToSegment(point, polyline[i], polyline[i + 1]);
      if (d < best) best = d;
    }
    return best;
  }

  /// Approximates distance from [p] to the segment [a]-[b] by projecting in
  /// a local lon/lat frame, then measuring the closest point with the real
  /// haversine distance. Accurate enough at pedestrian, city-block scale.
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final lenSq = dx * dx + dy * dy;
    double t = lenSq == 0 ? 0 : (((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) / lenSq);
    t = t.clamp(0.0, 1.0);
    final closest = LatLng(a.latitude + t * dy, a.longitude + t * dx);
    return _distance(p, closest);
  }
}
