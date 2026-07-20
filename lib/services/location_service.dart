// lib/services/location_service.dart

import 'database_service.dart';

class LocationModel {
  final int? id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String description;
  final bool hasWheelchairRamp;
  final bool hasAccessibleToilet;
  final bool hasAccessibleParking;
  final bool hasElevator;
  final bool isVerified;
  final String createdAt;

  LocationModel({
    this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.hasWheelchairRamp,
    required this.hasAccessibleToilet,
    required this.hasAccessibleParking,
    required this.hasElevator,
    required this.isVerified,
    required this.createdAt,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      description: map['description'] ?? '',
      hasWheelchairRamp: map['has_wheelchair_ramp'] == 1,
      hasAccessibleToilet: map['has_accessible_toilet'] == 1,
      hasAccessibleParking: map['has_accessible_parking'] == 1,
      hasElevator: map['has_elevator'] == 1,
      isVerified: map['is_verified'] == 1,
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'has_wheelchair_ramp': hasWheelchairRamp ? 1 : 0,
      'has_accessible_toilet': hasAccessibleToilet ? 1 : 0,
      'has_accessible_parking': hasAccessibleParking ? 1 : 0,
      'has_elevator': hasElevator ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
      'created_at': createdAt,
    };
  }

  // Returns a text summary for voice readout
  String toVoiceDescription() {
    final features = <String>[];
    if (hasWheelchairRamp) features.add('wheelchair ramp');
    if (hasAccessibleToilet) features.add('accessible toilet');
    if (hasAccessibleParking) features.add('accessible parking');
    if (hasElevator) features.add('elevator');

    if (features.isEmpty) {
      return '$name. Category: $category. No accessibility features recorded yet.';
    }
    return '$name. Category: $category. Has ${features.join(', ')}.';
  }
}

class LocationService {
  final DatabaseService _db = DatabaseService.instance;

  // Get all locations
  Future<List<LocationModel>> getAllLocations() async {
    final db = await _db.database;
    final result = await db.query('locations', orderBy: 'name ASC');
    return result.map((map) => LocationModel.fromMap(map)).toList();
  }

  // Get locations by category
  Future<List<LocationModel>> getByCategory(String category) async {
    final db = await _db.database;
    final result = await db.query(
      'locations',
      where: 'category = ?',
      whereArgs: [category],
    );
    return result.map((map) => LocationModel.fromMap(map)).toList();
  }

  // Get only locations with wheelchair ramps
  Future<List<LocationModel>> getWheelchairAccessible() async {
    final db = await _db.database;
    final result = await db.query(
      'locations',
      where: 'has_wheelchair_ramp = ?',
      whereArgs: [1],
    );
    return result.map((map) => LocationModel.fromMap(map)).toList();
  }

  // Get only locations with accessible toilets
  Future<List<LocationModel>> getWithAccessibleToilets() async {
    final db = await _db.database;
    final result = await db.query(
      'locations',
      where: 'has_accessible_toilet = ?',
      whereArgs: [1],
    );
    return result.map((map) => LocationModel.fromMap(map)).toList();
  }

  // Search locations by name
  Future<List<LocationModel>> searchByName(String query) async {
    final db = await _db.database;
    final result = await db.query(
      'locations',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result.map((map) => LocationModel.fromMap(map)).toList();
  }

  // Add a new location
  Future<int> addLocation(LocationModel location) async {
    final db = await _db.database;
    return await db.insert('locations', location.toMap());
  }

  // Update a location
  Future<int> updateLocation(LocationModel location) async {
    final db = await _db.database;
    return await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  // Delete a location
  Future<int> deleteLocation(int id) async {
    final db = await _db.database;
    return await db.delete(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}