import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../section_cutter_test.dart';
import '../misc_class_stuff.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

/// Simple class for Section Cutter Test.
///
/// Contains a [sectionLink] variable which refers to the section drawing
/// stored in Firebase. Contains a function for converting to Firebase.
class Section with JsonToString {
  final String sectionLink;

  Section({required this.sectionLink});

  Section.empty()
      : sectionLink = 'Empty sectionLink. SectionLink has not been set yet.';

  factory Section.fromJson(Map<String, dynamic> json) {
    if (json case {'sectionLink': String sectionLink}) {
      if (sectionLink.isNotEmpty) {
        return Section(sectionLink: sectionLink);
      }
    }
    return Section(sectionLink: 'Error retrieving file. File not retrieved.');
  }

  @override
  Map<String, String> toJson() {
    return {'sectionLink': sectionLink};
  }
}

/// Class for section cutter test info and methods.
class SectionCutterTest extends Test<Section> with JsonToString {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'section_cutter_tests';
  static const String displayName = 'Section Cutter';

  static final CollectionReference<SectionCutterTest> converterRef = _firestore
      .collection(collectionIDStatic)
      .withConverter<SectionCutterTest>(
        fromFirestore: (snapshot, _) =>
            SectionCutterTest.fromJson(snapshot.data()!),
        toFirestore: (test, _) => test.toJson(),
      );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  /// Line used for taking section. Standing point equivalent for this test.
  List<LatLng> linePoints;

  /// Creates a new [SectionCutterTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  SectionCutterTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    required this.linePoints,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for Map for Test.createNew
    Test.newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String id,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      List? standingPoints,
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        SectionCutterTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: Section.empty(),
          linePoints: (standingPoints as List<LatLng>?) ?? [],
        );

    // Register for Map for Test.recreateFromDoc
    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return SectionCutterTest.fromJson(testDoc.data()!);
    };

    // Register for Map for Test.getPage
    Test.pageBuilders[SectionCutterTest] =
        (project, test) => SectionCutterTestPage(
              activeProject: project,
              activeTest: test as SectionCutterTest,
            );

    Test.standingPointTestCollectionIDs.add(collectionIDStatic);
    Test.testInitialsMap[SectionCutterTest] = 'SC';
  }

  @override
  void submitData(Section data) async {
    try {
      // Updates data in Firestore
      await _firestore.collection(collectionID).doc(id).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In SectionCutterTest.submitData. firestoreData = $data');
    } catch (e, stacktrace) {
      print("Exception in SectionCutterTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  factory SectionCutterTest.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'title': String title,
          'id': String id,
          'scheduledTime': Timestamp scheduledTime,
          'project': DocumentReference project,
          'data': Map<String, dynamic> data,
          'creationTime': Timestamp creationTime,
          'maxResearchers': int maxResearchers,
          'isComplete': bool isComplete,
          'linePoints': List linePoints,
        }) {
      return SectionCutterTest._(
        title: title,
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        data: Section.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        linePoints: List<GeoPoint>.from(linePoints).toLatLngList(),
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': id,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
      'linePoints': linePoints.toGeoPointList(),
    };
  }

  /// Saves given [XFile] under the test's project reference.
  ///
  /// Takes in the given data and saves it according to its corresponding
  /// project reference, under its given test id. Then, returns a [Section]
  /// where the path to the file is saved in the [sectionLink] field.
  Future<Section> saveXFile(XFile data) async {
    Section? section;
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final sectionRef = storageRef
          .child("project_uploads/${projectRef.id}/section_cutter_files/$id");
      final File sectionFile = File(data.path);

      print(sectionRef.fullPath);
      section = Section(sectionLink: sectionRef.fullPath);
      await sectionRef.putFile(sectionFile);
    } catch (e, stacktrace) {
      print("Error in SectionCutterTest.saveXFile(): $e");
      print("Stacktrace: $stacktrace");
    }

    // Section should only be null if the file fails to save to Firebase.
    return section ??
        Section(sectionLink: 'Error saving file. File not saved.');
  }
}
