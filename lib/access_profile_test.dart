import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';
import 'theme.dart';
import 'widgets.dart';

import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/access_profile_test_class.dart';
import 'db_schema_classes/test_class.dart';
import 'google_maps_functions.dart';

class AccessProfileTestPage extends StatefulWidget {
  final Project activeProject;
  final Test activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const AccessProfileTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<AccessProfileTestPage> createState() => _AccessProfileState();
}

class _AccessProfileState extends State<AccessProfileTestPage> {
  bool _polygonMode = false;
  bool _pointMode = false;
  bool _polylineMode = false;
  bool _oldPolylinesToggle = true;

  int? _currentSpotsOrRoute;
  bool _deleteMode = false;
  AccessType? _type;
  String _directions = "Choose a category.";
  static const double _bottomSheetHeight = 315;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  double _zoom = 18;

  final AccessProfileData _accessData = AccessProfileData.empty();

  late final Polygon _projectPolygon;
  Polyline? _currentPolyline;
  List<LatLng> _currentPolylinePoints = [];
  final Set<Polyline> _polylines = {};
  Set<Marker> _polylineMarkers = {};
  Set<Marker> _visiblePolylineMarkers = {};
  Polygon? _currentPolygon;
  List<LatLng> _polygonPoints = [];
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  Set<Marker> _polygonMarkers = {};
  bool _directionsVisible = true;
  MapType _currentMapType = MapType.satellite;

  Project? project;

  @override
  void initState() {
    super.initState();
    _projectPolygon = widget.activeProject.polygon.clone();
    _location = getPolygonCentroid(_projectPolygon);
    _zoom = getIdealZoom(
          _projectPolygon.toMPLatLngList(),
          _location.toMPLatLng(),
        ) -
        0.1;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  /// Moves camera to project location.
  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
      ),
    );
  }

  void _togglePoint(LatLng point) {
    try {
      if (_polygonMode) _polygonTap(point);
      if (_polylineMode) _polylineTap(point);
    } catch (e, stacktrace) {
      print('Error in access_profile_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _polygonTap(LatLng point) {
    if (_type == null) return;
    final markerId = MarkerId('${_type!.name}_marker_${point.toString()}');
    setState(() {
      _polygonPoints.add(point);
      _polygonMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          icon: AssetMapBitmap(
            'assets/test_markers/${_type!.name}_marker.png',
            width: 30,
            height: 30,
          ),
          onTap: () {
            // If the marker is tapped again, it will be removed
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

  void _polylineTap(LatLng point) {
    if (_type == null) return;
    final markerId = MarkerId('${_type!.name}_marker_${point.toString()}');
    setState(() {
      _currentPolylinePoints.add(point);
      _polylineMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: true,
          icon: AssetMapBitmap(
            'assets/test_markers/${_type!.name}_marker.png',
            width: 30,
            height: 30,
          ),
          onTap: () {
            // If the marker is tapped again, it will be removed
            setState(() {
              _currentPolylinePoints.remove(point);
              _polylineMarkers
                  .removeWhere((marker) => marker.markerId == markerId);
              _currentPolyline =
                  createPolyline(_currentPolylinePoints, Colors.white);
              if (_polylineMarkers.isNotEmpty) {
                _visiblePolylineMarkers = {
                  _polylineMarkers.first,
                  _polylineMarkers.last
                };
              } else {
                _visiblePolylineMarkers = {};
              }
            });
          },
        ),
      );
    });
    if (_polylineMarkers.isNotEmpty) {
      _visiblePolylineMarkers = {_polylineMarkers.first, _polylineMarkers.last};
    }
    _currentPolyline =
        createPolyline([..._currentPolylinePoints, point], Colors.white);
  }

  void _finalizeShape() {
    if (_polygonMode) _finalizePolygon();
    if (_polylineMode) {
      // If parking, then make sure to save the polygon also.
      if (_type == AccessType.parking && _currentPolygon != null) {
        _polygons.add(_currentPolygon!);
      }
      _finalizePolyline();
    }
  }

  void _finalizePolyline() {
    Polyline? finalPolyline =
        createPolyline(_currentPolylinePoints, Colors.black);
    if (finalPolyline != null) {
      setState(() {
        _polylines.add(finalPolyline);
      });
    } else {
      print("Polyline is null. Nothing to finalize.");
    }
    // Save data to its respective type list.
    _saveLocalData();
    // Update widgets accordingly
    setState(() {
      _polylineMarkers = {};
      _currentPolylinePoints = [];
      _currentPolyline = null;
      _visiblePolylineMarkers = {};
      _currentPolygon = null;
      _directions = 'Choose a category. Or, click finish if done.';
    });
    _polylineMode = false;
    _currentSpotsOrRoute = null;
  }

  void _saveLocalData() {
    try {
      if (_type != AccessType.taxiAndRideShare &&
          _currentSpotsOrRoute == null) {
        throw Exception("Current spots/routes not set in _saveLocalData(). "
            "Make sure a value is entered before continuing.");
      }
      if (_currentPolyline == null) {
        throw Exception("Current polyline is null in _saveLocalData()");
      }
      switch (_type) {
        case null:
          throw Exception(
              "_type is null in saveLocalData(). Make sure that type is set correctly when invoking _finalizeShape().");
        case AccessType.bikeRack:
          _accessData.bikeRacks.add(BikeRack(
              spots: _currentSpotsOrRoute!, polyline: _currentPolyline!));
        case AccessType.taxiAndRideShare:
          _accessData.taxisAndRideShares
              .add(TaxiAndRideShare(polyline: _currentPolyline!));
        case AccessType.parking:
          _accessData.parkingStructures.add(Parking(
              spots: _currentSpotsOrRoute!,
              polyline: _currentPolyline!,
              polygon: _currentPolygon!));
        case AccessType.transportStation:
          _accessData.transportStations.add(TransportStation(
              routeNumber: _currentSpotsOrRoute!, polyline: _currentPolyline!));
      }
    } catch (e, stacktrace) {
      print(
          "Error saving data locally in identify_access_test.dart, saveLocalData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  void _finalizePolygon() {
    try {
      // Create polygon.
      _currentPolygon = finalizePolygon(_polygonPoints);

      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _polygonMarkers.clear();
        _polygonMode = false;
        _polylineMode = false;
      });

      _showInputDialog(
        text: 'How Many Parking Spots?',
        hintText: 'Enter number of spots.',
        onNext: () {
          setState(() {
            _polylineMode = true;
            _directions =
                'Now define the path to the project area from the parking.';
          });
        },
      );
    } catch (e, stacktrace) {
      print('Exception in _finalize_polygon(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
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
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                polylines: _currentPolyline == null
                    ? (_oldPolylinesToggle ? _polylines : {})
                    : (_oldPolylinesToggle
                        ? {..._polylines, _currentPolyline!}
                        : {_currentPolyline!}),
                padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                onMapCreated: _onMapCreated,
                initialCameraPosition:
                    CameraPosition(target: _location, zoom: _zoom),
                polygons: _oldPolylinesToggle
                    ? {
                        _projectPolygon,
                        ..._polygons,
                        if (_currentPolygon != null) _currentPolygon!
                      }
                    : {
                        _projectPolygon,
                        if (_currentPolygon != null) _currentPolygon!
                      },
                markers: {
                  ..._markers,
                  ..._polygonMarkers,
                  ..._visiblePolylineMarkers
                },
                onTap: _togglePoint,
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
                    Expanded(
                      child: _directionsVisible
                          ? DirectionsText(
                              onTap: () {
                                setState(() {
                                  _directionsVisible = !_directionsVisible;
                                });
                              },
                              text: _directions)
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
                          backgroundColor: Colors.green,
                          borderColor: Color(0xFF2D6040),
                          onPressed: _toggleMapType,
                          icon: const Icon(Icons.map),
                        ),
                        if (!_polygonMode && !_pointMode && !_polylineMode)
                          CircularIconMapButton(
                            borderColor: Color(0xFF2D6040),
                            onPressed: () {
                              setState(() {
                                _deleteMode = !_deleteMode;
                              });
                            },
                            backgroundColor:
                                _deleteMode ? Colors.blue : Colors.red,
                            icon: Icon(
                              _deleteMode ? Icons.location_on : Icons.delete,
                              size: 30,
                            ),
                          ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFE4E9EF).withValues(alpha: 0.9),
                          borderColor: Color(0xFF4A5D75),
                          onPressed: () {
                            setState(() {
                              _oldPolylinesToggle = !_oldPolylinesToggle;
                            });
                          },
                          icon: Icon(
                            _oldPolylinesToggle
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
            if (_deleteMode)
              TestErrorText(
                padding:
                    EdgeInsets.fromLTRB(20, 0, 20, _bottomSheetHeight + 20),
                text: "You are in delete mode.",
              ),
          ],
        ),
        bottomSheet: SizedBox(
          height: _bottomSheetHeight,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 10.0),
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
                  children: [
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'Identifying Access',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: placeYellow,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        'Mark where people enter the project area from.',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Center(
                      child: Text(
                        'Access Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        TestButton(
                          flex: 6,
                          buttonText: 'Parking',
                          onPressed: (_pointMode ||
                                  _polygonMode ||
                                  _polylineMode ||
                                  _deleteMode)
                              ? null
                              : () {
                                  setState(() {
                                    _type = AccessType.parking;
                                    _polygonMode = true;
                                    _directions =
                                        'First, define the parking area by creating a polygon.';
                                  });
                                },
                        ),
                        TestButton(
                          flex: 6,
                          buttonText: 'Public Transport',
                          onPressed: (_pointMode ||
                                  _polygonMode ||
                                  _polylineMode ||
                                  _deleteMode)
                              ? null
                              : () {
                                  _showInputDialog(
                                    text: 'Enter the Route Number',
                                    hintText: 'Route Number',
                                    onNext: () {
                                      setState(() {
                                        _type = AccessType.transportStation;
                                        _polylineMode = true;
                                        _directions =
                                            "Mark the spot of the transport station. Then define the path to the project area.";
                                      });
                                    },
                                  );
                                },
                        ),
                      ],
                    ),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        TestButton(
                          flex: 6,
                          onPressed: (_pointMode ||
                                  _polygonMode ||
                                  _polylineMode ||
                                  _deleteMode)
                              ? null
                              : () {
                                  _showInputDialog(
                                    text: 'How Many Bikes/Scooters Can Fit?',
                                    hintText: 'Enter number of spots.',
                                    onNext: () {
                                      setState(() {
                                        _type = AccessType.bikeRack;
                                        _polylineMode = true;
                                        _directions =
                                            "Mark the spot of the bike/scooter rack. Then define the path to the project area.";
                                      });
                                    },
                                  );
                                },
                          buttonText: 'Bike or Scooter Rack',
                        ),
                        TestButton(
                          flex: 6,
                          buttonText: 'Taxi or Rideshare',
                          onPressed: (_pointMode ||
                                  _polygonMode ||
                                  _polylineMode ||
                                  _deleteMode)
                              ? null
                              : () {
                                  setState(() {
                                    _type = AccessType.taxiAndRideShare;
                                    _polylineMode = true;
                                    _directions =
                                        'Mark a point where the taxi dropped off. Then make a line to denote the path to the project area.';
                                  });
                                },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        spacing: 10,
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              spacing: 10,
                              children: <Widget>[
                                Flexible(
                                  child: EditButton(
                                    text: 'Confirm Shape',
                                    foregroundColor: Colors.green,
                                    backgroundColor: Colors.white,
                                    icon: const Icon(Icons.check),
                                    iconColor: Colors.green,
                                    onPressed: ((_polylineMode &&
                                                (_currentPolyline != null &&
                                                    _currentPolyline!
                                                            .points.length >
                                                        2)) ||
                                            (_polygonMode &&
                                                _polygonPoints.length >= 3))
                                        ? _finalizeShape
                                        : null,
                                  ),
                                ),
                                Flexible(
                                  child: EditButton(
                                    text: 'Cancel',
                                    foregroundColor: Colors.red,
                                    backgroundColor: Colors.white,
                                    icon: const Icon(Icons.cancel),
                                    iconColor: Colors.red,
                                    onPressed: (_polylineMode || _polygonMode)
                                        ? () {
                                            setState(() {
                                              _pointMode = false;
                                              _polygonMode = false;
                                              _polylineMode = false;
                                              _polylineMarkers = {};
                                              _currentPolyline = null;
                                              _currentPolylinePoints = [];
                                              _visiblePolylineMarkers = {};
                                              _polygonMarkers = {};
                                              _currentPolygon = null;
                                              _directions =
                                                  'Choose a category. Or, click finish if done.';
                                            });
                                            _polygonPoints = [];
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 0,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: EditButton(
                                text: 'Finish',
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white,
                                icon: const Icon(Icons.chevron_right,
                                    color: Colors.black),
                                onPressed: (_polygonMode ||
                                        _polylineMode ||
                                        _deleteMode)
                                    ? null
                                    : () {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return TestFinishDialog(
                                                onNext: () {
                                                  widget.activeTest
                                                      .submitData(_accessData);
                                                  Navigator.pop(context);
                                                },
                                              );
                                            });
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInputDialog(
      {required String text,
      required String hintText,
      required VoidCallback? onNext}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Column(
            children: [
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            onChanged: (inputText) {
              int? parsedInt = int.tryParse(inputText);
              if (parsedInt == null) {
                print(
                    "Error: Could not parse int in _showInputDialog with type $_type");
                print("Invalid input: defaulting to null.");
              }
              setState(() {
                _currentSpotsOrRoute = parsedInt;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'Cancel');
                {
                  setState(() {
                    _pointMode = false;
                    _polygonMode = false;
                    _polylineMode = false;
                    _polylineMarkers = {};
                    _currentPolyline = null;
                    _currentPolylinePoints = [];
                    _visiblePolylineMarkers = {};
                    _polygonMarkers = {};
                    _currentPolygon = null;
                    _directions =
                        'Choose a category. Or, click finish if done.';
                    _currentSpotsOrRoute = null;
                  });
                  _polygonPoints = [];
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_currentSpotsOrRoute == null) return;
                onNext!();
                Navigator.pop(context, 'Next');
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );
  }
}
