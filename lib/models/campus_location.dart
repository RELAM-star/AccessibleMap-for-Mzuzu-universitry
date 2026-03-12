import 'package:latlong2/latlong.dart';

enum LocationType { academic, admin, library, hostel, facility, transport }

class CampusLocation {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final LocationType type;
  final String accessibilityInfo;

  CampusLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.type,
    required this.accessibilityInfo,
  });

  static List<CampusLocation> get mzuniBuildings => [
    CampusLocation(id: 'main_admin', name: 'Main Administration Block', description: 'Central admin offices and Registry', coordinates: LatLng(-11.4648, 34.0195), type: LocationType.admin, accessibilityInfo: 'Ramp access at main entrance. Wide corridors.'),
    CampusLocation(id: 'library', name: 'Mzuni Main Library', description: 'University library with study rooms', coordinates: LatLng(-11.4655, 34.0202), type: LocationType.library, accessibilityInfo: 'Step-free entrance on east side. Braille materials available.'),
    CampusLocation(id: 'foh', name: 'Faculty of Humanities', description: 'Arts, Social Sciences and Languages', coordinates: LatLng(-11.4660, 34.0190), type: LocationType.academic, accessibilityInfo: 'Ground floor fully accessible. Ramp at north entrance.'),
    CampusLocation(id: 'fose', name: 'Faculty of Science & Engineering', description: 'Science labs and engineering workshops', coordinates: LatLng(-11.4645, 34.0210), type: LocationType.academic, accessibilityInfo: 'Accessible entrance on south side.'),
    CampusLocation(id: 'fob', name: 'Faculty of Business', description: 'Business and Economics lecture halls', coordinates: LatLng(-11.4652, 34.0185), type: LocationType.academic, accessibilityInfo: 'Step-free access at main door.'),
    CampusLocation(id: 'student_centre', name: 'Student Centre', description: 'Student union and cafeteria', coordinates: LatLng(-11.4658, 34.0207), type: LocationType.facility, accessibilityInfo: 'Fully accessible. Accessible toilet inside.'),
    CampusLocation(id: 'health_centre', name: 'University Health Centre', description: 'Campus clinic for students and staff', coordinates: LatLng(-11.4650, 34.0175), type: LocationType.facility, accessibilityInfo: 'Fully accessible. Priority service for disabled students.'),
    CampusLocation(id: 'bus_stop', name: 'Main Campus Bus Stop', description: 'Minibus transport to Mzuzu city centre', coordinates: LatLng(-11.4635, 34.0195), type: LocationType.transport, accessibilityInfo: 'Covered waiting area.'),
    CampusLocation(id: 'chancellor_hostel', name: "Chancellor's Hostel", description: 'Male student residence block', coordinates: LatLng(-11.4638, 34.0188), type: LocationType.hostel, accessibilityInfo: 'Ground floor rooms for disabled students.'),
    CampusLocation(id: 'female_hostel', name: 'Female Hostel', description: 'Female student residence block', coordinates: LatLng(-11.4640, 34.0205), type: LocationType.hostel, accessibilityInfo: 'Ramp at entrance. Accessible rooms available.'),
    CampusLocation(id: 'ict_centre', name: 'ICT Centre', description: 'Computer labs and internet access', coordinates: LatLng(-11.4648, 34.0208), type: LocationType.academic, accessibilityInfo: 'Ground floor accessible. Screen reader available.'),
  ];
}