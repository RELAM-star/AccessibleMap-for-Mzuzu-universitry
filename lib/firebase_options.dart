import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: 'AIzaSyBF_oNDCf-FawtAqN2I5ZaUkzMHr96S1Tg',
        appId: '1:363948186877:web:6d3a1072ca9f246d08f294',
        messagingSenderId: '363948186877',
        projectId: 'access-map-697a8',
        authDomain: 'access-map-697a8.firebaseapp.com',
        storageBucket: 'access-map-697a8.firebasestorage.app',
      );
    }
    throw UnsupportedError('DefaultFirebaseOptions not configured for this platform.');
  }
}
