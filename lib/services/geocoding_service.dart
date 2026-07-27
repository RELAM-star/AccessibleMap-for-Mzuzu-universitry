import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class GeocodedPlace {
  final String label;
  final LatLng coordinates;

  GeocodedPlace({required this.label, required this.coordinates});
}

/// Looks up an arbitrary place name or address as real-world coordinates,
/// for destinations that aren't in the app's curated campus location list.
/// Uses OpenStreetMap's free Nominatim search, the same style of unauthenticated
/// public API already used for routing.
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const _userAgent = 'AccessMapMzuni/1.0 (campus accessibility navigation app)';

  /// Tries the query biased toward the Mzuzu, Malawi area first (since most
  /// spoken destinations will be local), then falls back to an unbiased
  /// search so a request for a place elsewhere still resolves.
  static Future<GeocodedPlace?> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    final local = await _query('$trimmed, Mzuzu, Malawi');
    if (local != null) return local;
    return _query(trimmed);
  }

  static Future<GeocodedPlace?> _query(String q) async {
    final url = Uri.parse('$_baseUrl?q=${Uri.encodeQueryComponent(q)}&format=json&limit=1');
    try {
      final response = await http.get(url, headers: {'User-Agent': _userAgent});
      if (response.statusCode != 200) return null;
      final results = json.decode(response.body) as List;
      if (results.isEmpty) return null;
      final first = results[0] as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;
      return GeocodedPlace(
        label: (first['display_name'] as String?) ?? q,
        coordinates: LatLng(lat, lon),
      );
    } catch (_) {
      return null;
    }
  }
}
