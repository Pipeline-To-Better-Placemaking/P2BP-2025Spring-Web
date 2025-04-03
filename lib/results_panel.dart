import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:p2b/pdf_output.dart';

import 'db_schema_classes.dart';
import 'results_map_data.dart';

class ResultsPage extends StatefulWidget {
  final Project activeProject;

  const ResultsPage({super.key, required this.activeProject});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  GoogleMapController? _mapController;
  List<VisualizedResults> _testData = [];
  bool _isLoading = true;
  Set<Marker> _visibleMarkers = {};
  Set<Polygon> _visiblePolygons = {};
  Set<Polyline> _visiblePolylines = {};
  Set<Circle> _visibleSoundCircle = {};
  Map<String, bool> _testVisibility = {};
  bool isDrawerOpen = false;

  // New property to store the project polygon
  Polygon? _projectPolygon;

  late Project visualized;

  // A method to create a deep copy of the Project
  Project _deepCopyProject(Project originalProject) {
    Project copiedProject = Project(
      creationTime: originalProject.creationTime,
      teamRef: originalProject.teamRef,
      projectAdmin: originalProject.projectAdmin,
      projectID: originalProject.projectID,
      title: originalProject.title,
      description: originalProject.description,
      address: originalProject.address,
      polygonPoints: originalProject.polygonPoints.toList(),
      polygonArea: originalProject.polygonArea,
      standingPoints: originalProject.standingPoints.toList(),
      testRefs: originalProject.testRefs.toList(),
      tests: originalProject.tests!.toList(),
    );
    return copiedProject;
  }

  @override
  void initState() {
    super.initState();
    _loadTestData();
    _loadProjectPolygon(); // Load the project polygon
    visualized = _deepCopyProject(widget.activeProject);
  }

  /// **Fetch test data from Firestore**
  Future<void> _loadTestData() async {
    try {
      List<VisualizedResults> testData = [];

      for (var testReference in widget.activeProject.testRefs) {
        DocumentSnapshot testDoc = await testReference.get();
        Map<String, dynamic> data = testDoc.data() as Map<String, dynamic>;

        VisualizedResults test = await VisualizedResults.fromFirebase(
          testReference.id,
          testDoc.reference.path,
          data,
        );
        testData.add(test);
      }

      setState(() {
        _testData = testData;
        _testVisibility = {for (var test in _testData) test.testID: false};
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading test data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// **Load the project polygon and center map**
  void _loadProjectPolygon() {
    // Use the polygonPoints from your project data
    List<LatLng> polygonPoints =
        List<LatLng>.from(widget.activeProject.polygonPoints);

    setState(() {
      // Create the polygon using the points
      _projectPolygon = Polygon(
        polygonId: PolygonId(widget.activeProject.projectID),
        points: polygonPoints,
        strokeColor: Colors.red,
        strokeWidth: 2,
        fillColor: Color.fromRGBO(255, 0, 0, 0.2), // Red with 20% opacity
      );
    });

    // Center the map to show the polygon
    _centerMapOnPolygon(polygonPoints);
  }

  // Finds the center of the polygon
  void _centerMapOnPolygon(List<LatLng> polygonPoints) {
    // Calculate the center of the polygon
    double northLat = polygonPoints[0].latitude;
    double southLat = polygonPoints[0].latitude;
    double eastLng = polygonPoints[0].longitude;
    double westLng = polygonPoints[0].longitude;

    for (LatLng point in polygonPoints) {
      if (point.latitude > northLat) northLat = point.latitude;
      if (point.latitude < southLat) southLat = point.latitude;
      if (point.longitude > eastLng) eastLng = point.longitude;
      if (point.longitude < westLng) westLng = point.longitude;
    }

    LatLng polygonCenter = LatLng(
      (northLat + southLat) / 2,
      (eastLng + westLng) / 2,
    );

    // Use the existing function to calculate zoom
    double zoomLevel = _calculateZoomLevel(polygonPoints);

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: polygonCenter,
        zoom: zoomLevel,
      )),
    );
  }

  /// **Calculate a zoom level based on the size of the polygon**
  /// Function to calculate the zoom level dynamically
  double _calculateZoomLevel(List<LatLng> polygonPoints) {
    // Calculate polygon area using the Shoelace formula
    double area = _calculatePolygonArea(polygonPoints);

    // Adjust zoom level based on area size
    if (area < 0.00001) {
      return 17.0; // Super close zoom for tiny polygons
    } else if (area < 0.0001) {
      return 16.0; // Small polygons
    } else if (area < 0.001) {
      return 15.0; // Medium-small polygons
    } else if (area < 0.01) {
      return 12.0; // Medium polygons
    } else if (area < 0.1) {
      return 10.0; // Large polygons
    } else {
      return 8.0; // Very large polygons, zoom out
    }
  }

  double _calculatePolygonArea(List<LatLng> points) {
    double area = 0.0;
    int j = points.length - 1; // Last point index

    for (int i = 0; i < points.length; i++) {
      area += (points[j].longitude + points[i].longitude) *
          (points[j].latitude - points[i].latitude);
      j = i; // Move to the next vertex
    }

    return area.abs() / 2.0; // Shoelace formula result
  }

  /// **Toggle visibility of a test's data**
  void _toggleTestVisibility(String testID, bool isVisible) {
    setState(() {
      _testVisibility[testID] = isVisible;
      _updateVisibleMapData();
    });
  }

  /// **Update visible markers, polylines, and polygons based on toggles**
  void _updateVisibleMapData() {
    Set<Marker> newMarkers = {};
    Set<Polyline> newPolylines = {};
    Set<Polygon> newPolygons = {};
    Set<Circle> newSoundCircle = {};

    for (var test in _testData) {
      if (_testVisibility[test.testID] == true) {
        newMarkers.addAll(test.markers);
        newPolylines.addAll(test.polylines);
        newPolygons.addAll(test.polygons);
        newSoundCircle.addAll(test.soundCircle);
      }
    }

    setState(() {
      _visibleMarkers = newMarkers;
      _visiblePolylines = newPolylines;
      _visiblePolygons = newPolygons;
      _visibleSoundCircle = newSoundCircle;
    });
  }

  List<Test> getVisibleTests() {
    return visualized.tests
            ?.where((test) => _testVisibility[test.testID] == true)
            .toList() ??
        [];
  }

  void toggleTest(Test test, bool isChecked) {
    setState(() {
      if (isChecked) {
        // Adding tests that are toggled on
        if (!visualized.tests!.contains(test)) {
          visualized.tests?.add(test);
        }
      } else {
        // Removing tests thaat aren't selected
        visualized.tests?.remove(test);
      }
    });
  }

  void filterToggledOnTests() {
    // Filter the tests based on their visibility toggle state
    visualized.tests = visualized.tests?.where((test) {
      return _testVisibility[test.testID] == true;
    }).toList();
  }

  LatLng _getPolygonCenter(List<LatLng> polygonPoints) {
    double sumLat = 0;
    double sumLng = 0;

    for (LatLng point in polygonPoints) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(sumLat / polygonPoints.length, sumLng / polygonPoints.length);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the center of the polygon
    LatLng polygonCenter =
        _getPolygonCenter(widget.activeProject.polygonPoints);

    // Calculate the zoom level dynamically based on the polygon's size
    double zoomLevel = _calculateZoomLevel(widget.activeProject.polygonPoints);

    // Create a Set for the project polygon to ensure it's always displayed
    if (_projectPolygon != null) {
      _visiblePolygons.add(_projectPolygon!);
    }

    // Define the test categories
    Map<String, List<VisualizedResults>> categorizedTests = {
      "Absence of Order": [],
      "Acoustic Profile": [],
      "Identifying Access": [],
      "Lighting Profile": [],
      "Nature Prevalence": [],
      "People in Motion": [],
      "People in Place": [],
      "Spatial Boundaries": [],
    };

    // Categorize tests based on their testName
    for (var test in _testData.where((test) =>
        test.isComplete &&
        !test.collectionID.startsWith("section_cutter_tests/"))) {
      if (test.collectionID.startsWith("absence_of_order_tests")) {
        categorizedTests["Absence of Order"]!.add(test);
      } else if (test.collectionID.startsWith("acoustic_profile_tests")) {
        categorizedTests["Acoustic Profile"]!.add(test);
      } else if (test.collectionID.startsWith("identifying_access_tests")) {
        categorizedTests["Identifying Access"]!.add(test);
      } else if (test.collectionID.startsWith("lighting_profile_tests")) {
        categorizedTests["Lighting Profile"]!.add(test);
      } else if (test.collectionID.startsWith("nature_prevalence_tests")) {
        categorizedTests["Nature Prevalence"]!.add(test);
      } else if (test.collectionID.startsWith("people_in_motion_tests")) {
        categorizedTests["People in Motion"]!.add(test);
      } else if (test.collectionID.startsWith("people_in_place_tests")) {
        categorizedTests["People in Place"]!.add(test);
      } else if (test.collectionID.startsWith("spatial_boundaries_tests")) {
        categorizedTests["Spatial Boundaries"]!.add(test);
      }
    }

    // Sort each category by scheduledTime
    for (var entry in categorizedTests.entries) {
      entry.value.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Results Page')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 100.0, // Adjust the height as per your need
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text(
                  'Results Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18, // Adjust the font size
                  ),
                ),
              ),
            ),
            if (_testData.isEmpty)
              Center(
                  child:
                      CircularProgressIndicator()) // Show a loading indicator
            else
              ...categorizedTests.entries.map((entry) => ExpansionTile(
                    title: Text(entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    tilePadding: EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 8.0), // Optional padding for ExpansionTile
                    expandedAlignment: Alignment.topLeft,
                    children: entry.value.map((test) {
                      return ListTile(
                        title: Text(test.testName),
                        subtitle: Text(
                          "Scheduled: ${DateFormat('hh:mm a, MMMM d, yyyy').format(test.scheduledTime)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Switch(
                          value: _testVisibility[test.testID] ?? false,
                          onChanged: (value) => _toggleTestVisibility(test.testID, value),
                        ),
                      );
                    }).toList(), // Align children when expanded
                  )),
          ],
        ),
      ),
      onDrawerChanged: (isOpen) {
        setState(() {
          isDrawerOpen = isOpen;
        });

        // Ensure unintended movement stops when opening the drawer
        if (isOpen) {
          Future.delayed(Duration(milliseconds: 100), () {
            _mapController
                ?.animateCamera(CameraUpdate.scrollBy(0, 0)); // Lock the camera
          });
        }
      },
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: polygonCenter,
              zoom: zoomLevel,
            ),
            markers: _visibleMarkers,
            polylines: _visiblePolylines,
            polygons: _visiblePolygons,
            circles: _visibleSoundCircle,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            mapType: MapType.satellite,
            gestureRecognizers: isDrawerOpen
                ? <Factory<OneSequenceGestureRecognizer>>{}
                    .toSet() // Disable gestures
                : {
                    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                    Factory<ScaleGestureRecognizer>(
                        () => ScaleGestureRecognizer()),
                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                    Factory<VerticalDragGestureRecognizer>(() =>
                        VerticalDragGestureRecognizer()), // Prevents scrolling
                  }.toSet(), // Enable gestures when drawer is closed
          ),
          // Button to go back
          Positioned(
            bottom: 40.0,
            left: 10.0,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                Navigator.of(context).pop();
              },
              backgroundColor: Colors.black,
              child: Icon(Icons.arrow_back,
                  color: Colors.white,
                  size: 48), // Increased size for better visibility
            ),
          ),

          // Button to go to the PDF output page
          Positioned(
            bottom: 40.0,
            right: 10.0, // Place it on the right side
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () {
                // filterToggledOnTests();
                final Project projectForPdf = _deepCopyProject(visualized);

                projectForPdf.tests = projectForPdf.tests?.where((test) {
                  bool isVisible = _testVisibility[test.testID] ?? false;
                  return isVisible;
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfReportPage(
                      activeProject: projectForPdf,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.red, // Change color for differentiation
              child: Icon(Icons.picture_as_pdf,
                  color: Colors.white, size: 48), // PDF icon
            ),
          ),
        ],
      ),
    );
  }
}
