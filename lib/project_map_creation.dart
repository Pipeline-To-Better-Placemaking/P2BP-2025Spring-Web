import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'google_maps_functions.dart';
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
  bool _showInstructions= true; // To control the visibility of the instruction box

  List<LatLng> _polygonPoints = []; // Points for polygons
  List<mp.LatLng> _mapToolsPolygonPoints = [];
  Set<Polygon> _polygon = {}; // Set of polygons
  Set<Marker> _markers = {};
  //List<GeoPoint> _polygonAsGeoPoints = []; // The current polygon represented as points (for Firestore).
  int _flagCounter = 0;
  List<Map> _standingPoints = [];

  String? _selectedPolygonId;
  LatLng _currentLocation = defaultLocation; // Default location

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
    _moveToCurrentLocation(); // Ensure the map is centered on the current location
  }

  Future<void> _checkAndFetchLocation() async {
    try {
      _currentLocation = await checkAndFetchLocation();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      print('Exception fetching location in project_map_creation.dart: $e');
      print('Stacktrace: $stacktrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Map failed to load. Error trying to retrieve location permissions.')),
      );
      Navigator.pop(context);
    }
  }

  void _moveToCurrentLocation() {
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: 14.0),
        ),
      );
    }
  }

  void _togglePoint(LatLng point) {
    if (_deleteMode || _isHoveringOverButton || _polygon.isNotEmpty) return;

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

    try {
      // Create polygon.
      _polygon = finalizePolygon(_polygonPoints);

      // Make sure _polygon is not empty before accessing first element
      if (_polygon.isNotEmpty) {
        // Print the ID of the finalized polygon for debugging
        print("Finalized Polygon ID: ${_polygon.first.polygonId.value}");
              // Print out the IDs of the polygon points (coordinates)
        for (int i = 0; i < _polygonPoints.length; i++) {
          print("Polygon Point $i: ${_polygonPoints[i].latitude}, ${_polygonPoints[i].longitude}");
        }
        // Creates Maps Toolkit representation of Polygon for checking if point
        // is inside area.
        _mapToolsPolygonPoints = _polygon.first.toMPLatLngList();

        // Clears polygon points and enter add points mode.
        _polygonPoints = [];

        // Clear markers from screen.
        setState(() {
          _markers.clear();
        });
      } else {
        print("Error: _polygon is empty after finalization.");
      }
    } catch (e, stacktrace) {
      print('Exception in _finalize_polygon(): $e');
      print('Stacktrace: $stacktrace');
    }
}

  void _removeSelectedPolygon() {
    if (_polygon.isEmpty) return;

    setState(() {
      _polygon.clear(); // Clears all polygons
      _mapToolsPolygonPoints.clear(); // Clears the Maps Toolkit representation
      _polygonPoints.clear(); // Clears the points list
      _markers.clear(); // Clears the flag markers
      _addPointsMode = true; // Allow adding new points again
      _polygonMode = false; // Exit polygon mode
    });

    print("Polygon removed successfully.");
  }

  void _addFlagMarker() {
    if (_polygon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a polygon before adding flags.')),
      );
      return;
    }

    // Use the first polygon from the set
    Polygon selectedPolygon = _polygon.first;

    // Convert google_maps_flutter LatLng to maps_toolkit LatLng
    List<mp.LatLng> toolkitPolygonPoints = selectedPolygon.points
        .map((latLng) => mp.LatLng(latLng.latitude, latLng.longitude))
        .toList();

    // Calculate centroid of the polygon
    LatLng centroid = _calculatePolygonCentroid(selectedPolygon.points);

    setState(() {
      final String flagId = 'flag_${_flagCounter++}';
      final Marker flagMarker = Marker(
        markerId: MarkerId(flagId),
        position: centroid,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          _removeFlagMarker(flagId);
        },
        onDragEnd: (LatLng newPosition) {
          // Convert the new position to maps_toolkit.LatLng
          mp.LatLng newPositionToolkit = mp.LatLng(newPosition.latitude, newPosition.longitude);
          print("Flag Marker $flagId new position: Latitude: ${newPosition.latitude}, Longitude: ${newPosition.longitude}");

          // Check if the new position is inside the selected polygon
          if (!mp.PolygonUtil.containsLocation(newPositionToolkit, toolkitPolygonPoints, false)) {
            // If the flag is outside the polygon, show a message and remove the flag
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Standing point removed. It cannot be placed outside the project area polygon.')),
            );
            _removeFlagMarker(flagId);
          }
        },
      );
      _markers.add(flagMarker);

      // Save the flag position to the standingPoints list
      _standingPoints.add({
        'id': flagId,
        'latitude': centroid.latitude,
        'longitude': centroid.longitude,
      });
    // Print the standing point ID and position
    print("Standing point added: ID=$flagId, Lat=${centroid.latitude}, Lng=${centroid.longitude}");
    print("Current standing points: $_standingPoints");
    });
  }

  // Function to calculate the centroid of a polygon
  LatLng _calculatePolygonCentroid(List<LatLng> points) {
    double centroidX = 0, centroidY = 0;
    int pointCount = points.length;

    for (LatLng point in points) {
      centroidX += point.latitude;
      centroidY += point.longitude;
    }

    return LatLng(centroidX / pointCount, centroidY / pointCount);
  }

  void _removeFlagMarker(String flagId) {
    setState(() {
      // Remove the marker from the map
      _markers.removeWhere((marker) => marker.markerId.value == flagId);

      print("Current standing points before removal: $_standingPoints");
      // Remove the corresponding standing point from the list
      _standingPoints.removeWhere((point) => point['id'] == flagId);

      print("Current standing points after removal: $_standingPoints");
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
                  polygons: _polygon.isEmpty ? {} : _polygon,
                  markers: _markers,
                  onTap: _addPointsMode ? _togglePoint : null,
                  mapType: _currentMapType,
                  onCameraMove: (CameraPosition position) {
                    _cameraCenterPosition = position.target;
                  },
                ),

                // Toggle Instruction Box
                if (_showInstructions)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0), // Adjust padding for the text
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 0, 0, 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "1️⃣ Tap on the map to define your project area polygon.\n"
                        "2️⃣ Click the ✅ button to confirm the polygon.\n"
                        "3️⃣ Press the 🚩 icon to place and move your standing points.\n"
                        "4️⃣ When you're satisfied, press 'Finish' to save your project.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Floating Action Buttons
                // Flag Button
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

                // Map change button
                Positioned(
                  bottom: 150,
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
                      onPressed: _toggleMapType,
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.map),
                    ),
                  ),
                ),

                // Finish polygon button
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
                      child: const Icon(Icons.check),
                    ),
                  ),
                ),

                // Delete polygon button
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

                // Back Button (Separate from Instruction Box)
                Positioned(
                  top: 10,
                  left: 20,
                  child: MouseRegion(
                    onEnter: (_) => setState(() {
                      _addPointsMode = false;
                      _isHoveringOverButton = true;
                    }),
                    onExit: (_) => setState(() {
                      _addPointsMode = true;
                      _isHoveringOverButton = false;
                    }),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 60, // You can change the size here
                      onPressed: () {
                        Navigator.pop(context); // Use this to go back to the previous page
                      },
                      color: _showInstructions || _currentMapType == MapType.satellite
                        ? Colors.white // If instructions are shown or map is satellite, make it white
                        : Colors.black, // Otherwise, black
                    ),
                  ),
                ),

                // Toggle Instructions Button
                Positioned(
                  top: 70, // Adjust the position as needed
                  left: 20,
                  child: MouseRegion(
                    onEnter: (_) => setState(() {
                      _addPointsMode = false;
                      _isHoveringOverButton = true;
                    }),
                    onExit: (_) => setState(() {
                      _addPointsMode = true;
                      _isHoveringOverButton = false;
                    }),
                    child: IconButton(
                      icon: const Icon(Icons.help_outline),
                      iconSize: 60, // Adjust size as needed
                      onPressed: () {
                        setState(() {
                          _showInstructions = !_showInstructions; // Toggle the instructions visibility
                        });
                      },
                      color: _showInstructions || _currentMapType == MapType.satellite
                        ? Colors.white // If instructions are shown or map is satellite, make it white
                        : Colors.black, // Otherwise, black
                    ),
                  ),
                ),

                // Finish Button
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: MouseRegion(
                    onEnter: (_) => setState(() {
                      _addPointsMode = false;
                      _isHoveringOverButton = true;
                    }),
                    onExit: (_) => setState(() {
                      _addPointsMode = true;
                      _isHoveringOverButton = false;
                    }),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4871AE),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_polygon.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please define your project area polygon first.'),
                                  ),
                                );
                                return;
                              }

                              if (_standingPoints.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Place at least one standing point before finishing.'),
                                  ),
                                );
                                return;
                              }

                              await saveProject(
                                projectTitle: widget.partialProjectData.title,
                                description: widget.partialProjectData.description,
                                teamRef: await getCurrentTeam(),
                                polygonPoints: _polygon.first.toGeoPointList(),
                                polygonArea: mp.SphericalUtil.computeArea(_mapToolsPolygonPoints) * pow(feetPerMeter, 2),
                                standingPoints: _standingPoints,
                              );

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => HomePage()),
                                (route) => false,
                              );
                            },
                      child: const Text('Finish'),
                    ),
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
