import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart';
import 'widgets.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class SectionCreationPage extends StatefulWidget {
  final Project activeProject;
  final List? currentSection;
  const SectionCreationPage(
      {super.key, required this.activeProject, this.currentSection});

  @override
  State<SectionCreationPage> createState() => _SectionCreationPageState();
}

class _SectionCreationPageState extends State<SectionCreationPage> {
  GoogleMapController? mapController;
  LatLng _location = defaultLocation;
  double _zoom = 18;
  bool _isLoading = true;
  String _directions =
      "Create your section by marking your points outside of the polygon then drag it to make your section. Then click confirm button.";
  final Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  List<LatLng> _linePoints = [];
  MapType _currentMapType = MapType.satellite;
  Polyline? _polyline;
  List<mp.LatLng> _projectArea = [];
  bool _sectionSet = false;
  bool _directionsVisible = true;
  bool _outsidePoint = false;
  bool _isConfirmed = false; // Flag to prevent further points after confirmation
  bool _isButtonPressed = false; // Prevent adding points while buttons are pressed

  @override
  void initState() {
    super.initState();
    _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
    _location = getPolygonCentroid(_polygons.first);
    _projectArea = _polygons.first.toMPLatLngList();
    _zoom = getIdealZoom(_projectArea, _location.toMPLatLng()) - 0.2;
    _isLoading = false;
  }

  Future<void> _polylineTap(LatLng point) async {
    if (_isConfirmed || _isButtonPressed) return; // Prevent adding points after confirmation or button press

    if (_sectionSet) return;

    if (!mp.PolygonUtil.containsLocation(
        mp.LatLng(point.latitude, point.longitude), _projectArea, true)) {
      setState(() {
        _outsidePoint = true;
      });
    }

    final index = _linePoints.length;
    final markerId = MarkerId('marker_$index');
    _linePoints.add(point);

    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(125),
          onDragEnd: (newPosition) {
            setState(() {
              _linePoints[index] = newPosition;
            });
          },
          onTap: () {
            setState(() {
              _linePoints.removeAt(index);
              _markers.removeWhere((m) => m.markerId == markerId);
            });
          },
        ),
      );
    });

    if (_outsidePoint) {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _outsidePoint = false;
      });
    }
  }

  void _confirmPolyline() {
    setState(() {
      _polyline = createPolyline(_linePoints, Colors.green[600]!);
      _isConfirmed = true; // Mark as confirmed
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation();
  }

  void _moveToLocation() {
    mapController!.animateCamera(
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

  void _resetSection() {
    setState(() {
      _isButtonPressed = true; // Disable point addition while resetting
    });

    setState(() {
      _markers.clear();
      _linePoints.clear();
      _polyline = null;
      _sectionSet = false;
      _directions =
          "Create your section by marking your points outside of the polygon then drag it to make your section. Then click confirm button.";
      _isConfirmed = false; // Reset the confirmation flag
    });

    setState(() {
      _isButtonPressed = false; // Re-enable point addition after reset
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition:
                        CameraPosition(target: _location, zoom: _zoom),
                    polygons: _polygons,
                    polylines: {if (_polyline != null) _polyline!},
                    markers: _markers,
                    mapType: _currentMapType,
                    onTap: _polylineTap,
                  ),
                ),
                SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _directionsVisible
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 15.0),
                                child: DirectionsText(
                                  onTap: () {
                                    setState(() {
                                      _directionsVisible = !_directionsVisible;
                                    });
                                  },
                                  text: _directions,
                                ),
                              )
                            : SizedBox(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15, right: 15),
                        child: Column(
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
                            CircularIconMapButton(
                              borderColor: Color(0xFF2D6040),
                              onPressed: _resetSection,
                              backgroundColor: Colors.red,
                              icon: Icon(
                                Icons.delete_sweep,
                                size: 30,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.only(left: 15, right: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 3.0,
                              shadowColor: Colors.black,
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                              iconColor: Colors.white,
                              disabledBackgroundColor: disabledGrey,
                            ),
                            onPressed: _confirmPolyline,
                            label: Text('Confirm Points'),
                            icon: const Icon(Icons.check),
                          ),
                          SizedBox(width: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.only(left: 15, right: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              elevation: 3.0,
                              shadowColor: Colors.black,
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                              iconColor: Colors.white,
                              disabledBackgroundColor: disabledGrey,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    try {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      Navigator.pop(context, _polyline?.points);
                                    } catch (e, stacktrace) {
                                      print("Exception in confirming section: $e");
                                      print("Stacktrace: $stacktrace");
                                    }
                                  },
                            label: Text('Finished'),
                            icon: const Icon(Icons.check),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(child: _outsidePoint ? TestErrorText() : SizedBox()),
              ],
            ),
    );
  }
}
