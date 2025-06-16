import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../assets.dart';
import '../../people_in_place_test.dart';
import '../misc_class_stuff.dart';
import '../standing_point_class.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  static final CollectionReference<PeopleInPlaceTest> converterRef = _firestore
      .collection(collectionIDStatic)
      .withConverter<PeopleInPlaceTest>(
        fromFirestore: (snapshot, _) =>
            PeopleInPlaceTest.fromJson(snapshot.data()!),
        toFirestore: (test, _) => test.toJson(),
      );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  @override
  final List<StandingPoint> standingPoints;
  @override
  final int testDuration;

  PeopleInPlaceTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    required this.standingPoints,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
    required this.testDuration,
  }) : super();

  static void register() {
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
        PeopleInPlaceTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: PeopleInPlaceData.empty(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
          testDuration: testDuration ?? -1,
        );

    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return PeopleInPlaceTest.fromJson(testDoc.data()!);
    };

    Test.pageBuilders[PeopleInPlaceTest] =
        (project, test) => PeopleInPlaceTestPage(
              activeProject: project,
              activeTest: test as PeopleInPlaceTest,
            );

    Test.testInitialsMap[PeopleInPlaceTest] = 'PP';
    Test.standingPointTestCollectionIDs.add(collectionIDStatic);
    Test.timerTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  void submitData(PeopleInPlaceData data) async {
    try {
      await _firestore.collection(collectionID).doc(id).update({
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
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
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
