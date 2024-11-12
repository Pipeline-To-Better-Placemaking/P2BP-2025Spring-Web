import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Import foundation for kIsWeb

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyCtrVdJD9W4IpXCJ1KSrHGqZKYG9HUrhgs",
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
