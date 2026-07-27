import '../models/campus_location.dart';
import 'geocoding_service.dart';

class ResolvedDestination {
  final CampusLocation location;
  final bool wasGeocoded;

  ResolvedDestination(this.location, {required this.wasGeocoded});
}

/// Turns a spoken destination phrase into a navigable location: first tries
/// to match it against the app's curated campus buildings (fast, reliable,
/// no network needed), and if nothing matches, falls back to a real address
/// search so a blind user can ask for literally any place by name.
class DestinationResolver {
  static CampusLocation? matchKnownBuilding(String spoken) {
    final q = spoken.toLowerCase();
    for (final b in CampusLocation.mzuniBuildings) {
      if (q.contains(b.name.toLowerCase())) return b;
    }
    for (final b in CampusLocation.mzuniBuildings) {
      final keywords = b.name.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3);
      if (keywords.any((w) => q.contains(w))) return b;
    }
    return null;
  }

  static Future<ResolvedDestination?> resolve(String spoken) async {
    final known = matchKnownBuilding(spoken);
    if (known != null) return ResolvedDestination(known, wasGeocoded: false);

    final place = await GeocodingService.search(spoken);
    if (place == null) return null;

    final synthetic = CampusLocation(
      id: 'geocoded_${DateTime.now().millisecondsSinceEpoch}',
      name: place.label.split(',').first.trim(),
      description: place.label,
      coordinates: place.coordinates,
      type: LocationType.facility,
      accessibilityInfo: 'Found via address search: ${place.label}',
    );
    return ResolvedDestination(synthetic, wasGeocoded: true);
  }
}
