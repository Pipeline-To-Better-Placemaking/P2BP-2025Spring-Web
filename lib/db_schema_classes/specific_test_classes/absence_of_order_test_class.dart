import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../absence_of_order_test.dart';
import '../../assets.dart';
import '../misc_class_stuff.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  static final CollectionReference<AbsenceOfOrderTest> converterRef = _firestore
      .collection(collectionIDStatic)
      .withConverter<AbsenceOfOrderTest>(
        fromFirestore: (snapshot, _) =>
            AbsenceOfOrderTest.fromJson(snapshot.data()!),
        toFirestore: (test, _) => test.toJson(),
      );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  @override
  final int testDuration;

  /// Creates a new [AbsenceOfOrderTest] instance from the given arguments.
  ///
  /// This is private because the intended usage of this is through the
  /// 'factory constructor' in [Test] via [Test]'s various static methods
  /// imitating factory constructors.
  AbsenceOfOrderTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    required this.testDuration,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Absence of Order Tests
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
        AbsenceOfOrderTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: AbsenceOfOrderData.empty(),
          testDuration: testDuration ?? -1,
        );

    // Register for recreating an Absence of Order Test from Firestore
    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return AbsenceOfOrderTest.fromJson(testDoc.data()!);
    };

    // Register for building an Absence of Order Test page
    Test.pageBuilders[AbsenceOfOrderTest] =
        (project, test) => AbsenceOfOrderTestPage(
              activeProject: project,
              activeTest: test as AbsenceOfOrderTest,
            );

    Test.testInitialsMap[AbsenceOfOrderTest] = 'AO';
    Test.timerTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  void submitData(AbsenceOfOrderData data) async {
    try {
      await _firestore.collection(collectionID).doc(id).update({
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
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
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
