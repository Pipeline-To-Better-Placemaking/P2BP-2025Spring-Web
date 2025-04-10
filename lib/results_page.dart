import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:p2b/theme.dart';
import 'package:p2b/widgets.dart';
import 'package:collection/collection.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class ResultsPage extends StatefulWidget {
  final Project activeProject;
  const ResultsPage({required this.activeProject, super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _drawerIsOpen = false;
  bool _isLoading = false;
  late GoogleMapController _mapController;

  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  LatLng _location = defaultLocation;
  double _zoom = 18;
  late final Polygon _projectPolygon;
  late final List<mp.LatLng> _projectPoints;

  final Map<String, List<TestTile>> _collectionIDToListTiles = {};
  late final List<TestExpansionTile> _expansionTiles;

  @override
  void initState() {
    super.initState();
    _projectPolygon = getProjectPolygon(widget.activeProject.polygonPoints);
    _location = getPolygonCentroid(_projectPolygon);
    _projectPoints = _projectPolygon.toMPLatLngList();
    _zoom = getIdealZoom(_projectPoints, _location.toMPLatLng());
    _expansionTiles = _getExpansionTiles();
  }

  void _updateVisibility(TestData testData) {
    if (testData.visibility == true) {
      setState(() {
        _polygons.addAll(testData.polygons);
        _polylines.addAll(testData.polylines);
        _markers.addAll(testData.markers);
        _circles.addAll(testData.circles);
      });
    } else {
      setState(() {
        _polygons.removeAll(testData.polygons);
        _polylines.removeAll(testData.polylines);
        _markers.removeAll(testData.markers);
        _circles.removeAll(testData.circles);
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveToLocation();
  }

  /// Moves camera to project location.
  void _moveToLocation() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
      ),
    );
  }

  List<TestExpansionTile> _getExpansionTiles() {
    List<TestExpansionTile> expansionTiles = [];
    _processProject();

    expansionTiles.add(
      TestExpansionTile(
        testType: AbsenceOfOrderTest.displayName,
        testTiles:
            _collectionIDToListTiles[AbsenceOfOrderTest.collectionIDStatic] ??
                [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: AcousticProfileTest.displayName,
        testTiles:
            _collectionIDToListTiles[AcousticProfileTest.collectionIDStatic] ??
                [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: IdentifyingAccessTest.displayName,
        testTiles: _collectionIDToListTiles[
                IdentifyingAccessTest.collectionIDStatic] ??
            [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: LightingProfileTest.displayName,
        testTiles:
            _collectionIDToListTiles[LightingProfileTest.collectionIDStatic] ??
                [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: NaturePrevalenceTest.displayName,
        testTiles:
            _collectionIDToListTiles[NaturePrevalenceTest.collectionIDStatic] ??
                [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: PeopleInMotionTest.displayName,
        testTiles:
            _collectionIDToListTiles[PeopleInMotionTest.collectionIDStatic] ??
                [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: PeopleInPlaceTest.displayName,
        testTiles:
            _collectionIDToListTiles[PeopleInPlaceTest.collectionIDStatic] ??
                [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: SectionCutterTest.displayName,
        testTiles:
            _collectionIDToListTiles[SectionCutterTest.collectionIDStatic] ??
                [],
      ),
    );
    expansionTiles.add(
      TestExpansionTile(
        testType: SpatialBoundariesTest.displayName,
        testTiles: _collectionIDToListTiles[
                SpatialBoundariesTest.collectionIDStatic] ??
            [],
      ),
    );

    return expansionTiles;
  }

  void _processProject() {
    final Set<Polygon> polygons = {};
    final Set<Polyline> polylines = {};
    final Set<Marker> markers = {};
    final Set<Circle> circles = {};
    TestData testData;

    if (widget.activeProject.tests == null) {
      widget.activeProject.loadAllTestData();
    }
    for (final Test test in widget.activeProject.tests!) {
      switch (test.collectionID) {
        case (AbsenceOfOrderTest.collectionIDStatic):
          {
            markers.addAll((test as AbsenceOfOrderTest)
                .data
                .behaviorList
                .map((behavior) => behavior.marker));
            markers.addAll(test.data.maintenanceList
                .map((maintenance) => maintenance.marker));
            testData = TestData(
              test: test,
              markers: markers.toSet(),
              displayName: AbsenceOfOrderTest.displayName,
            );
          }
        case (AcousticProfileTest.collectionIDStatic):
          {
            circles.addAll(
              (test as AcousticProfileTest).data.dataPoints.map(
                (dataPoint) {
                  double radius = dataPoint.measurements
                      .map((measurement) => measurement.decibels)
                      .average;
                  return Circle(
                    circleId: CircleId(UniqueKey().toString()),
                    center: dataPoint.standingPoint.location,
                    radius: radius,
                    fillColor: Color(0x90F000F0),
                    strokeWidth: 2,
                  );
                },
              ),
            );

            testData = TestData(
              test: test,
              circles: circles.toSet(),
              displayName: AcousticProfileTest.displayName,
            );
          }
        case (IdentifyingAccessTest.collectionIDStatic):
          {
            polygons.addAll((test as IdentifyingAccessTest)
                .data
                .parkingStructures
                .map((parkingStructure) => parkingStructure.polygon));
            polylines.addAll(test.data.parkingStructures
                .map((parkingStructure) => parkingStructure.polyline));
            polylines.addAll(
                test.data.bikeRacks.map((bikeRack) => bikeRack.polyline));
            polylines.addAll(test.data.transportStations
                .map((transportStation) => transportStation.polyline));
            polylines.addAll(test.data.taxisAndRideShares
                .map((taxiAndRideShare) => taxiAndRideShare.polyline));
            testData = TestData(
              test: test,
              polygons: polygons.toSet(),
              polylines: polylines.toSet(),
              displayName: IdentifyingAccessTest.displayName,
            );
          }
        case (NaturePrevalenceTest.collectionIDStatic):
          {
            markers.addAll((test as NaturePrevalenceTest)
                .data
                .animals
                .map((animal) => animal.marker));
            polygons.addAll(
                test.data.waterBodies.map((waterBody) => waterBody.polygon));
            polygons.addAll(
                test.data.vegetation.map((vegetation) => vegetation.polygon));
            testData = TestData(
              test: test,
              polygons: polygons.toSet(),
              markers: markers.toSet(),
              displayName: NaturePrevalenceTest.displayName,
            );
          }
        case (PeopleInMotionTest.collectionIDStatic):
          {
            polylines.addAll((test as PeopleInMotionTest)
                .data
                .persons
                .map((person) => person.polyline));
            testData = TestData(
              test: test,
              polylines: polylines.toSet(),
              displayName: PeopleInMotionTest.displayName,
            );
          }
        case (PeopleInPlaceTest.collectionIDStatic):
          {
            markers.addAll((test as PeopleInPlaceTest)
                .data
                .persons
                .map((person) => person.marker));
            testData = TestData(
              test: test,
              markers: markers.toSet(),
              displayName: PeopleInPlaceTest.displayName,
            );
          }
        case (SectionCutterTest.collectionIDStatic):
          {
            polylines.add(
              Polyline(
                polylineId: PolylineId(UniqueKey().toString()),
                points: (test as SectionCutterTest).linePoints,
              ),
            );
            testData = TestData(
              test: test,
              polylines: polylines.toSet(),
              displayName: SectionCutterTest.displayName,
            );
          }
        case (SpatialBoundariesTest.collectionIDStatic):
          {
            polylines.addAll((test as SpatialBoundariesTest)
                .data
                .constructed
                .map((constructed) => constructed.polyline));
            polygons.addAll(
                (test).data.material.map((material) => material.polygon));
            polygons
                .addAll((test).data.shelter.map((shelter) => shelter.polygon));
            testData = TestData(
              test: test,
              polygons: polygons.toSet(),
              polylines: polylines.toSet(),
              displayName: SpatialBoundariesTest.displayName,
            );
          }
        default:
          {
            testData = TestData(test: test, displayName: "Unknown Type");
          }
      }
      _collectionIDToListTiles[test.collectionID] =
          _collectionIDToListTiles[test.collectionID] ?? [];
      _collectionIDToListTiles[test.collectionID]?.add(
        TestTile(
          testData: testData,
          updateFunction: (testData) {
            setState(() {
              _updateVisibility(testData);
            });
          },
        ),
      );
      polygons.clear();
      polylines.clear();
      markers.clear();
      circles.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results Page')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _location,
          zoom: _zoom,
        ),
        mapType: MapType.satellite,
        myLocationButtonEnabled: false,
        zoomGesturesEnabled: !_drawerIsOpen,
        scrollGesturesEnabled: !_drawerIsOpen,
        polygons: {_projectPolygon, ..._polygons},
        polylines: _polylines,
        markers: _markers,
        circles: _circles,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 75.0,
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'Results Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            // Show a loading indicator
            ..._expansionTiles,
          ],
        ),
      ),
      onDrawerChanged: (isOpen) {
        setState(() {
          _drawerIsOpen = isOpen;
        });
      },
    );
  }
}

class TestExpansionTile extends StatefulWidget {
  final String testType;
  final List<TestTile> testTiles;
  const TestExpansionTile({
    super.key,
    required this.testType,
    required this.testTiles,
  });

  @override
  State<TestExpansionTile> createState() => _TestExpansionTileState();
}

class _TestExpansionTileState extends State<TestExpansionTile> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        widget.testType,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      tilePadding: EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 8.0), // Optional padding for ExpansionTile
      expandedAlignment: Alignment.topLeft,
      children: widget.testTiles,
    );
  }
}

class TestTile extends StatefulWidget {
  final TestData testData;
  final void Function(TestData) updateFunction;

  const TestTile({
    super.key,
    required this.testData,
    required this.updateFunction,
  });

  @override
  State<TestTile> createState() => _TestTileState();
}

class _TestTileState extends State<TestTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.testData.test.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "Scheduled: ${widget.testData.date}\n${widget.testData.time}",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      isThreeLine: true,
      trailing: Switch(
        value: widget.testData.visibility ?? false,
        onChanged: (visible) {
          setState(() {
            widget.testData.visibility = visible;
          });
          widget.updateFunction(widget.testData);
        },
      ),
    );
  }
}

class TestData {
  final Test test;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final Set<Circle> circles;
  final String displayName;
  final String date;
  final String time;
  bool? visibility;

  TestData({
    required this.test,
    this.polygons = const {},
    this.polylines = const {},
    this.markers = const {},
    this.circles = const {},
    required this.displayName,
  })  : time = DateFormat.jmv().format(test.scheduledTime.toDate()),
        date = DateFormat.yMMMd().format(test.scheduledTime.toDate());
}
