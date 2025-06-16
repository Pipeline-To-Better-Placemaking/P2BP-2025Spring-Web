import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../acoustic_profile_test.dart';
import '../misc_class_stuff.dart';
import '../standing_point_class.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  static final CollectionReference<AcousticProfileTest> converterRef =
      _firestore
          .collection(collectionIDStatic)
          .withConverter<AcousticProfileTest>(
            fromFirestore: (snapshot, _) =>
                AcousticProfileTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  @override
  final List<StandingPoint> standingPoints;
  @override
  final int intervalDuration;
  @override
  final int intervalCount;

  /// Private constructor for AcousticProfileTest.
  AcousticProfileTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    required this.standingPoints,
    required this.intervalDuration,
    required this.intervalCount,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super();

  /// Registers this test type in the Test class system.
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
        AcousticProfileTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: AcousticProfileData.empty(),
          standingPoints: (standingPoints as List<StandingPoint>?) ?? [],
          intervalDuration: intervalDuration ?? -1,
          intervalCount: intervalCount ?? -1,
        );

    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return AcousticProfileTest.fromJson(testDoc.data()!);
    };

    Test.pageBuilders[AcousticProfileTest] =
        (project, test) => AcousticProfileTestPage(
              activeProject: project,
              activeTest: test as AcousticProfileTest,
            );

    Test.testInitialsMap[AcousticProfileTest] = 'AP';
    Test.standingPointTestCollectionIDs.add(collectionIDStatic);
    Test.intervalTimerTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  Future<void> submitData(AcousticProfileData data) async {
    try {
      await _firestore.collection(collectionID).doc(id).update({
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
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
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
      'id': id,
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
