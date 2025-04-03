import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'absence_of_order_test.dart';
import 'acoustic_profile_test.dart';
import 'assets.dart';
import 'google_maps_functions.dart';
import 'lighting_profile_test.dart';
import 'people_in_motion_test.dart';
import 'people_in_place_test.dart';
import 'section_cutter_test.dart';
import 'spatial_boundaries_test.dart';

import 'firestore_functions.dart';
import 'identifying_access_test.dart';
import 'nature_prevalence_test.dart';

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

  Team({
    required this.teamID,
    required this.title,
    required this.adminName,
    required this.projects,
    required this.numProjects,
  });

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
  DocumentReference? projectAdmin;
  String projectID = '';
  String title = '';
  String description = '';
  String address = '';
  List<LatLng> polygonPoints = [];
  num polygonArea = 0;
  List<DocumentReference> testRefs = [];
  List<Test>? tests;
  List<StandingPoint> standingPoints = [];

  Project({
    this.creationTime,
    required this.teamRef,
    required this.projectAdmin,
    required this.projectID,
    required this.title,
    required this.description,
    required this.address,
    required this.polygonPoints,
    required this.polygonArea,
    required this.standingPoints,
    required this.testRefs,
    this.tests,
  });

  // TODO: Eventually add Team Photo and Team Color
  Project.partialProject(
      {required this.title, required this.description, required this.address});

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
        int? testDuration,
        int? intervalDuration,
        int? intervalCount,
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

  static final Map<Type, String> _testInitialsMap = {};

  /// Set used internally to determine whether a [Test] subclass uses
  /// standing points. Subclasses that do are expected to register themselves
  /// into this set.
  static final Set<String> _standingPointTestCollectionIDs = {};

  /// Set containing all tests that make use of timers.
  ///
  /// Used to check for test creation and saving.
  static final Set<String> _timerTestCollectionIDs = {};

  /// Set containing all tests that use a timer with intervals.
  ///
  /// Used to check for test creation and saving.
  static final Set<String> _intervalTimerTestCollectionIDs = {};

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
      List? standingPoints,
      int? testDuration,
      int? intervalDuration,
      int? intervalCount}) {
    final constructor = _newTestConstructors[collectionID];

    if (constructor != null) {
      return constructor(
        title: title,
        testID: testID,
        scheduledTime: scheduledTime,
        projectRef: projectRef,
        collectionID: collectionID,
        standingPoints: standingPoints,
        testDuration: testDuration,
        intervalDuration: intervalDuration,
        intervalCount: intervalCount,
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

  /// Returns whether [Test] subclass with given [collectionID] is
  /// registered as a timer test.
  static bool isTimerTest(String? collectionID) {
    return _timerTestCollectionIDs.contains(collectionID);
  }

  /// Returns whether [Test] subclass with given collection ID is
  /// registered as an interval timer test.
  static bool isIntervalTimerTest(String? collectionID) {
    return _intervalTimerTestCollectionIDs.contains(collectionID);
  }

  /// Returns 2-letter initials for given test type if they are registered.
  String getInitials() {
    return _testInitialsMap[runtimeType] ?? '';
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

  factory StandingPoint.fromJson(Map<String, dynamic> data) {
    if (data
        case {
          'point': GeoPoint location,
          'title': String title,
        }) {
      return StandingPoint(location: location.toLatLng(), title: title);
    }
    throw FormatException('Invalid JSON: $data', data);
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
}

extension StandingPointListHelpers on List<StandingPoint> {
  List<Map<String, Object>> toJsonList() {
    return [for (final point in this) point.toJson()];
  }
}

/// Class to be implemented by all Test subclasses which use standing points.
///
/// Using this also requires that the class run
/// [Test._standingPointTestCollectionIDs.add(collectionIDStatic)]
/// in its register method to be recognized as using standing points.
abstract interface class StandingPointTest {
  final List<StandingPoint> standingPoints = [];
}

/// Class to be implemented by all Test subclasses which use a timer.
///
/// Using this also requires that the class run
/// [Test._timerTestCollectionIDs.add(collectionIDStatic)]
/// in its register method to be recognized as using a timer.
abstract interface class TimerTest {
  final int testDuration;

  TimerTest(this.testDuration);
}

abstract interface class IntervalTimerTest {
  final int intervalDuration;
  final int intervalCount;

  IntervalTimerTest(this.intervalDuration, this.intervalCount);
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
enum LightType implements DisplayNameEnum {
  rhythmic(
    displayName: 'Rhythmic',
    iconName: 'assets/test_specific/lighting_profile/rhythmic-light.png',
  ),
  building(
    displayName: 'Building',
    iconName: 'assets/test_specific/lighting_profile/building-light.png',
  ),
  task(
    displayName: 'Task',
    iconName: 'assets/test_specific/lighting_profile/task-light.png',
  );

  const LightType({
    required this.displayName,
    required this.iconName,
  });

  @override
  final String displayName;
  final String iconName;
}

class Light {
  final LightType lightType;
  final Marker marker;

  Light({
    required this.lightType,
    required this.marker,
  });

  factory Light.fromLatLng(LatLng location, LightType type) {
    return Light(
      lightType: type,
      marker: Marker(
        markerId: MarkerId(location.toString()),
        position: location,
        consumeTapEvents: true,
        icon: lightingProfileIconMap[type]!,
      ),
    );
  }
}

class LightingProfileData with JsonToString {
  final List<Light> lights;

  LightingProfileData(this.lights);
  LightingProfileData.empty() : lights = <Light>[];

  factory LightingProfileData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'rhythmic': List rhythmic,
          'building': List building,
          'task': List task,
        }) {
      return LightingProfileData([
        if (rhythmic.isNotEmpty)
          for (final GeoPoint light in rhythmic)
            Light.fromLatLng(light.toLatLng(), LightType.rhythmic),
        if (building.isNotEmpty)
          for (final GeoPoint light in building)
            Light.fromLatLng(light.toLatLng(), LightType.building),
        if (task.isNotEmpty)
          for (final GeoPoint light in task)
            Light.fromLatLng(light.toLatLng(), LightType.task),
      ]);
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    Map<String, List> json = {
      for (final type in LightType.values) type.name: [],
    };

    for (final light in lights) {
      json[light.lightType.name]!.add(light.marker.position.toGeoPoint());
    }

    return json;
  }
}

/// Class for Lighting Profile Test info and methods.
class LightingProfileTest extends Test<LightingProfileData>
    with JsonToString
    implements TimerTest {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'lighting_profile_tests';
  static const String displayName = 'Lighting Profile';

  @override
  final int testDuration;

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
    required this.testDuration,
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
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        LightingProfileTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: LightingProfileData.empty(),
          testDuration: testDuration ?? -1,
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
    Test._testInitialsMap[LightingProfileTest] = 'LP';
    Test._timerTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  void submitData(LightingProfileData data) async {
    try {
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

  factory LightingProfileTest.fromJson(Map<String, dynamic> json) {
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
          'testDuration': int testDuration,
        }) {
      return LightingProfileTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: LightingProfileData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        testDuration: testDuration,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      'testDuration': testDuration,
    };
  }
}

enum MisconductType implements DisplayNameEnum {
  behavior(
    displayName: 'Behavior',
    iconName: 'assets/test_specific/absence_of_order_locator/'
        'behavior-misconduct.png',
  ),
  maintenance(
    displayName: 'Maintenance',
    iconName: 'assets/test_specific/absence_of_order_locator/'
        'maintenance-misconduct.png',
  );

  const MisconductType({
    required this.displayName,
    required this.iconName,
  });

  @override
  final String displayName;
  final String iconName;
}

enum BehaviorType implements DisplayNameEnum {
  boisterousVoice(displayName: 'Boisterous Voice'),
  dangerousWildlife(displayName: 'Dangerous Wildlife'),
  livingInPublic(displayName: 'Living in Public'),
  panhandling(displayName: 'Panhandling'),
  recklessBehavior(displayName: 'Reckless Behavior'),
  unsafeEquipment(displayName: 'Unsafe Equipment'),
  other(displayName: 'Other');

  const BehaviorType({required this.displayName});

  @override
  final String displayName;
}

enum MaintenanceType implements DisplayNameEnum {
  brokenEnvironment(displayName: 'Broken Environment'),
  dirtyOrUnmaintained(displayName: 'Dirty/Unmaintained'),
  littering(displayName: 'Littering'),
  overfilledTrash(displayName: 'Overfilled Trashcan'),
  unkeptLandscape(displayName: 'Unkept Landscape'),
  unwantedGraffiti(displayName: 'Unwanted Graffiti'),
  other(displayName: 'Other');

  const MaintenanceType({required this.displayName});

  @override
  final String displayName;
}

class BehaviorMisconduct with JsonToString {
  static const MisconductType misconductType = MisconductType.behavior;

  final Marker marker;
  final Set<BehaviorType> behaviorTypes;
  final String other;

  BehaviorMisconduct({
    required this.marker,
    required this.behaviorTypes,
    required this.other,
  }) {
    final hasOther = behaviorTypes.contains(BehaviorType.other);
    if ((hasOther && other.isEmpty) || (!hasOther && other.isNotEmpty)) {
      throw Exception('Other mismatch when constructing BehaviorMisconduct');
    }
  }

  factory BehaviorMisconduct.fromLatLng(
      LatLng location, Set<BehaviorType> behaviorTypes, String other) {
    return BehaviorMisconduct(
      marker: Marker(
        markerId: MarkerId(location.toString()),
        position: location,
        consumeTapEvents: true,
        icon: absenceOfOrderIconMap[misconductType]!,
      ),
      behaviorTypes: behaviorTypes.toSet(),
      other: other,
    );
  }

  factory BehaviorMisconduct.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'location': GeoPoint location,
          'behaviorTypes': List behaviorTypes,
          'other': String other,
        }) {
      if (behaviorTypes.isNotEmpty) {
        final point = location.toLatLng();
        return BehaviorMisconduct(
          marker: Marker(
            markerId: MarkerId(point.toString()),
            position: point,
            consumeTapEvents: true,
            icon: absenceOfOrderIconMap[misconductType]!,
          ),
          behaviorTypes: behaviorTypes
              .map((string) => BehaviorType.values.byName(string))
              .toSet(),
          other: other,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'location': marker.position.toGeoPoint(),
      'behaviorTypes': behaviorTypes.map((behavior) => behavior.name).toList(),
      'other': other,
    };
  }
}

class MaintenanceMisconduct with JsonToString {
  static const MisconductType misconductType = MisconductType.maintenance;

  final Marker marker;
  final Set<MaintenanceType> maintenanceTypes;
  final String other;

  MaintenanceMisconduct({
    required this.marker,
    required this.maintenanceTypes,
    required this.other,
  }) {
    final hasOther = maintenanceTypes.contains(MaintenanceType.other);
    if ((hasOther && other.isEmpty) || (!hasOther && other.isNotEmpty)) {
      throw Exception('Other mismatch when constructing MaintenanceMisconduct');
    }
  }

  factory MaintenanceMisconduct.fromLatLng(
      LatLng location, Set<MaintenanceType> maintenanceTypes, String other) {
    return MaintenanceMisconduct(
      marker: Marker(
        markerId: MarkerId(location.toString()),
        position: location,
        consumeTapEvents: true,
        icon: absenceOfOrderIconMap[misconductType]!,
      ),
      maintenanceTypes: maintenanceTypes.toSet(),
      other: other,
    );
  }

  factory MaintenanceMisconduct.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'location': GeoPoint location,
          'maintenanceTypes': List maintenanceTypes,
          'other': String other,
        }) {
      if (maintenanceTypes.isNotEmpty) {
        final point = location.toLatLng();
        return MaintenanceMisconduct(
          marker: Marker(
            markerId: MarkerId(point.toString()),
            position: point,
            consumeTapEvents: true,
            icon: absenceOfOrderIconMap[misconductType]!,
          ),
          maintenanceTypes: maintenanceTypes
              .map((string) => MaintenanceType.values.byName(string))
              .toSet(),
          other: other,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'location': marker.position.toGeoPoint(),
      'maintenanceTypes':
          maintenanceTypes.map((maintenance) => maintenance.name).toList(),
      'other': other,
    };
  }
}

/// Class representing the data format used for [AbsenceOfOrderTest].
///
/// This is used as the generic type in the definition
/// of [AbsenceOfOrderTest].
class AbsenceOfOrderData with JsonToString {
  final List<BehaviorMisconduct> behaviorList;
  final List<MaintenanceMisconduct> maintenanceList;

  AbsenceOfOrderData({
    required this.behaviorList,
    required this.maintenanceList,
  });
  AbsenceOfOrderData.empty()
      : behaviorList = [],
        maintenanceList = [];

  /// Creates an [AbsenceOfOrderData] object from a Json-type object.
  ///
  /// Used for recreating data instances from existing
  /// [AbsenceOfOrderTest] instances in Firestore.
  factory AbsenceOfOrderData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'behavior': List behaviorList,
          'maintenance': List maintenanceList,
        }) {
      return AbsenceOfOrderData(
        behaviorList: behaviorList
            .map((behavior) => BehaviorMisconduct.fromJson(behavior))
            .toList(),
        maintenanceList: maintenanceList
            .map((maintenance) => MaintenanceMisconduct.fromJson(maintenance))
            .toList(),
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      for (final type in MisconductType.values) type.name: [],
    };

    for (final behavior in behaviorList) {
      json[BehaviorMisconduct.misconductType.name]!.add(behavior.toJson());
    }
    for (final maintenance in maintenanceList) {
      json[MaintenanceMisconduct.misconductType.name]!
          .add(maintenance.toJson());
    }

    return json;
  }
}

/// Class for Absence of Order Test info and methods.
class AbsenceOfOrderTest extends Test<AbsenceOfOrderData>
    with JsonToString
    implements TimerTest {
  static const String collectionIDStatic = 'absence_of_order_tests';
  static const String displayName = 'Absence of Order Locator';

  @override
  final int testDuration;

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
    required this.testDuration,
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
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        AbsenceOfOrderTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: AbsenceOfOrderData.empty(),
          testDuration: testDuration ?? -1,
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
    Test._testInitialsMap[AbsenceOfOrderTest] = 'AO';
    Test._timerTestCollectionIDs.add(collectionIDStatic);
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
  /// object [json].
  ///
  /// Typically, [json] is a representation of an existing
  /// [AbsenceOfOrderTest] in Firestore and this is used for recreating
  /// that [Test] object.
  static AbsenceOfOrderTest fromJson(Map<String, dynamic> json) {
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
          'testDuration': int testDuration,
        }) {
      return AbsenceOfOrderTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: AbsenceOfOrderData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        testDuration: testDuration,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      'testDuration': testDuration,
    };
  }
}

enum BoundaryType implements DisplayNameEnum {
  constructed(displayName: 'Constructed', color: Color(0xFFD81860)),
  material(displayName: 'Material', color: Color(0xFF00897B)),
  shelter(displayName: 'Shelter', color: Color(0xFFF57C00));

  const BoundaryType({
    required this.displayName,
    required this.color,
  });

  @override
  final String displayName;
  final Color color;

  factory BoundaryType.byDisplayName(String displayName) {
    try {
      for (final type in BoundaryType.values) {
        if (type.displayName == displayName) return type;
      }
      throw Exception('Invalid BoundaryType displayName');
    } catch (e, s) {
      throw Exception('Error: $e\nStacktrace: $s');
    }
  }
}

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
  static const BoundaryType type = BoundaryType.constructed;
  final Polyline polyline;
  final double polylineLength;
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

  factory ConstructedBoundary.fromJsonAndType(
      Map<String, dynamic> json, ConstructedBoundaryType constructedType) {
    if (json
        case {
          'polyline': List polyline,
          'polylineLength': double polylineLength,
        }) {
      final List<LatLng> points = List<GeoPoint>.from(polyline).toLatLngList();
      return ConstructedBoundary.recreate(
        polyline: Polyline(
          polylineId: PolylineId(points.toString()),
          points: points,
          color: type.color,
          width: 4,
        ),
        polylineLength: polylineLength,
        constructedType: constructedType,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }
}

class MaterialBoundary {
  static const BoundaryType type = BoundaryType.material;
  final Polygon polygon;
  final double polygonArea;
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

  factory MaterialBoundary.fromJsonAndType(
      Map<String, dynamic> json, MaterialBoundaryType materialType) {
    if (json
        case {
          'polygon': List polygon,
          'polygonArea': double polygonArea,
        }) {
      final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
      return MaterialBoundary.recreate(
        polygon: finalizePolygon(points, strokeColor: type.color),
        polygonArea: polygonArea,
        materialType: materialType,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }
}

class ShelterBoundary {
  static const BoundaryType type = BoundaryType.shelter;
  final Polygon polygon;
  final double polygonArea;
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

  factory ShelterBoundary.fromJsonAndType(
      Map<String, dynamic> json, ShelterBoundaryType shelterType) {
    if (json
        case {
          'polygon': List polygon,
          'polygonArea': double polygonArea,
        }) {
      final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
      return ShelterBoundary.recreate(
        polygon: finalizePolygon(points, strokeColor: type.color),
        polygonArea: polygonArea,
        shelterType: shelterType,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }
}

class SpatialBoundariesData with JsonToString {
  final List<ConstructedBoundary> constructed;
  final List<MaterialBoundary> material;
  final List<ShelterBoundary> shelter;

  SpatialBoundariesData({
    required this.constructed,
    required this.material,
    required this.shelter,
  });

  SpatialBoundariesData.empty()
      : constructed = [],
        material = [],
        shelter = [];

  factory SpatialBoundariesData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'constructed': Map<String, dynamic> constructedBoundaries,
          'material': Map<String, dynamic> materialBoundaries,
          'shelter': Map<String, dynamic> shelterBoundaries,
        }) {
      List<ConstructedBoundary> constructedList = [];
      if (constructedBoundaries
          case {
            'curb': List curb,
            'buildingWall': List buildingWall,
            'fence': List fence,
            'planter': List planter,
            'partialWall': List partialWall,
          }) {
        constructedList = [
          if (curb.isNotEmpty)
            for (final bound in curb)
              ConstructedBoundary.fromJsonAndType(
                  bound, ConstructedBoundaryType.curb),
          if (buildingWall.isNotEmpty)
            for (final bound in buildingWall)
              ConstructedBoundary.fromJsonAndType(
                  bound, ConstructedBoundaryType.buildingWall),
          if (fence.isNotEmpty)
            for (final bound in fence)
              ConstructedBoundary.fromJsonAndType(
                  bound, ConstructedBoundaryType.fence),
          if (planter.isNotEmpty)
            for (final bound in planter)
              ConstructedBoundary.fromJsonAndType(
                  bound, ConstructedBoundaryType.planter),
          if (partialWall.isNotEmpty)
            for (final bound in partialWall)
              ConstructedBoundary.fromJsonAndType(
                  bound, ConstructedBoundaryType.partialWall),
          if (fence.isNotEmpty)
            for (final bound in fence)
              ConstructedBoundary.fromJsonAndType(
                  bound, ConstructedBoundaryType.fence),
        ];
      }
      List<MaterialBoundary> materialList = [];
      if (materialBoundaries
          case {
            'pavers': List pavers,
            'concrete': List concrete,
            'tile': List tile,
            'natural': List natural,
            'decking': List decking,
          }) {
        materialList = [
          if (pavers.isNotEmpty)
            for (final bound in pavers)
              MaterialBoundary.fromJsonAndType(
                  bound, MaterialBoundaryType.pavers),
          if (concrete.isNotEmpty)
            for (final bound in concrete)
              MaterialBoundary.fromJsonAndType(
                  bound, MaterialBoundaryType.concrete),
          if (tile.isNotEmpty)
            for (final bound in tile)
              MaterialBoundary.fromJsonAndType(
                  bound, MaterialBoundaryType.tile),
          if (natural.isNotEmpty)
            for (final bound in natural)
              MaterialBoundary.fromJsonAndType(
                  bound, MaterialBoundaryType.natural),
          if (decking.isNotEmpty)
            for (final bound in decking)
              MaterialBoundary.fromJsonAndType(
                  bound, MaterialBoundaryType.decking),
        ];
      }
      List<ShelterBoundary> shelterList = [];
      if (shelterBoundaries
          case {
            'canopy': List canopy,
            'tree': List tree,
            'furniture': List furniture,
            'temporary': List temporary,
            'constructed': List constructed,
          }) {
        shelterList = [
          if (canopy.isNotEmpty)
            for (final bound in canopy)
              ShelterBoundary.fromJsonAndType(
                  bound, ShelterBoundaryType.canopy),
          if (tree.isNotEmpty)
            for (final bound in tree)
              ShelterBoundary.fromJsonAndType(bound, ShelterBoundaryType.tree),
          if (furniture.isNotEmpty)
            for (final bound in furniture)
              ShelterBoundary.fromJsonAndType(
                  bound, ShelterBoundaryType.furniture),
          if (temporary.isNotEmpty)
            for (final bound in temporary)
              ShelterBoundary.fromJsonAndType(
                  bound, ShelterBoundaryType.temporary),
          if (constructed.isNotEmpty)
            for (final bound in constructed)
              ShelterBoundary.fromJsonAndType(
                  bound, ShelterBoundaryType.constructed),
        ];
      }
      return SpatialBoundariesData(
          constructed: constructedList,
          material: materialList,
          shelter: shelterList);
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    final List<ConstructedBoundaryType> constructedTypes =
        ConstructedBoundaryType.values;
    final List<MaterialBoundaryType> materialTypes =
        MaterialBoundaryType.values;
    final List<ShelterBoundaryType> shelterTypes = ShelterBoundaryType.values;

    final Map<String, Map<String, List>> json = {
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
    with JsonToString
    implements TimerTest {
  static const String collectionIDStatic = 'spatial_boundaries_tests';
  static const String displayName = 'Spatial Boundaries';

  @override
  final int testDuration;

  SpatialBoundariesTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    required this.testDuration,
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
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        SpatialBoundariesTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: SpatialBoundariesData.empty(),
          testDuration: testDuration ?? -1,
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
    Test._testInitialsMap[SpatialBoundariesTest] = 'SB';
    Test._timerTestCollectionIDs.add(collectionIDStatic);
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

  factory SpatialBoundariesTest.fromJson(Map<String, dynamic> json) {
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
          'testDuration': int testDuration,
        }) {
      return SpatialBoundariesTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: SpatialBoundariesData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        testDuration: testDuration,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      'testDuration': testDuration,
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
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
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
          activeProject: project,
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
    Test._testInitialsMap[SectionCutterTest] = 'SC';
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
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
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
enum AccessType {
  bikeRack(Colors.black),
  taxiAndRideShare(Colors.black),
  parking(Colors.black),
  transportStation(Colors.black);

  const AccessType(this.color);

  final Color color;

  static const Cap startCap = Cap.roundCap;
  static const int polylineWidth = 3;
}

/// Bike rack type for Identifying Access test. Enum type [bikeRack].
class BikeRack with JsonToString {
  static const AccessType type = AccessType.bikeRack;

  final int spots;
  final Polyline polyline;
  final double polylineLength;

  BikeRack({required this.spots, required this.polyline})
      : polylineLength = polyline.getLengthInFeet();

  BikeRack.recreate({
    required this.spots,
    required this.polyline,
    required this.polylineLength,
  });

  factory BikeRack.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'pathInfo': Map<String, dynamic> pathInfo,
          'spots': int spots,
        }) {
      if (pathInfo
          case {
            'path': List path,
            'pathLength': double pathLength,
          }) {
        final List<LatLng> points = List<GeoPoint>.from(path).toLatLngList();
        return BikeRack.recreate(
          spots: spots,
          polyline: Polyline(
            polylineId: PolylineId(points.toString()),
            points: points,
            color: type.color,
            width: AccessType.polylineWidth,
            startCap: AccessType.startCap,
          ),
          polylineLength: pathLength,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'pathInfo': {
        'path': polyline.toGeoPointList(),
        'pathLength': polylineLength,
      },
      'spots': spots,
    };
  }
}

/// Taxi/ride share type for Identifying Access test. Enum type
/// [taxiAndRideShare].
class TaxiAndRideShare with JsonToString {
  static const AccessType type = AccessType.taxiAndRideShare;

  final Polyline polyline;
  final double polylineLength;

  TaxiAndRideShare({required this.polyline})
      : polylineLength = polyline.getLengthInFeet();

  TaxiAndRideShare.recreate({
    required this.polyline,
    required this.polylineLength,
  });

  factory TaxiAndRideShare.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'pathInfo': Map<String, dynamic> pathInfo,
        }) {
      if (pathInfo
          case {
            'path': List path,
            'pathLength': double pathLength,
          }) {
        final List<LatLng> points = List<GeoPoint>.from(path).toLatLngList();
        return TaxiAndRideShare.recreate(
          polyline: Polyline(
            polylineId: PolylineId(points.toString()),
            points: points,
            color: type.color,
            width: AccessType.polylineWidth,
            startCap: AccessType.startCap,
          ),
          polylineLength: pathLength,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'pathInfo': {
        'path': polyline.toGeoPointList(),
        'pathLength': polylineLength,
      },
    };
  }
}

/// Parking type for Identifying Access test. Enum type [parking].
class Parking with JsonToString {
  static const AccessType type = AccessType.parking;

  final int spots;
  final Polyline polyline;
  final double polylineLength;
  final Polygon polygon;
  final double polygonArea;

  Parking({required this.spots, required this.polyline, required this.polygon})
      : polylineLength = polyline.getLengthInFeet(),
        polygonArea = polygon.getAreaInSquareFeet();

  Parking.recreate({
    required this.spots,
    required this.polyline,
    required this.polylineLength,
    required this.polygon,
    required this.polygonArea,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'pathInfo': Map<String, dynamic> pathInfo,
          'polygonInfo': Map<String, dynamic> polygonInfo,
          'spots': int spots,
        }) {
      if (pathInfo
          case {
            'path': List path,
            'pathLength': double pathLength,
          }) {
        if (polygonInfo
            case {
              'polygon': List polygon,
              'polygonArea': double polygonArea,
            }) {
          final List<LatLng> pathPoints =
              List<GeoPoint>.from(path).toLatLngList();
          final List<LatLng> polygonPoints =
              List<GeoPoint>.from(polygon).toLatLngList();
          return Parking.recreate(
            spots: spots,
            polyline: Polyline(
              polylineId: PolylineId(pathPoints.toString()),
              points: pathPoints,
              color: type.color,
              width: AccessType.polylineWidth,
              startCap: AccessType.startCap,
            ),
            polylineLength: pathLength,
            polygon: Polygon(
              polygonId: PolygonId(polygonPoints.toString()),
              points: polygonPoints,
              fillColor: Color(0x55999999),
            ),
            polygonArea: polygonArea,
          );
        }
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'pathInfo': {
        'path': polyline.toGeoPointList(),
        'pathLength': polylineLength,
      },
      'polygonInfo': {
        'polygon': polygon.toGeoPointList(),
        'polygonArea': polygonArea,
      },
      'spots': spots,
    };
  }
}

/// Transport station type for Identifying Access test. Enum type
/// [transportStation].
class TransportStation with JsonToString {
  static const AccessType type = AccessType.transportStation;

  final int routeNumber;
  final Polyline polyline;
  final double polylineLength;

  TransportStation({required this.routeNumber, required this.polyline})
      : polylineLength = polyline.getLengthInFeet();

  TransportStation.recreate({
    required this.routeNumber,
    required this.polyline,
    required this.polylineLength,
  });

  factory TransportStation.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'pathInfo': Map<String, dynamic> pathInfo,
          'routeNumber': int routeNumber,
        }) {
      if (pathInfo
          case {
            'path': List path,
            'pathLength': double pathLength,
          }) {
        final List<LatLng> points = List<GeoPoint>.from(path).toLatLngList();
        return TransportStation.recreate(
          routeNumber: routeNumber,
          polyline: Polyline(
            polylineId: PolylineId(points.toString()),
            points: points,
            color: type.color,
            width: AccessType.polylineWidth,
            startCap: AccessType.startCap,
          ),
          polylineLength: pathLength,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'pathInfo': {
        'path': polyline.toGeoPointList(),
        'pathLength': polylineLength,
      },
      'routeNumber': routeNumber,
    };
  }
}

class IdentifyingAccessData with JsonToString {
  final List<BikeRack> bikeRacks;
  final List<TaxiAndRideShare> taxisAndRideShares;
  final List<Parking> parkingStructures;
  final List<TransportStation> transportStations;

  IdentifyingAccessData({
    required this.bikeRacks,
    required this.taxisAndRideShares,
    required this.parkingStructures,
    required this.transportStations,
  });

  IdentifyingAccessData.empty()
      : bikeRacks = [],
        taxisAndRideShares = [],
        parkingStructures = [],
        transportStations = [];

  factory IdentifyingAccessData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'bikeRack': List bikeRacks,
          'taxiAndRideShare': List taxisAndRideShares,
          'transportStation': List transportStations,
          'parking': List parkingStructures,
        }) {
      return IdentifyingAccessData(
        bikeRacks: <BikeRack>[
          if (bikeRacks.isNotEmpty)
            for (final bikeRack in bikeRacks) BikeRack.fromJson(bikeRack)
        ],
        taxisAndRideShares: <TaxiAndRideShare>[
          if (taxisAndRideShares.isNotEmpty)
            for (final taxiOrRideShare in taxisAndRideShares)
              TaxiAndRideShare.fromJson(taxiOrRideShare)
        ],
        transportStations: <TransportStation>[
          if (transportStations.isNotEmpty)
            for (final transportStation in transportStations)
              TransportStation.fromJson(transportStation)
        ],
        parkingStructures: <Parking>[
          if (parkingStructures.isNotEmpty)
            for (final parkingStructure in parkingStructures)
              Parking.fromJson(parkingStructure)
        ],
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  /// Transforms data stored locally as in this class as Lists of objects to
  /// Json format specifically tailored to be stored in Firestore.
  @override
  Map<String, Object> toJson() {
    final Map<String, List<Map>> json = {
      for (final accessType in AccessType.values) accessType.name: <Map>[]
    };

    for (final bikeRack in bikeRacks) {
      json[AccessType.bikeRack.name]!.add(bikeRack.toJson());
    }
    for (final taxiOrRideShare in taxisAndRideShares) {
      json[AccessType.taxiAndRideShare.name]!.add(taxiOrRideShare.toJson());
    }
    for (final transportStation in transportStations) {
      json[AccessType.transportStation.name]!.add(transportStation.toJson());
    }
    for (final parking in parkingStructures) {
      json[AccessType.parking.name]!.add(parking.toJson());
    }

    return json;
  }
}

/// Class for identifying access test info and methods.
class IdentifyingAccessTest extends Test<IdentifyingAccessData>
    with JsonToString {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'identifying_access_tests';
  static const String displayName = 'Identifying Access';

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
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        IdentifyingAccessTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: IdentifyingAccessData.empty(),
        );
    // Register for recreating a Identifying Access Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return IdentifyingAccessTest.fromJson(testDoc.data()!);
    };
    // Register for building a Identifying Access Test page
    Test._pageBuilders[IdentifyingAccessTest] =
        (project, test) => IdentifyingAccess(
              activeProject: project,
              activeTest: test as IdentifyingAccessTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[IdentifyingAccessTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<IdentifyingAccessTest>(
            fromFirestore: (snapshot, _) =>
                IdentifyingAccessTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as IdentifyingAccessTest, SetOptions(merge: true));
    };
    Test._testInitialsMap[IdentifyingAccessTest] = 'IA';
  }

  @override
  void submitData(IdentifyingAccessData data) async {
    try {
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In IdentifyingAccessTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in IdentifyingAccessTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  factory IdentifyingAccessTest.fromJson(Map<String, dynamic> json) {
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
        }) {
      return IdentifyingAccessTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: IdentifyingAccessData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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

/// Enum for Nature Types. Used in Nature Prevalence test. Types include
/// [vegetation], [waterBody], and [animal].
enum NatureType { vegetation, waterBody, animal }

/// Enum for types of vegetation. Used in Nature Prevalence test. Types include
/// [native], [design], [openField], and [other].
enum VegetationType {
  native(Color(0x6508AC12)),
  design(Color(0x656DFD75)),
  openField(Color(0x65C7FF80)),
  other(Color(0x6C00FF3C));

  const VegetationType(this.color);

  final Color color;
}

/// Enum for types of bodies of water. Used in Nature Prevalence test. Types
/// include [ocean], [lake], [river], and [swamp].
enum WaterBodyType {
  ocean(Color(0x651020FF)),
  lake(Color(0x652FB3DD)),
  river(Color(0x656253EA)),
  swamp(Color(0x65009595));

  const WaterBodyType(this.color);

  final Color color;
}

/// Enum for types of animals. Used in Nature Prevalence test. Types include
/// [cat], [dog], [squirrel], [bird], [rabbit], [turtle], [duck], and [other].
/// </br> [cat] and [dog] are domestic, [other] is its own type, and all other
/// defined types are wild.
enum AnimalType implements DisplayNameEnum {
  cat(
    designation: AnimalDesignation.domesticated,
    displayName: 'Cat',
    iconName: 'cat_marker.png',
  ),
  dog(
    designation: AnimalDesignation.domesticated,
    displayName: 'Dog',
    iconName: 'dog_marker.png',
  ),
  squirrel(
    designation: AnimalDesignation.wild,
    displayName: 'Squirrel',
    iconName: 'squirrel_marker.png',
  ),
  bird(
    designation: AnimalDesignation.wild,
    displayName: 'Bird',
    iconName: 'bird_marker.png',
  ),
  rabbit(
    designation: AnimalDesignation.wild,
    displayName: 'Rabbit',
    iconName: 'rabbit_marker.png',
  ),
  turtle(
    designation: AnimalDesignation.wild,
    displayName: 'Turtle',
    iconName: 'turtle_marker.png',
  ),
  duck(
    designation: AnimalDesignation.wild,
    displayName: 'Duck',
    iconName: 'duck_marker.png',
  ),
  other(
    designation: AnimalDesignation.other,
    displayName: 'Other',
    iconName: 'other_marker.png',
  );

  const AnimalType({
    required this.designation,
    required this.displayName,
    required this.iconName,
  });

  final AnimalDesignation designation;
  @override
  final String displayName;
  final String iconName;
}

/// The following designations are used to differentiate types of animals. They
/// include [domesticated], [wild], and [other]
enum AnimalDesignation { domesticated, wild, other }

/// Types of weather for Nature Prevalence. Types include [sunny], [cloudy],
/// [rainy], [windy], and [stormy].
enum WeatherType {
  sunny,
  cloudy,
  rainy,
  windy,
  stormy;

  const WeatherType();

  static Set<WeatherType> setFromJson(Map<String, dynamic> json) {
    if (json
        case {
          'cloudy': bool cloudy,
          'rainy': bool rainy,
          'stormy': bool stormy,
          'sunny': bool sunny,
          'windy': bool windy,
        }) {
      return <WeatherType>{
        if (cloudy) WeatherType.cloudy,
        if (rainy) WeatherType.rainy,
        if (stormy) WeatherType.stormy,
        if (sunny) WeatherType.sunny,
        if (windy) WeatherType.windy,
      };
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  static Map<String, bool> setToJson(Set<WeatherType> set) {
    return {
      for (final type in WeatherType.values) type.name: set.contains(type)
    };
  }
}

/// Class for weather in Nature Prevalence Test. Implements enum type
/// [weather].
class WeatherData with JsonToString {
  final Set<WeatherType> weatherTypes;
  final double temp;

  WeatherData({required this.weatherTypes, required this.temp});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'temperature': double temperature,
          'weatherTypes': Map<String, dynamic> weatherTypes,
        }) {
      return WeatherData(
        temp: temperature,
        weatherTypes: WeatherType.setFromJson(weatherTypes),
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'temperature': temp,
      'weatherTypes': WeatherType.setToJson(weatherTypes),
    };
  }
}

/// Class for vegetation in Nature Prevalence Test. Implements enum type
/// [vegetation].
class Vegetation with JsonToString {
  static const NatureType natureType = NatureType.vegetation;

  final VegetationType vegetationType;
  final String? otherName;
  final Polygon polygon;
  final double polygonArea;

  /// For all vegetation, other or not, otherType is required. If the
  /// vegetation is of a defined type (i.e. not other) then set otherType equal
  /// to [null].
  /// </br> A [null] otherType will be ignored in convertToFirestoreData().
  Vegetation({
    required this.vegetationType,
    required this.otherName,
    required this.polygon,
  }) : polygonArea = polygon.getAreaInSquareFeet();

  Vegetation.recreate({
    required this.vegetationType,
    required this.otherName,
    required this.polygon,
    required this.polygonArea,
  });

  factory Vegetation.fromJsonAndType(
      Map<String, dynamic> json, VegetationType vegetationType) {
    if (vegetationType == VegetationType.other) {
      if (json
          case {
            'polygon': List polygon,
            'polygonArea': double polygonArea,
            'name': String name,
          }) {
        final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
        return Vegetation.recreate(
          vegetationType: vegetationType,
          otherName: name,
          polygon: Polygon(
            polygonId: PolygonId(points.toString()),
            points: points,
            fillColor: vegetationType.color,
          ),
          polygonArea: polygonArea,
        );
      }
    } else {
      if (json
          case {
            'polygon': List polygon,
            'polygonArea': double polygonArea,
          }) {
        final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
        return Vegetation.recreate(
          vegetationType: vegetationType,
          otherName: null,
          polygon: Polygon(
            polygonId: PolygonId(points.toString()),
            points: points,
            fillColor: vegetationType.color,
          ),
          polygonArea: polygonArea,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    if (vegetationType == VegetationType.other && otherName != null) {
      return {
        'name': otherName!,
        'polygon': polygon.toGeoPointList(),
        'polygonArea': polygonArea,
      };
    } else {
      return {
        'polygon': polygon.toGeoPointList(),
        'polygonArea': polygonArea,
      };
    }
  }
}

/// Class for bodies of water in Nature Prevalence Test. Implements enum type
/// [waterBody].
class WaterBody with JsonToString {
  static const NatureType natureType = NatureType.waterBody;

  final WaterBodyType waterBodyType;
  final Polygon polygon;
  final double polygonArea;

  WaterBody({required this.waterBodyType, required this.polygon})
      : polygonArea = polygon.getAreaInSquareFeet();

  WaterBody.recreate({
    required this.waterBodyType,
    required this.polygon,
    required this.polygonArea,
  });

  factory WaterBody.fromJsonAndType(
      Map<String, dynamic> json, WaterBodyType waterBodyType) {
    if (json
        case {
          'polygon': List polygon,
          'polygonArea': double polygonArea,
        }) {
      final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
      return WaterBody.recreate(
        waterBodyType: waterBodyType,
        polygon: Polygon(
          polygonId: PolygonId(points.toString()),
          points: points,
          fillColor: waterBodyType.color,
        ),
        polygonArea: polygonArea,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'polygon': polygon.toGeoPointList(),
      'polygonArea': polygonArea,
    };
  }
}

/// Class for animals in Nature Prevalence Test. Implements enum type [animal].
class Animal {
  static const NatureType natureType = NatureType.animal;

  final AnimalType animalType;
  final String? otherName;
  final Marker marker;

  /// For all animals, other or not, otherType is required. If the animal is
  /// of a defined type (i.e. not other) then set otherType equal to [null].
  /// </br> A [null] otherType will be ignored in convertToFirestoreData().
  Animal({
    required this.animalType,
    required this.otherName,
    required this.marker,
  });

  /// Creates a marker in the standard way intended for an instance of [Animal]
  /// from given arguments.
  static Marker newMarker(LatLng location, AnimalType animalType,
      [String? name]) {
    if (animalType == AnimalType.other && name == null) {
      throw Exception(
          'Animal.newMarker was used with incompatible name and animalType.');
    }
    return Marker(
      markerId: MarkerId(location.toString()),
      position: location,
      consumeTapEvents: false,
      infoWindow: InfoWindow(
          title: name ?? animalType.displayName,
          snippet: '(${location.latitude.toStringAsFixed(5)}, '
              '${location.longitude.toStringAsFixed(5)})'),
      icon: naturePrevalenceAnimalIconMap[animalType]!,
    );
  }

  factory Animal.fromJsonAndType(Object json, AnimalType animalType) {
    if (animalType == AnimalType.other && json is Map<String, dynamic>) {
      if (json
          case {
            'name': String name,
            'point': GeoPoint point,
          }) {
        final LatLng location = point.toLatLng();
        return Animal(
          animalType: animalType,
          otherName: name,
          marker: newMarker(location, animalType, name),
        );
      }
    } else {
      if (json is GeoPoint) {
        final LatLng location = json.toLatLng();
        return Animal(
          animalType: animalType,
          otherName: null,
          marker: newMarker(location, animalType),
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  Object toJsonOrGeoPoint() {
    if (animalType == AnimalType.other && otherName != null) {
      return {
        'name': otherName!,
        'point': marker.position.toGeoPoint(),
      };
    } else {
      return marker.position.toGeoPoint();
    }
  }

  @override
  String toString() {
    return toJsonOrGeoPoint().toString();
  }
}

/// Containing class for Nature Prevalence Test.
///
/// Contains a list of objects corresponding to the Nature Prevalence Test
/// types ([Animal], [WaterBody], [Vegetation]). Also implements the
/// [convertToFirestoreData()], which returns a map that is able to be inputted
/// directly into Firestore.
class NaturePrevalenceData with JsonToString {
  final List<Animal> animals;
  final List<WaterBody> waterBodies;
  final List<Vegetation> vegetation;
  WeatherData? weather;

  NaturePrevalenceData({
    required this.animals,
    required this.waterBodies,
    required this.vegetation,
    this.weather,
  });

  NaturePrevalenceData.empty()
      : animals = [],
        waterBodies = [],
        vegetation = [];

  factory NaturePrevalenceData.fromJson(Map<String, dynamic> json) {
    final List<Animal> animalList = [];
    final List<Vegetation> vegetationList = [];
    final List<WaterBody> waterBodyList = [];
    WeatherData? weatherData;

    if (json
        case {
          'animal': Map<String, dynamic> animal,
          'vegetation': Map<String, dynamic> vegetation,
          'waterBody': Map<String, dynamic> waterBody,
          'weather': Map<String, dynamic> weather,
        }) {
      if (animal
          case {
            'domesticated': Map<String, dynamic> domesticated,
            'wild': Map<String, dynamic> wild,
            'other': List other,
          }) {
        if (domesticated
            case {
              'cat': List cats,
              'dog': List dogs,
            }) {
          for (final cat in cats) {
            animalList.add(Animal.fromJsonAndType(cat, AnimalType.cat));
          }
          for (final dog in dogs) {
            animalList.add(Animal.fromJsonAndType(dog, AnimalType.dog));
          }
        }

        if (wild
            case {
              'bird': List birds,
              'duck': List ducks,
              'rabbit': List rabbits,
              'squirrel': List squirrels,
              'turtle': List turtles,
            }) {
          for (final bird in birds) {
            animalList.add(Animal.fromJsonAndType(bird, AnimalType.bird));
          }
          for (final duck in ducks) {
            animalList.add(Animal.fromJsonAndType(duck, AnimalType.duck));
          }
          for (final rabbit in rabbits) {
            animalList.add(Animal.fromJsonAndType(rabbit, AnimalType.rabbit));
          }
          for (final squirrel in squirrels) {
            animalList
                .add(Animal.fromJsonAndType(squirrel, AnimalType.squirrel));
          }
          for (final turtle in turtles) {
            animalList.add(Animal.fromJsonAndType(turtle, AnimalType.turtle));
          }
        }

        for (final animal in other) {
          animalList.add(Animal.fromJsonAndType(animal, AnimalType.other));
        }
      }

      if (vegetation
          case {
            'design': List design,
            'native': List native,
            'openField': List openField,
            'other': List other,
          }) {
        if (design.isNotEmpty) {
          for (final veg in design) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.design));
          }
        }
        if (native.isNotEmpty) {
          for (final veg in native) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.native));
          }
        }
        if (openField.isNotEmpty) {
          for (final veg in openField) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.openField));
          }
        }
        if (other.isNotEmpty) {
          for (final veg in other) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.other));
          }
        }
      }

      if (waterBody
          case {
            'lake': List lakes,
            'ocean': List oceans,
            'river': List rivers,
            'swamp': List swamps,
          }) {
        if (lakes.isNotEmpty) {
          for (final lake in lakes) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(lake, WaterBodyType.lake));
          }
        }
        if (oceans.isNotEmpty) {
          for (final ocean in oceans) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(ocean, WaterBodyType.ocean));
          }
        }
        if (rivers.isNotEmpty) {
          for (final river in rivers) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(river, WaterBodyType.river));
          }
        }
        if (swamps.isNotEmpty) {
          for (final swamp in swamps) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(swamp, WaterBodyType.swamp));
          }
        }
      }

      if (weather.isNotEmpty) {
        weatherData = WeatherData.fromJson(weather);
      }

      return NaturePrevalenceData(
        animals: animalList,
        waterBodies: waterBodyList,
        vegetation: vegetationList,
        weather: weatherData,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    final List<AnimalDesignation> animalDesignations = AnimalDesignation.values;
    final List<AnimalType> animalTypes = AnimalType.values;
    final List<WaterBodyType> waterBodyTypes = WaterBodyType.values;
    final List<VegetationType> vegetationTypes = VegetationType.values;

    final Map<String, Map<String, dynamic>> json = {
      NatureType.animal.name: {
        for (final designation in animalDesignations)
          designation.name: (designation == AnimalDesignation.other)
              ? []
              : {
                  for (final type in animalTypes)
                    if (type.designation == designation) type.name: []
                }
      },
      NatureType.waterBody.name: {
        for (final type in waterBodyTypes) type.name: <Map>[]
      },
      NatureType.vegetation.name: {
        for (final type in vegetationTypes) type.name: <Map>[]
      },
      'weather': {},
    };

    for (final animal in animals) {
      if (animal.animalType == AnimalType.other) {
        json[NatureType.animal.name]![animal.animalType.designation.name]
            .add(animal.toJsonOrGeoPoint());
      } else {
        json[NatureType.animal.name]![animal.animalType.designation.name]
                [animal.animalType.name]
            .add(animal.toJsonOrGeoPoint());
      }
    }
    for (final waterBody in waterBodies) {
      json[NatureType.waterBody.name]![waterBody.waterBodyType.name]
          .add(waterBody.toJson());
    }
    for (final veg in vegetation) {
      json[NatureType.vegetation.name]![veg.vegetationType.name]
          .add(veg.toJson());
    }
    if (weather != null) {
      json['weather'] = weather!.toJson();
    }

    return json;
  }
}

/// Class for Nature Prevalence test info and methods.
class NaturePrevalenceTest extends Test<NaturePrevalenceData>
    with JsonToString
    implements TimerTest {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'nature_prevalence_tests';
  static const String displayName = 'Nature Prevalence';

  static const String assetDirectoryPath =
      'assets/test_specific/nature_prevalence/';

  /// User defined test timer duration in seconds.
  @override
  final int testDuration;

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
    required this.testDuration,
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
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        NaturePrevalenceTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: NaturePrevalenceData.empty(),
          testDuration: testDuration ?? -1,
        );
    // Register for recreating a Nature Prevalence Test from Firestore
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return NaturePrevalenceTest.fromJson(testDoc.data()!);
    };
    // Register for building a Nature Prevalence Test page
    Test._pageBuilders[NaturePrevalenceTest] =
        (project, test) => NaturePrevalence(
              activeProject: project,
              activeTest: test as NaturePrevalenceTest,
            );
    // Register a function for saving to Firestore
    Test._saveToFirestoreFunctions[NaturePrevalenceTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<NaturePrevalenceTest>(
            fromFirestore: (snapshot, _) =>
                NaturePrevalenceTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as NaturePrevalenceTest, SetOptions(merge: true));
    };
    Test._testInitialsMap[NaturePrevalenceTest] = 'NP';
    Test._timerTestCollectionIDs.add(collectionIDStatic);
  }

  /// Submits data to Firestore for Nature Prevalence Test.
  ///
  /// Unlike other tests, this [submitData()] function (for
  /// [NaturePrevalenceTest]) takes in a [NaturePrevalenceData] type.
  @override
  void submitData(NaturePrevalenceData data) async {
    try {
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In NaturePrevalenceTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in NaturePrevalenceTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  factory NaturePrevalenceTest.fromJson(Map<String, dynamic> json) {
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
          'testDuration': int testDuration,
        }) {
      return NaturePrevalenceTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: NaturePrevalenceData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        testDuration: testDuration,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      'testDuration': testDuration,
    };
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

enum GenderType implements DisplayNameEnum {
  male(displayName: 'Male', iconNameSegment: 'male'),
  female(displayName: 'Female', iconNameSegment: 'female'),
  unspecified(displayName: 'Unspecified', iconNameSegment: 'na');

  const GenderType({
    required this.displayName,
    required this.iconNameSegment,
  });

  @override
  final String displayName;
  final String iconNameSegment;

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

enum PostureType implements DisplayNameEnum {
  standing(
    displayName: 'Standing',
    color: Color(0xFF4285f4),
    iconNameSegment: 'standing',
  ),
  sitting(
    displayName: 'Sitting',
    color: Color(0xFF28a745),
    iconNameSegment: 'sitting',
  ),
  layingDown(
    displayName: 'Laying Down',
    color: Color(0xFFc41484),
    iconNameSegment: 'laying',
  ),
  squatting(
    displayName: 'Squatting',
    color: Color(0xFF6f42c1),
    iconNameSegment: 'squatting',
  );

  const PostureType({
    required this.displayName,
    required this.color,
    required this.iconNameSegment,
  });

  @override
  final String displayName;
  final Color color;
  final String iconNameSegment;

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
  final Marker marker;
  final AgeRangeType ageRange;
  final Set<ActivityTypeInPlace> activities;
  final GenderType gender;
  final PostureType posture;

  PersonInPlace({
    required this.marker,
    required this.ageRange,
    required this.gender,
    required this.activities,
    required this.posture,
  });

  factory PersonInPlace.fromLatLng({
    required LatLng location,
    required AgeRangeType ageRange,
    required Set<ActivityTypeInPlace> activities,
    required GenderType gender,
    required PostureType posture,
  }) {
    return PersonInPlace(
      marker: Marker(
          markerId: MarkerId(location.toString()),
          position: location,
          consumeTapEvents: true,
          icon: peopleInPlaceIconMap[(posture, gender)]!),
      ageRange: ageRange,
      gender: gender,
      activities: activities,
      posture: posture,
    );
  }

  factory PersonInPlace.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'location': GeoPoint location,
          'ageRange': String ageRange,
          'activities': List activities,
          'gender': String gender,
          'posture': String posture,
        }) {
      final LatLng point = location.toLatLng();
      final GenderType genderType = GenderType.values.byName(gender);
      final PostureType postureType = PostureType.values.byName(posture);
      return PersonInPlace(
        marker: Marker(
          markerId: MarkerId(point.toString()),
          position: point,
          consumeTapEvents: true,
          icon: peopleInPlaceIconMap[(postureType, genderType)]!,
        ),
        ageRange: AgeRangeType.values.byName(ageRange),
        activities: activities
            .map((activity) => ActivityTypeInPlace.values.byName(activity))
            .toSet(),
        gender: genderType,
        posture: postureType,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'location': marker.position.toGeoPoint(),
      'ageRange': ageRange.name,
      'activities': <String>[for (final activity in activities) activity.name],
      'gender': gender.name,
      'posture': posture.name,
    };
  }
}

class PeopleInPlaceData with JsonToString {
  final List<PersonInPlace> persons;

  PeopleInPlaceData(this.persons);
  PeopleInPlaceData.empty() : persons = [];

  factory PeopleInPlaceData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'persons': List persons,
        }) {
      return PeopleInPlaceData([
        if (persons.isNotEmpty)
          for (final person in persons) PersonInPlace.fromJson(person)
      ]);
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {'persons': persons.map((person) => person.toJson()).toList()};
  }
}

class PeopleInPlaceTest extends Test<PeopleInPlaceData>
    with JsonToString
    implements StandingPointTest, TimerTest {
  static const String collectionIDStatic = 'people_in_place_tests';
  static const String displayName = 'People in Place';

  @override
  final List<StandingPoint> standingPoints;
  @override
  final int testDuration;

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
    required this.testDuration,
  }) : super._();

  static void register() {
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        PeopleInPlaceTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: PeopleInPlaceData.empty(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
          testDuration: testDuration ?? -1,
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
          .withConverter<PeopleInPlaceTest>(
            fromFirestore: (snapshot, _) =>
                PeopleInPlaceTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as PeopleInPlaceTest, SetOptions(merge: true));
    };
    Test._testInitialsMap[PeopleInPlaceTest] = 'PP';
    Test._standingPointTestCollectionIDs.add(collectionIDStatic);
    Test._timerTestCollectionIDs.add(collectionIDStatic);
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

  factory PeopleInPlaceTest.fromJson(Map<String, dynamic> json) {
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
          'standingPoints': List standingPoints,
          'testDuration': int testDuration,
        }) {
      return PeopleInPlaceTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: PeopleInPlaceData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        standingPoints: StandingPoint.fromJsonList(standingPoints),
        testDuration: testDuration,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      'standingPoints': standingPoints.toJsonList(),
      'testDuration': testDuration,
    };
  }
}

enum ActivityTypeInMotion implements DisplayNameEnum {
  walking(
    displayName: 'Walking',
    color: Colors.teal,
    iconName: 'assets/test_specific/people_in_motion/square_marker_teal.png',
  ),
  running(
    displayName: 'Running',
    color: Colors.red,
    iconName: 'assets/test_specific/people_in_motion/square_marker_red.png',
  ),
  swimming(
    displayName: 'Swimming',
    color: Colors.cyan,
    iconName: 'assets/test_specific/people_in_motion/square_marker_cyan.png',
  ),
  activityOnWheels(
    displayName: 'Activity on Wheels',
    color: Colors.orange,
    iconName: 'assets/test_specific/people_in_motion/square_marker_orange.png',
  ),
  handicapAssistedWheels(
    displayName: 'Handicap Assisted Wheels',
    color: Colors.purple,
    iconName: 'assets/test_specific/people_in_motion/square_marker_purple.png',
  );

  const ActivityTypeInMotion({
    required this.displayName,
    required this.color,
    required this.iconName,
  });

  @override
  final String displayName;
  final Color color;
  final String iconName;

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

  factory PersonInMotion.fromJsonAndActivity(
      Map<String, dynamic> json, ActivityTypeInMotion activity) {
    if (json
        case {
          'polyline': List polylinePoints,
          'polylineLength': double polylineLength,
        }) {
      if (polylinePoints.isNotEmpty && polylinePoints.length >= 2) {
        final List<LatLng> points =
            List<GeoPoint>.from(polylinePoints).toLatLngList();
        return PersonInMotion.recreate(
          polyline: Polyline(
            polylineId: PolylineId(points.toString()),
            points: points,
            color: activity.color,
            width: 4,
          ),
          polylineLength: polylineLength,
          activity: activity,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  ({Map<String, Object> json, ActivityTypeInMotion activity})
      toJsonAndActivity() {
    return (
      json: {
        'polyline': polyline.toGeoPointList(),
        'polylineLength': polylineLength,
      },
      activity: activity,
    );
  }
}

class PeopleInMotionData with JsonToString {
  final List<PersonInMotion> persons;

  PeopleInMotionData(this.persons);
  PeopleInMotionData.empty() : persons = [];

  factory PeopleInMotionData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'walking': List walking,
          'running': List running,
          'swimming': List swimming,
          'activityOnWheels': List activityOnWheels,
          'handicapAssistedWheels': List handicapAssistedWheels,
        }) {
      final data = PeopleInMotionData([
        if (walking.isNotEmpty)
          for (final person in walking)
            PersonInMotion.fromJsonAndActivity(
                person, ActivityTypeInMotion.walking),
        if (running.isNotEmpty)
          for (final person in running)
            PersonInMotion.fromJsonAndActivity(
                person, ActivityTypeInMotion.running),
        if (swimming.isNotEmpty)
          for (final person in swimming)
            PersonInMotion.fromJsonAndActivity(
                person, ActivityTypeInMotion.swimming),
        if (activityOnWheels.isNotEmpty)
          for (final person in activityOnWheels)
            PersonInMotion.fromJsonAndActivity(
                person, ActivityTypeInMotion.activityOnWheels),
        if (handicapAssistedWheels.isNotEmpty)
          for (final person in handicapAssistedWheels)
            PersonInMotion.fromJsonAndActivity(
                person, ActivityTypeInMotion.handicapAssistedWheels),
      ]);
      print(data);
      return data;
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    Map<String, List<Map<String, Object>>> json = {
      for (final activity in ActivityTypeInMotion.values) activity.name: []
    };

    for (final person in persons) {
      final record = person.toJsonAndActivity();
      json[record.activity.name]!.add(record.json);
    }

    return json;
  }
}

class PeopleInMotionTest extends Test<PeopleInMotionData>
    with JsonToString
    implements StandingPointTest, TimerTest {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'people_in_motion_tests';
  static const String displayName = 'People in Motion';

  @override
  final List<StandingPoint> standingPoints;

  /// User defined test timer duration in seconds.
  @override
  final int testDuration;

  /// Private constructor for PeopleInMotionTest.
  PeopleInMotionTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    required this.standingPoints,
    required this.testDuration,
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
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        PeopleInMotionTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: PeopleInMotionData.empty(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
          testDuration: testDuration ?? -1,
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
    Test._testInitialsMap[PeopleInMotionTest] = 'PM';
    Test._timerTestCollectionIDs.add(collectionIDStatic);
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

  factory PeopleInMotionTest.fromJson(Map<String, dynamic> json) {
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
          'standingPoints': List standingPoints,
          'testDuration': int testDuration,
        }) {
      return PeopleInMotionTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: PeopleInMotionData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        standingPoints: StandingPoint.fromJsonList(standingPoints),
        testDuration: testDuration,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      'standingPoints': standingPoints.toJsonList(),
      'testDuration': testDuration,
    };
  }
}

enum SoundType implements DisplayNameEnum {
  water(displayName: 'Water', color: Colors.blue),
  traffic(displayName: 'Traffic', color: Colors.orange),
  people(displayName: 'People', color: Colors.purple),
  animals(displayName: 'Animals', color: Colors.brown),
  wind(displayName: 'Wind', color: Colors.grey),
  music(displayName: 'Music', color: Colors.red),
  other(displayName: 'Other', color: Colors.black87);

  const SoundType({required this.displayName, required this.color});

  @override
  final String displayName;
  final Color color;
}

/// Data model to store one acoustic measurement
class AcousticMeasurement with JsonToString {
  final double decibels;
  final Set<SoundType> soundTypes;
  final String other;
  final SoundType mainSoundType;

  AcousticMeasurement({
    required this.decibels,
    required this.soundTypes,
    required this.other,
    required this.mainSoundType,
  }) {
    // Validation
    final hasOther = soundTypes.contains(SoundType.other);
    if ((hasOther && other.isEmpty) || (!hasOther && other.isNotEmpty)) {
      throw Exception('Other mismatch when constructing AcousticMeasurement');
    }
  }

  factory AcousticMeasurement.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'decibels': num decibels,
          'soundTypes': List soundTypes,
          'other': String other,
          'mainSoundType': String mainSoundType,
        }) {
      if (soundTypes.isNotEmpty) {
        return AcousticMeasurement(
            decibels: decibels.toDouble(),
            soundTypes: soundTypes
                .map((string) => SoundType.values.byName(string))
                .toSet(),
            other: other,
            mainSoundType: SoundType.values.byName(mainSoundType));
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'decibels': decibels,
      'soundTypes': soundTypes.map((type) => type.name).toList(),
      'mainSoundType': mainSoundType.name,
      'other': other,
    };
  }
}

class AcousticDataPoint with JsonToString {
  final StandingPoint standingPoint;
  final List<AcousticMeasurement> measurements;

  AcousticDataPoint({required this.standingPoint, required this.measurements});

  factory AcousticDataPoint.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'standingPoint': Map<String, dynamic> point,
          'measurements': List measurements,
        }) {
      return AcousticDataPoint(
        standingPoint: StandingPoint.fromJson(point),
        measurements: measurements
            .map((json) => AcousticMeasurement.fromJson(json))
            .toList(),
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'standingPoint': standingPoint.toJson(),
      'measurements':
          measurements.map((measurement) => measurement.toJson()).toList(),
    };
  }
}

class AcousticProfileData with JsonToString {
  final List<AcousticDataPoint> dataPoints;

  AcousticProfileData(this.dataPoints);
  AcousticProfileData.empty() : dataPoints = [];

  factory AcousticProfileData.fromJson(Map<String, dynamic> json) {
    if (json case {'dataPoints': List dataPoints}) {
      return AcousticProfileData(dataPoints
          .map((dataPoint) => AcousticDataPoint.fromJson(dataPoint))
          .toList());
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {'dataPoints': dataPoints.map((point) => point.toJson()).toList()};
  }
}

/// Class for Acoustic Profile Test info and methods.
class AcousticProfileTest extends Test<AcousticProfileData>
    with JsonToString
    implements StandingPointTest, IntervalTimerTest {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'acoustic_profile_tests';
  static const String displayName = 'Acoustic Profile';

  @override
  final List<StandingPoint> standingPoints;
  @override
  final int intervalDuration;
  @override
  final int intervalCount;

  /// Private constructor for AcousticProfileTest.
  AcousticProfileTest._({
    required super.title,
    required super.testID,
    required super.scheduledTime,
    required super.projectRef,
    required super.collectionID,
    required super.data,
    required this.standingPoints,
    required this.intervalDuration,
    required this.intervalCount,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super._();

  /// Registers this test type in the Test class system.
  static void register() {
    Test._newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String testID,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      required String collectionID,
      List? standingPoints,
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        AcousticProfileTest._(
          title: title,
          testID: testID,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          collectionID: collectionID,
          data: AcousticProfileData.empty(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
          intervalDuration: intervalDuration ?? -1,
          intervalCount: intervalCount ?? -1,
        );
    Test._recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return AcousticProfileTest.fromJson(testDoc.data()!);
    };
    Test._pageBuilders[AcousticProfileTest] =
        (project, test) => AcousticProfileTestPage(
              activeProject: project,
              activeTest: test as AcousticProfileTest,
            );
    Test._saveToFirestoreFunctions[AcousticProfileTest] = (test) async {
      final testRef = _firestore
          .collection(test.collectionID)
          .doc(test.testID)
          .withConverter<AcousticProfileTest>(
            fromFirestore: (snapshot, _) =>
                AcousticProfileTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );
      await testRef.set(test as AcousticProfileTest, SetOptions(merge: true));
    };
    Test._testInitialsMap[AcousticProfileTest] = 'AP';
    Test._standingPointTestCollectionIDs.add(collectionIDStatic);
    Test._intervalTimerTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  Future<void> submitData(AcousticProfileData data) async {
    try {
      await _firestore.collection(collectionID).doc(testID).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In AcousticProfileTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in AcousticProfileTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  factory AcousticProfileTest.fromJson(Map<String, dynamic> json) {
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
          'standingPoints': List standingPoints,
          'intervalDuration': int intervalDuration,
          'intervalCount': int intervalCount,
        }) {
      return AcousticProfileTest._(
        title: title,
        testID: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        collectionID: collectionIDStatic,
        data: AcousticProfileData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers.toInt(),
        isComplete: isComplete,
        standingPoints: StandingPoint.fromJsonList(standingPoints),
        intervalDuration: intervalDuration,
        intervalCount: intervalCount,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
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
      'standingPoints': standingPoints.toJsonList(),
      'intervalDuration': intervalDuration,
      'intervalCount': intervalCount,
    };
  }
}