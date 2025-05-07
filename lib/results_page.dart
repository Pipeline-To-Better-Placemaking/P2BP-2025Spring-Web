import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:p2b/extensions.dart';
import 'package:p2b/pdf_output.dart';
import 'package:p2b/widgets.dart';
import 'package:collection/collection.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes/specific_test_classes/absence_of_order_test_class.dart';
import 'db_schema_classes/specific_test_classes/access_profile_test_class.dart';
import 'db_schema_classes/specific_test_classes/acoustic_profile_test_class.dart';
import 'db_schema_classes/specific_test_classes/lighting_profile_test_class.dart';
import 'db_schema_classes/specific_test_classes/nature_prevalence_test_class.dart';
import 'db_schema_classes/specific_test_classes/people_in_motion_test_class.dart';
import 'db_schema_classes/specific_test_classes/people_in_place_test_class.dart';
import 'db_schema_classes/specific_test_classes/section_cutter_test_class.dart';
import 'db_schema_classes/specific_test_classes/spatial_boundaries_test_class.dart';
import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/test_class.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class ResultsPage extends StatefulWidget {
  final Project activeProject;
  const ResultsPage({required this.activeProject, super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

Map<String, String> testStaticStrings = {
  AbsenceOfOrderTest.displayName: AbsenceOfOrderTest.collectionIDStatic,
  AcousticProfileTest.displayName: AcousticProfileTest.collectionIDStatic,
  AccessProfileTest.displayName: AccessProfileTest.collectionIDStatic,
  LightingProfileTest.displayName: LightingProfileTest.collectionIDStatic,
  NaturePrevalenceTest.displayName: NaturePrevalenceTest.collectionIDStatic,
  PeopleInMotionTest.displayName: PeopleInMotionTest.collectionIDStatic,
  PeopleInPlaceTest.displayName: PeopleInPlaceTest.collectionIDStatic,
  SectionCutterTest.displayName: SectionCutterTest.collectionIDStatic,
  SpatialBoundariesTest.displayName: SpatialBoundariesTest.collectionIDStatic,
};

class _ResultsPageState extends State<ResultsPage> {
  bool _drawerIsOpen = false;
  bool _isLoading = true;
  late GoogleMapController _mapController;

  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  LatLng _location = defaultLocation;
  double _zoom = 18;
  MapType _currentMapType = MapType.satellite;
  late final Polygon _projectPolygon;
  late final List<mp.LatLng> _projectPoints;

  final Map<String, List<TestTile>> _collectionIDToListTiles = {};
  late final List<TestExpansionTile> _expansionTiles;
  final List<Test> _pdfTests = [];

  @override
  void initState() {
    super.initState();
    _projectPolygon = widget.activeProject.polygon.clone();
    _location = getPolygonCentroid(_projectPolygon);
    _projectPoints = _projectPolygon.toMPLatLngList();
    _zoom = getIdealZoom(_projectPoints, _location.toMPLatLng());
    _expansionTiles = _getExpansionTiles();
  }

  /// Updates visibility of testData, including their respective shapes.
  ///
  /// Toggles visibility of shapes for given testData object. Also adds or
  /// removes it from the list of PDF tests to be sent to the PDF page
  /// accordingly.
  void _updateVisibility(TestData testData) {
    if (testData.visibility == true) {
      setState(() {
        _pdfTests.add(testData.test);
        _polygons.addAll(testData.polygons);
        _polylines.addAll(testData.polylines);
        _markers.addAll(testData.markers);
        _circles.addAll(testData.circles);
      });
    } else {
      setState(() {
        _pdfTests.remove(testData.test);
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

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
  }

  /// Moves camera to project location.
  void _moveToLocation() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
      ),
    );
  }

  /// Creates expansion tiles list for results drawer.
  ///
  /// Returns a [List] of [ExpansionTile]s to use in the results drawer.
  /// Populates the Expansion Tiles with their appropriate children
  /// ([TestTile]s)
  List<TestExpansionTile> _getExpansionTiles() {
    List<TestExpansionTile> expansionTiles = [];
    _processProject();
    for (String name in testStaticStrings.keys) {
      expansionTiles.add(TestExpansionTile(
          testType: name,
          testTiles: _collectionIDToListTiles[testStaticStrings[name]] ?? []));
    }
    setState(() {
      _isLoading = false;
    });
    return expansionTiles;
  }

  /// Process all data from project object into appropriate representation.
  ///
  /// Extracts polygons, polylines, markers, circles from all project's test
  /// and puts them in their appropriate testData object.
  void _processProject() {
    final Set<Polygon> polygons = {};
    final Set<Polyline> polylines = {};
    final Set<Marker> markers = {};
    final Set<Circle> circles = {};
    TestData testData;

    if (widget.activeProject.tests == null) {
      widget.activeProject.loadAllTestInfo();
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
                    strokeColor: Color(0x90F000F0),
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
        case (AccessProfileTest.collectionIDStatic):
          {
            polygons.addAll((test as AccessProfileTest)
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
              displayName: AccessProfileTest.displayName,
            );
          }
        case (LightingProfileTest.collectionIDStatic):
          {
            markers.addAll((test as LightingProfileTest)
                .data
                .lights
                .map((light) => light.marker));
            testData = TestData(
              test: test,
              markers: markers.toSet(),
              displayName: LightingProfileTest.displayName,
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Results Page'),
        backgroundColor: const Color(0xEDFFFFFF),
        actionsPadding: EdgeInsets.only(right: 15.0),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.home),
            iconSize: 35.0,
          )
        ],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _location,
              zoom: _zoom,
            ),
            mapType: _currentMapType,
            myLocationButtonEnabled: false,
            zoomGesturesEnabled: !_drawerIsOpen,
            scrollGesturesEnabled: !_drawerIsOpen,
            polygons: {_projectPolygon, ..._polygons},
            polylines: _polylines,
            markers: _markers,
            circles: _circles,
          ),
          Padding(
            padding:
                const EdgeInsets.only(right: 15.0, top: kToolbarHeight + 15.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                spacing: 10,
                children: <Widget>[
                  // Map type button
                  CircularIconMapButton(
                    backgroundColor: Colors.green,
                    borderColor: Color(0xFF2D6040),
                    onPressed: () {
                      _toggleMapType();
                    },
                    icon: const Icon(Icons.map),
                  ),
                  // PDF page button
                  CircularIconMapButton(
                    backgroundColor: Colors.red,
                    borderColor: Color(0xFF2D6040),
                    onPressed: () {
                      // Create project to pass to PDF with only visible tests.
                      Project projectForPdf = Project(
                        teamRef: widget.activeProject.teamRef,
                        title: widget.activeProject.title,
                        description: widget.activeProject.description,
                        address: widget.activeProject.address,
                        polygonArea: widget.activeProject.polygonArea,
                        standingPoints: widget.activeProject.standingPoints,
                        testRefs: widget.activeProject.testRefs,
                        tests: _pdfTests,
                        id: widget.activeProject.id,
                        memberRefMap: widget.activeProject.memberRefMap,
                        polygon: widget.activeProject.polygon,
                      );
                      // Go to PDF Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfReportPage(
                            activeProject: projectForPdf,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                  ),
                ],
              ),
            ),
          )
        ],
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
            if (_isLoading) CircularProgressIndicator(),
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

class TestExpansionTile extends StatelessWidget {
  final String testType;
  final List<TestTile> testTiles;

  const TestExpansionTile({
    super.key,
    required this.testType,
    required this.testTiles,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        testType,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      tilePadding: EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 8.0), // Optional padding for ExpansionTile
      expandedAlignment: Alignment.topLeft,
      children: testTiles,
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

  /// TestData object containing the extracted shapes from a test object, and
  /// the test itself to send through to the PDF page. Also contains a
  /// visibility boolean to update visible shapes accordingly.
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
