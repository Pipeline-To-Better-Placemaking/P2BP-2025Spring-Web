import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart';
import 'firestore_functions.dart';
import 'package:flutter/material.dart';
import 'google_maps_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

import 'identifying_access_test.dart';
import 'nature_prevalence_test.dart';
import 'absence_of_order_test.dart';
import 'lighting_profile_test.dart';
import 'section_cutter_test.dart';
import 'spatial_boundaries_test.dart';
import 'people_in_place_test.dart';
import 'people_in_motion_test.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// User class for create_project_and_teams.dart
class Member {
  String userID = '';
  String fullName = '';
  bool invited = false;

  Member({required this.userID, required this.fullName, this.invited = false});
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
  List<LatLng> polygonPoints = [];
  num polygonArea = 0;
  List<DocumentReference> testRefs = [];
  List<Test>? tests;
  List<StandingPoint> standingPoints = [];

  Project({
    this.creationTime,
    required this.teamRef,
    required this.projectID,
    required this.title,
    required this.description,
    required this.polygonPoints,
    required this.polygonArea,
    required this.standingPoints,
    required this.testRefs,
    this.tests,
  });

  // TODO: Eventually add Team Photo and Team Color
  Project.partialProject({required this.title, required this.description});

  // TODO: Probably want to delete test if test reference is not found; however, functionality may be unnecessary if the implementation of deleting a test deletes it from the project also (which is ideal).
  /// Gets all fields for each [Test] in this [Project] and loads them
  /// into the [tests]. Also returns [tests].
  Future<List<Test>> loadAllTestData() async {
    List<Test> tests = [];
    for (final ref in testRefs) {
      if (ref is DocumentReference<Map<String, dynamic>>) {
        tests.add(await getTestInfo(ref));
      }
    }
    this.tests = tests;
    return tests;
  }
}

/// Comparison function for tests. Used in [.sort].
///
/// Sorts based on scheduled time.
/// The tests are split further into two categories completed and not completed.
/// For completed tests, simply sort by scheduled time.
/// For non-completed tests, sort first by whether the date has passed. This gives two more groups.
/// Sort both by their scheduled time.
int testTimeComparison(Test a, Test b) {
  Timestamp currentTime = Timestamp.now();
  if (a.isComplete) {
    // If a and b are both complete
    if (b.isComplete) {
      return a.scheduledTime.compareTo(b.scheduledTime);
    }
    // If a is complete and b is not
    else {
      return 2;
    }
  }
  // If a is not complete and b is
  else if (b.isComplete) {
    return -2;
  }
  // If both a and b are not complete
  else {
    // If a's time has passed
    if (a.scheduledTime.compareTo(currentTime) > 0) {
      // If b's time has also passed
      if (b.scheduledTime.compareTo(currentTime) > 0) {
        return a.scheduledTime.compareTo(b.scheduledTime);
      }
      // Else if a's time has not passed, but b's has
      else {
        return -3;
      }
    }
    // Else if a's time has passed
    else {
      return 3;
    }
  }
}

// *--------------------------------------------------------------------------*
// | Important: When adding a test, make sure to implement the requisite      |
// | fields and functions. When done, make sure to implement it in the        |
// | dropdown on create_test_form.dart, register it on main.dart, and add it  |
// | to the initials list on project_details.dart. If it it implements        |
// | standing points and a timer, add it to the following lists.              |
// *--------------------------------------------------------------------------*

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
  DocumentReference projectRef;

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
  T data;

  /// The collection ID used in Firestore for this specific test.
  ///
  /// Each implementation of [Test] should statically define its
  /// collection ID for comparison against this field in
  /// factory constructors and other use cases.
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
  /// public methods acting as factory constructors.
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
  })  : creationTime = creationTime ?? Timestamp.now(),
        maxResearchers = maxResearchers ?? 1,
        isComplete = isComplete ?? false;

  // The below Maps must have values registered for each subclass of Test.
  // Thus each subclass should have a method `static void register()`
  // which adds the appropriate values to each Map.

  /// Maps from the collection ID of each [Test] subclass to a function
  /// which should use a constructor of that [Test] type to make a new instance
  /// of said [Test].
  static final Map<
      String,
      Test Function({
        required String title,
        required String testID,
        required Timestamp scheduledTime,
        required DocumentReference projectRef,
        required String collectionID,
        List? standingPoints,
      })> _newTestConstructors = {};

  /// Maps from collection ID to a function which should use a constructor
  /// to make and return a [Test] object from the existing information
  /// given in [testDoc].
  static final Map<String,
          Test Function(DocumentSnapshot<Map<String, dynamic>>)>
      _recreateTestConstructors = {};

  /// Maps from a [Type] assumed to be a subclass of [Test] to the page
  /// for completing that [Test].
  static final Map<Type, Widget Function(Project, Test)> _pageBuilders = {};

  /// Maps from [Type] assumed to extend [Test] to the function used to
  /// save that [Test] instance to Firestore.
  static final Map<Type, Future<void> Function(Test)>
      _saveToFirestoreFunctions = {};

  /// Set used internally to determine whether a [Test] subclass uses
  /// standing points. Subclasses that do are expected to register themselves
  /// into this set.
  static final Set<String> _standingPointTestCollectionIDs = {};

  /// Set containing all tests that make use of timers.
  ///
  /// Used to check for test creation and saving.
  static final Set<String> _timerTestCollectionIDs = {};

  /// Returns a new instance of the [Test] subclass associated with
  /// [collectionID].
  ///
  /// This acts as a factory constructor and is intended to be used for
  /// any newly created tests.
  ///
  /// Utilizes values registered to [Test._newTestConstructors].
  static Test createNew(
      {required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints}) {
    final constructor = _newTestConstructors[collectionID];

    if (constructor != null) {
      return constructor(
        title: title,
        testID: testID,
        scheduledTime: scheduledTime,
        projectRef: projectRef,
        collectionID: collectionID,
        standingPoints: standingPoints,
      );
    }
    throw Exception('Unregistered Test type for collection: $collectionID');
  }

  /// Returns a new instance of the [Test] subclass appropriate for the
  /// given [testDoc] based on the collection it is from.
  ///
  /// This acts as a factory constructor for tests which already exist in
  /// Firestore.
  ///
  /// Utilizes values registered to [Test._recreateTestConstructors].
  static Test recreateFromDoc(DocumentSnapshot<Map<String, dynamic>> testDoc) {
    final constructor = _recreateTestConstructors[testDoc.reference.parent.id];
    if (constructor != null) {
      return constructor(testDoc);
    }
    throw Exception(
        'Unregistered Test type for collection: ${testDoc.reference.parent.id}');
  }

  /// Returns the [Widget] of the page used to complete this type of [Test]
  /// with the given [Test] and [Project] parameters already given.
  ///
  /// Basically when you want to navigate to [Test] completion page just use
  /// `test.getPage(project)` as the page given to a Navigator function.
  Widget getPage(Project project) {
    final pageBuilder = _pageBuilders[runtimeType];
    if (pageBuilder != null) {
      return pageBuilder(project, this);
    }
    throw Exception('No registered page for test type: $runtimeType');
  }

  Future<void> saveToFirestore() {
    final saveFunction = _saveToFirestoreFunctions[runtimeType];
    if (saveFunction != null) {
      return saveFunction(this);
    }
    throw Exception(
        'No registered saveToFirestore function for test type: $runtimeType');
  }

  /// Returns whether [Test] subclass with given [collectionID] is
  /// registered as a standing points test.
  static bool isStandingPointTest(String? collectionID) {
    return _standingPointTestCollectionIDs.contains(collectionID);
  }

  @override
  String toString() {
    return 'This is an instance of $runtimeType\n'
        'title: ${this.title}\n'
        'testID: ${this.testID}\n'
        'scheduledTime: ${this.scheduledTime}\n'
        'projectRef: ${this.projectRef}\n'
        'collectionID: ${this.collectionID}\n'
        'data: ${this.data}\n'
        'creationTime: ${this.creationTime}\n'
        'maxResearchers: ${this.maxResearchers}\n'
        'isComplete: ${this.isComplete}\n';
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

class StandingPoint with JsonToString {
  late final LatLng location;
  late final String title;

  StandingPoint({required this.location, required this.title});

  StandingPoint.fromJson(Map<String, dynamic> data) {
    if (data.containsKey('point') && data['point'] is GeoPoint) {
      location = (data['point'] as GeoPoint).toLatLng();
    }
    if (data.containsKey('title') && data['title'] is String) {
      title = data['title'] as String;
    }
  }

  @override
  Map<String, Object> toJson() {
    return {
      'point': location.toGeoPoint(),
      'title': title,
    };
  }

  static List<StandingPoint> fromJsonList(List points) {
    List<StandingPoint> output = [];
    for (final point in points) {
      if (point is Map<String, dynamic>) {
        output.add(StandingPoint.fromJson(point));
      }
    }
    return output;
  }

  static List<Map<String, Object>> toJsonList(List<StandingPoint> points) {
    List<Map<String, Object>> json = [];
    for (final point in points) {
      json.add(point.toJson());
    }
    return json;
  }
}

/// Mixin to add toString functionality to any class with a toJson() method.
mixin JsonToString {
  @override
  String toString() {
    return toJson().toString();
  }

  Map<String, Object?> toJson();
}

/// Types of light for lighting profile test.
enum LightType { rhythmic, building, task }

class Light {
  final LightType lightType;
  final LatLng point;

  Light({
    required this.lightType,
    required this.point,
  });
}

class LightingProfileData with JsonToString {
  List<Light> lights = [];

  LightingProfileData();

  LightingProfileData.fromJson(Map<String, dynamic> data) {
    List<LightType> types = LightType.values;
    for (final type in types) {
      if (data.containsKey(type.name) && (data[type.name] as List).isNotEmpty) {
        for (final light in data[type.name]) {
          if (light is GeoPoint) {
            lights.add(Light(
              point: light.toLatLng(),
              lightType: type,
            ));
          }
        }
      }
    }
  }

  @override
  Map<String, Object> toJson() {
    // Create base map with each light type mapping to empty list
    List<LightType> types = LightType.values;
    Map<String, List> json = {
      for (final type in types) type.name: [],
    };

    // Loop through all lights and add to map based on type
    for (final light in lights) {
      json[light.lightType.name]!.add(light.point.toGeoPoint());
    }

    return json;
  }
}

/// Class for Lighting Profile Test info and methods.
class LightingProfileTest extends Test<LightingProfileData> with JsonToString {
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

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Lighting Profile Tests
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        LightingProfileTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: LightingProfileData(),
        );
    // Register for recreating a Lighting Profile Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return LightingProfileTest.fromJson(testDoc.data()!);
    };
    // Register for building a Lighting Profile Test page
    Test._pageBuilders[LightingProfileTest] =
        (project, test) => LightingProfileTestPage(
              activeProject: project,
              activeTest: test as LightingProfileTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[LightingProfileTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<LightingProfileTest>(
            fromFirestore: (snapshot, _) =>
                LightingProfileTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as LightingProfileTest, SetOptions(merge: true));
    };
  }

  @override
  void submitData(LightingProfileData data) async {
    try {
      // Updates data in Firestore
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In LightingProfileTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in LightingProfileTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  static LightingProfileTest fromJson(Map<String, dynamic> doc) {
    return LightingProfileTest._(
      title: doc['title'],
      testID: doc['id'],
      scheduledTime: doc['scheduledTime'],
      projectRef: doc['project'],
      collectionID: collectionIDStatic,
      data: LightingProfileData.fromJson(doc['data']),
      creationTime: doc['creationTime'],
      maxResearchers: doc['maxResearchers'],
      isComplete: doc['isComplete'],
    );
  }

  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': testID,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
    };
  }
}

/// Parent class for data classes which need a single location point.
///
/// Created for use with [BehaviorPoint] and [MaintenancePoint] in
/// [AbsenceOfOrderTest], but could potentially be used for other similar
/// data types which use a single point with an arbitrary amount of other
/// attributes attached to it.
abstract class DataPoint {
  LatLng? location;

  DataPoint({this.location});
}

/// Class for points representing instances of Behavior Misconduct in
/// [AbsenceOfOrderTest].
class BehaviorPoint extends DataPoint with JsonToString {
  bool boisterousVoice;
  bool dangerousWildlife;
  bool livingInPublic;
  bool panhandling;
  bool recklessBehavior;
  bool unsafeEquipment;
  String other;

  BehaviorPoint({
    required super.location,
    required this.boisterousVoice,
    required this.dangerousWildlife,
    required this.livingInPublic,
    required this.panhandling,
    required this.recklessBehavior,
    required this.unsafeEquipment,
    required this.other,
  });

  /// Constructor not requiring a location. Used when setting description
  /// of misconduct before placing point on [AbsenceOfOrderTestPage].
  BehaviorPoint.noLocation({
    required this.boisterousVoice,
    required this.dangerousWildlife,
    required this.livingInPublic,
    required this.panhandling,
    required this.recklessBehavior,
    required this.unsafeEquipment,
    required this.other,
  });

  /// Directly takes a Json-type object and returns a new [BehaviorPoint]
  /// created with that data.
  static BehaviorPoint fromJson(Map<String, dynamic> dataPoint) {
    return BehaviorPoint(
      location: (dataPoint['location'] as GeoPoint).toLatLng(),
      boisterousVoice: dataPoint['boisterousVoice'],
      dangerousWildlife: dataPoint['dangerousWildlife'],
      livingInPublic: dataPoint['livingInPublic'],
      panhandling: dataPoint['panhandling'],
      recklessBehavior: dataPoint['recklessBehavior'],
      unsafeEquipment: dataPoint['unsafeEquipment'],
      other: dataPoint['other'],
    );
  }

  /// Returns a new Json-type object containing all properties of this
  /// [BehaviorPoint].
  ///
  /// Converts the [location] to [GeoPoint] since that is the type
  /// used in Firestore. This leads to [location] not being as easily
  /// converted to a String as the rest of the properties.
  @override
  Map<String, Object?> toJson() {
    return {
      'location': location?.toGeoPoint(),
      'boisterousVoice': boisterousVoice,
      'dangerousWildlife': dangerousWildlife,
      'livingInPublic': livingInPublic,
      'panhandling': panhandling,
      'recklessBehavior': recklessBehavior,
      'unsafeEquipment': unsafeEquipment,
      'other': other,
    };
  }
}

/// Class for points representing instances of Maintenance Misconduct in
/// [AbsenceOfOrderTest].
class MaintenancePoint extends DataPoint with JsonToString {
  bool brokenEnvironment;
  bool dirtyOrUnmaintained;
  bool littering;
  bool overfilledTrash;
  bool unkeptLandscape;
  bool unwantedGraffiti;
  String other;

  MaintenancePoint({
    required super.location,
    required this.brokenEnvironment,
    required this.dirtyOrUnmaintained,
    required this.littering,
    required this.overfilledTrash,
    required this.unkeptLandscape,
    required this.unwantedGraffiti,
    required this.other,
  });

  /// Constructor not requiring a location. Used when setting description
  /// of misconduct before placing point on [AbsenceOfOrderTestPage].
  MaintenancePoint.noLocation({
    required this.brokenEnvironment,
    required this.dirtyOrUnmaintained,
    required this.littering,
    required this.overfilledTrash,
    required this.unkeptLandscape,
    required this.unwantedGraffiti,
    required this.other,
  });

  /// Directly takes a Json-type object and returns a new [MaintenancePoint]
  /// created with that data.
  static MaintenancePoint fromJson(Map<String, dynamic> dataPoint) {
    return MaintenancePoint(
      location: (dataPoint['location'] as GeoPoint).toLatLng(),
      brokenEnvironment: dataPoint['brokenEnvironment'],
      dirtyOrUnmaintained: dataPoint['dirtyOrUnmaintained'],
      littering: dataPoint['littering'],
      overfilledTrash: dataPoint['overfilledTrash'],
      unkeptLandscape: dataPoint['unkeptLandscape'],
      unwantedGraffiti: dataPoint['unwantedGraffiti'],
      other: dataPoint['other'],
    );
  }

  /// Returns a new Json-type object containing all properties of this
  /// [MaintenancePoint].
  ///
  /// Converts the [location] to [GeoPoint] since that is the type
  /// used in Firestore. This leads to [location] not being as easily
  /// converted to a String as the rest of the properties.
  @override
  Map<String, Object?> toJson() {
    return {
      'location': location?.toGeoPoint(),
      'brokenEnvironment': brokenEnvironment,
      'dirtyOrUnmaintained': dirtyOrUnmaintained,
      'littering': littering,
      'overfilledTrash': overfilledTrash,
      'unkeptLandscape': unkeptLandscape,
      'unwantedGraffiti': unwantedGraffiti,
      'other': other,
    };
  }
}

/// Class representing the data format used for [AbsenceOfOrderTest].
///
/// This is used as the generic type in the definition
/// of [AbsenceOfOrderTest].
class AbsenceOfOrderData with JsonToString {
  final List<BehaviorPoint> behaviorList = [];
  final List<MaintenancePoint> maintenanceList = [];

  AbsenceOfOrderData();

  /// Creates an [AbsenceOfOrderData] object from a Json-type object.
  ///
  /// Used for recreating data instances from existing
  /// [AbsenceOfOrderTest] instances in Firestore.
  AbsenceOfOrderData.fromJson(Map<String, dynamic> data) {
    if (data.containsKey('behaviorPoints') &&
        (data['behaviorPoints'] as List).isNotEmpty) {
      for (final point in data['behaviorPoints'] as List) {
        behaviorList.add(BehaviorPoint.fromJson(point));
      }
    }
    if (data.containsKey('maintenancePoints') &&
        (data['maintenancePoints'] as List).isNotEmpty) {
      for (final point in data['maintenancePoints'] as List) {
        maintenanceList.add(MaintenancePoint.fromJson(point));
      }
    }
  }

  /// Returns a new Json-type object containing all data from this
  /// [AbsenceOfOrderData] object.
  ///
  /// Used when submitting a new [AbsenceOfOrderData] object from
  /// a completed [AbsenceOfOrderTest] to get the correct format for
  /// Firestore.
  @override
  Map<String, Object> toJson() {
    Map<String, List<Map<String, dynamic>?>> json = {
      'behaviorPoints': [],
      'maintenancePoints': [],
    };
    for (final behavior in behaviorList) {
      json['behaviorPoints']!.add(behavior.toJson());
    }
    for (final maintenance in maintenanceList) {
      json['maintenancePoints']!.add(maintenance.toJson());
    }
    return json;
  }

  /// Adds given [dataPoint] to the appropriate List in this data set.
  ///
  /// An exception is thrown if [dataPoint] has a null `location`.
  void addDataPoint(DataPoint dataPoint) {
    if (dataPoint.location == null) {
      print(
          'Error: dataPoint in AbsenceOfOrderTest.addDataPoint has no location');
      throw Exception('null-location-on-datapoint');
    }
    if (dataPoint is BehaviorPoint) {
      behaviorList.add(dataPoint);
      return;
    }
    if (dataPoint is MaintenancePoint) {
      maintenanceList.add(dataPoint);
      return;
    }
  }

  /// Removes all data points where [location] matches the given [point]
  /// from both Lists.
  void removeDataPoint(LatLng point) {
    behaviorList
        .removeWhere((behaviorPoint) => behaviorPoint.location == point);
    maintenanceList
        .removeWhere((maintenancePoint) => maintenancePoint.location == point);
  }
}

/// Class for Absence of Order Test info and methods.
class AbsenceOfOrderTest extends Test<AbsenceOfOrderData> with JsonToString {
  static const String collectionIDStatic = 'absence_of_order_tests';

  /// Creates a new [AbsenceOfOrderTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  AbsenceOfOrderTest._({
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

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Absence of Order Tests
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        AbsenceOfOrderTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: AbsenceOfOrderData(),
        );
    // Register for recreating an Absence of Order Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return AbsenceOfOrderTest.fromJson(testDoc.data()!);
    };
    // Register for building an Absence of Order Test page
    Test._pageBuilders[AbsenceOfOrderTest] =
        (project, test) => AbsenceOfOrderTestPage(
              activeProject: project,
              activeTest: test as AbsenceOfOrderTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[AbsenceOfOrderTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<AbsenceOfOrderTest>(
            fromFirestore: (snapshot, _) =>
                AbsenceOfOrderTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as AbsenceOfOrderTest, SetOptions(merge: true));
    };
  }

  @override
  void submitData(AbsenceOfOrderData data) async {
    try {
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In AbsenceOfOrder.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in AbsenceOfOrderTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  /// Returns a new [AbsenceOfOrderTest] instance created from Json-type
  /// object [doc].
  ///
  /// Typically, [doc] is a representation of an existing
  /// [AbsenceOfOrderTest] in Firestore and this is used for recreating
  /// that [Test] object.
  static AbsenceOfOrderTest fromJson(Map<String, dynamic> doc) {
    return AbsenceOfOrderTest._(
      title: doc['title'],
      testID: doc['id'],
      scheduledTime: doc['scheduledTime'],
      projectRef: doc['project'],
      collectionID: collectionIDStatic,
      data: AbsenceOfOrderData.fromJson(doc['data']),
      creationTime: doc['creationTime'],
      maxResearchers: doc['maxResearchers'],
      isComplete: doc['isComplete'],
    );
  }

  /// Returns a Json-type object representing this [AbsenceOfOrderTest]
  /// object.
  ///
  /// Typically used when saving or updating this object to get the
  /// correct format for Firestore.
  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': testID,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
    };
  }
}

enum BoundaryType { constructed, material, shelter }

enum ConstructedBoundaryType {
  curb,
  buildingWall,
  fence,
  planter,
  partialWall,
}

enum MaterialBoundaryType {
  pavers,
  concrete,
  tile,
  natural,
  decking,
}

enum ShelterBoundaryType {
  canopy,
  tree,
  furniture,
  temporary,
  constructed,
}

class ConstructedBoundary {
  static Color polylineColor = Colors.purpleAccent;
  late final Polyline polyline;
  late final double polylineLength;
  final ConstructedBoundaryType constructedType;

  ConstructedBoundary({
    required this.polyline,
    required this.constructedType,
  }) : polylineLength = polyline.getLengthInFeet();

  ConstructedBoundary.recreate({
    required this.polyline,
    required this.polylineLength,
    required this.constructedType,
  });
}

class MaterialBoundary {
  late final Polygon polygon;
  late final double polygonArea;
  final MaterialBoundaryType materialType;

  MaterialBoundary({
    required this.polygon,
    required this.materialType,
  }) : polygonArea = polygon.getAreaInSquareFeet();

  MaterialBoundary.recreate({
    required this.polygon,
    required this.polygonArea,
    required this.materialType,
  });
}

class ShelterBoundary {
  late final Polygon polygon;
  late final double polygonArea;
  final ShelterBoundaryType shelterType;

  ShelterBoundary({
    required this.polygon,
    required this.shelterType,
  }) : polygonArea = polygon.getAreaInSquareFeet();

  ShelterBoundary.recreate({
    required this.polygon,
    required this.polygonArea,
    required this.shelterType,
  });
}

class SpatialBoundariesData with JsonToString {
  final List<ConstructedBoundary> constructed = [];
  final List<MaterialBoundary> material = [];
  final List<ShelterBoundary> shelter = [];

  SpatialBoundariesData();

  SpatialBoundariesData.fromJson(Map<String, dynamic> data) {
    if (data.containsKey(BoundaryType.constructed.name) &&
        (data[BoundaryType.constructed.name] as Map).isNotEmpty) {
      final constructedData = data[BoundaryType.constructed.name];
      List<ConstructedBoundaryType> types = ConstructedBoundaryType.values;
      for (final type in types) {
        if (constructedData.containsKey(type.name) &&
            (constructedData[type.name] as List).isNotEmpty) {
          for (final boundary in (constructedData[type.name] as List)) {
            // Try to create polyline from existing and only add if successful
            List points = boundary['polyline'];
            Polyline? polyline = createPolyline(
                points.toLatLngList(), ConstructedBoundary.polylineColor);
            if (polyline != null) {
              constructed.add(ConstructedBoundary.recreate(
                polyline: polyline,
                polylineLength: boundary['polylineLength'],
                constructedType: type,
              ));
            }
          }
        }
      }
    }
    if (data.containsKey(BoundaryType.material.name) &&
        (data[BoundaryType.material.name] as Map).isNotEmpty) {
      final materialData = data[BoundaryType.material.name];
      List<MaterialBoundaryType> types = MaterialBoundaryType.values;
      for (final type in types) {
        if (materialData.containsKey(type.name) &&
            (materialData[type.name] as List).isNotEmpty) {
          for (final boundary in (materialData[type.name] as List)) {
            List points = boundary['polygon'];
            Polygon polygon = Polygon(
              polygonId:
                  PolygonId(DateTime.now().millisecondsSinceEpoch.toString()),
              points: points.toLatLngList(),
            );
            material.add(MaterialBoundary.recreate(
              polygon: polygon,
              polygonArea: boundary['polygonArea'],
              materialType: type,
            ));
          }
        }
      }
    }
    if (data.containsKey(BoundaryType.shelter.name) &&
        (data[BoundaryType.shelter.name] as Map).isNotEmpty) {
      final shelterData = data[BoundaryType.shelter.name];
      List<ShelterBoundaryType> types = ShelterBoundaryType.values;
      for (final type in types) {
        if (shelterData.containsKey(type.name) &&
            (shelterData[type.name] as List).isNotEmpty) {
          for (final boundary in (shelterData[type.name] as List)) {
            List points = boundary['polygon'];
            Polygon polygon = Polygon(
              polygonId:
                  PolygonId(DateTime.now().millisecondsSinceEpoch.toString()),
              points: points.toLatLngList(),
            );
            shelter.add(ShelterBoundary.recreate(
              polygon: polygon,
              polygonArea: boundary['polygonArea'],
              shelterType: type,
            ));
          }
        }
      }
    }
  }

  @override
  Map<String, Object> toJson() {
    List<ConstructedBoundaryType> constructedTypes =
        ConstructedBoundaryType.values;
    List<MaterialBoundaryType> materialTypes = MaterialBoundaryType.values;
    List<ShelterBoundaryType> shelterTypes = ShelterBoundaryType.values;
    Map<String, Map<String, List>> json = {
      BoundaryType.constructed.name: {
        for (final type in constructedTypes) type.name: []
      },
      BoundaryType.material.name: {
        for (final type in materialTypes) type.name: []
      },
      BoundaryType.shelter.name: {
        for (final type in shelterTypes) type.name: []
      },
    };

    for (final boundary in constructed) {
      json[BoundaryType.constructed.name]![boundary.constructedType.name]?.add({
        'polyline': boundary.polyline.toGeoPointList(),
        'polylineLength': boundary.polylineLength,
      });
    }
    for (final boundary in material) {
      json[BoundaryType.material.name]![boundary.materialType.name]?.add({
        'polygon': boundary.polygon.toGeoPointList(),
        'polygonArea': boundary.polygonArea,
      });
    }
    for (final boundary in shelter) {
      json[BoundaryType.shelter.name]![boundary.shelterType.name]?.add({
        'polygon': boundary.polygon.toGeoPointList(),
        'polygonArea': boundary.polygonArea,
      });
    }

    return json;
  }
}

class SpatialBoundariesTest extends Test<SpatialBoundariesData>
    with JsonToString {
  static const String collectionIDStatic = 'spatial_boundaries_tests';

  SpatialBoundariesTest._({
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

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Spatial Boundaries Tests
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        SpatialBoundariesTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: SpatialBoundariesData(),
        );
    // Register for recreating a Spatial Boundaries Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return SpatialBoundariesTest.fromJson(testDoc.data()!);
    };
    // Register for building a Spatial Boundaries Test page
    Test._pageBuilders[SpatialBoundariesTest] =
        (project, test) => SpatialBoundariesTestPage(
              activeProject: project,
              activeTest: test as SpatialBoundariesTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[SpatialBoundariesTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<SpatialBoundariesTest>(
            fromFirestore: (snapshot, _) =>
                SpatialBoundariesTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as SpatialBoundariesTest, SetOptions(merge: true));
    };
  }

  @override
  void submitData(SpatialBoundariesData data) async {
    try {
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In SpatialBoundariesTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in SpatialBoundariesTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  static SpatialBoundariesTest fromJson(Map<String, dynamic> doc) {
    return SpatialBoundariesTest._(
      title: doc['title'],
      testID: doc['id'],
      scheduledTime: doc['scheduledTime'],
      projectRef: doc['project'],
      collectionID: collectionIDStatic,
      data: SpatialBoundariesData.fromJson(doc['data']),
      creationTime: doc['creationTime'],
      maxResearchers: doc['maxResearchers'],
      isComplete: doc['isComplete'],
    );
  }

  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': testID,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
    };
  }
}

/// Simple class for Section Cutter Test.
///
/// Contains a [sectionLink] variable which refers to the section drawing
/// stored in Firebase. Contains a function for converting to Firebase.
class Section with JsonToString {
  final String sectionLink;

  Section({required this.sectionLink});

  Section.empty()
      : sectionLink = 'Empty sectionLink. SectionLink has not been set yet.';

  static Section fromJson(Map<String, dynamic> data) {
    Section? output;
    if (data.containsKey('sectionLink') && data['sectionLink'] is String) {
      output = Section(sectionLink: data['sectionLink']);
    }
    return output ??
        Section(sectionLink: 'Error retrieving file. File not retrieved.');
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

  /// Line used for taking section. Standing point equivalent for this test.
  List<LatLng> linePoints;

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
    required this.linePoints,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for Map for Test.createNew
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        SectionCutterTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: Section.empty(),
          linePoints: (standingPoints as List<LatLng>?) ?? [],
        );
    // Register for Map for Test.recreateFromDoc
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return SectionCutterTest.fromJson(testDoc.data()!);
    };
    // Register for Map for Test.getPage
    Test._pageBuilders[SectionCutterTest] = (project, test) => SectionCutter(
          projectData: project,
          activeTest: test as SectionCutterTest,
        );
    // Register for Map for Test.saveToFirestore
    // Standing points are saved under line, as they will be made to create
    // a polyline, instead of displayed as individual points.
    Test._saveToFirestoreFunctions[SectionCutterTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<SectionCutterTest>(
            fromFirestore: (snapshot, _) =>
                SectionCutterTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as SectionCutterTest, SetOptions(merge: true));
    };
    Test._standingPointTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  void submitData(Section data) async {
    try {
      // Updates data in Firestore
      await _firestore.collection(collectionID).doc(testID).update({
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

  static SectionCutterTest fromJson(Map<String, dynamic> doc) {
    return SectionCutterTest._(
      title: doc['title'],
      testID: doc['id'],
      scheduledTime: doc['scheduledTime'],
      projectRef: doc['project'],
      collectionID: collectionIDStatic,
      data: Section.fromJson(doc['data']),
      creationTime: doc['creationTime'],
      maxResearchers: doc['maxResearchers'],
      isComplete: doc['isComplete'],
      linePoints: (doc['linePoints'] as List).toLatLngList(),
    );
  }

  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': testID,
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
      final sectionRef = storageRef.child(
          "project_uploads/${projectRef.id}/section_cutter_files/$testID");
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

/// Enum types for Identifying Access test:
/// [bikeRack], [taxiAndRideShare], [parking], or [transportStation]
enum AccessType { bikeRack, taxiAndRideShare, parking, transportStation }

/// Interface for Access Types. All Access Types must implement this interface
/// and its functions.
abstract class AccessTypes {
  // Constants for all access types:
  static const Cap startCap = Cap.roundCap;
  static const int polylineWidth = 3;

  /// Uses the class fields to create a [Map] that is able to be stored in
  /// Firestore easily.
  Map<String, dynamic> convertToFirestoreData();
}

class AccessData implements AccessTypes {
  List<BikeRack> bikeRacks = [];
  List<TaxiAndRideShare> taxisAndRideShares = [];
  List<Parking> parkingStructures = [];
  List<TransportStation> transportStations = [];

  @override

  /// Transforms data stored locally as a [List]s of access type objects to
  /// Firestore format (represented by a [Map])
  /// with String keys and any other needed changes.
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, List> output = {
      AccessType.bikeRack.name: [],
      AccessType.taxiAndRideShare.name: [],
      AccessType.parking.name: [],
      AccessType.transportStation.name: [],
    };

    for (BikeRack bikeRack in bikeRacks) {
      output[AccessType.bikeRack.name]?.add(bikeRack.convertToFirestoreData());
    }
    for (TaxiAndRideShare taxisAndRideShare in taxisAndRideShares) {
      output[AccessType.taxiAndRideShare.name]
          ?.add(taxisAndRideShare.convertToFirestoreData());
    }
    for (TransportStation transportStation in transportStations) {
      output[AccessType.transportStation.name]
          ?.add(transportStation.convertToFirestoreData());
    }
    for (Parking parking in parkingStructures) {
      output[AccessType.parking.name]?.add(parking.convertToFirestoreData());
    }
    return output;
  }
}

/// Bike rack type for Identifying Access test. Enum type [bikeRack].
class BikeRack implements AccessTypes {
  static const AccessType type = AccessType.bikeRack;
  static const Color color = Colors.black;
  final int spots;
  final Polyline polyline;
  final double pathLength;

  BikeRack({required this.spots, required this.polyline})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
                .toDouble() *
            feetPerMeter;

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'spots': spots,
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength,
      }
    };
    return firestoreData;
  }
}

/// Taxi/ride share type for Identifying Access test. Enum type
/// [taxiAndRideShare].
class TaxiAndRideShare implements AccessTypes {
  static const AccessType type = AccessType.taxiAndRideShare;
  static const Color color = Colors.black;
  final Polyline polyline;
  final double pathLength;

  TaxiAndRideShare({required this.polyline})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
                .toDouble() *
            feetPerMeter;

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength
      }
    };
    return firestoreData;
  }
}

/// Parking type for Identifying Access test. Enum type [parking].
class Parking implements AccessTypes {
  static const AccessType type = AccessType.parking;
  static const Color color = Colors.black;
  final int spots;
  final Polygon polygon;
  final Polyline polyline;
  final double pathLength;
  final double polygonArea;

  Parking({required this.spots, required this.polyline, required this.polygon})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
                .toDouble() *
            feetPerMeter,
        polygonArea = (mp.SphericalUtil.computeArea(polygon.toMPLatLngList()) *
                pow(feetPerMeter, 2))
            .toDouble();

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'spots': spots,
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength,
      },
      'polygonInfo': {
        'polygon': polygon.points.toGeoPointList(),
        'polygonArea': polygonArea,
      }
    };
    return firestoreData;
  }
}

/// Transport station type for Identifying Access test. Enum type
/// [transportStation].
class TransportStation implements AccessTypes {
  static const AccessType type = AccessType.transportStation;
  static const Color color = Colors.black;
  final int routeNumber;
  final Polyline polyline;
  final double pathLength;

  TransportStation({required this.routeNumber, required this.polyline})
      : pathLength = mp.SphericalUtil.computeLength(polyline.toMPLatLngList())
                .toDouble() *
            feetPerMeter;

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {
      'routeNumber': routeNumber,
      'pathInfo': {
        'path': polyline.points.toGeoPointList(),
        'pathLength': pathLength,
      }
    };
    return firestoreData;
  }
}

/// Class for identifying access test info and methods.
class IdentifyingAccessTest extends Test<AccessData> {
  /// Returns a new instance of the initial data structure used for
  /// Identifying Access Test.
  static AccessData newInitialDataDeepCopy() {
    return AccessData();
  }

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'identifying_access_tests';

  /// Creates a new [IdentifyingAccessTest] instance from the given arguments.
  IdentifyingAccessTest._({
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

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Identifying Access Tests
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        IdentifyingAccessTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: newInitialDataDeepCopy(),
        );
    // Register for recreating a Identifying Access Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      print(testDoc['data']);
      return IdentifyingAccessTest._(
        title: testDoc['title'],
        testID: testDoc['id'],
        scheduledTime: testDoc['scheduledTime'],
        projectRef: testDoc['project'],
        collectionID: testDoc.reference.parent.id,
        data: convertDataFromFirestore(testDoc['data']),
        creationTime: testDoc['creationTime'],
        maxResearchers: testDoc['maxResearchers'],
        isComplete: testDoc['isComplete'],
      );
    };
    // Register for building a Identifying Access Test page
    Test._pageBuilders[IdentifyingAccessTest] =
        (project, test) => IdentifyingAccess(
              activeProject: project,
              activeTest: test as IdentifyingAccessTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[IdentifyingAccessTest] = (test) async {
      await _firestore.collection(test.collectionID).doc(test.testID).set({
        'title': test.title,
        'id': test.testID,
        'scheduledTime': test.scheduledTime,
        'project': test.projectRef,
        'data': convertDataToFirestore(test.data),
        'creationTime': test.creationTime,
        'maxResearchers': test.maxResearchers,
        'isComplete': false,
      }, SetOptions(merge: true));
    };
  }

  @override
  void submitData(AccessData data) async {
    // Adds all points of each type from submitted data to overall data
    Map firestoreData = convertDataToFirestore(data);

    // Updates data in Firestore
    await _firestore.collection(collectionID).doc(testID).update({
      'data': firestoreData,
      'isComplete': true,
    });

    this.data = data;
    isComplete = true;

    print(
        'Success! In IdentifyingAccessTest.submitData. firestoreData = $firestoreData');
  }

  /// Transforms data retrieved from Firestore test instance to
  /// a list of AccessType objects, with data accessed through the fields of
  /// the respective objects.
  static AccessData convertDataFromFirestore(Map<String, dynamic> data) {
    AccessData accessData = newInitialDataDeepCopy();
    List<AccessType> types = AccessType.values;
    List dataList;
    // Adds all data to output one type at a time
    for (final type in types) {
      if (data.containsKey(type.name)) {
        dataList = data[type.name];
        switch (type) {
          case AccessType.bikeRack:
            for (Map bikeRackMap in dataList) {
              if (bikeRackMap.containsKey('pathInfo') &&
                  bikeRackMap['pathInfo'].containsKey('path')) {
                List polylinePoints = bikeRackMap['pathInfo']['path'];
                accessData.bikeRacks.add(
                  BikeRack(
                    spots: bikeRackMap['spots'],
                    polyline: Polyline(
                      polylineId: PolylineId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      color: BikeRack.color,
                      width: AccessTypes.polylineWidth,
                      startCap: AccessTypes.startCap,
                      points: polylinePoints.toLatLngList(),
                    ),
                  ),
                );
              }
            }
          case AccessType.taxiAndRideShare:
            for (Map taxiRideShareMap in dataList) {
              if (taxiRideShareMap.containsKey('pathInfo') &&
                  taxiRideShareMap['pathInfo'].containsKey('path')) {
                List polylinePoints = taxiRideShareMap['pathInfo']['path'];
                accessData.taxisAndRideShares.add(
                  TaxiAndRideShare(
                    polyline: Polyline(
                      polylineId: PolylineId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      color: TaxiAndRideShare.color,
                      width: AccessTypes.polylineWidth,
                      startCap: AccessTypes.startCap,
                      points: polylinePoints.toLatLngList(),
                    ),
                  ),
                );
              }
            }
          case AccessType.parking:
            for (Map parkingMap in dataList) {
              if ((parkingMap.containsKey('pathInfo') &&
                      parkingMap['pathInfo'].containsKey('path')) &&
                  (parkingMap.containsKey('polygonInfo') &&
                      parkingMap['polygonInfo'].containsKey('polygon'))) {
                List polylinePoints = parkingMap['pathInfo']['path'];
                List polygonPoints = parkingMap['polygonInfo']['polygon'];
                accessData.parkingStructures.add(
                  Parking(
                    spots: parkingMap['spots'],
                    polyline: Polyline(
                        polylineId: PolylineId(
                            DateTime.now().millisecondsSinceEpoch.toString()),
                        color: Parking.color,
                        width: AccessTypes.polylineWidth,
                        startCap: AccessTypes.startCap,
                        points: polylinePoints.toLatLngList()),
                    polygon: Polygon(
                      polygonId: PolygonId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      points: polygonPoints.toLatLngList(),
                      fillColor: Color(0x55999999),
                    ),
                  ),
                );
              }
            }
          case AccessType.transportStation:
            for (Map transportStationMap in dataList) {
              if (transportStationMap.containsKey('pathInfo') &&
                  transportStationMap['pathInfo'].containsKey('path')) {
                List polylinePoints = transportStationMap['pathInfo']['path'];
                accessData.transportStations.add(
                  TransportStation(
                    routeNumber: transportStationMap['routeNumber'],
                    polyline: Polyline(
                        polylineId: PolylineId(
                            DateTime.now().millisecondsSinceEpoch.toString()),
                        color: TransportStation.color,
                        width: AccessTypes.polylineWidth,
                        startCap: AccessTypes.startCap,
                        points: polylinePoints.toLatLngList()),
                  ),
                );
              }
            }
        }
      }
    }
    return accessData;
  }

  static Map convertDataToFirestore(AccessData accessData) {
    return accessData.convertToFirestoreData();
  }
}

/// Enum for Nature Types. Used in Nature Prevalence test. Types include
/// [vegetation], [waterBody], and [animal].
enum NatureType { vegetation, waterBody, animal }

/// Enum for types of vegetation. Used in Nature Prevalence test. Types include
/// [native], [design], [openField], and [other].
enum VegetationType { native, design, openField, other }

/// Enum for types of bodies of water. Used in Nature Prevalence test. Types
/// include [ocean], [lake], [river], and [swamp].
enum WaterBodyType { ocean, lake, river, swamp }

/// Enum for types of animals. Used in Nature Prevalence test. Types include
/// [cat], [dog], [squirrel], [bird], [rabbit], [turtle], [duck], and [other].
/// </br> [cat] and [dog] are domestic, [other] is its own type, and all other
/// defined types are wild.
enum AnimalType { cat, dog, squirrel, bird, rabbit, turtle, duck, other }

/// The following designations are used to differentiate types of animals. They
/// include [domesticated], [wild], and [other]
enum AnimalDesignation { domesticated, wild, other }

/// Map used to match animal type with their respective designation.
Map<AnimalType, AnimalDesignation> animalToDesignation = {
  AnimalType.cat: AnimalDesignation.domesticated,
  AnimalType.dog: AnimalDesignation.domesticated,
  AnimalType.squirrel: AnimalDesignation.wild,
  AnimalType.bird: AnimalDesignation.wild,
  AnimalType.rabbit: AnimalDesignation.wild,
  AnimalType.turtle: AnimalDesignation.wild,
  AnimalType.duck: AnimalDesignation.wild,
  AnimalType.other: AnimalDesignation.other
};

/// Interface for Nature Types. All Nature Types must implement this interface
/// and its functions.
abstract class NatureTypes {
  /// Uses the class fields to create a [Map] that is able to be stored in
  /// Firestore easily.
  Map<String, dynamic> convertToFirestoreData();
}

/// Containing class for Nature Prevalence Test.
///
/// Contains a list of objects corresponding to the Nature Prevalence Test
/// types ([Animal], [WaterBody], [Vegetation]). Also implements the
/// [convertToFirestoreData()], which returns a map that is able to be inputted
/// directly into Firestore.
class NatureData implements NatureTypes {
  List<Animal> animals = [];
  List<WaterBody> waterBodies = [];
  List<Vegetation> vegetation = [];
  WeatherData? weather;

  @override
  Map<String, Map> convertToFirestoreData() {
    Map<String, Map> firestoreData = {};
    Map<String, dynamic> animalData = {
      AnimalDesignation.wild.name: {
        AnimalType.squirrel.name: [],
        AnimalType.bird.name: [],
        AnimalType.rabbit.name: [],
        AnimalType.turtle.name: [],
        AnimalType.duck.name: [],
      },
      AnimalDesignation.domesticated.name: {
        AnimalType.cat.name: [],
        AnimalType.dog.name: [],
      },
      AnimalDesignation.other.name: [],
    };
    Map<String, List> vegetationData = {
      VegetationType.native.name: [],
      VegetationType.design.name: [],
      VegetationType.openField.name: [],
      VegetationType.other.name: [],
    };
    Map<String, List> waterBodyData = {
      WaterBodyType.ocean.name: [],
      WaterBodyType.lake.name: [],
      WaterBodyType.river.name: [],
      WaterBodyType.swamp.name: [],
    };
    Map<String, dynamic> weatherData = {};
    try {
      if (weather == null) {
        throw Exception(
            "Weather not set in NatureType.convertToFirestoreData()!");
      } else {
        weatherData = weather!.convertToFirestoreData();
      }
      for (Animal animal in animals) {
        // Checks that the set contains the correct fields as needed, included
        // domestication designation and name, then adds the data accordingly.
        if (animal.animalType == AnimalType.other &&
            animalData.containsKey(animal.designation.name)) {
          animalData[animal.designation.name]
              ?.add(animal.convertToFirestoreData());
        } else if (animalData.containsKey(animal.designation.name) &&
            animalData[animal.designation.name]!
                .containsKey(animal.animalType.name)) {
          animalData[animal.designation.name]![animal.animalType.name]
              ?.add(animal.convertToFirestoreData()['point']);
        }
      }
      for (WaterBody waterBody in waterBodies) {
        waterBodyData[waterBody.waterBodyType.name]
            ?.add(waterBody.convertToFirestoreData());
      }
      for (Vegetation vegetation in vegetation) {
        vegetationData[vegetation.vegetationType.name]
            ?.add(vegetation.convertToFirestoreData());
      }
      firestoreData = {
        'weather': weatherData,
        NatureType.animal.name: animalData,
        NatureType.vegetation.name: vegetationData,
        NatureType.waterBody.name: waterBodyData,
      };
    } catch (e, stacktrace) {
      print("Error in NatureType.convertToFirestoreData(): $e");
      print("Stacktrace $stacktrace");
    }

    return firestoreData;
  }
}

/// Types of weather for Nature Prevalence. Types include [sunny], [cloudy],
/// [rainy], [windy], and [stormy].
enum Weather { sunny, cloudy, rainy, windy, stormy }

/// Class for weather in Nature Prevalence Test. Implements enum type
/// [weather].
class WeatherData implements NatureTypes {
  final List<Weather> weatherTypes;
  final double temp;

  WeatherData({required this.weatherTypes, required this.temp});

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {};
    Map<String, bool> weatherMap = {};
    try {
      // Initialize a map for Firestore with true or false depending on weather.
      for (Weather weatherType in Weather.values) {
        weatherTypes.contains(weatherType)
            ? weatherMap[weatherType.name] = true
            : weatherMap[weatherType.name] = false;
      }
      firestoreData = {
        'weatherTypes': weatherMap,
        'temperature': temp,
      };
    } catch (e, stacktrace) {
      print("Error in Vegetation.convertToFirestoreData(): $e");
      print("Stacktrace: $stacktrace");
    }
    return firestoreData;
  }
}

/// Class for vegetation in Nature Prevalence Test. Implements enum type
/// [vegetation].
class Vegetation implements NatureTypes {
  static const NatureType natureType = NatureType.vegetation;
  static const Map<VegetationType, Color> vegetationTypeToColor = {
    VegetationType.native: VegetationColors.nativeGreen,
    VegetationType.design: VegetationColors.designGreen,
    VegetationType.openField: VegetationColors.openFieldGreen,
    VegetationType.other: VegetationColors.otherGreen,
  };
  final Color polygonColor;
  final VegetationType vegetationType;
  final String? otherType;
  final Polygon polygon;
  final double polygonArea;

  /// For all vegetation, other or not, otherType is required. If the
  /// vegetation is of a defined type (i.e. not other) then set otherType equal
  /// to [null].
  /// </br> A [null] otherType will be ignored in convertToFirestoreData().
  Vegetation(
      {required this.vegetationType,
      required this.polygon,
      required this.otherType})
      : polygonArea = (mp.SphericalUtil.computeArea(polygon.toMPLatLngList()) *
                pow(feetPerMeter, 2))
            .toDouble(),
        polygonColor = vegetationTypeToColor[vegetationType] ??
            VegetationColors.otherGreen;

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {};
    try {
      if (vegetationType == VegetationType.other) {
        if (otherType == null) {
          throw Exception(
              "It seems that the selected type is other, however no otherType "
              "was specified or was specified as null. Please make sure "
              "to specify otherType.");
        }
        firestoreData = {
          'name': otherType,
          'polygon': polygon.points.toGeoPointList(),
          'polygonArea': polygonArea
        };
      } else {
        firestoreData = {
          'polygon': polygon.points.toGeoPointList(),
          'polygonArea': polygonArea
        };
      }
    } catch (e, stacktrace) {
      print("Error in Vegetation.convertToFirestoreData(): $e");
      print("Stacktrace: $stacktrace");
    }
    return firestoreData;
  }
}

/// Class for bodies of water in Nature Prevalence Test. Implements enum type
/// [waterBody].
class WaterBody implements NatureTypes {
  static const NatureType natureType = NatureType.waterBody;
  static const Map<WaterBodyType, Color> waterBodyTypeToColor = {
    WaterBodyType.ocean: WaterBodyColors.oceanBlue,
    WaterBodyType.river: WaterBodyColors.riverBlue,
    WaterBodyType.lake: WaterBodyColors.lakeBlue,
    WaterBodyType.swamp: WaterBodyColors.swampBlue,
  };
  final Color polygonColor;
  final WaterBodyType waterBodyType;
  final Polygon polygon;
  final double polygonArea;

  WaterBody({required this.waterBodyType, required this.polygon})
      : polygonArea = (mp.SphericalUtil.computeArea(polygon.toMPLatLngList()) *
                pow(feetPerMeter, 2))
            .toDouble(),
        polygonColor = waterBodyTypeToColor[waterBodyType] ?? Colors.blue;

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {};
    try {
      firestoreData = {
        'polygon': polygon.points.toGeoPointList(),
        'polygonArea': polygonArea
      };
    } catch (e, stacktrace) {
      print("Error in WaterBody.convertToFirestoreData(): $e");
      print("Stacktrace: $stacktrace");
    }
    return firestoreData;
  }
}

/// Class for animals in Nature Prevalence Test. Implements enum type [animal].
class Animal implements NatureTypes {
  static const NatureType natureType = NatureType.animal;
  final AnimalType animalType;
  final AnimalDesignation designation;
  final String? otherType;
  final LatLng point;

  /// For all animals, other or not, otherType is required. If the animal is
  /// of a defined type (i.e. not other) then set otherType equal to [null].
  /// </br> A [null] otherType will be ignored in convertToFirestoreData().
  Animal(
      {required this.animalType, required this.point, required this.otherType})
      // Map should never return [null]. Will produce a runtime error if that
      // happens.
      : designation = animalToDesignation[animalType]!;

  @override
  Map<String, dynamic> convertToFirestoreData() {
    Map<String, dynamic> firestoreData = {};
    try {
      if (animalType == AnimalType.other) {
        if (otherType == null) {
          throw Exception(
              "It seems that the selected type is other, however no otherType "
              "was specified or was specified as null. Please make sure "
              "to specify otherType.");
        }
        firestoreData = {
          'name': otherType,
          'point': point.toGeoPoint(),
        };
      } else {
        firestoreData = {
          'point': point.toGeoPoint(),
        };
      }
    } catch (e, stacktrace) {
      print("Error in Animal.convertToFirestoreData(): $e");
      print("Stacktrace: $stacktrace");
    }
    return firestoreData;
  }
}

/// Class for Nature Prevalence test info and methods.
class NaturePrevalenceTest extends Test<NatureData> {
  /// Returns a new instance of the initial data structure used for
  /// Nature Prevalence Test.
  static NatureData newInitialDataDeepCopy() {
    return NatureData();
  }

  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'nature_prevalence_tests';

  /// Creates a new [NaturePrevalenceTest] instance from the given arguments.
  NaturePrevalenceTest._({
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

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Nature Prevalence Tests
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        NaturePrevalenceTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: newInitialDataDeepCopy(),
        );
    // Register for recreating a Nature Prevalence Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return NaturePrevalenceTest._(
        title: testDoc['title'],
        testID: testDoc['id'],
        scheduledTime: testDoc['scheduledTime'],
        projectRef: testDoc['project'],
        collectionID: testDoc.reference.parent.id,
        data: convertDataFromFirestore(testDoc['data']),
        creationTime: testDoc['creationTime'],
        maxResearchers: testDoc['maxResearchers'],
        isComplete: testDoc['isComplete'],
      );
    };
    // Register for building a Nature Prevalence Test page
    Test._pageBuilders[NaturePrevalenceTest] =
        (project, test) => NaturePrevalence(
              activeProject: project,
              activeTest: test as NaturePrevalenceTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[NaturePrevalenceTest] = (test) async {
      await _firestore.collection(test.collectionID).doc(test.testID).set({
        'title': test.title,
        'id': test.testID,
        'scheduledTime': test.scheduledTime,
        'project': test.projectRef,
        'data': convertDataToFirestore(test.data),
        'creationTime': test.creationTime,
        'maxResearchers': test.maxResearchers,
        'isComplete': false,
      }, SetOptions(merge: true));
    };
    Test._timerTestCollectionIDs.add(collectionIDStatic);
  }

  @override

  /// Submits data to Firestore for Nature Prevalence Test.
  ///
  /// Unlike other tests, this [submitData()] function (for
  /// [NaturePrevalenceTest]) takes in a [NatureData] type.
  void submitData(NatureData data) async {
    // Adds all points of each type from submitted data to overall data
    Map firestoreData = data.convertToFirestoreData();

    // Updates data in Firestore
    await _firestore.collection(collectionID).doc(testID).update({
      'data': firestoreData,
      'isComplete': true,
    });

    this.data = data;
    isComplete = true;

    print(
        'Success! In NaturePrevalenceTest.submitData. firestoreData = $firestoreData');
  }

  /// Transforms data retrieved from Firestore test instance to
  /// a list of AccessType objects, with data accessed through the fields of
  /// the respective objects.
  static NatureData convertDataFromFirestore(Map<String, dynamic> data) {
    NatureData output = NatureData();
    List<Animal> animalList = [];
    List<WaterBody> waterBodyList = [];
    List<Vegetation> vegetationList = [];
    WeatherData? weatherData;
    List<Weather> weatherTypes = [];

    try {
      if (data.containsKey('weather')) {
        for (Weather weatherType in Weather.values) {
          if (data['weather'].containsKey(weatherType) &&
              data['weather'][weatherType] == true) {
            weatherTypes.add(weatherType);
          }
        }
        if (data['weather'].containsKey('temperature')) {
          weatherData = WeatherData(
              weatherTypes: weatherTypes, temp: data['weather']['temperature']);
        }
      }
      // Getting data from animal in Firestore
      if (data.containsKey(NatureType.animal.name)) {
        // For every animal type
        for (AnimalType animal in animalToDesignation.keys) {
          // If contains key corresponding to designation (domestic,
          // wild, other) and animal type.
          if (data[NatureType.animal.name]
              .containsKey(animalToDesignation[animal]?.name)) {
            if (animal == AnimalType.other) {
              // For every 'other' type of animal
              for (Map map in data[NatureType.animal.name]
                  [animalToDesignation[animal]?.name]) {
                animalList.add(
                  Animal(
                    animalType: animal,
                    point: (map['point'] as GeoPoint).toLatLng(),
                    otherType: map['name'],
                  ),
                );
              }
            } else if (data[NatureType.animal.name]
                    [animalToDesignation[animal]?.name]
                .containsKey(animal.name)) {
              // For every specified (non-other) type of animal
              for (GeoPoint coordinate in data[NatureType.animal.name]
                  [animalToDesignation[animal]?.name][animal.name]) {
                animalList.add(
                  Animal(
                    animalType: animal,
                    point: coordinate.toLatLng(),
                    otherType: null,
                  ),
                );
              }
            }
          }
        }
      }
      // Getting data from vegetation in Firestore
      if (data.containsKey(NatureType.vegetation.name)) {
        // For every kind of vegetation
        for (VegetationType vegetation in VegetationType.values) {
          if (data[NatureType.vegetation.name].containsKey(vegetation)) {
            if (vegetation == VegetationType.other) {
              // For every 'other' type of vegetation
              for (Map map in data[NatureType.vegetation.name]
                  [vegetation.name]) {
                vegetationList.add(
                  Vegetation(
                    otherType: map['name'],
                    vegetationType: vegetation,
                    polygon: Polygon(
                      polygonId: PolygonId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      points: map['polygon'].toLatLngList(),
                      fillColor: Vegetation.vegetationTypeToColor[vegetation] ??
                          VegetationColors.otherGreen,
                    ),
                  ),
                );
              }
            } else {
              // For every defined (non-other) type of vegetation
              for (Map map in data[NatureType.vegetation.name]
                  [vegetation.name]) {
                vegetationList.add(
                  Vegetation(
                    otherType: null,
                    vegetationType: vegetation,
                    polygon: Polygon(
                      polygonId: PolygonId(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      points: map['polygon'].toLatLngList(),
                      fillColor: Vegetation.vegetationTypeToColor[vegetation] ??
                          VegetationColors.otherGreen,
                    ),
                  ),
                );
              }
            }
          }
        }
      }
      // Getting data from waterBody in Firestore
      if (data.containsKey(NatureType.waterBody.name)) {
        // For every kind of body of water
        for (WaterBodyType waterBody in WaterBodyType.values) {
          if (data[NatureType.waterBody.name].containsKey(waterBody)) {
            // For every type of body of water (no 'other' type)
            for (Map map in data[NatureType.waterBody.name][waterBody.name]) {
              waterBodyList.add(
                WaterBody(
                  waterBodyType: waterBody,
                  polygon: Polygon(
                    polygonId: PolygonId(
                        DateTime.now().millisecondsSinceEpoch.toString()),
                    points: map['polygon'].toLatLngList(),
                    fillColor: WaterBody.waterBodyTypeToColor[waterBody] ??
                        WaterBodyColors.nullBlue,
                  ),
                ),
              );
            }
          }
        }
      }
      output.animals = animalList;
      output.vegetation = vegetationList;
      output.waterBodies = waterBodyList;
      if (weatherData == null) {
        throw Exception(
            "Weather is not defined in Firestore in Nature Prevalence test .");
      } else {
        output.weather = weatherData;
      }
    } catch (e, stacktrace) {
      print("Warning in NaturePrevalenceTest.convertDataFromFirestore(): $e");
      print("Stacktrace: $stacktrace");
    }

    return output;
  }

  /// Simply invokes the class method for [NatureData] to convert the data to
  /// the appropriate Firestore representation.
  static Map<String, Map> convertDataToFirestore(NatureData data) {
    return data.convertToFirestoreData();
  }
}

abstract interface class DisplayNameEnum {
  final String displayName;

  DisplayNameEnum({required this.displayName});

  /// Returns the enumerated type with the matching displayName.
  factory DisplayNameEnum.byDisplayName(String displayName) {
    throw UnimplementedError();
  }
}

enum AgeRangeType implements DisplayNameEnum {
  age0to14(displayName: '0-14'),
  age15to21(displayName: '15-21'),
  age22to30(displayName: '22-30'),
  age31to50(displayName: '31-50'),
  age51to65(displayName: '51-65'),
  age66andAbove(displayName: '66+');

  const AgeRangeType({required this.displayName});

  @override
  final String displayName;

  /// Returns the enumerated type with the matching displayName.
  factory AgeRangeType.byDisplayName(String displayName) {
    try {
      for (final type in AgeRangeType.values) {
        if (type.displayName == displayName) return type;
      }
      throw Exception('Invalid AgeRangeType displayName');
    } catch (e, s) {
      throw Exception('Error: $e\nStacktrace: $s');
    }
  }
}

enum GenderType implements DisplayNameEnum {
  male(displayName: 'Male'),
  female(displayName: 'Female'),
  nonbinary(displayName: 'Nonbinary'),
  unspecified(displayName: 'Unspecified');

  const GenderType({required this.displayName});

  @override
  final String displayName;

  /// Returns the enumerated type with the matching displayName.
  factory GenderType.byDisplayName(String displayName) {
    try {
      for (final type in GenderType.values) {
        if (type.displayName == displayName) return type;
      }
      throw Exception('Invalid GenderType displayName');
    } catch (e, s) {
      throw Exception('Error: $e\nStacktrace: $s');
    }
  }
}

enum ActivityTypeInPlace implements DisplayNameEnum {
  socializing(displayName: 'Socializing'),
  waiting(displayName: 'Waiting'),
  recreation(displayName: 'Recreation'),
  eating(displayName: 'Eating'),
  solitary(displayName: 'Solitary');

  const ActivityTypeInPlace({required this.displayName});

  @override
  final String displayName;

  /// Returns the enumerated type with the matching displayName.
  factory ActivityTypeInPlace.byDisplayName(String displayName) {
    try {
      for (final type in ActivityTypeInPlace.values) {
        if (type.displayName == displayName) return type;
      }
      throw Exception('Invalid ActivityTypeInPlace displayName');
    } catch (e, s) {
      throw Exception('Error: $e\nStacktrace: $s');
    }
  }
}

enum PostureType implements DisplayNameEnum {
  standing(displayName: 'Standing', color: Color(0xFF4285f4)),
  sitting(displayName: 'Sitting', color: Color(0xFF28a745)),
  layingDown(displayName: 'Laying Down', color: Color(0xFFc41484)),
  squatting(displayName: 'Squatting', color: Color(0xFF6f42c1));

  const PostureType({required this.displayName, required this.color});

  @override
  final String displayName;
  final Color color;

  /// Returns the enumerated type with the matching displayName.
  factory PostureType.byDisplayName(String displayName) {
    try {
      for (final type in PostureType.values) {
        if (type.displayName == displayName) return type;
      }
      throw Exception('Invalid PostureType displayName');
    } catch (e, s) {
      throw Exception('Error: $e\nStacktrace: $s');
    }
  }
}

class PersonInPlace with JsonToString {
  late final LatLng location;
  late final AgeRangeType ageRange;
  late final GenderType gender;
  late final Set<ActivityTypeInPlace> activities;
  late final PostureType posture;

  PersonInPlace({
    required this.location,
    required this.ageRange,
    required this.gender,
    required this.activities,
    required this.posture,
  });

  PersonInPlace.fromJson(Map<String, dynamic> data) {
    if (data.containsKey('location') && data['location'] is GeoPoint) {
      location = (data['location'] as GeoPoint).toLatLng();
    }
    if (data.containsKey('ageRange') && data['ageRange'] is String) {
      String ageString = data['ageRange'] as String;
      ageRange = AgeRangeType.values.byName(ageString);
    }
    if (data.containsKey('gender') && data['gender'] is String) {
      String genderString = data['gender'] as String;
      gender = GenderType.values.byName(genderString);
    }
    if (data.containsKey('activities') &&
        data['activities'] is List &&
        data['activities'].first is String) {
      List activityStrings = data['activities'];
      activities = {
        for (final string in activityStrings)
          ActivityTypeInPlace.values.byName(string)
      };
    }
    if (data.containsKey('posture') && data['posture'] is String) {
      String postureString = data['posture'] as String;
      posture = PostureType.values.byName(postureString);
    }
  }

  @override
  Map<String, Object> toJson() {
    return {
      'location': location.toGeoPoint(),
      'ageRange': ageRange.name,
      'gender': gender.name,
      'activities': <String>[for (final activity in activities) activity.name],
      'posture': posture.name,
    };
  }
}

class PeopleInPlaceData with JsonToString {
  final List<PersonInPlace> persons = [];

  PeopleInPlaceData();

  PeopleInPlaceData.fromJson(Map<String, dynamic> data) {
    if (data.containsKey('persons') &&
        (data['persons'] as List).isNotEmpty &&
        data['persons'].first is Map) {
      List personsJsonList = data['persons'];
      for (final personJson in personsJsonList) {
        persons.add(PersonInPlace.fromJson(personJson));
      }
    }
    print(this);
  }

  @override
  Map<String, Object> toJson() {
    return {'persons': persons.map((person) => person.toJson()).toList()};
  }
}

class PeopleInPlaceTest extends Test<PeopleInPlaceData> with JsonToString {
  static const String collectionIDStatic = 'people_in_place_tests';

  final List<StandingPoint> standingPoints;

  PeopleInPlaceTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    required this.standingPoints,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  static void register() {
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        PeopleInPlaceTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: PeopleInPlaceData(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
        );
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return PeopleInPlaceTest.fromJson(testDoc.data()!);
    };
    Test._pageBuilders[PeopleInPlaceTest] =
        (project, test) => PeopleInPlaceTestPage(
              activeProject: project,
              activeTest: test as PeopleInPlaceTest,
            );
    Test._saveToFirestoreFunctions[PeopleInPlaceTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter(
            fromFirestore: (snapshot, _) =>
                PeopleInPlaceTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as PeopleInPlaceTest, SetOptions(merge: true));
    };
    Test._standingPointTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  void submitData(PeopleInPlaceData data) async {
    try {
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In PeopleInPlaceTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in PeopleInPlaceTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  static PeopleInPlaceTest fromJson(Map<String, dynamic> doc) {
    return PeopleInPlaceTest._(
      title: doc['title'],
      testID: doc['id'],
      scheduledTime: doc['scheduledTime'],
      projectRef: doc['project'],
      collectionID: collectionIDStatic,
      data: PeopleInPlaceData.fromJson(doc['data']),
      creationTime: doc['creationTime'],
      maxResearchers: doc['maxResearchers'],
      isComplete: doc['isComplete'],
      standingPoints: StandingPoint.fromJsonList(doc['standingPoints']),
    );
  }

  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': testID,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
      'standingPoints': StandingPoint.toJsonList(standingPoints),
    };
  }
}

enum ActivityTypeInMotion implements DisplayNameEnum {
  walking(displayName: 'Walking', color: Colors.teal),
  running(displayName: 'Running', color: Colors.red),
  swimming(displayName: 'Swimming', color: Colors.cyan),
  activityOnWheels(displayName: 'Activity on Wheels', color: Colors.orange),
  handicapAssistedWheels(
      displayName: 'Handicap Assisted Wheels', color: Colors.purple);

  const ActivityTypeInMotion({
    required this.displayName,
    required this.color,
  });

  @override
  final String displayName;
  final Color color;

  factory ActivityTypeInMotion.byDisplayName(String displayName) {
    try {
      for (final type in ActivityTypeInMotion.values) {
        if (type.displayName == displayName) return type;
      }
      throw Exception('Invalid ActivityTypeInMotion displayName');
    } catch (e, s) {
      throw Exception('Error: $e\nStacktrace: $s');
    }
  }
}

class PersonInMotion {
  late final Polyline polyline;
  late final double polylineLength;
  late final ActivityTypeInMotion activity;

  PersonInMotion({required this.polyline, required this.activity})
      : polylineLength = polyline.getLengthInFeet();

  PersonInMotion.recreate({
    required this.polyline,
    required this.polylineLength,
    required this.activity,
  });
}

class PeopleInMotionData with JsonToString {
  final List<PersonInMotion> persons = [];

  PeopleInMotionData();

  PeopleInMotionData.fromJson(Map<String, dynamic> data) {
    for (final type in ActivityTypeInMotion.values) {
      if (data.containsKey(type.name) && (data[type.name] as List).isNotEmpty) {
        for (final person in data[type.name] as List) {
          List points = person['polyline'];
          Polyline? polyline =
              createPolyline(points.toLatLngList(), type.color);
          if (polyline != null) {
            persons.add(PersonInMotion.recreate(
              polyline: polyline,
              polylineLength: person['polylineLength'],
              activity: type,
            ));
          }
        }
      }
    }
    print(this);
  }

  @override
  Map<String, Object> toJson() {
    // Initialize map with a field for each activity type with empty list
    Map<String, List<Map<String, Object>>> json = {
      for (final type in ActivityTypeInMotion.values) type.name: []
    };

    // Add each person data stored in persons to the appropriate list.
    for (final person in persons) {
      json[person.activity.name]!.add({
        'polyline': person.polyline.toGeoPointList(),
        'polylineLength': person.polylineLength,
      });
    }

    return json;
  }
}

class PeopleInMotionTest extends Test<PeopleInMotionData> with JsonToString {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'people_in_motion_tests';

  final List<StandingPoint> standingPoints;

  /// Private constructor for PeopleInMotionTest.
  PeopleInMotionTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    required this.standingPoints,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  /// Registers this test type in the Test class system.
  static void register() {
    // Register for creating new instances
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
    }) =>
        PeopleInMotionTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: PeopleInMotionData(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
        );
    // Register for recreating from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return PeopleInMotionTest.fromJson(testDoc.data()!);
    };
    // Register the test's UI page
    Test._pageBuilders[PeopleInMotionTest] =
        (project, test) => PeopleInMotionTestPage(
              activeProject: project,
              activeTest: test as PeopleInMotionTest,
            );
    // Register the save function
    Test._saveToFirestoreFunctions[PeopleInMotionTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<PeopleInMotionTest>(
            fromFirestore: (snapshot, _) =>
                PeopleInMotionTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as PeopleInMotionTest, SetOptions(merge: true));
    };
    Test._standingPointTestCollectionIDs.add(collectionIDStatic);
  }

  /// Handles data submission to Firestore when the test is completed.
  @override
  void submitData(PeopleInMotionData data) async {
    try {
      // Update Firestore with the test data and mark it as complete
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! PeopleInMotionTest data submitted. data = $data');
    } catch (e, stacktrace) {
      print("Exception in PeopleInMotionTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  static PeopleInMotionTest fromJson(Map<String, dynamic> doc) {
    return PeopleInMotionTest._(
      title: doc['title'],
      testID: doc['id'],
      scheduledTime: doc['scheduledTime'],
      projectRef: doc['project'],
      collectionID: collectionIDStatic,
      data: PeopleInMotionData.fromJson(doc['data']),
      creationTime: doc['creationTime'],
      maxResearchers: doc['maxResearchers'],
      isComplete: doc['isComplete'],
      standingPoints: StandingPoint.fromJsonList(doc['standingPoints']),
    );
  }

  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': testID,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
      'standingPoints': StandingPoint.toJsonList(standingPoints),
    };
  }
}