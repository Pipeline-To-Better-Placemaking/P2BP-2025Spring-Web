import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import foundation for kIsWeb

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
        authDomain: const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        databaseURL: const String.fromEnvironment('FIREBASE_DATABASE_URL'),
        projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        messagingSenderId: const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        appId: const String.fromEnvironment('FIREBASE_APP_ID'),
        measurementId: const String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
      );
    } else {
      throw UnsupportedError('Current platform is not supported.');
    }
  }
}
