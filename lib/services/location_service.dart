import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;

enum LocationFailure { serviceDisabled, permissionDenied, permissionDeniedForever }

class LocationServiceException implements Exception {
  final LocationFailure reason;
  final String message;
  LocationServiceException(this.reason, this.message);

  @override
  String toString() => message;
}

class LocationResult {
  final LatLng position;
  final double accuracyMeters;
  final bool isWithinMzuni;

  LocationResult({
    required this.position,
    required this.accuracyMeters,
    required this.isWithinMzuni,
  });
}

/// Single source of truth for "where is Mzuzu University campus" and for
/// the permission -> service -> fix flow needed to get the device's GPS
/// position. Every screen that needs the user's location or needs to know
/// whether a point is on campus should go through here instead of calling
/// Geolocator directly, so the bounds used for "am I on campus" checks
/// can never drift out of sync between screens.
class LocationService {
  static const LatLng mzuniCenter = LatLng(-11.4653, 34.0199);

  // ~1.9km (north-south) x 1.8km (east-west) box around the real Mzuzu
  // University campus in Mzuzu, Malawi, generous enough to cover campus
  // approach roads without including the whole city.
  static final LatLngBounds mzuniBounds = LatLngBounds(
    const LatLng(-11.475, 34.012),
    const LatLng(-11.458, 34.028),
  );

  static bool isWithinMzuni(LatLng point) => mzuniBounds.contains(point);

  /// Runs the full location startup flow — checks the location service is
  /// on, checks/requests permission, then reads the current GPS fix —
  /// logging each step so failures are diagnosable from the device log.
  /// Throws [LocationServiceException] with a reason the UI can act on
  /// (e.g. show a "request again" retry vs. "open settings").
  static Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    developer.log('service enabled: $serviceEnabled', name: 'LocationService');
    if (!serviceEnabled) {
      throw LocationServiceException(
        LocationFailure.serviceDisabled,
        'Location services are turned off. Enable them in your device settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    developer.log('permission (initial): $permission', name: 'LocationService');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      developer.log('permission (after request): $permission', name: 'LocationService');
    }
    if (permission == LocationPermission.denied) {
      throw LocationServiceException(
        LocationFailure.permissionDenied,
        'Location permission was denied. AccessMap needs it to find your position on campus.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        LocationFailure.permissionDeniedForever,
        'Location permission is permanently denied. Enable it from your device app settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final point = LatLng(position.latitude, position.longitude);
    final withinCampus = isWithinMzuni(point);
    developer.log(
      'lat: ${position.latitude}, lng: ${position.longitude}, '
      'accuracy: ${position.accuracy}m, withinMzuniCampus: $withinCampus',
      name: 'LocationService',
    );

    return LocationResult(
      position: point,
      accuracyMeters: position.accuracy,
      isWithinMzuni: withinCampus,
    );
  }
}
