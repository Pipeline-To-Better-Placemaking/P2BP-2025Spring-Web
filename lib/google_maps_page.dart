import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  bool _isAddingPoint = false; // Flag to track if the user is in "add point" mode
  bool _isRemovingPoint = false; // Flag to track if the user is in "remove point" mode

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

  void _addPoint(LatLng point) {
    if (_isAddingPoint) {
      setState(() {
        // If the point already exists in the markers, remove it
        final markerId = MarkerId(point.toString());
        if (_markers.any((marker) => marker.markerId == markerId)) {
          _markers.removeWhere((marker) => marker.markerId == markerId);
          _polygonPoints.remove(point);
        } else {
          // Otherwise, add the point
          _polygonPoints.add(point);
          _markers.add(
            Marker(
              markerId: markerId,
              position: point,
              onTap: () {
                // If the marker is tapped, remove it
                _removePoint(point);
              },
            ),
          );
        }
      });
    }
  }

  void _removePoint(LatLng point) {
    if (_isRemovingPoint) {
      setState(() {
        _polygonPoints.remove(point);
        _markers.removeWhere((marker) => marker.position == point);
      });
    }
  }

  void _finalizePolygon() {
    if (_polygonPoints.isEmpty) return;

    final String polygonId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _polygons.add(
        Polygon(
          polygonId: PolygonId(polygonId),
          points: _polygonPoints,
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
    });
  }

  void _removeSelectedPolygon() {
    if (_selectedPolygonId == null) return;

    setState(() {
      _polygons.removeWhere((polygon) => polygon.polygonId.value == _selectedPolygonId);
      _selectedPolygonId = null; // Clear the selection
    });
  }

  void _startAddingPoint() {
    setState(() {
      _isAddingPoint = true;
      _isRemovingPoint = false;
    });
  }

  void _startRemovingPoint() {
    setState(() {
      _isAddingPoint = false;
      _isRemovingPoint = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.0, // Keep the zoom level consistent
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            polygons: _polygons,
            markers: _markers,
            onTap: (point) {
              if (_isAddingPoint && !_isButtonArea(point)) {
                _addPoint(point);
              } else if (_isRemovingPoint && !_isButtonArea(point)) {
                _removePoint(point);
              }
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 20,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _startAddingPoint,
                  heroTag: 'add',
                  child: const Icon(Icons.add_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _startRemovingPoint,
                  heroTag: 'remove',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _finalizePolygon,
                  heroTag: 'finalize',
                  child: const Icon(Icons.done),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _removeSelectedPolygon,
                  heroTag: 'remove_polygon',
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isButtonArea(LatLng point) {
    // Check if the tapped point is near the bottom-right corner of the screen
    // You can adjust the threshold based on your layout
    const double buttonAreaMargin = 0.01;  // Adjust this based on your layout

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Example condition to consider taps near the bottom right as the "button area"
    return point.latitude < _currentPosition.latitude + buttonAreaMargin &&
           point.longitude > _currentPosition.longitude + buttonAreaMargin;
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
