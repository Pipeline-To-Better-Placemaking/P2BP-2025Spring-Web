import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'homepage.dart';
import 'db_schema_classes.dart';
import 'dart:math';
import 'firestore_functions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class ProjectMapCreation extends StatefulWidget {
  final Project partialProjectData;
  const ProjectMapCreation({super.key, required this.partialProjectData});

  @override
  State<ProjectMapCreation> createState() => _ProjectMapCreationState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final User? loggedInUser = FirebaseAuth.instance.currentUser;

class _ProjectMapCreationState extends State<ProjectMapCreation> {
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(28.6024, -81.2001);
  LatLng _cameraCenterPosition = const LatLng(28.6024, -81.2001);
  bool _isLoading = true;

  List<LatLng> _polygonPoints = []; // Points for polygons
  List<mp.LatLng> _mapToolsPolygonPoints = [];
  Polygon? _polygon;
  Set<Marker> _markers = {};
  List<GeoPoint> _polygonAsPoints = []; // The current polygon represented as points (for Firestore).
  int _flagCounter = 0;

  String? _selectedPolygonId;

  bool _addPointsMode = true;
  bool _polygonMode = false;
  bool _deleteMode = false;
  bool _isHoveringOverButton = false;

  MapType _currentMapType = MapType.satellite;

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation();
  }

  Future<void> _checkAndFetchLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to use this feature.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await _getCurrentLocation();

    } catch (e) {
      print('Error checking location permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to retrieve location. Please check your GPS settings.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _moveToCurrentLocation() {
    if (_currentPosition != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 14.0),
        ),
      );
    }
  }

  void _togglePoint(LatLng point) {
    if (_deleteMode || _isHoveringOverButton || _polygon != null) return;

    setState(() {
      _polygonPoints.add(point);
      _markers.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        onTap: () => _removePoint(point),
      ));
    });
  }

  void _removePoint(LatLng point) {
    setState(() {
      _markers.removeWhere((marker) => marker.position == point);
    });
  }

  void _finalizePolygon() {
    if (_polygonPoints.isEmpty) return;

    List<LatLng> sortedPoints = _sortPointsClockwise(_polygonPoints);

    // Empty current polygon as points representation
    _polygonAsPoints = [];
    _mapToolsPolygonPoints = [];

    final String polygonId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _polygon = Polygon(
        polygonId: PolygonId(polygonId),
        points: sortedPoints,
        strokeColor: Colors.blue,
        strokeWidth: 2,
        fillColor: Color(0x330000FF), // 20% opacity blue
        onTap: () {
          setState(() {
            _selectedPolygonId = polygonId;
          });
        },
      );

      // Creating points representations for Firestore storage and area calculation
      for (LatLng coordinate in _polygonPoints) {
        _polygonAsPoints
            .add(GeoPoint(coordinate.latitude, coordinate.longitude));
        _mapToolsPolygonPoints
            .add(mp.LatLng(coordinate.latitude, coordinate.longitude));
      }

      _polygonPoints = [];
      _markers.clear();
      _addPointsMode = true;
      _polygonMode = false;
    });
  }

  void _removeSelectedPolygon() {
    if (_polygon == null) return;

    setState(() {
      _polygon = null;
      _addPointsMode = true;
    });
  }

  List<LatLng> _sortPointsClockwise(List<LatLng> points) {
    double centerX = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double centerY = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    points.sort((a, b) {
      double angleA = _calculateAngle(centerX, centerY, a.latitude, a.longitude);
      double angleB = _calculateAngle(centerX, centerY, b.latitude, b.longitude);
      return angleA.compareTo(angleB);
    });

    return points;
  }

  double _calculateAngle(double centerX, double centerY, double x, double y) {
    return atan2(y - centerY, x - centerX);
  }

  void _addFlagMarker() {
    if (_polygon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a polygon before adding flags.')),
      );
      return;
    }

    setState(() {
      final String flagId = 'flag_${_flagCounter++}';
      final Marker flagMarker = Marker(
        markerId: MarkerId(flagId),
        position: _cameraCenterPosition,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          _removeFlagMarker(flagId);
        },
        onDragEnd: (LatLng newPosition) {
          print("Flag $flagId moved to: $newPosition");
        },
      );
      _markers.add(flagMarker);
    });
  }

  void _removeFlagMarker(String flagId) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == flagId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(target: _currentPosition, zoom: 14.0),
                  polygons: _polygon == null ? {} : {_polygon!},
                  markers: _markers,
                  onTap: _addPointsMode ? _togglePoint : null,
                  mapType: _currentMapType,
                  onCameraMove: (CameraPosition position) {
                    _cameraCenterPosition = position.target;
                  },
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Define your project area.",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 215,
                  right: 55,
                  child: MouseRegion(
                    onEnter: (_) => setState(() {
                      _addPointsMode = false;
                      _isHoveringOverButton = true;
                    }),
                    onExit: (_) => setState(() {
                      _addPointsMode = true;
                      _isHoveringOverButton = false;
                    }),
                    child: FloatingActionButton(
                      onPressed: _addFlagMarker,
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.flag),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 150,
                  right: 55,
                  child: FloatingActionButton(
                    onPressed: _toggleMapType,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.map),
                  ),
                ),
                Positioned(
                  bottom: 85,
                  right: 55,
                  child: MouseRegion(
                    onEnter: (_) => setState(() {
                      _addPointsMode = false;
                      _isHoveringOverButton = true;
                    }),
                    onExit: (_) => setState(() {
                      _addPointsMode = true;
                      _isHoveringOverButton = false;
                    }),
                    child: FloatingActionButton(
                      onPressed: _finalizePolygon,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 55,
                  child: MouseRegion(
                    onEnter: (_) => setState(() {
                      _addPointsMode = false;
                      _isHoveringOverButton = true;
                    }),
                    onExit: (_) => setState(() {
                      _addPointsMode = true;
                      _isHoveringOverButton = false;
                    }),
                    child: FloatingActionButton(
                      onPressed: _removeSelectedPolygon,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.delete),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4871AE),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () async {
                      if (_polygon != null) {
                        await saveProject(
                          projectTitle: widget.partialProjectData.title,
                          description: widget.partialProjectData.description,
                          teamRef: await getCurrentTeam(),
                          polygonPoints: _polygonAsPoints,
                          // Polygon area is square meters
                          // (miles *= 0.00062137 * 0.00062137)
                          polygonArea: mp.SphericalUtil.computeArea(_mapToolsPolygonPoints),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please designate your project area and confirm with the check button.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Finish'),
                  ),
                ),
              ],
            ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite ? MapType.normal : MapType.satellite;
    });
  }
}
