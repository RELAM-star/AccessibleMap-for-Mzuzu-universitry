import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RouteStep {
  final String instruction;
  final double distanceMeters;
  final LatLng maneuverLocation;

  RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.maneuverLocation,
  });
}

class RouteResult {
  final List<RouteStep> steps;
  final List<LatLng> polyline;
  final double totalDistanceMeters;
  final double totalDurationSeconds;

  RouteResult({
    required this.steps,
    required this.polyline,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });
}

class RoutingService {
  static const _baseUrl = 'https://router.project-osrm.org/route/v1/foot';

  /// Fetches a full walking route with turn-by-turn steps and the
  /// coordinates of each maneuver, so callers can track live progress
  /// against it rather than just reading a one-shot summary.
  static Future<RouteResult?> getRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      '$_baseUrl/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes[0] as Map<String, dynamic>;

      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List?;
      if (coordinates == null) return null;
      final polyline = coordinates
          .map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      final legs = route['legs'] as List? ?? [];
      final steps = <RouteStep>[];
      for (final leg in legs) {
        final legSteps = (leg as Map<String, dynamic>)['steps'] as List? ?? [];
        for (final step in legSteps) {
          final stepMap = step as Map<String, dynamic>;
          final maneuver = stepMap['maneuver'] as Map<String, dynamic>?;
          final location = maneuver?['location'] as List?;
          if (location == null) continue;
          final type = maneuver?['type'] as String? ?? 'continue';
          final modifier = maneuver?['modifier'] as String?;
          final roadName = stepMap['name'] as String? ?? '';
          final distance = (stepMap['distance'] as num?)?.toDouble() ?? 0.0;

          steps.add(RouteStep(
            instruction: _buildInstruction(type, modifier, roadName),
            distanceMeters: distance,
            maneuverLocation: LatLng((location[1] as num).toDouble(), (location[0] as num).toDouble()),
          ));
        }
      }
      if (steps.isEmpty) return null;

      return RouteResult(
        steps: steps,
        polyline: polyline,
        totalDistanceMeters: (route['distance'] as num?)?.toDouble() ?? 0.0,
        totalDurationSeconds: (route['duration'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (_) {
      return null;
    }
  }

  static String _buildInstruction(String type, String? modifier, String roadName) {
    final road = roadName.isNotEmpty ? ' onto $roadName' : '';
    switch (type) {
      case 'depart':
        return 'Head ${modifier ?? 'straight'}$road';
      case 'arrive':
        return 'You have arrived at your destination';
      case 'turn':
        return 'Turn ${modifier ?? 'ahead'}$road';
      case 'continue':
        return 'Continue ${modifier ?? 'straight'}$road';
      case 'merge':
        return 'Merge${modifier != null ? ' $modifier' : ''}$road';
      case 'roundabout':
      case 'rotary':
        return 'Enter the roundabout and exit$road';
      case 'fork':
        return 'Keep ${modifier ?? 'straight'} at the fork$road';
      case 'end of road':
        return 'At the end of the road, turn ${modifier ?? 'ahead'}$road';
      default:
        return 'Continue$road';
    }
  }

  /// One-shot spoken summary of a route, kept for places that just want
  /// a single announcement rather than live turn-by-turn guidance.
  static Future<String?> getRouteSteps(LatLng from, LatLng to) async {
    final route = await getRoute(from, to);
    if (route == null) return null;
    return route.steps.map((s) {
      final distText = s.distanceMeters < 1000
          ? '${s.distanceMeters.toStringAsFixed(0)} metres'
          : '${(s.distanceMeters / 1000).toStringAsFixed(1)} kilometres';
      return '${s.instruction} for $distText';
    }).join('. Then ');
  }
}
