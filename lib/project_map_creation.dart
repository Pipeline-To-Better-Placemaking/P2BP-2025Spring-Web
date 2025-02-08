import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:p2b/homepage.dart';
import 'homepage.dart';
import 'widgets.dart';
import 'db_schema_classes.dart';
import 'dart:math';

import 'firestore_functions.dart';

class ProjectMapCreation extends StatefulWidget {
  final Project partialProjectData;
  const ProjectMapCreation({super.key, required this.partialProjectData});

  @override
  State<ProjectMapCreation> createState() => _ProjectMapCreationState();
}

final User? loggedInUser = FirebaseAuth.instance.currentUser;

class _ProjectMapCreationState extends State<ProjectMapCreation> {
  DocumentReference? teamRef;
  late GoogleMapController mapController;
  LatLng _currentPosition =
      const LatLng(45.521563, -122.677433); // Default location
  bool _isLoading = true;

  List<LatLng> _polygonPoints = []; // Points for the polygon
  Set<Polygon> _polygon = {}; // Set of polygons
  List<GeoPoint> _polygonAsPoints =
      []; // The current polygon represented as points (for Firestore).
  Set<Marker> _markers = {}; // Set of markers for points

  String? _selectedPolygonId; // The ID of the selected polygon

  bool _addPointsMode = true; // Flag to add points mode
  bool _polygonMode = false; // Flag for polygon creation mode
  bool _deleteMode = false; // Flag to enable polygon deletion

  MapType _currentMapType = MapType.satellite; // Default map type

  Project? project;

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
    _getCurrentTeam();
  }

  // Function to set teamRef to current team.
  Future<void> _getCurrentTeam() async {
    try {
      teamRef = await getCurrentTeam();
      if (teamRef == null) {
        throw Exception(
            "Error populating projects in home_screen.dart. No selected team available.");
      }
    } catch (e) {
      print("Error in project_map_creation.dart, _getCurrentTeam(): $e");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation(); // Ensure the map is centered on the current location
  }

  Future<void> _checkAndFetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permission is required to use this feature.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await _getCurrentLocation();

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (e) {
      print('Error checking location permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Unable to retrieve location. Please check your GPS settings.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high, // Specify the desired accuracy
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _moveToCurrentLocation() {
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 14.0),
        ),
      );
    }
  }

  void _togglePoint(LatLng point) {
    // TODO: Probably unnecessary for current mobile implementation
    if (_deleteMode)
      return; // Prevent adding points when hovering over buttons or in delete mode

    setState(() {
      final markerId = MarkerId(point.toString());
      if (_markers.any((marker) => marker.markerId == markerId)) {
        _markers.removeWhere((marker) => marker.markerId == markerId);
        _polygonPoints.remove(point);
      } else {
        _polygonPoints.add(point);
        _markers.add(
          Marker(
            markerId: markerId,
            position: point,
            onTap: () {
              // If the marker is tapped again, it will be removed
              _togglePoint(point);
            },
          ),
        );
      }
    });
  }

  void _finalizePolygon() {
    if (_polygonPoints.length < 3) return;

    // Sort points in clockwise order
    List<LatLng> sortedPoints = _sortPointsClockwise(_polygonPoints);

    // Empty current polygon as points representation.
    _polygonAsPoints = [];

    final String polygonId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _polygon = {
        Polygon(
          polygonId: PolygonId(polygonId),
          points: sortedPoints,
          strokeColor: Colors.blue,
          strokeWidth: 2,
          fillColor: Colors.blue.withOpacity(0.2),
          onTap: () {
            setState(() {
              _selectedPolygonId =
                  polygonId; // Store the ID of the clicked polygon
            });
          },
        ),
      };
      for (LatLng coordinate in _polygonPoints) {
        _polygonAsPoints
            .add(GeoPoint(coordinate.latitude, coordinate.longitude));
      }
      _polygonPoints = [];
      _markers.clear();
      _addPointsMode =
          true; // Enable adding points again after finalizing the polygon
      _polygonMode = false; // Disable polygon mode
    });
  }

  void _removeSelectedPolygon() {
    if (_selectedPolygonId == null) return;

    setState(() {
      _polygon = {};
    });
  }

  // Function to sort points in clockwise order
  List<LatLng> _sortPointsClockwise(List<LatLng> points) {
    // Calculate the centroid of the points
    double centerX =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double centerY =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    // Sort the points based on the angle from the centroid
    points.sort((a, b) {
      double angleA =
          _calculateAngle(centerX, centerY, a.latitude, a.longitude);
      double angleB =
          _calculateAngle(centerX, centerY, b.latitude, b.longitude);
      return angleA.compareTo(angleB);
    });

    return points;
  }

  // Calculate the angle of the point relative to the centroid
  double _calculateAngle(double centerX, double centerY, double x, double y) {
    return atan2(y - centerY, x - centerX);
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Define your project area.",
                    style: TextStyle(fontSize: 24),
                  ),
                  Center(
                    child: SizedBox(
                      // TODO: Explore alternative approaches. Maps widgets automatically sizes to infinity unless declared.
                      height: MediaQuery.of(context).size.height * .8,
                      child: Padding(
                        // TODO: Define padding
                        padding: const EdgeInsets.all(0),
                        child: Stack(
                          children: [
                            GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                  target: _currentPosition, zoom: 14.0),
                              polygons: _polygon,
                              markers: _markers,
                              onTap: _addPointsMode ? _togglePoint : null,
                              mapType: _currentMapType, // Use current map type
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60.0, vertical: 90.0),
                                child: FloatingActionButton(
                                  heroTag: null,
                                  onPressed: _toggleMapType,
                                  backgroundColor: Colors.green,
                                  child: const Icon(Icons.map),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 60.0, vertical: 20.0),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: FloatingActionButton(
                                  heroTag: null,
                                  onPressed: () {
                                    setState(() {
                                      if (_polygonPoints.isEmpty) {
                                        _polygonMode = true;
                                      } else {
                                        _finalizePolygon();
                                      }
                                    });
                                  },
                                  backgroundColor: Colors.blue,
                                  child: const Icon(
                                    Icons.check,
                                    size: 35,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: EditButton(
                        text: 'Finish',
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF4871AE),
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          if (_polygon.isNotEmpty) {
                            saveProject(
                              projectTitle: widget.partialProjectData.title,
                              description:
                                  widget.partialProjectData.description,
                              teamRef: teamRef,
                              polygonPoints: _polygonAsPoints,
                            );
                            print("Successfully created project");
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(),
                                ));
                            // TODO: Push to project details page.
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePage(),
                                ));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please designate your project area, and confirm with the check button.')),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
