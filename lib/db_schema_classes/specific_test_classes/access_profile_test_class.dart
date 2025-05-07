import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../access_profile_test.dart';
import '../misc_class_stuff.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

/// Enum types for Access Profile test:
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

/// Bike rack type for Access Profile test. Enum type [bikeRack].
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

/// Taxi/ride share type for Access Profile test. Enum type
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

/// Parking type for Access Profile test. Enum type [parking].
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

/// Transport station type for Access Profile test. Enum type
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

class AccessProfileData with JsonToString {
  final List<BikeRack> bikeRacks;
  final List<TaxiAndRideShare> taxisAndRideShares;
  final List<Parking> parkingStructures;
  final List<TransportStation> transportStations;

  AccessProfileData({
    required this.bikeRacks,
    required this.taxisAndRideShares,
    required this.parkingStructures,
    required this.transportStations,
  });

  AccessProfileData.empty()
      : bikeRacks = [],
        taxisAndRideShares = [],
        parkingStructures = [],
        transportStations = [];

  factory AccessProfileData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'bikeRack': List bikeRacks,
          'taxiAndRideShare': List taxisAndRideShares,
          'transportStation': List transportStations,
          'parking': List parkingStructures,
        }) {
      return AccessProfileData(
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

/// Class for Access Profile test info and methods.
class AccessProfileTest extends Test<AccessProfileData> with JsonToString {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'access_profile_tests';
  static const String displayName = 'Access Profile';

  static final CollectionReference<AccessProfileTest> converterRef = _firestore
      .collection(collectionIDStatic)
      .withConverter<AccessProfileTest>(
        fromFirestore: (snapshot, _) =>
            AccessProfileTest.fromJson(snapshot.data()!),
        toFirestore: (test, _) => test.toJson(),
      );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  /// Creates a new [AccessProfileTest] instance from the given arguments.
  AccessProfileTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
  }) : super();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Access Profile Tests
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
        AccessProfileTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: AccessProfileData.empty(),
        );

    // Register for recreating a Access Profile Test from Firestore
    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return AccessProfileTest.fromJson(testDoc.data()!);
    };

    // Register for building a Access Profile Test page
    Test.pageBuilders[AccessProfileTest] =
        (project, test) => AccessProfileTestPage(
              activeProject: project,
              activeTest: test as AccessProfileTest,
            );

    Test.testInitialsMap[AccessProfileTest] = 'IA';
  }

  @override
  void submitData(AccessProfileData data) async {
    try {
      await _firestore.collection(collectionID).doc(id).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In AccessProfileTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in AccessProfileTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  factory AccessProfileTest.fromJson(Map<String, dynamic> json) {
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
      return AccessProfileTest._(
        title: title,
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        data: AccessProfileData.fromJson(data),
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
      'id': id,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
    };
  }
}
