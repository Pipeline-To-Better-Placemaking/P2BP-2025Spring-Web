import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'results_map_data.dart';
import 'results_firebase.dart';
import 'db_schema_classes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show Factory;

class ResultsPage extends StatefulWidget {
  final Project projectData;

  const ResultsPage({Key? key, required this.projectData}) : super(key: key);

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  GoogleMapController? _mapController;
  List<VisualizedResults> _testData = [];
  bool _isLoading = true;
  Set<Marker> _visibleMarkers = {};
  Set<Polygon> _visiblePolygons = {};
  Set<Polyline> _visiblePolylines = {};
  Map<String, bool> _testVisibility = {};
  bool isDrawerOpen = false;

  // New property to store the project polygon
  Polygon? _projectPolygon;

  @override
  void initState() {
    super.initState();
    _loadTestData();
    _loadProjectPolygon(); // Load the project polygon
  }

  /// **Fetch test data from Firestore**
  Future<void> _loadTestData() async {
    try {
      List<VisualizedResults> testData = [];

      for (var testReference in widget.projectData.testRefs) {
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
    List<LatLng> polygonPoints = List<LatLng>.from(widget.projectData.polygonPoints);

    setState(() {
      // Create the polygon using the points
      _projectPolygon = Polygon(
        polygonId: PolygonId(widget.projectData.projectID),
        points: polygonPoints,
        strokeColor: Colors.blue,
        strokeWidth: 2,
        fillColor: Color.fromRGBO(0, 0, 255, 0.2), // Blue with 20% opacity
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
    //print("Polygon area: $area");

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

    for (var test in _testData) {
      if (_testVisibility[test.testID] == true) {
        newMarkers.addAll(test.markers);
        newPolylines.addAll(test.polylines);
        newPolygons.addAll(test.polygons);
      }
    }

    setState(() {
      _visibleMarkers = newMarkers;
      _visiblePolylines = newPolylines;
      _visiblePolygons = newPolygons;
    });
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
    LatLng polygonCenter = _getPolygonCenter(widget.projectData.polygonPoints);

    // Calculate the zoom level dynamically based on the polygon's size
    double zoomLevel = _calculateZoomLevel(widget.projectData.polygonPoints);

    // Create a Set for the project polygon to ensure it's always displayed
    if (_projectPolygon != null) {
      _visiblePolygons.add(_projectPolygon!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Results Page'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Results Panel'),
            ),
            for (var test in _testData.where((test) => test.isComplete && !test.collectionID.startsWith("section_cutter_tests/"))) 
              ListTile(
                title: Text(test.testName),
                trailing: Switch(
                  value: _testVisibility[test.testID] ?? false,
                  onChanged: (value) => _toggleTestVisibility(test.testID, value),
                ),
              ),
          ],
        ),
      ),
      onDrawerChanged: (isOpen) {
        setState(() {
          isDrawerOpen = isOpen;
        });
      },
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: polygonCenter,
          zoom: zoomLevel,
        ),
        markers: _visibleMarkers,
        polylines: _visiblePolylines,
        polygons: _visiblePolygons, // Use the Set with the project polygon + toggled polygons
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        mapType: MapType.satellite,

        // ✅ Disable map gestures when the drawer is open
        gestureRecognizers: isDrawerOpen
            ? <Factory<OneSequenceGestureRecognizer>>{}.toSet() // No gestures allowed
            : {
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              }.toSet(), // Enable gestures when drawer is closed
      ),
    );
  }
}