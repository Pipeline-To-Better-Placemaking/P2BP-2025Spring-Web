import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'people_in_motion_instructions.dart';
import 'theme.dart';
import 'widgets.dart';

import 'assets.dart';
import 'google_maps_functions.dart';

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
  bool _isTestRunning = false;
  bool _isTracingMode = false;
  bool _outsidePoint = false;
  bool _isPointsMenuVisible = false;
  bool _directionsVisible = true;

  double _zoom = 18;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  List<mp.LatLng> _projectArea = [];
  final Set<Polygon> _polygons = {}; // Only gets project polygon.
  MapType _currentMapType = MapType.satellite;

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
  final PeopleInMotionData _newData = PeopleInMotionData.empty();

  // Define an initial time
  int _remainingSeconds = -1;
  Timer? _timer;
  Timer? _outsidePointTimer;

  @override
  void initState() {
    super.initState();
    _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
    _location = getPolygonCentroid(_polygons.first);
    _projectArea = _polygons.first.toMPLatLngList();
    _zoom = getIdealZoom(_projectArea, _location.toMPLatLng());
    _remainingSeconds = widget.activeTest.testDuration;
    for (final point in widget.activeTest.standingPoints) {
      _standingPointMarkers.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point.location,
        icon: standingPointDisabledIcon,
        consumeTapEvents: true,
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _showInstructionOverlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    super.dispose();
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          actionsPadding: EdgeInsets.zero,
          title: Text(
            'How It Works:',
            style: TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation();
  }

  /// Moves camera to project location.
  void _moveToCurrentLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
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
  void _handleMapTap(LatLng point) {
    // If point is outside the project boundary, display error message
    if (!isPointInsidePolygon(point, _polygons.first)) {
      setState(() {
        _outsidePoint = true;
      });
      _outsidePointTimer?.cancel();
      _outsidePointTimer = Timer(Duration(seconds: 3), () {
        setState(() {
          _outsidePoint = false;
        });
      });
    }

    final markerId = MarkerId(point.toString());
    final Marker marker = Marker(
      markerId: markerId,
      position: point,
      consumeTapEvents: true,
      icon: tempMarkerIcon,
      anchor: const Offset(0.5, 0.9),
    );

    setState(() {
      _tracingPoints.add(point);
      _tracingMarkers.add(marker);
    });

    // Rebuild polyline with new point.
    Polyline? polyline = createPolyline(_tracingPoints, Colors.grey);
    if (polyline == null) {
      throw Exception('Failed to create Polyline from given points.');
    }

    setState(() {
      _tracingPolyline = polyline;
    });
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
    final AssetMapBitmap connectorIcon = peopleInMotionIconMap[activity]!;
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

      _clearTracing();
    });
  }

  void _clearTracing() {
    _tracingPoints.clear();
    _tracingMarkers.clear();
    _tracingPolyline = null;
  }

  void _startTest() {
    setState(() {
      _isTestRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isTestRunning = false;
          timer.cancel();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TimerEndDialog(onSubmit: () {
                Navigator.pop(context);
                _endTest();
              }, onBack: () {
                setState(() {
                  _remainingSeconds = widget.activeTest.testDuration;
                });
                Navigator.pop(context);
              });
            },
          );
        }
      });
    });
  }

  void _endTest() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_currentMapType == MapType.normal)
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _location,
                  zoom: _zoom,
                ),
                markers: {
                  ..._standingPointMarkers,
                  if (_tracingMarkers.isNotEmpty) ...{
                    _tracingMarkers.first,
                    _tracingMarkers.last,
                  },
                  ..._confirmedPolylineEndMarkers
                },
                polygons: _polygons,
                polylines: {
                  ..._confirmedPolylines,
                  if (_tracingPolyline != null) _tracingPolyline!
                },
                onTap:
                    (_isTestRunning && _isTracingMode) ? _handleMapTap : null,
                mapType: _currentMapType,
                myLocationButtonEnabled: false,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TimerButtonAndDisplay(
                      onPressed: () {
                        setState(() {
                          if (_isTestRunning) {
                            setState(() {
                              _isTestRunning = false;
                              _timer?.cancel();
                              _clearTracing();
                            });
                          } else {
                            _startTest();
                          }
                        });
                      },
                      isTestRunning: _isTestRunning,
                      remainingSeconds: _remainingSeconds,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _directionsVisible
                          ? DirectionsText(
                              onTap: () {
                                setState(() {
                                  _directionsVisible = !_directionsVisible;
                                });
                              },
                              text: 'Tap the screen to trace.',
                            )
                          : SizedBox(),
                    ),
                    SizedBox(width: 15),
                    Column(
                      spacing: 10,
                      children: <Widget>[
                        DirectionsButton(
                          onTap: () {
                            setState(() {
                              _directionsVisible = !_directionsVisible;
                            });
                          },
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              const Color(0xFF7EAD80).withValues(alpha: 0.9),
                          borderColor: Color(0xFF2D6040),
                          onPressed: _toggleMapType,
                          icon: Center(
                            child: Icon(Icons.layers, color: Color(0xFF2D6040)),
                          ),
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFBACFEB).withValues(alpha: 0.9),
                          borderColor: Color(0xFF37597D),
                          onPressed: _showInstructionOverlay,
                          icon: Center(
                            child: Icon(
                              FontAwesomeIcons.info,
                              color: Color(0xFF37597D),
                            ),
                          ),
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFBD9FE4).withValues(alpha: 0.9),
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
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFFF9800).withValues(alpha: 0.9),
                          borderColor: Color(0xFF8C2F00),
                          onPressed: () {
                            setState(() {
                              _isTracingMode = !_isTracingMode;
                              _clearTracing();
                            });
                          },
                          icon: Icon(
                            FontAwesomeIcons.pen,
                            color: Color(0xFF8C2F00),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            if (_outsidePoint)
              TestErrorText(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 150),
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
                _clearTracing();
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