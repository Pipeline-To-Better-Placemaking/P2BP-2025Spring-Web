import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreFunctions {
  /// Gets the value of fullName from 'users' the document for the given uid.
  /// Contains error handling for every case starting from uid being null.
  /// This will always either return the successfully found name or throw
  /// an exception, so running this in a try-catch is strongly encouraged.
  static Future<String> getUserFullName(String? uid) async {
    try {
      if (uid == null) {
        throw Exception('no-user-id-found');
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String? fullName = userDoc['fullName'];
        if (fullName == null || fullName.isEmpty) {
          throw Exception('user-has-no-name');
        } else {
          return fullName;
        }
      } else {
        throw Exception('user-document-does-not-exist');
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}