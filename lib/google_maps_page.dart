import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class GoogleMapsPage extends StatefulWidget {
  const GoogleMapsPage({super.key});

  @override
  State<GoogleMapsPage> createState() => _GoogleMapsPageState();
}

class _GoogleMapsPageState extends State<GoogleMapsPage> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(45.521563, -122.677433); // Default location
  bool _isLoading = true;

  List<LatLng> _polygonPoints = []; // Points for the polygon
  Set<Polygon> _polygons = {}; // Set of polygons
  Set<Marker> _markers = {}; // Set of markers for points

  String? _selectedPolygonId; // The ID of the selected polygon

  bool _addPointsMode = true; // Flag to add points mode
  bool _polygonMode = false; // Flag for polygon creation mode
  bool _deleteMode = false; // Flag to enable polygon deletion
  bool _isHoveringOverButton = false; // Track if the mouse is hovering over a button

  MapType _currentMapType = MapType.satellite; // Default map type

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation(); // Ensure the map is centered on the current location
  }

  Future<void> _checkAndFetchLocation() async {
    try {
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
        desiredAccuracy: LocationAccuracy.high,
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
    if (_deleteMode || _isHoveringOverButton) return; // Prevent adding points when hovering over buttons or in delete mode

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
    if (_polygonPoints.isEmpty) return;

    // Sort points in clockwise order
    List<LatLng> sortedPoints = _sortPointsClockwise(_polygonPoints);

    final String polygonId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _polygons.add(
        Polygon(
          polygonId: PolygonId(polygonId),
          points: sortedPoints,
          strokeColor: Colors.blue,
          strokeWidth: 2,
          fillColor: Colors.blue.withOpacity(0.2),
          onTap: () {
            setState(() {
              _selectedPolygonId = polygonId; // Store the ID of the clicked polygon
            });
          },
        ),
      );
      _polygonPoints = [];
      _markers.clear();
      _addPointsMode = true; // Enable adding points again after finalizing the polygon
      _polygonMode = false; // Disable polygon mode
    });
  }

  void _removeSelectedPolygon() {
    if (_selectedPolygonId == null) return;

    setState(() {
      _polygons.removeWhere((polygon) => polygon.polygonId.value == _selectedPolygonId);
      _selectedPolygonId = null; // Clear the selection
      _addPointsMode = true; // Enable adding points again after deleting a polygon
    });
  }

  // Function to sort points in clockwise order
  List<LatLng> _sortPointsClockwise(List<LatLng> points) {
    // Calculate the centroid of the points
    double centerX = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double centerY = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    // Sort the points based on the angle from the centroid
    points.sort((a, b) {
      double angleA = _calculateAngle(centerX, centerY, a.latitude, a.longitude);
      double angleB = _calculateAngle(centerX, centerY, b.latitude, b.longitude);
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
      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
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
                  polygons: _polygons,
                  markers: _markers,
                  onTap: _addPointsMode ? _togglePoint : null,
                  mapType: _currentMapType, // Use current map type
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
                    onEnter: (_) {
                      setState(() {
                        _addPointsMode = false;
                        _isHoveringOverButton = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _addPointsMode = true;
                        _isHoveringOverButton = false;
                      });
                    },
                    child: FloatingActionButton(
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
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 55,
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _addPointsMode = false;
                        _isHoveringOverButton = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _addPointsMode = true;
                        _isHoveringOverButton = false;
                      });
                    },
                    child: FloatingActionButton(
                      onPressed: _removeSelectedPolygon,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.delete),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
