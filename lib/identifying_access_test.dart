import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart';
import 'widgets.dart';
import 'project_details_page.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'google_maps_functions.dart';
import 'homepage.dart';

class IdentifyingAccess extends StatefulWidget {
  final Project activeProject;
  final Test activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const IdentifyingAccess({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<IdentifyingAccess> createState() => _IdentifyingAccessState();
}

class _IdentifyingAccessState extends State<IdentifyingAccess> {
  bool _isLoading = true;
  bool _polygonMode = false;
  bool _pointMode = false;
  bool _polylineMode = false;
  bool _oldPolylinesToggle = true;
  int _currentSpotsOrRoute = 0;
  AccessType? _type;
  String _directions = "Choose a category.";
  final double _bottomSheetHeight = 300;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  Map<AccessType, List> _accessData = {
    AccessType.bikeRack: [],
    AccessType.taxiAndRideShare: [],
    AccessType.parking: [],
    AccessType.transportStation: [],
  };

  Polyline? _currentPolyline;
  List<LatLng> _currentPolylinePoints = [];
  Set<Polyline> _polylines = {};
  Set<Marker> _polylineMarkers = {};
  Set<Marker> _visiblePolylineMarkers = {};
  Set<Polygon> _currentPolygon = {};
  List<LatLng> _polygonPoints = []; // Points for the polygon
  Set<Polygon> _polygons = {}; // Set of polygons
  List<GeoPoint> _polygonAsGeoPoints =
      []; // The current polygon represented as points (for Firestore).
  Set<Marker> _markers = {}; // Set of markers for points
  Set<Marker> _polygonMarkers = {}; // Set of markers for polygon creation

  MapType _currentMapType = MapType.satellite; // Default map type

  Project? project;

  @override
  void initState() {
    super.initState();
    initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void initProjectArea() {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 14),
      ),
    );
  }

  void _togglePoint(LatLng point) {
    try {
      if (_pointMode) _pointTap(point);
      if (_polygonMode) _polygonTap(point);
      if (_polylineMode) _polylineTap(point);
    } catch (e, stacktrace) {
      print('Error in identifying_access_test.dart, _togglePoint(): $e');
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

  // TODO: Delete if proves to be unnecessary...
  void _pointTap(LatLng point) {
    if (_type == null) return;
    final markerId = MarkerId('${_type!.name}_marker_${point.toString()}');
    setState(() {
      // TODO: create list of markers for test, add these to it (cat, dog, etc.)
      _markers.add(
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
            // If placing a point or polygon, don't remove point.
            if (_polylineMode || _polygonMode) return;
            // If the marker is tapped again, it will be removed
            setState(() {
              _markers.removeWhere((marker) => marker.markerId == markerId);
              // TODO: create list of points for test
            });
          },
        ),
      );
    });
    _pointMode = false;
  }

  void _finalizeShape() {
    if (_polygonMode) _finalizePolygon();
    if (_polylineMode) {
      // If parking, then make sure to save the polygon also.
      if (_type == AccessType.parking) {
        _polygons = {..._polygons, ..._currentPolygon};
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
    _saveLocalData();
    setState(() {
      _polylineMarkers = {};
      _currentPolylinePoints = [];
      _currentPolyline = null;
      _visiblePolylineMarkers = {};
      _directions = 'Choose a category. Or, click finish if done.';
    });
    _polylineMode = false;
    _currentSpotsOrRoute = 0;
  }

  void _saveLocalData() {
    try {
      if (_accessData[_type] == null) {
        throw Exception(
            "Data map for given type ($_type) is null in _saveLocalData()");
      }
      if (_currentPolyline == null) {
        throw Exception("Current polyline is null in _saveLocalData()");
      }
      switch (_type) {
        case null:
          throw Exception(
              "_type is null in saveLocalData(). Make sure that type is set correctly when invoking _finalizeShape().");
        case AccessType.bikeRack:
          _accessData[_type]?.add(BikeRack(
              spots: _currentSpotsOrRoute, polyline: _currentPolyline!));
        case AccessType.taxiAndRideShare:
          _accessData[_type]
              ?.add(TaxiAndRideShare(polyline: _currentPolyline!));
        case AccessType.parking:
          _accessData[_type]?.add(Parking(
              spots: _currentSpotsOrRoute,
              polyline: _currentPolyline!,
              polygon: _currentPolygon.first));
        case AccessType.transportStation:
          _accessData[_type]?.add(TransportStation(
              routeNumber: _currentSpotsOrRoute, polyline: _currentPolyline!));
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
      // TODO: add to object;
      // Cleans up current polygon representations.
      _polygonAsGeoPoints = [];

      // Gets list of polygon points for Firestore.
      _polygonAsGeoPoints = _polygonPoints.toGeoPointList();

      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _polygonMarkers.clear();
        _polygonMode = false;
        _polylineMode = false;
      });

      _showDialog(
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
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: GoogleMap(
                        // TODO: size based off of bottomsheet container
                        polylines: _currentPolyline == null
                            ? (_oldPolylinesToggle ? _polylines : {})
                            : (_oldPolylinesToggle
                                ? {..._polylines, _currentPolyline!}
                                : {_currentPolyline!}),
                        padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 14),
                        polygons: {..._polygons, ..._currentPolygon},
                        markers: {
                          ..._markers,
                          ..._polygonMarkers,
                          ..._visiblePolylineMarkers
                        },
                        onTap: _togglePoint,
                        mapType: _currentMapType, // Use current map type
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20.0, horizontal: 25.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: directionsTransparency,
                            gradient: defaultGrad,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _directions,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: _bottomSheetHeight + 130, left: 5),
                        child: FloatingActionButton(
                          heroTag: null,
                          onPressed: _toggleMapType,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.map),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: _bottomSheetHeight + 35, left: 5),
                        child: Container(
                          decoration: BoxDecoration(
                              gradient: defaultGrad,
                              color: directionsTransparency,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 7.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Previous Lines:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Tooltip(
                                  message: "Toggle Old Polylines",
                                  child: Switch(
                                    // This bool value toggles the switch.
                                    value: _oldPolylinesToggle,
                                    activeTrackColor: placeYellow,
                                    inactiveThumbColor: placeYellow,
                                    onChanged: (bool value) {
                                      // This is called when the user toggles the switch.
                                      setState(() {
                                        _oldPolylinesToggle = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        bottomSheet: _isLoading
            ? SizedBox()
            : Container(
                height: _bottomSheetHeight,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(
                      'Access Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      spacing: 10,
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: buildTestButton(
                            onPressed: (BuildContext context) {
                              _showDialog(
                                text: 'How Many Bikes Can Fit?',
                                hintText: 'Enter number of spots.',
                                onNext: () {
                                  setState(() {
                                    _type = AccessType.bikeRack;
                                    _polylineMode = true;
                                    _directions =
                                        "Mark the spot of the bike rack. Then define the path to the project area.";
                                  });
                                },
                              );
                            },
                            context: context,
                            text: 'Bike Rack',
                          ),
                        ),
                        Flexible(
                          flex: 2,
                          child: buildTestButton(
                            text: 'Parking',
                            context: context,
                            onPressed: (BuildContext context) {
                              setState(() {
                                _type = AccessType.parking;
                                _polygonMode = true;
                                _directions =
                                    'First, define the parking area by creating a polygon.';
                              });
                            },
                          ),
                        ),
                        Flexible(
                          flex: 3,
                          child: buildTestButton(
                            text: 'Public Transport',
                            context: context,
                            onPressed: (BuildContext context) {
                              _showDialog(
                                text: 'Enter the Route Number',
                                hintText: 'Route Number',
                                onNext: () {
                                  setState(() {
                                    _type = AccessType.transportStation;
                                    _polylineMode = true;
                                    _directions =
                                        "Mark the spot of the bike rack. Then define the path to the project area.";
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Flexible(flex: 1, child: SizedBox())
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Flexible(
                          flex: 2,
                          child: buildTestButton(
                              context: context,
                              text: 'Taxi or Rideshare',
                              onPressed: (BuildContext context) {
                                setState(() {
                                  _type = AccessType.taxiAndRideShare;
                                  _polylineMode = true;
                                  _directions =
                                      'Mark a point where the taxi dropped off. Then make a line to denote the path to the project area.';
                                });
                              }),
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
                                    onPressed: (_polylineMode || _polygonMode)
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
                                              _currentPolygon = {};
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
                                onPressed: () {
                                  // TODO: check isComplete either before submitting or probably before starting test
                                  widget.activeTest.submitData(_accessData);
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomePage(),
                                      ));
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProjectDetailsPage(
                                                projectData:
                                                    widget.activeProject),
                                      ));
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
      ),
    );
  }

  void _showDialog(
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
              Text(
                "Leave blank if unknown.",
                style: TextStyle(
                  fontSize: 15,
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
                    "Error: Could not parse int in _showDialog with type $_type");
                print("Invalid input: defaulting to 0.");
              }
              _currentSpotsOrRoute = parsedInt ?? 0;
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
                    _currentPolygon = {};
                    _directions =
                        'Choose a category. Or, click finish if done.';
                  });
                  _currentSpotsOrRoute = 0;
                  _polygonPoints = [];
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
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

  FilledButton buildTestButton(
      {required BuildContext context,
      required String text,
      required Function(BuildContext) onPressed}) {
    return FilledButton(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.only(left: 15, right: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        iconColor: Colors.black,
        disabledBackgroundColor: disabledGrey,
      ),
      onPressed:
          (_polylineMode || _polygonMode) ? null : () => onPressed(context),
      child: Text(text),
    );
  }
}