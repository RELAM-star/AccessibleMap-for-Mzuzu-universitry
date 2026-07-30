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

  Future<List<Map<String, dynamic>>> getReportsByLocation(
      String locationName) async {
    final snapshot =
        await _reports.where('location', isEqualTo: locationName).get();
    final reports = snapshot.docs.map((doc) => doc.data()).toList();
    reports.sort((a, b) {
      final aTime = a['createdAt'] as Timestamp?;
      final bTime = b['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });
    return reports;
  }

  CampusLocation _locationFromDoc(
      String docId, Map<String, dynamic> data) {
    return CampusLocation(
      id: data['id'] ?? docId,
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
      isAccessible: data['isAccessible'] as bool? ?? true,
    );
  }

  Future<List<CampusLocation>> getLocations() async {
    final snapshot = await _locations.get();
    return snapshot.docs
        .map((doc) => _locationFromDoc(doc.id, doc.data()))
        .toList();
  }

  Stream<List<CampusLocation>> watchLocations() {
    return _locations.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => _locationFromDoc(doc.id, doc.data()))
          .toList();
    });
  }

  /// Locations for voice/search matching: tries Firestore first and falls
  /// back to the curated offline list so destination matching still works
  /// without a network connection.
  Future<List<CampusLocation>> getLocationsOrFallback() async {
    try {
      final fetched = await getLocations();
      return fetched.isNotEmpty ? fetched : CampusLocation.mzuniBuildings;
    } catch (_) {
      return CampusLocation.mzuniBuildings;
    }
  }
}
