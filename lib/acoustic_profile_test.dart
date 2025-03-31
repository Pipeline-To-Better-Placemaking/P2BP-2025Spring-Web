import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        CameraPosition,
        CameraUpdate,
        GoogleMap,
        GoogleMapController,
        LatLng,
        LatLngBounds,
        MapType,
        Marker,
        Polygon,
        createLocalImageConfiguration;
import 'package:geolocator/geolocator.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'google_maps_functions.dart';
import 'people_in_place_instructions.dart'; // for _showInstructionOverlay
import 'project_details_page.dart';

// Data model to store one acoustic measurement
class AcousticMeasurement {
  final double decibel;
  final List<String> soundTypes;
  final String mainSoundType;
  final DateTime timestamp;

  AcousticMeasurement({
    required this.decibel,
    required this.soundTypes,
    required this.mainSoundType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'decibel': decibel,
      'soundTypes': soundTypes,
      'mainSoundType': mainSoundType,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Converts a list of AcousticMeasurement objects into a list of JSON maps.
List<Map<String, dynamic>> acousticMeasurementsToJson(
    List<AcousticMeasurement> measurements) {
  return measurements.map((m) => m.toJson()).toList();
}

/// AcousticProfileTestPage displays a Google Map (with the project polygon)
/// in the background and uses a timer to prompt the researcher for sound
/// measurements at fixed intervals.
class AcousticProfileTestPage extends StatefulWidget {
  final Project activeProject;
  final dynamic
      activeTest; // Depending on your schema, this might be a specific test type

  const AcousticProfileTestPage({
    Key? key,
    required this.activeProject,
    required this.activeTest,
  }) : super(key: key);

  @override
  State<AcousticProfileTestPage> createState() =>
      _AcousticProfileTestPageState();
}

class _AcousticProfileTestPageState extends State<AcousticProfileTestPage> {
  late GoogleMapController mapController;
  LatLng _currentLocation = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _intervalTimer;
  int _currentInterval = 0;
  Set<Polygon> _polygons = {};
  final int _maxIntervals = 15; // Total number of intervals
  // List to store acoustic measurements for each interval.
  List<AcousticMeasurement> _measurements = [];
  // Timer (in seconds) for each interval (e.g. 4 seconds).
  final int _intervalDuration = 4;
  // Controls whether the test is running.
  bool _isTestRunning = false;
  // For simplicity, we remove marker/point-tap functionality.
  MapType _currentMapType = MapType.normal;
  // Firestore instance.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _showErrorMessage = false;
  int _remainingSeconds = 0;
  bool _isBottomSheetOpen = false;

  @override
  void initState() {
    super.initState();
    // Center the map based on the project polygon.
    _initProjectArea();
    _checkAndFetchLocation();
    // Delay starting the interval timer until the map is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _intervalTimer?.cancel();
    super.dispose();
  }

  /// Initializes the project area by calculating the polygon’s centroid.
  void _initProjectArea() {
    if (widget.activeProject.polygonPoints.isNotEmpty) {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      if (_polygons.isNotEmpty) {
        _currentLocation = getPolygonCentroid(_polygons.first);
      }
    }
  }

  /// Checks for location permissions and fetches the current location.
  Future<void> _checkAndFetchLocation() async {
    try {
      _currentLocation = await checkAndFetchLocation();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Show instructions once the map loads.
      _showInstructionOverlay();
    } catch (e, stacktrace) {
      print('Error fetching location: $e');
      print('Stacktrace: $stacktrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Map failed to load. Error retrieving location permissions.')));
      Navigator.pop(context);
    }
  }

  // Helper method to format elapsed seconds into mm:ss
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Starts the interval timer. Every [_intervalDuration] seconds, this timer
  /// pauses and launches the acoustic measurement sequence.
  void _startIntervalTimer() {
    setState(() {
      _isTestRunning = true;
      _currentInterval = 0;
    });
    _intervalTimer =
        Timer.periodic(Duration(seconds: _intervalDuration), (timer) async {
      // Pause timer at the end of each interval to record acoustic data.
      timer.cancel();
      await _showAcousticBottomSheetSequence();
      _currentInterval++;
      // If we haven't reached the maximum intervals, restart the timer.
      if (_currentInterval < _maxIntervals) {
        _startIntervalTimer();
      } else {
        // Test complete.
        await _endTest();
      }
      setState(() {});
    });
  }

  /// Displays a series of bottom sheets in sequence:
  /// 1. Sound Decibel Level input.
  /// 2. Sound Types multi-select.
  /// 3. Main Sound Type single-select.
  ///
  /// Each step collects data which is then stored as an AcousticMeasurement.
  Future<void> _showAcousticBottomSheetSequence() async {
    setState(() {
      _isBottomSheetOpen = true;
    });

    // 1. Bottom sheet for Sound Decibel Level.
    double? decibel;
    if (!mounted) return;
    decibel = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      backgroundColor: const Color(0xFFDDE6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        final TextEditingController decibelController = TextEditingController();
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sound Decibel Level',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: decibelController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Enter decibel value'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    double? value =
                        double.tryParse(decibelController.text.trim());
                    if (value != null) {
                      Navigator.pop(context, value);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        );
      },
    );

    // If no decibel value was entered, default to 0.
    decibel ??= 0.0;

    // 2. Bottom sheet for Sound Types (multi-select).
    List<String> selectedSoundTypes = [];
    selectedSoundTypes = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          backgroundColor: const Color(0xFFDDE6F2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          builder: (context) {
            // List of available sound types.
            final List<String> soundOptions = [
              'Water',
              'Traffic',
              'People',
              'Animals',
              'Wind',
              'Music'
            ];
            // Use a local set to track selection.
            final Set<String> selections = {};
            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: MediaQuery.of(context).viewInsets,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Sound Types',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select all of the sounds you heard during the measurement',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 3, // Three columns
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Prevent scrolling inside the sheet
                          mainAxisSpacing: 1,
                          crossAxisSpacing: 2,
                          padding: const EdgeInsets.only(bottom: 8),
                          childAspectRatio:
                              2, // Adjust to change the height/width ratio of each cell
                          children: soundOptions.map((option) {
                            final bool isSelected = selections.contains(option);
                            return ChoiceChip(
                              label: Text(option),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selections.add(option);
                                  } else {
                                    selections.remove(option);
                                  }
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(20), // Pill shape
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors
                                          .grey, // Distinct border when selected
                                  width: 2.0,
                                ),
                              ),
                              selectedColor: Colors.blue
                                  .shade100, // Background color when selected
                              backgroundColor: Colors
                                  .grey.shade200, // Default background color
                            );
                          }).toList(),
                        ),
                        // Other option text field and select button.
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Other',
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    selections.add(value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                // For simplicity, just do nothing extra here.
                              },
                              child: const Text('Select'),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, selections.toList());
                          },
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ) ??
        [];

    // 3. Bottom sheet for Main Sound Type (single-select).
    String? mainSoundType;
    mainSoundType = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFDDE6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        final List<String> soundOptions = [
          'Water Feature',
          'Traffic',
          'People Sounds',
          'Animals',
          'Wind',
          'Music'
        ];
        String? selectedOption;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Main Sound Type',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the main source of sound that you heard during the measurement',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: soundOptions.map((option) {
                        return ChoiceChip(
                          label: Text(option),
                          selected: selectedOption == option,
                          onSelected: (selected) {
                            setState(() {
                              selectedOption = selected ? option : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Other option row.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Other',
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  selectedOption = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Select'),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedOption != null) {
                          Navigator.pop(context, selectedOption);
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    setState(() {
      _isBottomSheetOpen = false;
    });

    // Construct an AcousticMeasurement using the collected data.
    final measurement = AcousticMeasurement(
      decibel: decibel,
      soundTypes: selectedSoundTypes,
      mainSoundType: mainSoundType ?? '',
      timestamp: DateTime.now(),
    );
    _measurements.add(measurement);
  }

  /// Ends the test, saves the acoustic measurement data to Firestore, and
  /// navigates back to the project details page.
  Future<void> _endTest() async {
    setState(() {
      _isTestRunning = false;
    });
    try {
      // await _firestore
      //     .collection(widget.activeTest.collectionID)
      //     .doc(widget.activeTest.testID)
      //     .update({
      //   'data': acousticMeasurementsToJson(_measurements),
      //   'isComplete': true,
      // });
      print("Acoustic Profile test data submitted successfully.");
    } catch (e, stacktrace) {
      print("Error submitting Acoustic Profile test data: $e");
      print("Stacktrace: $stacktrace");
    }
    // Navigate back to the Project Details page.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProjectDetailsPage(projectData: widget.activeProject),
      ),
    );
  }

  /// Displays the same instruction overlay as People In Place.
  void _showInstructionOverlay() {
    // For now, reusing the People In Place instructions.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.05,
              vertical: screenSize.height * 0.005),
          actionsPadding: EdgeInsets.zero,
          title: const Text(
            'How It Works:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  peopleInPlaceInstructions(),
                  const SizedBox(height: 10),
                  buildLegends(),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: const [
                    Checkbox(value: false, onChanged: null),
                    Text("Don't show this again next time"),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Overlay widget to display a centered message.
  Widget _buildCenterMessage() {
    // Only display if no bottom sheet is open.
    if (_isBottomSheetOpen) return SizedBox.shrink();
    // Choose message based on whether the test has started.
    String message = !_isTestRunning
        ? "Do not leave the application once the activity has started"
        : "Listen carefully to your surroundings";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        // Start/End button (for this test, we rely solely on the interval timer)
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: _isTestRunning ? Colors.red : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              if (!_isTestRunning) {
                setState(() {
                  _isTestRunning = true;
                  _startIntervalTimer(); // Start the countdown timer when pressed
                });
              } else {
                Navigator.pop(context); // Exit the test if End is displayed
              }
            },
            child: Text(
              _isTestRunning ? 'End' : 'Start',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        // Centered message reminding the user not to leave the app.
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: // Interval counter (e.g. "Interval 3/15")
                  Text(
                '${_currentInterval + 1} / $_maxIntervals',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        centerTitle: true,
        // Timer display on the right (shows remaining seconds for current interval)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map displaying the project polygon.
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition:
                CameraPosition(target: _currentLocation, zoom: 14.0),
            polygons: _polygons,
            mapType: _currentMapType,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Optionally, display an error message if the user taps outside the polygon.
          if (_showErrorMessage)
            Positioned(
              bottom: 100.0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Please place points inside the boundary.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          // Floating button for toggling map type.
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.0,
            right: 20.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7EAD80).withValues(alpha: 0.9),
                border: Border.all(color: const Color(0xFF2D6040), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Center(
                  child: Icon(Icons.layers, color: const Color(0xFF2D6040)),
                ),
                onPressed: _toggleMapType,
              ),
            ),
          ),
          // Floating button for toggling instructions.
          if (!_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 70.0,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBACFEB).withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFF37597D), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6.0,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(FontAwesomeIcons.info,
                      color: const Color(0xFF37597D)),
                  onPressed: _showInstructionOverlay,
                ),
              ),
            ),
          if (!_isBottomSheetOpen) _buildCenterMessage(),
        ],
      ),
    );
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

  /// Toggle the map type between normal and satellite view.
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Callback when the map is created. Saves the controller for later use.
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      if (widget.activeProject.polygonPoints.isNotEmpty) {
        _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bounds = _getPolygonBounds(widget.activeProject.polygonPoints);
          mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        });
      } else {
        _moveToCurrentLocation(); // Ensure the map is centered on the current location
      }
    });
  }
}