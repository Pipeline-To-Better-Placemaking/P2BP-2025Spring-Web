import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firestore_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// User class for create_project_and_teams.dart
class Member {
  String _userID = '';
  String _fullName = '';
  bool _invited = false;

  Member(
      {required String userID,
      required String fullName,
      bool invited = false}) {
    _userID = userID;
    _fullName = fullName;
    _invited = invited;
  }
  void setUserID(String userID) {
    _userID = userID;
  }

  void setFullName(String fullName) {
    _fullName = fullName;
  }

  void setInvited(bool invited) {
    _invited = invited;
  }

  String getUserID() {
    return _userID;
  }

  String getFullName() {
    return _fullName;
  }

  bool getInvited() {
    return _invited;
  }
}

// Team class for teams_and_invites_page.dart
class Team {
  Timestamp? creationTime;
  String adminName = '';
  String teamID = '';
  String title = '';
  List teamMembers = [];
  List projects = [];
  int numProjects = 0;

  Team(
      {required this.teamID,
      required this.title,
      required this.adminName,
      required this.projects,
      required this.numProjects});

  // Specifically for a team invite. Invite does not need numProjects, projects,
  // etc.
  Team.teamInvite({
    required this.teamID,
    required this.title,
    required this.adminName,
  });
}

// Project class for project creation (create project + map)
class Project {
  Timestamp? creationTime;
  DocumentReference? teamRef;
  String projectID = '';
  String title = '';
  String description = '';
  List polygonPoints = [];
  num polygonArea = 0;
  List<Test>? tests = [];

  Project(
      {this.creationTime,
      required this.teamRef,
      required this.projectID,
      required this.title,
      required this.description,
      required this.polygonPoints,
      required this.polygonArea,
      this.tests});

  // TODO: Eventually add Team Photo and Team Color
  Project.partialProject({required this.title, required this.description});
}

/// Parent class extended by every specific test class.
///
/// Each specific test will most likely have a different format for data
/// which needs to be specified around the implementation and used in place
/// of generic type [T] in each subclass.
///
/// Additionally, each subclass is expected to statically define constants
/// for the associated collection ID in Firestore and the basic structure
/// used for that test's [data] for initialization.
abstract class Test<T> {
  /// The time this [Test] was initially created at.
  late Timestamp creationTime;

  String title = '';
  String testID = '';

  /// The time scheduled for this test to be completed.
  ///
  /// For most tests this is the time that the test should be completed at
  /// but for some like 'Section cutter' and 'Identify programs' it is more
  /// like a deadline for the latest it should be completed by.
  Timestamp scheduledTime;

  /// The [DocumentReference] pointing to the project in which this [Test]
  /// resides.
  DocumentReference? projectRef;

  /// Maximum researchers that can complete this test.
  ///
  /// Currently always 1.
  late int maxResearchers;

  /// Instance member using custom data type for each specific test
  /// implementation for storing test data.
  ///
  /// Initial framework for storing data for each test should be defined in
  /// each implementation as the value returned from
  /// `getInitialDataStructure()`, as this is used for initializing `data`
  /// when it is not defined in the constructor.
  late T data;

  /// The collection ID used in Firestore for this specific test.
  ///
  /// Each implementation of [Test] should statically define its
  /// collection ID for comparison in factory constructors and possibly
  /// other use cases, but it is also assigned to this instance member
  /// for no particular reason.
  late final String collectionID;

  /// Whether this test has been completed by a surveyor yet.
  bool isComplete = false;

  /// Creates a new [Test] instance from the given arguments.
  ///
  /// Used for all creation of [Test] subclasses through super-constructor
  /// calls through factory constructors, so all logic for when certain
  /// values are not provided should be here.
  ///
  /// This is private because the only intended usage is through various
  /// static methods acting as factory constructors.
  Test._({
    required this.title,
    required this.testID,
    required this.scheduledTime,
    required this.projectRef,
    required this.collectionID,
    required this.data,
    Timestamp? creationTime,
    int? maxResearchers,
    bool? isComplete,
  }) {
    this.creationTime = creationTime ?? Timestamp.now();
    this.maxResearchers = maxResearchers ?? 1;
    this.isComplete = isComplete ?? false;
  }

  /// Returns a new instance of the [Test] subclass associated with
  /// [collectionID].
  ///
  /// This is the real 'factory constructor' always used for creating instances
  /// of any [Test] subclass, but is private and called by the various public
  /// static methods acting like factory constructors.
  ///
  /// Throws an exception if the given [collectionID] does not match any of
  /// the subclasses that have been included here.
  ///
  /// Every new subclass of [Test] is expected to have a case added to this
  /// method for its statically defined [collectionID] and using its
  /// unnamed constructor and statically defined initial structure for [data]
  /// when [data] is not provided.
  static Test _create({
    required String title,
    required String testID,
    required Timestamp scheduledTime,
    required DocumentReference projectRef,
    required String collectionID,
    dynamic data,
    Timestamp? creationTime,
    int? maxResearchers,
    bool? isComplete,
  }) {
    switch (collectionID) {
      case LightingProfileTest.collectionIDStatic:
        return LightingProfileTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: (data != null && data is LightToGeoPointMap) // Verify type
              ? LightingProfileTest.convertDataFromFirestore(data)
              : LightingProfileTest.initialDataStructure,
          creationTime: creationTime,
          maxResearchers: maxResearchers,
          isComplete: isComplete,
        );
      case SectionCutterTest.collectionIDStatic:
        return SectionCutterTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: (data != null && data is String) // Verify type
              ? {"sectionLink": data}
              : SectionCutterTest.initialDataStructure,
          creationTime: creationTime,
          maxResearchers: maxResearchers,
          isComplete: isComplete,
        );
      default:
        throw Exception('Invalid collectionID used with Test.createNew()');
    }
  }

  /// Returns a new instance of the [Test] subclass associated with
  /// [collectionID].
  ///
  /// This acts as a factory constructor and is intended to be used for
  /// any newly created tests.
  static Test createNew({
    required String title,
    required String testID,
    required Timestamp scheduledTime,
    required DocumentReference projectRef,
    required String collectionID,
  }) {
    return _create(
      title: title,
      testID: testID,
      scheduledTime: scheduledTime,
      projectRef: projectRef,
      collectionID: collectionID,
    );
  }

  /// Returns a new instance of the [Test] subclass appropriate for the
  /// given [testDoc] based on the collection it is from.
  ///
  /// This acts as a factory constructor for tests which already exist in
  /// Firestore.
  static Test recreateFromDoc(DocumentSnapshot<Map<String, dynamic>> testDoc) {
    return _create(
      title: testDoc['title'],
      testID: testDoc['id'],
      scheduledTime: testDoc['scheduledTime'],
      projectRef: testDoc['project'],
      collectionID: testDoc.reference.parent.id,
      data: testDoc['data'],
      creationTime: testDoc['creationTime'],
      maxResearchers: testDoc['maxResearchers'],
      isComplete: testDoc['isComplete'],
    );
  }

  /// Checks if given [Test] has the specified generic type which extends
  /// [Test] and if so returns it as that type. Otherwise returns `null`.
  static S? castTo<S extends Test>(Test test) {
    if (test is S) {
      return (test as S);
    } else {
      return null;
    }
  }

  /// Uploads the data from a completed test to Firestore.
  ///
  /// Used on completion of a test and should be passed all data
  /// collected throughout the duration of the test.
  ///
  /// Updates this test instance in Firestore with
  /// this new data and marks the test as complete; `isComplete = true`.
  /// This will need to change if more than 1 researcher is allowed per test.
  void submitData(T data);
}

/// Types of light for lighting profile test.
enum LightType { rhythmic, building, task }

// Author's note: I hate the names I used for both of these typedefs but I've
// already changed it/them so many times and I still cannot think of a better
// or shorter naming scheme for them so it is what it is.
/// Convenience alias for `LightingProfileTest` format used for `data`
/// locally (in Flutter/Dart).
typedef LightToLatLngMap = Map<LightType, Set<LatLng>>;

/// Convenience alias for `LightingProfileTest` format used for `data`
/// retrieved from Firestore.
typedef LightToGeoPointMap = Map<String, List<GeoPoint>>;

/// Class for lighting profile test info and methods.
class LightingProfileTest extends Test<LightToLatLngMap> {
  /// Hard-coded definition of basic structure for `data`
  /// used for initialization of new lighting tests.
  static const LightToLatLngMap initialDataStructure = {
    LightType.rhythmic: {},
    LightType.building: {},
    LightType.task: {},
  };

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'lighting_profile_tests';

  /// Creates a new [LightingProfileTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  LightingProfileTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  @override
  void submitData(LightToLatLngMap data) async {
    this.data = data;

    // Adds all points of each type from submitted data to overall data
    LightToGeoPointMap firestoreData = convertDataToFirestore(data);

    // Updates data in Firestore
    await _firestore.collection(collectionID).doc(testID).update({
      'data': firestoreData,
      'isComplete': true,
    });

    print(
        'Success! In LightingProfileTest.submitData. firestoreData = $firestoreData');
  }

  /// Transforms data retrieved from Firestore test instance to
  /// [LightToLatLngMap] for local manipulation.
  static LightToLatLngMap convertDataFromFirestore(LightToGeoPointMap data) {
    LightToLatLngMap output = initialDataStructure;
    List<LightType> types = LightType.values;

    // Adds all data from parameter to output one type at a time
    for (final type in types) {
      if (data.containsKey(type.name) && data[type.name] is List) {
        for (final geopoint in data[type.name]!) {
          output[type]?.add(geopoint.toLatLng());
        }
      }
    }

    return output;
  }

  /// Transforms data stored locally as [LightToLatLngMap] to
  /// Firestore format (represented by [LightToGeoPointMap])
  /// with String keys and any other needed changes.
  static LightToGeoPointMap convertDataToFirestore(LightToLatLngMap data) {
    LightToGeoPointMap output = {};
    List<LightType> types = LightType.values;

    for (final type in types) {
      output[type.name] = [];
      if (data.containsKey(type) && data[type] is Set) {
        for (final latlng in data[type]!) {
          output[type.name]?.add(latlng.toGeoPoint());
        }
      }
    }

    return output;
  }
}

/// Class for section cutter test info and methods.
class SectionCutterTest extends Test<Map<String, String>> {
  /// Default structure for Section Cutter test. Simply a [Map<String, String>],
  /// where the first string is the field and the second is the reference which
  /// refers to the path of the section drawing.
  static const Map<String, String> initialDataStructure = {"sectionLink": " "};

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'section_cutter_tests';

  /// Creates a new [SectionCutterTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  SectionCutterTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  @override
  void submitData(Map<String, String> data) async {
    try {
      // Updates data in Firestore
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data,
        'isComplete': true,
      });

      print('Success! In SectionCutterTest.submitData. firestoreData = $data');
    } catch (e, stacktrace) {
      print("Exception in SectionCutterTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  Future<Map<String, String>> saveXFile(XFile data) async {
    Map<String, String> storageLocation = initialDataStructure;
    try {
      if (projectRef == null) return storageLocation;
      final storageRef = FirebaseStorage.instance.ref();
      final sectionRef = storageRef.child(
          "project_uploads/${projectRef?.id}/section_cutter_files/$testID");
      final File sectionFile = File(data.path);

      print(sectionRef.fullPath);
      storageLocation = {"sectionLink": sectionRef.fullPath};
      await sectionRef.putFile(sectionFile);
    } catch (e, stacktrace) {
      print("Error in SectionCutterTest.saveXFile(): $e");
      print("Stacktrace: $stacktrace");
    }

    return storageLocation;
  }
}