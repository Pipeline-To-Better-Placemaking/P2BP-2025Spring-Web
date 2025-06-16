import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../assets.dart';
import '../../lighting_profile_test.dart';
import '../misc_class_stuff.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  static final CollectionReference<LightingProfileTest> converterRef =
      _firestore
          .collection(collectionIDStatic)
          .withConverter<LightingProfileTest>(
            fromFirestore: (snapshot, _) =>
                LightingProfileTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  @override
  final int testDuration;

  /// Creates a new [LightingProfileTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  LightingProfileTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
    required this.testDuration,
  }) : super();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Lighting Profile Tests
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
        LightingProfileTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: LightingProfileData.empty(),
          testDuration: testDuration ?? -1,
        );

    // Register for recreating a Lighting Profile Test from Firestore
    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return LightingProfileTest.fromJson(testDoc.data()!);
    };

    // Register for building a Lighting Profile Test page
    Test.pageBuilders[LightingProfileTest] =
        (project, test) => LightingProfileTestPage(
              activeProject: project,
              activeTest: test as LightingProfileTest,
            );

    Test.testInitialsMap[LightingProfileTest] = 'LP';
    Test.timerTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  void submitData(LightingProfileData data) async {
    try {
      await _firestore.collection(collectionID).doc(id).update({
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
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
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
      'id': id,
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
