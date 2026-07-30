import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:accessmap_mzuni/models/campus_location.dart';

void main() {
  test('CampusLocation has correct fields', () {
    final loc = CampusLocation(
      id: 'test',
      name: 'Test Building',
      description: 'A test building',
      coordinates: const LatLng(-11.4648, 34.0195),
      type: LocationType.academic,
      accessibilityInfo: 'Ramp access',
    );
    expect(loc.id, 'test');
    expect(loc.name, 'Test Building');
    expect(loc.coordinates.latitude, -11.4648);
    expect(loc.type, LocationType.academic);
  });

  test('mzuniBuildings list is not empty', () {
    expect(CampusLocation.mzuniBuildings.isNotEmpty, isTrue);
  });

  test('All mzuni buildings have required fields', () {
    for (final b in CampusLocation.mzuniBuildings) {
      expect(b.id.isNotEmpty, isTrue);
      expect(b.name.isNotEmpty, isTrue);
      expect(b.description.isNotEmpty, isTrue);
      expect(b.accessibilityInfo.isNotEmpty, isTrue);
    }
  });
}
