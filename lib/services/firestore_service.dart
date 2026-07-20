import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../models/campus_location.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  CollectionReference<Map<String, dynamic>> get _locations =>
      _db.collection('locations');

  Future<void> saveUserProfile(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<void> submitReport(Map<String, dynamic> report) async {
    await _reports.add({
      ...report,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReports() {
    return _reports.orderBy('createdAt', descending: true).snapshots();
  }

  Future<List<CampusLocation>> getLocations() async {
    final snapshot = await _locations.get();
    return snapshot.docs.map<CampusLocation>((doc) {
      final data = doc.data();
      return CampusLocation(
        id: data['id'] ?? doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        coordinates: LatLng(
          (data['lat'] as num?)?.toDouble() ?? 0.0,
          (data['lng'] as num?)?.toDouble() ?? 0.0,
        ),
        type: LocationType.values.firstWhere(
          (e) => e.name == (data['type'] ?? 'facility'),
          orElse: () => LocationType.facility,
        ),
        accessibilityInfo: data['accessibilityInfo'] ?? '',
      );
    }).toList();
  }

  Stream<List<CampusLocation>> watchLocations() {
    return _locations.snapshots().map((snapshot) {
      return snapshot.docs.map<CampusLocation>((doc) {
        final data = doc.data();
        return CampusLocation(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          coordinates: LatLng(
            (data['lat'] as num?)?.toDouble() ?? 0.0,
            (data['lng'] as num?)?.toDouble() ?? 0.0,
          ),
          type: LocationType.values.firstWhere(
            (e) => e.name == (data['type'] ?? 'facility'),
            orElse: () => LocationType.facility,
          ),
          accessibilityInfo: data['accessibilityInfo'] ?? '',
        );
      }).toList();
    });
  }
}
