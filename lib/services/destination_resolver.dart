import '../models/campus_location.dart';
import 'firestore_service.dart';
import 'geocoding_service.dart';

class ResolvedDestination {
  final CampusLocation location;
  final bool wasGeocoded;

  ResolvedDestination(this.location, {required this.wasGeocoded});
}

/// Turns a spoken destination phrase into a navigable location: first tries
/// to match it against the campus buildings stored in Firestore (fast,
/// reliable, works offline via a curated fallback list), and if nothing
/// matches, falls back to a real address search so a blind user can ask for
/// literally any place by name.
class DestinationResolver {
  static final FirestoreService _firestoreService = FirestoreService();

  static CampusLocation? matchKnownBuilding(
      String spoken, List<CampusLocation> candidates) {
    final q = spoken.toLowerCase();
    for (final b in candidates) {
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
    for (final b in candidates) {
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
    final candidates = await _firestoreService.getLocationsOrFallback();
    final known = matchKnownBuilding(spoken, candidates);
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
      isAccessible: false,
    );
    return ResolvedDestination(synthetic, wasGeocoded: true);
  }
}
