import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import foundation for kIsWeb

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyDDGViCn0hRT65s__fK3V_OsxYJTtMinsk",
        authDomain: "better-placemaking.firebaseapp.com",
        databaseURL: "https://better-placemaking-default-rtdb.firebaseio.com",
        projectId: "better-placemaking",
        storageBucket: "better-placemaking.appspot.com",
        messagingSenderId: "15566872110",
        appId: "1:15566872110:web:b9df66810a6c87df0509bf",
        measurementId: "G-GF659M1GPV",
      );
    } else {
      throw UnsupportedError('Current platform is not supported.');
    }
  }
}

// Separate configuration for Google Maps API Key
class GoogleMapsConfig {
  static const mapsApiKey = "AIzaSyDwn6wqGymn4bYA_PB8TorQDelDuHZvyOc";
}