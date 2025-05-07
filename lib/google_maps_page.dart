import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class GoogleMapsPage extends StatefulWidget {
  @override
  _GoogleMapsPageState createState() => _GoogleMapsPageState();
}

class _GoogleMapsPageState extends State<GoogleMapsPage> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(45.521563, -122.677433);
  LatLng _cameraCenterPosition = const LatLng(45.521563, -122.677433);
  bool _isLoading = true;

  List<LatLng> _polygonPoints = [];
  Polygon? _polygon;
  Set<Marker> _markers = {};
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
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
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
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 14.0),
      ),
    );
  }

  void _togglePoint(LatLng point) {
    if (_deleteMode || _isHoveringOverButton) return;

    if (_polygon == null) {
      setState(() {
        _polygonPoints.add(point);
        _markers.add(Marker(
          markerId: MarkerId(point.toString()),
          position: point,
          onTap: () => _removePoint(point),
        ));
      });
    } else {
      if (isPointInsidePolygon(point, _polygon!.points)) {
        setState(() {
          _markers.add(Marker(
            markerId: MarkerId(point.toString()),
            position: point,
            onTap: () => _removePoint(point),
          ));
        });
      } else {
        print("Point is outside the polygon!");
      }
    }
  }

  void _removePoint(LatLng point) {
    setState(() {
      _markers.removeWhere((marker) => marker.position == point);
    });
  }

  bool isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    return rayCastingAlgorithm(point, polygon);
  }

  bool rayCastingAlgorithm(LatLng point, List<LatLng> polygon) {
    int n = polygon.length;
    bool inside = false;
    double xinters;
    LatLng p1 = polygon[0], p2;

    for (int i = 1; i <= n; i++) {
      p2 = polygon[i % n];
      if (point.latitude > min(p1.latitude, p2.latitude)) {
        if (point.latitude <= max(p1.latitude, p2.latitude)) {
          if (point.longitude <= max(p1.longitude, p2.longitude)) {
            if (p1.latitude != p2.latitude) {
              xinters = (point.latitude - p1.latitude) *
                      (p2.longitude - p1.longitude) /
                      (p2.latitude - p1.latitude) +
                  p1.longitude;
              if (p1.longitude == p2.longitude || point.longitude <= xinters) {
                inside = !inside;
              }
            }
          }
        }
      }
      p1 = p2;
    }
    return inside;
  }

  void _finalizePolygon() {
    if (_polygonPoints.isEmpty) return;

    List<LatLng> sortedPoints = _sortPointsClockwise(_polygonPoints);

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
    double centerX =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double centerY =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    points.sort((a, b) {
      double angleA =
          _calculateAngle(centerX, centerY, a.latitude, a.longitude);
      double angleB =
          _calculateAngle(centerX, centerY, b.latitude, b.longitude);
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
        const SnackBar(
            content: Text('Please create a polygon before adding flags.')),
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
          if (isPointInsidePolygon(newPosition, _polygon!.points)) {
            print("Flag $flagId placed inside the polygon!");
          } else {
            print("Flag $flagId placed outside the polygon!");
          }
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
                  initialCameraPosition:
                      CameraPosition(target: _currentPosition, zoom: 14.0),
                  polygons: _polygon == null ? {} : {_polygon!},
                  markers: _markers,
                  onTap: _addPointsMode ? _togglePoint : null,
                  mapType: _currentMapType,
                  onCameraMove: (CameraPosition position) {
                    _cameraCenterPosition = position.target;
                  },
                ),
                // Define your project area text
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    "Define your project area.",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              ],
            ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite
          ? MapType.normal
          : MapType.satellite;
    });
  }
}
