// One-time script to push CampusLocation.mzuniBuildings into Firestore's
// `locations` collection. Firebase plugins need a running Flutter engine
// (this can't be a plain `dart run` script), so launch it as its own app:
//
//   flutter run -d chrome -t tool/seed_locations.dart
//
// Safe to re-run: each location is written with its stable id and merge:true.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accessmap_mzuni/firebase_options.dart';
import 'package:accessmap_mzuni/models/campus_location.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SeedApp());
}

class SeedApp extends StatefulWidget {
  const SeedApp({super.key});

  @override
  State<SeedApp> createState() => _SeedAppState();
}

class _SeedAppState extends State<SeedApp> {
  String _status = 'Seeding locations...';

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    final locations = FirebaseFirestore.instance.collection('locations');
    try {
      // The `locations` write rule requires a signed-in user; anonymous
      // auth is enough since there's no admin role flow yet.
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final batch = FirebaseFirestore.instance.batch();
      for (final loc in CampusLocation.mzuniBuildings) {
        batch.set(
          locations.doc(loc.id),
          {
            'id': loc.id,
            'name': loc.name,
            'description': loc.description,
            'lat': loc.coordinates.latitude,
            'lng': loc.coordinates.longitude,
            'type': loc.type.name,
            'accessibilityInfo': loc.accessibilityInfo,
            'isAccessible': loc.isAccessible,
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      setState(() => _status =
          'Done. Wrote ${CampusLocation.mzuniBuildings.length} locations to Firestore.');
    } catch (e) {
      setState(() => _status = 'Failed to seed locations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_status))),
      ),
    );
  }
}
