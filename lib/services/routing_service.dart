import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RoutingService {
  static const _baseUrl = 'https://router.project-osrm.org/route/v1/foot';

  static Future<String?> getRouteSteps(LatLng from, LatLng to) async {
    final url = Uri.parse('$_baseUrl/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=false&steps=true');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List;
        if (routes.isEmpty) return null;
        final legs = routes[0]['legs'] as List;
        if (legs.isEmpty) return null;
        final steps = legs[0]['steps'] as List;
        final instructions = <String>[];
        for (final step in steps) {
          final instruction = step['maneuver']['modifier'] as String? ?? step['maneuver']['type'] as String?;
          final distance = step['distance'] as num?;
          if (instruction != null && distance != null) {
            final distText = distance < 1000 ? '${distance.toStringAsFixed(0)} metres' : '${(distance / 1000).toStringAsFixed(1)} kilometres';
            instructions.add('$instruction for $distText');
          }
        }
        if (instructions.isEmpty) return null;
        return instructions.join('. Then ');
      }
    } catch (_) {}
    return null;
  }
}
