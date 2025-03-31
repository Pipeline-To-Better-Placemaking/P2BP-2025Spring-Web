import 'package:cloud_firestore/cloud_firestore.dart';
import 'results_map_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<VisualizedResults>> fetchAllTests() async {
    List<VisualizedResults> tests = [];

    try {
      // Fetch the main document (make sure this document exists)
      DocumentSnapshot snapshot = await _firestore.collection('your_main_collection').doc('your_doc_id').get();

      if (!snapshot.exists) {
        print('Main document does not exist');
        return tests; // Return an empty list if the document does not exist
      }

      // Fetch the list of test references
      List testRefs = snapshot['tests'];

      if (testRefs == null || testRefs.isEmpty) {
        print('No test references found');
        return tests;
      }

      // Iterate over each reference and fetch corresponding data
      for (var ref in testRefs) {
        String path = ref.path;
        List<String> parts = path.split('/');
        if (parts.length == 2) {
          String collectionID = parts[0];
          String testID = parts[1];

          try {
            DocumentSnapshot testSnapshot = await _firestore.collection(collectionID).doc(testID).get();

            if (testSnapshot.exists) {
              Map<String, dynamic> data = testSnapshot.data() as Map<String, dynamic>;
              tests.add(await VisualizedResults.fromFirebase(testID, collectionID, data));
            } else {
              print('Test document not found for $testID in collection $collectionID');
            }
          } catch (e) {
            print('Error fetching test data for $testID: $e');
          }
        } else {
          print('Invalid reference path: $path');
        }
      }
    } catch (e) {
      print('Error fetching main document or test references: $e');
    }

    return tests;
  }
}
