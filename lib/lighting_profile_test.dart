import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2b/extensions.dart';
import 'theme.dart';
import 'widgets.dart';

import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/lighting_profile_test_class.dart';
import 'google_maps_functions.dart';

class LightingProfileTestPage extends StatefulWidget {
  final Project activeProject;
  final LightingProfileTest activeTest;

  const LightingProfileTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<StatefulWidget> createState() => _LightingProfileTestPageState();
}

class _LightingProfileTestPageState extends State<LightingProfileTestPage> {
  bool _isTypeSelected = false;
  bool _outsidePoint = false;
  bool _isTestRunning = false;
  bool _directionsVisible = true;

  LightType? _selectedType;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  double _zoom = 18;
  MapType _currentMapType = MapType.satellite;
  List<mp.LatLng> _projectArea = [];
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  final LightingProfileData _newData = LightingProfileData.empty();

  Timer? _timer;
  Timer? _outsidePointTimer;
  int _remainingSeconds = -1;
  static const double _bottomSheetHeight = 220;

  @override
  void initState() {
    super.initState();
    _polygons.add(widget.activeProject.polygon.clone());
    _location = getPolygonCentroid(_polygons.first);
    _projectArea = _polygons.first.toMPLatLngList();
    _zoom = getIdealZoom(_projectArea, _location.toMPLatLng());
    _remainingSeconds = widget.activeTest.testDuration;
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

  /// Adds a `Marker` to the map and stores that same point in
  /// `_allPointsMap` to be submitted as test data later.
  ///
  /// This also resets the fields for selecting type so another can be
  /// selected after this point is placed.
  Future<void> _togglePoint(LatLng point) async {
    try {
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

      _newData.lights.add(Light.fromLatLng(point, _selectedType!));
      final markerId = _newData.lights.last.marker.markerId;
      setState(() {
        _markers.add(_newData.lights.last.marker.copyWith(onTapParam: () {
          _newData.lights
              .removeWhere((light) => light.marker.markerId == markerId);
          setState(() {
            _markers.removeWhere((marker) => marker.markerId == markerId);
          });
        }));
      });
    } catch (e, stacktrace) {
      print('Error in lighting_profile_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
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
          _setLightType(null);
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

  /// Cancels timer, submits data, and pops test page.
  void _endTest() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  /// Sets [_selectedType] to parameter `type` and [_isTypeSelected] to
  /// true if [type] is non-null and false otherwise.
  void _setLightType(LightType? type) {
    setState(() {
      _selectedType = type;
      _isTypeSelected = _selectedType != null;
    });
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
                markers: _markers,
                polygons: _polygons,
                onTap: _isTypeSelected ? _togglePoint : null,
                mapType: _currentMapType,
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
                              _setLightType(null);
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
                              text: !_isTypeSelected
                                  ? 'Select a type of light.'
                                  : 'Drop a pin where the light is.',
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
                          backgroundColor: Colors.green,
                          borderColor: Color(0xFF2D6040),
                          onPressed: _toggleMapType,
                          icon: const Icon(Icons.map),
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
              gradient: defaultGrad,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    'Lighting Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[600],
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  spacing: 10,
                  children: <Widget>[
                    Expanded(
                      flex: 6,
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: (!_isTypeSelected && _isTestRunning)
                            ? () => _setLightType(LightType.rhythmic)
                            : null,
                        child: Text('Rhythmic'),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: (!_isTypeSelected && _isTestRunning)
                            ? () => _setLightType(LightType.building)
                            : null,
                        child: Text('Building'),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: (!_isTypeSelected && _isTestRunning)
                            ? () => _setLightType(LightType.task)
                            : null,
                        child: Text('Task'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: <Widget>[
                    Spacer(flex: 1),
                    Expanded(
                      flex: 8,
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: (_isTypeSelected)
                            ? () => _setLightType(null)
                            : null,
                        child: Text('Select New Light Type'),
                      ),
                    ),
                    Spacer(flex: 1),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: <Widget>[
                    Flexible(
                      child: FilledButton.icon(
                        style: testButtonStyle,
                        onPressed: () => Navigator.pop(context),
                        label: Text('Back'),
                        icon: Icon(Icons.chevron_left),
                        iconAlignment: IconAlignment.start,
                      ),
                    ),
                    Flexible(
                      child: FilledButton.icon(
                        style: testButtonStyle,
                        onPressed: (!_isTypeSelected && !_isTestRunning)
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
