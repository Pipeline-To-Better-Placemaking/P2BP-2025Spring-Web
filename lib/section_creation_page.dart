import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';
import 'theme.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes/project_class.dart';

class SectionCreationPage extends StatefulWidget {
  final Project activeProject;
  final List? currentSection;
  const SectionCreationPage(
      {super.key, required this.activeProject, this.currentSection});

  @override
  State<SectionCreationPage> createState() => _SectionCreationPageState();
}

class _SectionCreationPageState extends State<SectionCreationPage> {
  DocumentReference? teamRef;
  GoogleMapController? mapController;
  LatLng _location = defaultLocation; // Default location
  bool _isLoading = true;
  String _directions =
      "Create your section by marking points by tapping outside of the polygon area. Then click the check button to confirm.";
  final Set<Polygon> _polygons = {}; // Set of polygons
  Set<Marker> _markers = {}; // Set of markers for points
  MapType _currentMapType = MapType.satellite; // Default map type
  Project? project;
  Set<Polyline> _polyline = {};
  LatLng? _currentPoint;
  bool _sectionSet = false;

  bool _addPointsMode = true;
  bool _isHoveringOverButton = false;

  @override
  void initState() {
    super.initState();
    initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void initProjectArea() {
    setState(() {
      _polygons.add(widget.activeProject.polygon.clone());
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      if (widget.currentSection != null) {
        final List? currentSection = widget.currentSection;
        _loadCurrentSection(currentSection);
      }
      _isLoading = false;
    });
  }

  void _loadCurrentSection(List? currentSection) {
    final Polyline? polyline =
        createPolyline(currentSection!.toLatLngList(), Colors.green[600]!);
    if (polyline == null) return;
    setState(() {
      _polyline = {polyline};
    });
  }

  void _polylineTap(LatLng point) {
    // Allow adding any number of points.

    final MarkerId markerId = MarkerId('marker_${point.toString()}');
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _markers = _markers.map((marker) {
                if (marker.markerId == markerId) {
                  return marker.copyWith(positionParam: newPosition);
                }
                return marker;
              }).toSet();

              _polyline = {
                Polyline(
                  polylineId: PolylineId('polyline_1'),
                  points: _markers.map((marker) => marker.position).toList(),
                  color: Colors.green,
                  width: 5,
                ),
              };
            });
          },
        ),
      );

      _directions =
          'Move the points to your desired spots to create a polyline, then press the finalize button to create the polyline.';
    });
    _currentPoint = point;
  }

  void _finalizePolyline() {
    setState(() {
      if (_markers.length >= 2) {
        _polyline.add(
          Polyline(
            polylineId: PolylineId(
                'polyline_${_polyline.length + 1}'), // Increment polyline ID for multiple polylines
            points: _markers.map((marker) => marker.position).toList(),
            color: Colors.green,
            width: 5,
          ),
        );
        _markers.clear(); // Clear markers after creating the polyline
        _directions =
            'Polyline created. If you are satisfied with it, press the finish button.';
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  void _moveToLocation() {
    if (mapController == null) return;
    mapController!.animateCamera(
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition:
                              CameraPosition(target: _location, zoom: 14.0),
                          polygons: _polygons,
                          polylines: _polyline,
                          markers: _markers,
                          mapType: _currentMapType, // Use current map type
                          onTap: _addPointsMode
                              ? _polylineTap
                              : null, // Only allow tapping to add points when _addPointsMode is true
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
                                    color: Color.fromRGBO(0, 0, 0,
                                        0.1), // RGBA format (Red, Green, Blue, Alpha),
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
                            padding: const EdgeInsets.only(
                                left: 10.0, bottom: 130.0),
                            child: MouseRegion(
                              onEnter: (_) => setState(() {
                                _addPointsMode =
                                    false; // Disable adding points when hovering over button
                                _isHoveringOverButton = true;
                              }),
                              onExit: (_) => setState(() {
                                _addPointsMode =
                                    true; // Re-enable adding points when not hovering over button
                                _isHoveringOverButton = false;
                              }),
                              child: FloatingActionButton(
                                tooltip: 'Clear all.',
                                heroTag: null,
                                onPressed: () {
                                  setState(() {
                                    _markers = {}; // Remove all markers
                                    _currentPoint = null;
                                    _polyline = {}; // Remove polyline
                                    _sectionSet = false;
                                    _directions =
                                        "Create your section by marking points by tapping on the map outside of the polygon area. Then click the check to confirm.";
                                  });
                                },
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.delete_sweep,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Finalize Polyline Button
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 10.0, bottom: 210.0), // Adjusted padding
                            child: MouseRegion(
                              onEnter: (_) => setState(() {
                                _addPointsMode =
                                    false; // Disable adding points when hovering over button
                                _isHoveringOverButton = true;
                              }),
                              onExit: (_) => setState(() {
                                _addPointsMode =
                                    true; // Re-enable adding points when not hovering over button
                                _isHoveringOverButton = false;
                              }),
                              child: FloatingActionButton(
                                tooltip: 'Finalize Polyline',
                                heroTag: null,
                                onPressed: _markers.length >= 2
                                    ? _finalizePolyline // Enable if 2 or more markers are present
                                    : null,
                                backgroundColor:
                                    _markers.length >= 2 ? Colors.blue : Colors.grey,
                                child: Icon(
                                  Icons.check, // Checkmark icon
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(left: 10.0, bottom: 50),
                            child: MouseRegion(
                              onEnter: (_) => setState(() {
                                _addPointsMode =
                                    false; // Disable adding points when hovering over button
                                _isHoveringOverButton = true;
                              }),
                              onExit: (_) => setState(() {
                                _addPointsMode =
                                    true; // Re-enable adding points when not hovering over button
                                _isHoveringOverButton = false;
                              }),
                              child: FloatingActionButton(
                                tooltip: 'Change map type.',
                                onPressed: _toggleMapType,
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.map),
                              ),
                            ),
                          ),
                        ),
                        // Finish Button
                        Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.only(left: 15, right: 15),
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
                              onPressed: (_isLoading ||
                                      _polyline.isEmpty ||
                                      _polyline.first.points.length < 2)
                                  ? null
                                  : () {
                                      try {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        final pointsToSave =
                                            _polyline.first.points;
                                        Navigator.pop(context, pointsToSave);
                                      } catch (e, stacktrace) {
                                        print(
                                            "Exception in confirming section: $e");
                                        print("Stacktrace: $stacktrace");
                                      }

                                      setState(() {
                                        _isLoading = false;
                                      }); // Ensure loading state resets without `finally`
                                    },
                              label: Text('Finish'),
                              icon: const Icon(Icons.check),
                              iconAlignment: IconAlignment.end,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
