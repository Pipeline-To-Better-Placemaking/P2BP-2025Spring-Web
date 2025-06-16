import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../people_in_motion_test.dart';
import '../misc_class_stuff.dart';
import '../standing_point_class.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  static final CollectionReference<PeopleInMotionTest> converterRef = _firestore
      .collection(collectionIDStatic)
      .withConverter<PeopleInMotionTest>(
        fromFirestore: (snapshot, _) =>
            PeopleInMotionTest.fromJson(snapshot.data()!),
        toFirestore: (test, _) => test.toJson(),
      );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  @override
  final List<StandingPoint> standingPoints;

  /// User defined test timer duration in seconds.
  @override
  final int testDuration;

  /// Private constructor for PeopleInMotionTest.
  PeopleInMotionTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    required this.standingPoints,
    required this.testDuration,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super();

  /// Registers this test type in the Test class system.
  static void register() {
    // Register for creating new instances
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
        PeopleInMotionTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: PeopleInMotionData.empty(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
          testDuration: testDuration ?? -1,
        );

    // Register for recreating from Firestore
    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return PeopleInMotionTest.fromJson(testDoc.data()!);
    };

    // Register the test's UI page
    Test.pageBuilders[PeopleInMotionTest] =
        (project, test) => PeopleInMotionTestPage(
              activeProject: project,
              activeTest: test as PeopleInMotionTest,
            );

    Test.standingPointTestCollectionIDs.add(collectionIDStatic);
    Test.testInitialsMap[PeopleInMotionTest] = 'PM';
    Test.timerTestCollectionIDs.add(collectionIDStatic);
  }

  /// Handles data submission to Firestore when the test is completed.
  @override
  void submitData(PeopleInMotionData data) async {
    try {
      // Update Firestore with the test data and mark it as complete
      await _firestore.collection(collectionID).doc(id).update({
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
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
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
      'id': id,
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
