/*
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        AssetMapBitmap,
        BitmapDescriptor,
        CameraPosition,
        CameraUpdate,
        GoogleMap,
        GoogleMapController,
        InfoWindow,
        LatLng,
        LatLngBounds,
        MapType,
        Marker,
        MarkerId,
        Polygon,
        createLocalImageConfiguration;
import 'package:shared_preferences/shared_preferences.dart';
import 'google_maps_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'firestore_functions.dart';
import 'db_schema_classes.dart';

// Class to represent a logged data point for backend storage.
class LoggedDataPoint {
  final LatLng location;
  final String age;
  final String gender;
  final String activityType;
  final String posture;
  final DateTime timestamp;

  LoggedDataPoint({
    required this.location,
    required this.age,
    required this.gender,
    required this.activityType,
    required this.posture,
    required this.timestamp,
  });

  // Convert the data point into a JSON‑compatible map.
  Map<String, dynamic> toJson() {
    return {
      'location': {'lat': location.latitude, 'lng': location.longitude},
      'age': age,
      'gender': gender,
      'activityType': activityType,
      'posture': posture,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Conversion method to convert the list of LoggedDataPoint objects to a Firestore-friendly list
List<Map<String, dynamic>> loggedDataPointsToJson(
    List<LoggedDataPoint> dataPoints) {
  return dataPoints.map((point) => point.toJson()).toList();
}

class PeopleInPlaceTestPage extends StatefulWidget {
  final Project activeProject;
  final PeopleInPlaceTest activeTest;

  const PeopleInPlaceTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<PeopleInPlaceTestPage> createState() => _PeopleInPlaceTestPageState();
}

class _PeopleInPlaceTestPageState extends State<PeopleInPlaceTestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _hintTimer;
  bool _showHint = false;
  bool _isTestRunning = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  Set<Marker> _markers = {}; // Set of markers for points
  Set<Polygon> _polygons = {}; // Set of polygons
  MapType _currentMapType = MapType.normal; // Default map type
  bool _showErrorMessage = false;
  bool _isPointsMenuVisible = false;
  List<LatLng> _loggedPoints = [];

  // List to store backend‑compatible logged data points.
  List<LoggedDataPoint> _loggedDataPoints = [];

  // Custom marker icons

  // Male Markers
  BitmapDescriptor? standingMaleMarker;
  BitmapDescriptor? sittingMaleMarker;
  BitmapDescriptor? layingMaleMarker;
  BitmapDescriptor? squattingMaleMarker;

  // Female Markers
  BitmapDescriptor? standingFemaleMarker;
  BitmapDescriptor? sittingFemaleMarker;
  BitmapDescriptor? layingFemaleMarker;
  BitmapDescriptor? squattingFemaleMarker;

  // N/A Markers
  BitmapDescriptor? standingNAMarker;
  BitmapDescriptor? sittingNAMarker;
  BitmapDescriptor? layingNAMarker;
  BitmapDescriptor? squattingNAMarker;
  bool _customMarkersLoaded = false;

  MarkerId? _openMarkerId;

  @override
  void initState() {
    super.initState();
    print("initState called");
    _checkAndFetchLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _loadCustomMarkers();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  // Helper method to format elapsed seconds into mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Method to start the test and timer
  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _remainingSeconds = 300;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  // Method to end the test and cancel the timer
  Future<void> _endTest() async {
    setState(() {
      _isTestRunning = false;
    });
    _timer?.cancel();

    try {
      await _firestore
          .collection(widget.activeTest.collectionID)
          .doc(widget.activeTest.testID)
          .update({
        'data': loggedDataPointsToJson(_loggedDataPoints),
        'isComplete': true,
      });
      print("PeopleInPlace test data submitted successfully.");
    } catch (e, stacktrace) {
      print("Error submitting PeopleInPlace test data: $e");
      print("Stacktrace: $stacktrace");
    }
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Instructions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tap screen to log a data point.'),
              Row(
                children: [
                  // Checkbox to make sure pop up doesn't open the next time they conduct this type of test
                  Checkbox(
                    value: false,
                    onChanged: (_) {},
                  ),
                  Text("Don't show this again"),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetHintTimer() {
    // Cancel any existing timer.
    _hintTimer?.cancel();
    // Hide the hint if it was showing.
    setState(() {
      _showHint = false;
    });
    // Start a new timer.
    _hintTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _showHint = true;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      if (widget.activeProject.polygonPoints.isNotEmpty) {
        _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bounds = _getPolygonBounds(
              widget.activeProject.polygonPoints.toLatLngList());
          mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        });
      } else {
        _moveToCurrentLocation(); // Ensure the map is centered on the current location
      }
    });
  }

  Future<void> _checkAndFetchLocation() async {
    try {
      _currentLocation = await checkAndFetchLocation();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Delay popup till after the map has loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInstructionOverlay();
      });
    } catch (e, stacktrace) {
      print('Exception fetching location in project_map_creation.dart: $e');
      print('Stracktrace: $stacktrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Map failed to load. Error trying to retrieve location permissions.')),
      );
      Navigator.pop(context);
    }
  }

  LatLngBounds _getPolygonBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
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

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  // Check if tapped point is inside the polygon boundary.
  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    final List<mp.LatLng> mpPolygon = polygon
        .map((latLng) => mp.LatLng(latLng.latitude, latLng.longitude))
        .toList();
    return mp.PolygonUtil.containsLocation(
      mp.LatLng(point.latitude, point.longitude),
      mpPolygon,
      false, // Edge considered outside; change as needed.
    );
  }

  // Tap handler for People In Place
  Future<void> _handleMapTap(LatLng point) async {
    _resetHintTimer();
    // Check if tapped point is inside the polygon boundary.
    bool inside = _isPointInsidePolygon(
        point, widget.activeProject.polygonPoints.toLatLngList());
    if (!inside) {
      // If outside, show error message.
      setState(() {
        _showErrorMessage = true;
      });
      Timer(Duration(seconds: 3), () {
        setState(() {
          _showErrorMessage = false;
        });
      });
      return; // Do not proceed with logging the data point.
    }
    // Check if custom markers are loaded
    if (!_customMarkersLoaded) {
      print("Custom markers not loaded yet. Please wait.");
      return; // Prevent creating markers if not loaded
    }
    // Show bottom sheet for classification
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
      ), // Make bottom sheet full-width.
      builder: (BuildContext bottomSheetContext) {
        return PeopleInPlaceClassificationSheet(
          onSubmit: (classificationData) {
            // Marker ID values
            final String markerIdStr =
                DateTime.now().millisecondsSinceEpoch.toString();
            final MarkerId markerId = MarkerId(markerIdStr);

            final key =
                '${classificationData['posture']}_${classificationData['gender']}';
            BitmapDescriptor markerIcon;
            switch (key) {
              case 'Standing_Male':
                markerIcon =
                    standingMaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Sitting_Male':
                markerIcon =
                    sittingMaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Laying Down_Male':
                markerIcon = layingMaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Squatting_Male':
                markerIcon =
                    squattingMaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Standing_Female':
                markerIcon =
                    standingFemaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Sitting_Female':
                markerIcon =
                    sittingFemaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Laying Down_Female':
                markerIcon =
                    layingFemaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Squatting_Female':
                markerIcon =
                    squattingFemaleMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Standing_N/A':
                markerIcon = standingNAMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Sitting_N/A':
                markerIcon = sittingNAMarker ?? BitmapDescriptor.defaultMarker;
                break;
              case 'Laying Down_N/A':
                markerIcon = layingNAMarker ?? BitmapDescriptor.defaultMarker;
              default:
                markerIcon =
                    squattingNAMarker ?? BitmapDescriptor.defaultMarker;
            }
            // Once classification data is provided, add the marker with an info window.
            setState(() {
              _markers.add(
                Marker(
                  markerId: markerId,
                  position: point,
                  icon: markerIcon,
                  infoWindow: InfoWindow(
                      title: 'Age: ${classificationData['age']}', // for example
                      snippet:
                          'Gender: ${classificationData['gender']}\nActivity: ${classificationData['activityType']}\nPosture: ${classificationData['posture']}'),
                  onTap: () {
                    // Print for debugging:
                    print("Marker tapped: $markerIdStr");
                    // Use a short delay to ensure the marker is rendered,
                    // then show its info window using the same markerId.
                    if (_openMarkerId == markerId) {
                      mapController.hideMarkerInfoWindow(markerId);
                      setState(() {
                        _openMarkerId = null;
                      });
                    } else {
                      Future.delayed(Duration(milliseconds: 300), () {
                        mapController.showMarkerInfoWindow(markerId);
                        setState(() {
                          _openMarkerId = markerId;
                        });
                      });
                    }
                  },
                ),
              );
              // Create a LoggedDataPoint from the classification data.
              final loggedPoint = LoggedDataPoint(
                location: point,
                age: classificationData['age'] ?? '',
                gender: classificationData['gender'] ?? '',
                activityType: classificationData['activityType'] ?? '',
                posture: classificationData['posture'] ?? '',
                timestamp: DateTime.now(),
              );
              _loggedDataPoints.add(loggedPoint); // Store backend-ready data

              // Log the point
              _loggedPoints.add(point);
            });

            Navigator.pop(bottomSheetContext);
          },
        );
      },
    );
  }

  // Function to load custom marker icons using AssetMapBitmap.
  Future<void> _loadCustomMarkers() async {
    final ImageConfiguration configuration =
        createLocalImageConfiguration(context);
    try {
      standingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_male_marker.png',
        width: 36,
        height: 36,
      );
      sittingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_male_marker.png',
        width: 36,
        height: 36,
      );
      layingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_male_marker.png',
        width: 36,
        height: 36,
      );
      squattingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_male_marker.png',
        width: 36,
        height: 36,
      );
      standingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_male_marker.png',
        width: 36,
        height: 36,
      );
      sittingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_male_marker.png',
        width: 36,
        height: 36,
      );
      layingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_male_marker.png',
        width: 36,
        height: 36,
      );
      squattingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_male_marker.png',
        width: 36,
        height: 36,
      );
      standingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_male_marker.png',
        width: 36,
        height: 36,
      );
      sittingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_male_marker.png',
        width: 36,
        height: 36,
      );
      layingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_male_marker.png',
        width: 36,
        height: 36,
      );
      squattingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_male_marker.png',
        width: 36,
        height: 36,
      );
      setState(() {
        _customMarkersLoaded = true;
      });
      print("Custom markers loaded successfully.");
    } catch (e) {
      print("Error loading custom markers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle:
            SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        // Start/End button on the left
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20), // Rounded rectangle shape.
              ),
              backgroundColor: _isTestRunning ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              if (_isTestRunning) {
                // _endTest();
                Navigator.pop(context);
              } else {
                // _startTest();
                Navigator.pop(context);
              }
            },
            child: Text(
              _isTestRunning ? 'End' : 'Start',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        // Persistent prompt in the middle with a translucent background.
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Tap to log data point',
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        centerTitle: true,
        // Timer on the right
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map.
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14.0,
            ),
            markers: _markers,
            polygons: _polygons,
            onTap: _handleMapTap,
            mapType: _currentMapType,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_showErrorMessage)
            Positioned(
              bottom: 100.0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Please place points inside the boundary.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          // Overlaid button for toggling map type.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Center(
                  child: Icon(Icons.layers, color: Colors.white),
                ),
                onPressed: _toggleMapType,
              ),
            ),
          ),
          // Overlaid button for toggling tooltip popup to appear on the screen.
          if (!_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 70.0,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(FontAwesomeIcons.info, color: Colors.white),
                  onPressed: _showInstructionOverlay,
                ),
              ),
            ),
          // Overlaid button for toggling points menu.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 132.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                  icon: Icon(FontAwesomeIcons.locationDot, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isPointsMenuVisible = !_isPointsMenuVisible;
                    });
                  }),
            ),
          ),
          if (_isPointsMenuVisible)
            Positioned(
              bottom: 220.0,
              left: 20.0,
              right: 20.0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _loggedPoints.length,
                        itemBuilder: (context, index) {
                          final point = _loggedPoints[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              'Point ${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                              textAlign: TextAlign.left,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  // Construct the markerId the same way it was created.
                                  final markerId = MarkerId(point.toString());
                                  // Remove the marker from the markers set.
                                  _markers.removeWhere(
                                      (marker) => marker.markerId == markerId);
                                  // Remove the point from the list.
                                  _loggedPoints.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PeopleInPlaceClassificationSheet extends StatefulWidget {
  final Function(Map<String, String>) onSubmit;
  const PeopleInPlaceClassificationSheet({super.key, required this.onSubmit});

  @override
  State<PeopleInPlaceClassificationSheet> createState() =>
      _PeopleInPlaceClassificationSheetState();
}

class _PeopleInPlaceClassificationSheetState
    extends State<PeopleInPlaceClassificationSheet> {
  String? _selectedAge;
  String? _selectedGender;
  List<String> _selectedActivities = [];
  String? _selectedPosture;

  // Helper to build an option button.
  Widget _buildOptionButton(
      String option, String? selected, void Function(String) onTap) {
    final bool isSelected = option == selected;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: TextButton(
        onPressed: () => onTap(option),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(option),
      ),
    );
  }

  // Helper to build a group row with a label and option buttons.
  Widget _buildGroup(String groupName, List<String> options, String? selected,
      void Function(String) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map((option) => _buildOptionButton(option, selected, onTap))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Helper to build a group row for multi-select (for Activity Type).
  Widget _buildMultiSelectGroup(String groupName, List<String> options,
      List<String> selectedList, void Function(String) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            groupName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final bool isSelected = selectedList.contains(option);
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextButton(
                  onPressed: () {
                    onTap(option);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.blue : Colors.grey[200],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(option),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Adjusts for keyboard appearance.
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        // Use a wider container.
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Centered header text.
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: const Text(
                        'Data',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                  )
                ],
              ),
              const SizedBox(height: 20),
              // Age group.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGroup(
                      'Age',
                      ['0-14', '15-21', '22-30', '30-50', '50-65', '65+'],
                      _selectedAge, (val) {
                    setState(() {
                      _selectedAge = val;
                    });
                  }),
                  // Gender group.
                  _buildGroup(
                      'Gender', ['Male', 'Female', 'N/A'], _selectedGender,
                      (val) {
                    setState(() {
                      _selectedGender = val;
                    });
                  }),
                  // Activity Type group.
                  _buildMultiSelectGroup(
                      'Activity Type',
                      [
                        'Socializing',
                        'Waiting',
                        'Recreation',
                        'Eating',
                        'Solitary'
                      ],
                      _selectedActivities, (val) {
                    setState(() {
                      if (_selectedActivities.contains(val)) {
                        _selectedActivities.remove(val);
                      } else {
                        _selectedActivities.add(val);
                      }
                    });
                  }),
                  // Posture group.
                  _buildGroup(
                      'Posture',
                      ['Standing', 'Sitting', 'Laying Down', 'Squatting'],
                      _selectedPosture, (val) {
                    setState(() {
                      _selectedPosture = val;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 20),
              // Centered Submit button.
              ElevatedButton(
                onPressed: () {
                  // For now, just close the bottom sheet after sending data.
                  widget.onSubmit({
                    'age': _selectedAge ?? '',
                    'gender': _selectedGender ?? '',
                    'activityType': _selectedActivities.join(', '),
                    'posture': _selectedPosture ?? '',
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} */