import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2b/extensions.dart';
import 'assets.dart';

import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/spatial_boundaries_test_class.dart';
import 'google_maps_functions.dart';
import 'spatial_boundaries_instructions.dart';
import 'theme.dart';
import 'widgets.dart';

class SpatialBoundariesTestPage extends StatefulWidget {
  final Project activeProject;
  final SpatialBoundariesTest activeTest;

  const SpatialBoundariesTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<SpatialBoundariesTestPage> createState() =>
      _SpatialBoundariesTestPageState();
}

class _SpatialBoundariesTestPageState extends State<SpatialBoundariesTestPage> {
  bool _polygonMode = false;
  bool _polylineMode = false;
  bool _outsidePoint = false;
  bool _boundariesVisible = true;
  bool _isTestRunning = false;
  bool _directionsVisible = true;

  int _remainingSeconds = -1;
  Timer? _timer;
  Timer? _outsidePointTimer;

  double _zoom = 18;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite;
  List<mp.LatLng> _projectArea = [];

  late final Polygon _projectPolygon; // Set for project polygon
  final Set<Polygon> _polygons = {};
  final List<LatLng> _polygonPoints = [];
  final Set<Marker> _polygonMarkers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _polylinePoints = [];
  final Set<Marker> _polylineMarkers = {};

  final SpatialBoundariesData _newData = SpatialBoundariesData.empty();
  BoundaryType? _boundaryType;
  ConstructedBoundaryType? _constructedType;
  MaterialBoundaryType? _materialType;
  ShelterBoundaryType? _shelterType;

  static const List<String> _directionsList = [
    'Select a type of boundary.',
    'Place points outlining the boundary and press confirm when you\'re done.',
  ];
  late String _directionsActive;
  static final double _bottomSheetHeight = Platform.isIOS ? 250 : 220;

  BitmapDescriptor? polyNodeMarker;

  @override
  void initState() {
    super.initState();
    _projectPolygon = widget.activeProject.polygon.clone();
    _location = getPolygonCentroid(_projectPolygon);
    _projectArea = _projectPolygon.toMPLatLngList();
    _zoom = getIdealZoom(_projectArea, _location.toMPLatLng());
    _remainingSeconds = widget.activeTest.testDuration;
    _directionsActive = _directionsList[0];
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation();
  }

  /// Moves camera to project location.
  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
      ),
    );
  }

  /// Toggles map type between satellite and normal
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Called whenever map is tapped
  void _togglePoint(LatLng point) {
    try {
      if (!isPointInsidePolygon(point, _projectPolygon)) {
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
      if (_polygonMode) _polygonTap(point);
      if (_polylineMode) _polylineTap(point);
    } catch (e, stacktrace) {
      print('Error in spatial_boundaries_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  /// Place marker to be used in making polygon.
  void _polygonTap(LatLng point) {
    final markerId = MarkerId(point.toString());
    setState(() {
      _polygonPoints.add(point);
      _polygonMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          icon: tempMarkerIcon,
          consumeTapEvents: true,
          onTap: () {
            // If the marker is tapped again, it will be removed.
            setState(() {
              _polygonPoints.remove(point);
              _polygonMarkers
                  .removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );
    });
  }

  /// Convert markers to polygon and save the data to be submitted later.
  void _finalizePolygon() {
    Polygon tempPolygon;
    try {
      // Create polygon and add it to the visible set of polygons.
      tempPolygon = finalizePolygon(
        _polygonPoints,
        strokeColor: _boundaryType!.color,
      );

      _polygons.add(tempPolygon);

      if (_boundaryType == BoundaryType.material && _materialType != null) {
        _newData.material.add(MaterialBoundary(
          polygon: tempPolygon,
          materialType: _materialType!,
        ));
      } else if (_boundaryType == BoundaryType.shelter &&
          _shelterType != null) {
        _newData.shelter.add(ShelterBoundary(
          polygon: tempPolygon,
          shelterType: _shelterType!,
        ));
      } else {
        throw Exception('Invalid boundary type in _finalizePolygon(), '
            '_boundaryType = $_boundaryType');
      }

      // Reset everything to be able to make new boundary.
      _resetPlacementVariables();
    } catch (e, stacktrace) {
      print('Exception in _finalizePolygon(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  /// Place marker to be used in making polyline.
  void _polylineTap(LatLng point) {
    final markerId = MarkerId(point.toString());
    setState(() {
      _polylinePoints.add(point);
      _polylineMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          icon: tempMarkerIcon,
          consumeTapEvents: true,
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _polylinePoints.remove(point);
              _polylineMarkers
                  .removeWhere((marker) => marker.markerId == markerId);
            });
          },
        ),
      );
    });
  }

  /// Convert markers to polyline and save the data to be submitted later.
  void _finalizePolyline() {
    Polyline tempPolyline;
    try {
      if (_boundaryType != BoundaryType.constructed ||
          _constructedType == null) {
        throw Exception('Invalid boundary type in _finalizePolyline(),'
            '_boundaryType = $_boundaryType');
      }

      tempPolyline = Polyline(
        polylineId: PolylineId(_polylinePoints.toString()),
        points: _polylinePoints.toList(),
        color: _boundaryType!.color,
        width: 4,
      );

      _polylines.add(tempPolyline);

      _newData.constructed.add(ConstructedBoundary(
        polyline: tempPolyline,
        constructedType: _constructedType!,
      ));

      // Reset everything to be able to make new boundary.
      _resetPlacementVariables();
    } catch (e, stacktrace) {
      print('Exception in _finalizePolyline(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  /// Resets all state variables relevant to placing boundaries to default.
  void _resetPlacementVariables() {
    setState(() {
      _polylinePoints.clear();
      _polylineMarkers.clear();
      _polylineMode = false;
      _polygonPoints.clear();
      _polygonMarkers.clear();
      _polygonMode = false;

      _boundaryType = null;
      _constructedType = null;
      _materialType = null;
      _shelterType = null;
      _directionsActive = _directionsList[0];
    });
  }

  /// Display constructed modal and use result to adjust state variables.
  void _doConstructedModal(BuildContext context) async {
    final ConstructedBoundaryType? constructed = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _ConstructedDescriptionForm(),
    );
    if (constructed != null) {
      setState(() {
        _boundaryType = BoundaryType.constructed;
        _constructedType = constructed;
        _polylineMode = true;
        _directionsActive = _directionsList[1];
      });
    }
  }

  /// Display material modal and use result to adjust state variables.
  void _doMaterialModal(BuildContext context) async {
    final MaterialBoundaryType? material = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _MaterialDescriptionForm(),
    );
    if (material != null) {
      setState(() {
        _boundaryType = BoundaryType.material;
        _materialType = material;
        _polygonMode = true;
        _directionsActive = _directionsList[1];
      });
    }
  }

  /// Display shelter modal and use result to adjust state variables.
  void _doShelterModal(BuildContext context) async {
    final ShelterBoundaryType? shelter = await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => _ShelterDescriptionForm(),
    );
    if (shelter != null) {
      setState(() {
        _boundaryType = BoundaryType.shelter;
        _shelterType = shelter;
        _polygonMode = true;
        _directionsActive = _directionsList[1];
      });
    }
  }

  /// Displays instructions for how to conduct Spatial Boundaries test.
  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          actionsPadding: EdgeInsets.zero,
          title: const Text(
            'How It Works:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  spatialBoundariesInstructions(),
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

  /// Method to end the test and timer.
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
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                onMapCreated: _onMapCreated,
                initialCameraPosition:
                    CameraPosition(target: _location, zoom: _zoom),
                markers: {..._polygonMarkers, ..._polylineMarkers},
                polygons: {
                  _projectPolygon,
                  if (_boundariesVisible) ..._polygons,
                },
                polylines: _boundariesVisible ? _polylines : <Polyline>{},
                onTap: (_polygonMode || _polylineMode) ? _togglePoint : null,
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
                              _resetPlacementVariables();
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
                              text: _directionsActive,
                            )
                          : SizedBox(),
                    ),
                    SizedBox(width: 15),
                    Column(
                      spacing: 10,
                      children: [
                        DirectionsButton(
                          onTap: () {
                            setState(() {
                              _directionsVisible = !_directionsVisible;
                            });
                          },
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFF7EAD80).withValues(alpha: 0.9),
                          borderColor: Color(0xFF2D6040),
                          onPressed: _toggleMapType,
                          icon: Icon(Icons.layers),
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFBACFEB).withValues(alpha: 0.9),
                          borderColor: Color(0xFF37597D),
                          onPressed: _showInstructionOverlay,
                          icon: Icon(FontAwesomeIcons.info),
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFE4E9EF).withValues(alpha: 0.9),
                          borderColor: Color(0xFF4A5D75),
                          onPressed: () {
                            setState(() {
                              _boundariesVisible = !_boundariesVisible;
                            });
                          },
                          icon: Icon(
                            _boundariesVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 30,
                            color: Color(0xFF4A5D75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_outsidePoint)
              TestErrorText(
                padding:
                    EdgeInsets.fromLTRB(50, 0, 50, _bottomSheetHeight + 20),
              ),
          ],
        ),
        bottomSheet: SizedBox(
          height: _bottomSheetHeight,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              gradient: formGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0.0, 1.0), //(x,y)
                  blurRadius: 6.0,
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Center(
                  child: Text(
                    'Spatial Boundaries',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F6DCF),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 10,
                  children: <Widget>[
                    Expanded(
                      flex: 11,
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed:
                            (_isTestRunning && !_polygonMode && !_polylineMode)
                                ? () {
                                    _doConstructedModal(context);
                                  }
                                : null,
                        child: Text('Constructed'),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed:
                            (_isTestRunning && !_polygonMode && !_polylineMode)
                                ? () {
                                    _doMaterialModal(context);
                                  }
                                : null,
                        child: Text('Material'),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed:
                            (_isTestRunning && !_polygonMode && !_polylineMode)
                                ? () {
                                    _doShelterModal(context);
                                  }
                                : null,
                        child: Text('Shelter'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 15,
                  children: <Widget>[
                    Expanded(
                      flex: 9,
                      child: EditButton(
                        text: 'Confirm Shape',
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        icon: const Icon(Icons.check),
                        iconColor: Colors.green,
                        onPressed: (_polygonMode && _polygonPoints.length >= 3)
                            ? _finalizePolygon
                            : (_polylineMode && _polylinePoints.length >= 2)
                                ? _finalizePolyline
                                : null,
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: EditButton(
                        text: 'Cancel',
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        icon: const Icon(Icons.cancel),
                        iconColor: Colors.red,
                        onPressed: (_polygonMode || _polylineMode)
                            ? _resetPlacementVariables
                            : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: <Widget>[
                    Flexible(
                      child: FilledButton.icon(
                        style: testButtonStyle,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        label: Text('Back'),
                        icon: Icon(Icons.chevron_left),
                        iconAlignment: IconAlignment.start,
                      ),
                    ),
                    Flexible(
                      child: FilledButton.icon(
                        style: testButtonStyle,
                        onPressed:
                            (!_polygonMode && !_polylineMode && !_isTestRunning)
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          TestFinishDialog(onNext: () {
                                        Navigator.pop(context);
                                        _endTest();
                                      }),
                                    );
                                  }
                                : null,
                        label: Text('Finish'),
                        icon: Icon(Icons.chevron_right),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConstructedDescriptionForm extends StatefulWidget {
  const _ConstructedDescriptionForm();

  @override
  State<_ConstructedDescriptionForm> createState() =>
      _ConstructedDescriptionFormState();
}

class _ConstructedDescriptionFormState
    extends State<_ConstructedDescriptionForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          gradient: formGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Boundary Description',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6DCF),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    softWrap: true,
                    TextSpan(
                      text: 'Choose the option that ',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'best',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(text: ' describes your boundary.'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.curb,
                        );
                      },
                      child: Text(
                        'Curbs',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.buildingWall,
                        );
                      },
                      child: Text(
                        'Building Wall',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.fence,
                        );
                      },
                      child: Text(
                        'Fences',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.planter,
                        );
                      },
                      child: Text(
                        'Planter',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ConstructedBoundaryType.partialWall,
                        );
                      },
                      child: Text(
                        'Partial Wall',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Color(0xFF7A8DA6),
                ),
              ),
              Row(
                children: [
                  Spacer(flex: 4),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 4),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialDescriptionForm extends StatefulWidget {
  const _MaterialDescriptionForm();

  @override
  State<_MaterialDescriptionForm> createState() =>
      _MaterialDescriptionFormState();
}

class _MaterialDescriptionFormState extends State<_MaterialDescriptionForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: formGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Boundary Description',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6DCF),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    softWrap: true,
                    TextSpan(
                      text: 'Choose the option that ',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'best',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(text: ' describes your boundary.'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.pavers,
                        );
                      },
                      child: Text(
                        'Pavers',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.concrete,
                        );
                      },
                      child: Text(
                        'Concrete',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.tile,
                        );
                      },
                      child: Text(
                        'Tile',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.natural,
                        );
                      },
                      child: Text(
                        'Natural',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MaterialBoundaryType.decking,
                        );
                      },
                      child: Text(
                        'Decking',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Color(0xFF7A8DA6),
                ),
              ),
              Row(
                children: [
                  Spacer(flex: 4),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 4),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelterDescriptionForm extends StatefulWidget {
  const _ShelterDescriptionForm();

  @override
  State<_ShelterDescriptionForm> createState() =>
      _ShelterDescriptionFormState();
}

class _ShelterDescriptionFormState extends State<_ShelterDescriptionForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            gradient: formGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Boundary Description',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F6DCF),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    softWrap: true,
                    TextSpan(
                      text: 'Choose the option that ',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'best',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextSpan(text: ' describes your boundary.'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.canopy,
                        );
                      },
                      child: Text(
                        'Canopy',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.tree,
                        );
                      },
                      child: Text(
                        'Trees',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.furniture,
                        );
                      },
                      child: Text(
                        'Furniture',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.temporary,
                        );
                      },
                      child: Text(
                        'Temporary',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                spacing: 20,
                children: <Widget>[
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(
                          context,
                          ShelterBoundaryType.constructed,
                        );
                      },
                      child: Text(
                        'Constructed',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: Color(0xFF7A8DA6),
                ),
              ),
              Row(
                children: [
                  Spacer(flex: 4),
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      style: testButtonStyle,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Spacer(flex: 4),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
