import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_functions.dart';
import 'homepage.dart';
import 'db_schema_classes.dart';
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
  List<StandingPoint> _standingPoints = [];

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

  // Conversion from LatLng to GeoPoint
  GeoPoint latLngToGeoPoint(LatLng latLng) {
    return GeoPoint(latLng.latitude, latLng.longitude);
  }

  // Helper function to compare LatLngs with a tolerance
  bool _areLatLngsClose(LatLng a, LatLng b) {
    const double tolerance = 1e-6; // Tolerance for floating-point precision issues
    return (a.latitude - b.latitude).abs() < tolerance && (a.longitude - b.longitude).abs() < tolerance;
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

  Future<String?> _showNameInputDialog() async {
    TextEditingController nameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Standing Point Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Standing Point Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // Return null if canceled
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(nameController.text); // Return entered name
              },
            ),
          ],
        );
      },
    );
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

  // Remove a point from the polygon and markers
  void _removePoint(LatLng point) {
    setState(() {
      _polygonPoints.removeWhere((polygonPoint) =>
          _areLatLngsClose(polygonPoint, point)); // Remove from polygon

      _markers.removeWhere((marker) =>
          _areLatLngsClose(marker.position, point)); // Remove marker from map
    });
  }

  void _finalizePolygon() {
    if (_polygonPoints.isEmpty) return;

    try {
      // Create polygon.
      _polygon.add(finalizePolygon(_polygonPoints));

      // Make sure _polygon is not empty before accessing first element
      if (_polygon.isNotEmpty) {
        // Creates Maps Toolkit representation of Polygon for checking if point
        // is inside area.
        _mapToolsPolygonPoints = _polygon.first.toMPLatLngList();

        // Clears polygon points and enter add points mode.
        _polygonPoints = [];

        // Clear markers from screen.
        setState(() {
          _markers.clear();
        });
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
      _standingPoints.clear();
    });
  }

  void _addFlagMarker() async {
    if (_polygon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a polygon before adding flags.')),
      );
      return;
    }

    String? customName = await _showNameInputDialog();
    if (customName == null || customName.trim().isEmpty) {
      return; // User canceled input
    }

    // Use the first polygon from the set
    Polygon selectedPolygon = _polygon.first;

    // Convert google_maps_flutter LatLng to maps_toolkit LatLng
    List<mp.LatLng> toolkitPolygonPoints = selectedPolygon.points
        .map((latLng) => mp.LatLng(latLng.latitude, latLng.longitude))
        .toList();

    // Calculate centroid of the polygon
    LatLng centroid = _calculatePolygonCentroid(selectedPolygon.points);

    // Check if the centroid is inside the polygon
    mp.LatLng centroidToolkit = mp.LatLng(centroid.latitude, centroid.longitude);
    if (!mp.PolygonUtil.containsLocation(centroidToolkit, toolkitPolygonPoints, false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The point is outside the polygon.')),
      );
      return;
    }

    // Create a flag marker and add to the map
    String flagId = 'flag_${_flagCounter++}';
    
    // Track the position manually (using a variable instead of flagMarker.position)
    LatLng markerPosition = centroid;

    Marker flagMarker = Marker(
      markerId: MarkerId(flagId),
      position: markerPosition,
      draggable: true,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(
        title: customName,
        snippet: "Lat: ${markerPosition.latitude}, Lng: ${markerPosition.longitude}",
      ),
      onTap: () {
        if (_deleteMode) {
          setState(() {
            // Remove the marker and standing point from the lists if in delete mode
            _markers.removeWhere((marker) => marker.markerId == MarkerId(flagId));

            // Remove the standing point by comparing updated LatLng position
            _standingPoints.removeWhere((standingPoint) =>
                standingPoint.title == customName &&
                _areLatLngsClose(standingPoint.location, markerPosition));
          });
        }
      },
      onDragEnd: (LatLng newPosition) {
        // Handle the marker drag end, but ensure it is within the polygon
        mp.LatLng newPositionToolkit = mp.LatLng(newPosition.latitude, newPosition.longitude);

        if (!mp.PolygonUtil.containsLocation(newPositionToolkit, toolkitPolygonPoints, false)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Standing point removed. It cannot be placed outside the project area polygon.')),
          );
          setState(() {
            // Remove the marker and standing point from the lists if it’s outside the polygon
            _markers.removeWhere((marker) => marker.markerId == MarkerId(flagId));
            _standingPoints.removeWhere((standingPoint) =>
                standingPoint.title == customName &&
                _areLatLngsClose(standingPoint.location, markerPosition)); // Remove by centroid (original position)
          });
        } else {
          // Update the position of the marker and the standing point
          setState(() {
            markerPosition = newPosition;  // Update the position manually
            
            // Update the marker's position and infoWindow with new coordinates
            _markers = _markers.map((marker) {
              if (marker.markerId == MarkerId(flagId)) {
                return marker.copyWith(
                  positionParam: markerPosition,
                  infoWindowParam: InfoWindow(
                    title: customName,
                    snippet: "Lat: ${markerPosition.latitude}, Lng: ${markerPosition.longitude}",
                  ),
                );
              }
              return marker;
            }).toSet();

            // Update the standing point with the new position
            _standingPoints = _standingPoints.map((point) {
              if (point.title == customName) {
                return StandingPoint(title: customName, location: markerPosition);
              }
              return point;
            }).toList();

          });
        }
      },
    );
    _markers.add(flagMarker);

    // Save the flag position with the custom name and LatLng as GeoPoint
    _standingPoints.add(StandingPoint(title: customName, location: centroid));

    // Trigger a UI update to ensure the marker is displayed
    setState(() {});
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
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
                  bottom: 150,
                  right: 120,
                  child: Tooltip(
                    message: 'Add Standing Points',
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
                        heroTag: null,
                        onPressed: () {
                          // Disable delete mode when adding a flag
                          if (_deleteMode) {
                            setState(() {
                              _deleteMode = false; // Disable delete mode when adding a flag
                            });
                          }
                          _addFlagMarker();
                        },
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.flag),
                      ),
                    ),
                  ),
                ),

                // Delete Mode Button
                Positioned(
                  bottom: 85,
                  right: 120,
                  child: Tooltip(
                    message: 'Toggle Delete Mode for Standing Points',
                    child: MouseRegion(
                      onEnter: (_) => setState(() {
                        _isHoveringOverButton = true;
                      }),
                      onExit: (_) => setState(() {
                        _isHoveringOverButton = false;
                      }),
                      child: FloatingActionButton(
                        heroTag: null,
                        onPressed: () {
                          if (_polygon.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No polygon area to delete')),
                            );
                          } else if (_standingPoints.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No standing points to delete')),
                            );
                          } else {
                            setState(() {
                              _deleteMode = !_deleteMode; // Toggle delete mode
                            });
                          }
                        },
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.delete),
                      ),
                    ),
                  ),
                ),

                // Map change button
                Positioned(
                  bottom: 150,
                  right: 55,
                  child: Tooltip(
                    message: 'Toggle Map Type',
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
                        heroTag: null,
                        onPressed: _toggleMapType,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.map),
                      ),
                    ),
                  ),
                ),

                // Finish polygon button
                Positioned(
                  bottom: 85,
                  right: 55,
                  child: Tooltip(
                    message: 'Finalize Polygon',
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
                        heroTag: null,
                        onPressed: () {
                          if (_polygonPoints.length < 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('At least 3 points are required to create a polygon.')),
                            );
                          } else {
                            _finalizePolygon(); // Only finalize polygon if there are 3 or more standing points
                          }
                        },
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.check),
                      ),
                    ),
                  ),
                ),

                // Delete polygon button
                Positioned(
                  bottom: 20,
                  right: 55,
                  child: Tooltip(
                    message: 'Delete Polygon',
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
                        heroTag: null,
                        onPressed: () async {
                        if (_polygon.isNotEmpty) {
                          // Use the _confirmDelete function to show the dialog
                          bool confirmDelete = await _confirmDelete();

                          // If user confirms, remove the polygon
                          if (confirmDelete) {
                            setState(() {
                              _removeSelectedPolygon(); // Call the function to remove the polygon
                            });
                          }
                        } else {
                          // If no polygon exists, show a message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No project area to delete.'),
                            ),
                          );
                        }
                      },
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.delete),
                      ),
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
                      iconSize: 60,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      color: _showInstructions || _currentMapType == MapType.satellite
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),

                // Toggle Instructions Button
                Positioned(
                  top: 70,
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
                      iconSize: 60,
                      onPressed: () {
                        setState(() {
                          _showInstructions = !_showInstructions;
                        });
                      },
                      color: _showInstructions || _currentMapType == MapType.satellite
                          ? Colors.white
                          : Colors.black,
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
                                address: widget.partialProjectData.address,
                                polygonPoints: _polygon.first.points,
                                polygonArea: _polygon.first.getAreaInSquareFeet(),
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

  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this polygon?'),
        actions: [
          MouseRegion(
            onEnter: (_) => setState(() {
              _addPointsMode = false; // Disable point adding when hovering over the Cancel button
            }),
            onExit: (_) => setState(() {
              _addPointsMode = true; // Re-enable point adding when not hovering over the button
            }),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          MouseRegion(
            onEnter: (_) => setState(() {
              _addPointsMode = false; // Disable point adding when hovering over the Delete button
            }),
            onExit: (_) => setState(() {
              _addPointsMode = true; // Re-enable point adding when not hovering over the button
            }),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.satellite ? MapType.normal : MapType.satellite;
    });
  }
}
