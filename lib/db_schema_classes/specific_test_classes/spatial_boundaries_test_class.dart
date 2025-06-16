import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../google_maps_functions.dart';
import '../../spatial_boundaries_test.dart';
import '../misc_class_stuff.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  static final CollectionReference<SpatialBoundariesTest> converterRef =
      _firestore
          .collection(collectionIDStatic)
          .withConverter<SpatialBoundariesTest>(
            fromFirestore: (snapshot, _) =>
                SpatialBoundariesTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  @override
  final int testDuration;

  SpatialBoundariesTest._({
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
    // Register for creating new Spatial Boundaries Tests
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
        SpatialBoundariesTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: SpatialBoundariesData.empty(),
          testDuration: testDuration ?? -1,
        );

    // Register for recreating a Spatial Boundaries Test from Firestore
    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return SpatialBoundariesTest.fromJson(testDoc.data()!);
    };

    // Register for building a Spatial Boundaries Test page
    Test.pageBuilders[SpatialBoundariesTest] =
        (project, test) => SpatialBoundariesTestPage(
              activeProject: project,
              activeTest: test as SpatialBoundariesTest,
            );

    Test.testInitialsMap[SpatialBoundariesTest] = 'SB';
    Test.timerTestCollectionIDs.add(collectionIDStatic);
  }

  @override
  void submitData(SpatialBoundariesData data) async {
    try {
      await _firestore.collection(collectionID).doc(id).update({
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
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
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
