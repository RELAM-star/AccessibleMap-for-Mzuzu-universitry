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

    // Fall back to keyword matching, scored by how much of the building's
    // name was actually said rather than the first partial match. Several
    // buildings share generic words (e.g. "main" appears in the
    // Administration Block, Library, Bus Stop and Cafeteria names), so
    // picking the first match in list order picks the wrong building
    // whenever the spoken phrase includes one of those shared words.
    CampusLocation? best;
    int bestScore = 0;
    for (final b in CampusLocation.mzuniBuildings) {
      final keywords = b.name.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 3);
      final score = keywords.where((w) => q.contains(w)).fold<int>(0, (sum, w) => sum + w.length);
      if (score > bestScore) {
        bestScore = score;
        best = b;
      }
    }
    return best;
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
