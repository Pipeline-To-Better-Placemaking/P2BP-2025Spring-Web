import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firestore_functions.dart';
import 'theme.dart';
import 'widgets.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'people_in_motion_instructions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

bool isPointInsidePolygon(LatLng point, Polygon polygon) {
  List<mp.LatLng> polygonPoints = polygon.points
      .map((p) => mp.LatLng(p.latitude, p.longitude))
      .toList();

  return mp.PolygonUtil.containsLocation(
      mp.LatLng(point.latitude, point.longitude), polygonPoints, false);
}

class PeopleInMotionTestPage extends StatefulWidget {
  final Project activeProject;
  final PeopleInMotionTest activeTest;

  const PeopleInMotionTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<PeopleInMotionTestPage> createState() => _PeopleInMotionTestPageState();
}

class _PeopleInMotionTestPageState extends State<PeopleInMotionTestPage> {
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _hintTimer;
  bool _showHint = false;
  bool _isTestRunning = false;
  bool _isTracingMode = false;
  bool _showErrorMessage = false;
  bool _isPointsMenuVisible = false;
  Timer? _timer;

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<mp.LatLng> _projectArea = [];
  Set<Polygon> _polygons = {}; // Only has project polygon.
  MapType _currentMapType = MapType.normal;

  /// Markers placed while in TracingMode.
  /// Should always be empty when [_isTracingMode] is false.
  final Set<Marker> _tracingMarkers = {};

  /// Points placed while in TracingMode.
  /// Should always be empty when [_isTracingMode] is false.
  final List<LatLng> _tracingPoints = [];

  /// Polyline made with [_tracingPoints].
  /// Should always be null when [_isTracingMode] is false.
  Polyline? _tracingPolyline;

  /// Set of polylines created and confirmed during this test.
  final Set<Polyline> _confirmedPolylines = {};

  /// Contains the first and last marker from each element of
  /// [_confirmedPolylines].
  final Set<Marker> _confirmedPolylineEndMarkers = {};

  final Set<Marker> _standingPointMarkers = {};

  final PeopleInMotionData _newData = PeopleInMotionData();

  // Custom marker icons
  BitmapDescriptor? standingPointMarker;
  BitmapDescriptor? walkingConnector;
  BitmapDescriptor? runningConnector;
  BitmapDescriptor? swimmingConnector;
  BitmapDescriptor? wheelsConnector;
  BitmapDescriptor? handicapConnector;
  BitmapDescriptor? tempMarkerIcon;
  bool _customMarkersLoaded = false;

  // Define an initial time
  int _remainingSeconds = 300;

  @override
  void initState() {
    super.initState();
    _initProjectArea();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _loadCustomMarkers();
      _showInstructionOverlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void _initProjectArea() {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      print(_polygons);
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      _projectArea = _polygons.first.toMPLatLngList();
      // TODO: dynamic zooming
      _isLoading = false;
    });
  }

  // Function to load custom marker icons using AssetMapBitmap.
  Future<void> _loadCustomMarkers() async {
    final ImageConfiguration configuration =
        createLocalImageConfiguration(context);
    try {
      standingPointMarker = await AssetMapBitmap.create(
        configuration,
        'assets/standing_point_disabled_marker.png',
        width: 36,
        height: 36,
      );
      walkingConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_teal.png',
        width: 24,
        height: 24,
      );
      runningConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_red.png',
        width: 24,
        height: 24,
      );
      swimmingConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_cyan.png',
        width: 24,
        height: 24,
      );
      wheelsConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_orange.png',
        width: 24,
        height: 24,
      );
      handicapConnector = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/square_marker_purple.png',
        width: 24,
        height: 24,
      );
      tempMarkerIcon = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_motion/polyline_marker4.png',
        width: 48,
        height: 48,
      );
      setState(() {
        _customMarkersLoaded = true;
        _buildStandingPointMarkers();
      });
      print("Custom markers loaded successfully.");
    } catch (e) {
      print("Error loading custom markers: $e");
    }
  }

  void _buildStandingPointMarkers() {
    for (final point in widget.activeTest.standingPoints) {
      _standingPointMarkers.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point.location,
        icon: standingPointMarker!,
        consumeTapEvents: true,
      ));
    }
  }

  // Returns Marker icon for the given [ActivityTypeInMotion].
  BitmapDescriptor _getMarkerIcon(ActivityTypeInMotion? key) {
    switch (key) {
      case ActivityTypeInMotion.walking:
        return walkingConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.running:
        return runningConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.swimming:
        return swimmingConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.activityOnWheels:
        return wheelsConnector ?? BitmapDescriptor.defaultMarker;
      case ActivityTypeInMotion.handicapAssistedWheels:
        return handicapConnector ?? BitmapDescriptor.defaultMarker;
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.height * 0.005),
          actionsPadding: EdgeInsets.zero,
          title: Text(
            'How It Works:',
            style: TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  peopleInMotionInstructions(),
                  SizedBox(height: 10),
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
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (_) {},
                    ),
                    Text("Don't show this again next time"),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _resetHintTimer() {
    _hintTimer?.cancel();
    setState(() {
      _showHint = false;
    });
    _hintTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _showHint = true;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (widget.activeProject.polygonPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latLngPoints = widget.activeProject.polygonPoints;
        final bounds = getLatLngBounds(latLngPoints);
        if (bounds != null) {
          mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        }
      });
    } else {
      _moveToCurrentLocation(); // Center on current location.
    }
  }

  void _moveToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 14.0),
      ),
    );
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  // When in tracing mode, each tap creates a dot marker and updates the temporary polyline
  Future<void> _handleMapTap(LatLng point) async {
    _resetHintTimer();
    // If point is outside the project boundary, display error message
    if (!isPointInsidePolygon(point, _polygons.first)) {
      setState(() {
        _showErrorMessage = true;
      });
      Timer(Duration(seconds: 3), () {
        setState(() {
          _showErrorMessage = false;
        });
      });
    }
    if (_isTracingMode) {
      // Add this tap as a dot marker.
      final markerId = MarkerId(point.toString());
      // Using a different hue for temporary markers.
      final Marker marker = Marker(
        markerId: markerId,
        position: point,
        icon: _customMarkersLoaded && tempMarkerIcon != null
            ? tempMarkerIcon!
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        anchor: const Offset(0.5, 0.9),
      );

      setState(() {
        _tracingPoints.add(point);
        _tracingMarkers.add(marker);
      });

      // Append the tapped point to the traced polyline.
      Polyline? polyline = createPolyline(_tracingPoints, Colors.grey);
      if (polyline == null) {
        throw Exception('Failed to create Polyline from given points.');
      }

      setState(() {
        _tracingPolyline = polyline;
      });
    }
  }

  void _doActivityDataSheet() async {
    final ActivityTypeInMotion? activity = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      builder: (BuildContext context) => _ActivityForm(),
    );
    if (activity == null) return;

    // Map the selected activity to its corresponding marker icon.
    BitmapDescriptor connectorIcon = _getMarkerIcon(activity);

    final newPolyline = _tracingPolyline!.copyWith(colorParam: activity.color);

    // Create a data point from the polyline and activity
    _newData.persons.add(PersonInMotion(
      polyline: newPolyline,
      activity: activity,
    ));

    setState(() {
      // Add polyline to set of finished ones
      _confirmedPolylines.add(newPolyline);

      // Add markers at first and last point of polyline
      _confirmedPolylineEndMarkers.addAll([
        _tracingMarkers.first.copyWith(
          iconParam: connectorIcon,
          anchorParam: const Offset(0.5, 0.5),
        ),
        _tracingMarkers.last.copyWith(
          iconParam: connectorIcon,
          anchorParam: const Offset(0.5, 0.5),
        ),
      ]);

      // Clear temp values previously holding polyline info and turn off tracing
      _tracingPoints.clear();
      _tracingMarkers.clear();
      _tracingPolyline = null;
      _isTracingMode = false;
    });
  }

  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _remainingSeconds = 300; // Reset countdown value
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // TODO: extract the timer and necessary functionality to its own
      // stateful widget to stop this from forcing the whole screen to
      // need to rebuild every second.
      setState(() {
        if (_remainingSeconds <= 0) {
          timer.cancel();
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  void _endTest() async {
    _isTestRunning = false;
    _timer?.cancel();
    _hintTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> visibleMarkers = {
      ..._standingPointMarkers,
      if (_tracingMarkers.isNotEmpty) ...{
        _tracingMarkers.first,
        _tracingMarkers.last,
      },
      ..._confirmedPolylineEndMarkers
    };
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 100,
          // Start/End button on the left.
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: _isTestRunning ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                if (_isTestRunning) {
                  _endTest();
                } else {
                  _startTest();
                }
              },
              child: Text(
                _isTestRunning ? 'End' : 'Start',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          // Persistent prompt in the middle.
          title: _isTracingMode
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap the screen to trace',
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : null,
          centerTitle: true,
          // Timer on the right.
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
                    formatTime(_remainingSeconds),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            // Full-screen map with polylines.
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _location,
                zoom: 14.0,
              ),
              markers: visibleMarkers,
              polygons: _polygons,
              polylines: {
                ..._confirmedPolylines,
                if (_tracingPolyline != null) _tracingPolyline!
              },
              onTap: (_isTracingMode) ? _handleMapTap : null,
              mapType: _currentMapType,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

            if (_showErrorMessage) OutsideBoundsWarning(),
            // Buttons in top right corner of map below timer.
            // Button for toggling map type.
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.0,
              right: 20.0,
              child: CircularIconMapButton(
                backgroundColor: const Color(0xFF7EAD80).withValues(alpha: 0.9),
                borderColor: Color(0xFF2D6040),
                onPressed: _toggleMapType,
                icon: Center(
                  child: Icon(Icons.layers, color: Color(0xFF2D6040)),
                ),
              ),
            ),
            // Button for toggling instructions.
            if (!_isLoading)
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 70.0,
                right: 20,
                child: CircularIconMapButton(
                  backgroundColor: Color(0xFFBACFEB).withValues(alpha: 0.9),
                  borderColor: Color(0xFF37597D),
                  onPressed: _showInstructionOverlay,
                  icon: Center(
                    child: Icon(
                      FontAwesomeIcons.info,
                      color: Color(0xFF37597D),
                    ),
                  ),
                ),
              ),
            // Button for toggling points menu.
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 132.0,
              right: 20.0,
              child: CircularIconMapButton(
                backgroundColor: Color(0xFFBD9FE4).withValues(alpha: 0.9),
                borderColor: Color(0xFF5A3E85),
                onPressed: () {
                  setState(() {
                    _isPointsMenuVisible = !_isPointsMenuVisible;
                  });
                },
                icon: Icon(
                  FontAwesomeIcons.locationDot,
                  color: Color(0xFF5A3E85),
                ),
              ),
            ),
            // Button for activating tracing mode.
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 194.0,
              right: 20.0,
              child: CircularIconMapButton(
                backgroundColor: Color(0xFFFF9800).withValues(alpha: 0.9),
                borderColor: Color(0xFF8C2F00),
                onPressed: () {
                  setState(() {
                    _isTracingMode = !_isTracingMode;
                    _tracingPoints.clear();
                    _tracingMarkers.clear();
                    _tracingPolyline = null;
                  });
                },
                icon: Icon(
                  FontAwesomeIcons.pen,
                  color: Color(0xFF8C2F00),
                ),
              ),
            ),
            if (_isPointsMenuVisible)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: DataEditMenu(
                    title: 'Route Color Guide',
                    colorLegendItems: [
                      for (final type in ActivityTypeInMotion.values)
                        ColorLegendItem(
                          label: type.displayName,
                          color: type.color,
                        ),
                    ],
                    placedDataList: _buildPlacedPolylineList(),
                    onPressedCloseMenu: () => setState(
                        () => _isPointsMenuVisible = !_isPointsMenuVisible),
                    onPressedClearAll: () {
                      setState(() {
                        // Clear all confirmed polylines.
                        _confirmedPolylineEndMarkers.clear();
                        _confirmedPolylines.clear();
                        _newData.persons.clear();
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
        bottomSheet: (_isTracingMode) ? _buildTraceConfirmSheet() : null,
      ),
    );
  }

  ListView _buildPlacedPolylineList() {
    // Tracks how many elements of each type have been added so far.
    Map<ActivityTypeInMotion, int> typeCounter = {};
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _newData.persons.length,
      itemBuilder: (context, index) {
        final person = _newData.persons[index];
        // Increment this type's count
        typeCounter.update(person.activity, (i) => i + 1, ifAbsent: () => 1);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            '${person.activity.displayName} Route ${typeCounter[person.activity]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Points: ${person.polyline.points.length}',
            textAlign: TextAlign.left,
          ),
          trailing: IconButton(
            icon: const Icon(
              FontAwesomeIcons.trashCan,
              color: Color(0xFFD32F2F),
            ),
            onPressed: () {
              setState(() {
                // Delete this polyline and related objects from all sources.
                _confirmedPolylineEndMarkers.removeWhere((marker) {
                  final points = person.polyline.points;
                  if (marker.markerId.value == points.first.toString() ||
                      marker.markerId.value == points.last.toString()) {
                    return true;
                  }
                  return false;
                });
                _confirmedPolylines.remove(person.polyline);
                _newData.persons.remove(person);
              });
            },
          ),
        );
      },
    );
  }

  Container _buildTraceConfirmSheet() {
    return Container(
      color: Color(0xFFDDE6F2),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel: clear placed points and leave tracing mode.
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tracingPoints.clear();
                _tracingMarkers.clear();
                _tracingPolyline = null;
                _isTracingMode = false;
              });
            },
            child: Text('Cancel'),
          ),
          // Confirm: display sheet to select activity type.
          ElevatedButton(
            onPressed: (_tracingPoints.length > 1 && _tracingPolyline != null)
                ? _doActivityDataSheet
                : null,
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ActivityForm extends StatefulWidget {
  const _ActivityForm();

  @override
  State<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<_ActivityForm> {
  ActivityTypeInMotion? _selectedActivity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Theme(
        data: theme.copyWith(
          chipTheme: theme.chipTheme.copyWith(
            showCheckmark: false,
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: ChipLabelColor(),
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row.
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
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
                  SizedBox(width: 48)
                ],
              ),
              const SizedBox(height: 20),
              // Activity type label.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Activity type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              // Activity selection buttons.
              Column(
                children: List<Widget>.generate(
                    ActivityTypeInMotion.values.length, (index) {
                  final List activities = ActivityTypeInMotion.values;
                  return ChoiceChip(
                    label: Text(activities[index].displayName),
                    selected: _selectedActivity == activities[index],
                    onSelected: (selected) {
                      setState(() {
                        _selectedActivity = selected ? activities[index] : null;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Submit button.
              ElevatedButton(
                onPressed: (_selectedActivity != null)
                    ? () => Navigator.pop(context, _selectedActivity)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
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
}