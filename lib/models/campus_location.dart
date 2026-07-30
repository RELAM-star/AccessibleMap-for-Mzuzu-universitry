import 'package:latlong2/latlong.dart';

enum LocationType { academic, admin, library, hostel, facility, transport }

class CampusLocation {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final LocationType type;
  final String accessibilityInfo;
  final bool isAccessible;

  CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.type,
    required this.accessibilityInfo,
    this.isAccessible = true,
  });

  /// Seed data only — used by tool/seed_locations.dart to populate Firestore
  /// and as an offline fallback if the Firestore fetch fails. Firestore's
  /// `locations` collection is the runtime source of truth.
  static List<CampusLocation> get mzuniBuildings => [
    CampusLocation(id: 'main_admin', name: 'Main Administration Block', description: 'Central admin offices, Registry, and Student Affairs', coordinates: const LatLng(-11.4648, 34.0195), type: LocationType.admin, accessibilityInfo: 'Ramp access at main entrance. Wide corridors.', isAccessible: true),
    CampusLocation(id: 'library', name: 'Mzuni Main Library', description: 'University library with study rooms and computer lab', coordinates: const LatLng(-11.4655, 34.0202), type: LocationType.library, accessibilityInfo: 'Step-free entrance on east side. Braille materials available.', isAccessible: true),
    CampusLocation(id: 'foh', name: 'Faculty of Humanities', description: 'Arts, Social Sciences and Languages', coordinates: const LatLng(-11.4660, 34.0190), type: LocationType.academic, accessibilityInfo: 'Ground floor fully accessible. Ramp at north entrance.', isAccessible: true),
    CampusLocation(id: 'fose', name: 'Faculty of Science & Engineering', description: 'Science labs, engineering workshops and lecture rooms', coordinates: const LatLng(-11.4645, 34.0210), type: LocationType.academic, accessibilityInfo: 'Accessible entrance on south side. Ground floor wheelchair friendly.', isAccessible: true),
    CampusLocation(id: 'fob', name: 'Faculty of Business', description: 'Business, Economics and Management lecture halls', coordinates: const LatLng(-11.4652, 34.0185), type: LocationType.academic, accessibilityInfo: 'Step-free access at main door. Wide corridors throughout.', isAccessible: true),
    CampusLocation(id: 'foe', name: 'Faculty of Education', description: 'Education department offices and lecture rooms', coordinates: const LatLng(-11.4665, 34.0198), type: LocationType.academic, accessibilityInfo: 'Ramp at main entrance. All classrooms on ground floor accessible.', isAccessible: true),
    CampusLocation(id: 'student_centre', name: 'Student Centre', description: 'Student union, cafeteria, and recreation facilities', coordinates: const LatLng(-11.4658, 34.0207), type: LocationType.facility, accessibilityInfo: 'Fully accessible. Accessible toilet inside. Wide entrance doors.', isAccessible: true),
    CampusLocation(id: 'chapel', name: 'University Chapel', description: 'Multi-faith worship space for students and staff', coordinates: const LatLng(-11.4642, 34.0200), type: LocationType.facility, accessibilityInfo: 'Level access at all entrances. Reserved seating for wheelchair users.', isAccessible: true),
    CampusLocation(id: 'sports', name: 'Sports Complex', description: 'Football field, basketball courts and gym', coordinates: const LatLng(-11.4670, 34.0215), type: LocationType.facility, accessibilityInfo: 'Paved pathway from main road. Viewing area for wheelchair users.', isAccessible: true),
    CampusLocation(id: 'chancellor_hostel', name: "Chancellor's Hostel", description: 'Male student residence block', coordinates: const LatLng(-11.4638, 34.0188), type: LocationType.hostel, accessibilityInfo: 'Ground floor rooms for disabled students. Accessible bathroom available.', isAccessible: true),
    CampusLocation(id: 'female_hostel', name: 'Female Hostel', description: 'Female student residence block', coordinates: const LatLng(-11.4640, 34.0205), type: LocationType.hostel, accessibilityInfo: 'Ramp at entrance. Accessible rooms available on request.', isAccessible: true),
    CampusLocation(id: 'health_centre', name: 'University Health Centre', description: 'Campus clinic for students and staff', coordinates: const LatLng(-11.4650, 34.0175), type: LocationType.facility, accessibilityInfo: 'Fully accessible. Priority service for disabled students.', isAccessible: true),
    CampusLocation(id: 'bus_stop', name: 'Main Campus Bus Stop', description: 'Minibus transport to Mzuzu city centre', coordinates: const LatLng(-11.4635, 34.0195), type: LocationType.transport, accessibilityInfo: 'Covered waiting area. Low-floor minibuses on some routes.', isAccessible: false),
    CampusLocation(id: 'cafeteria', name: 'Main Cafeteria', description: 'University dining hall serving all meals', coordinates: const LatLng(-11.4656, 34.0193), type: LocationType.facility, accessibilityInfo: 'Step-free entrance. Wide aisles. Staff available to assist.', isAccessible: true),
    CampusLocation(id: 'ict_centre', name: 'ICT Centre', description: 'Computer labs and internet access for students', coordinates: const LatLng(-11.4648, 34.0208), type: LocationType.academic, accessibilityInfo: 'Ground floor accessible. Screen reader software available.', isAccessible: true),
  ];
}