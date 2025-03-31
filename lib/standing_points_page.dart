import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';

class StandingPointsPage extends StatefulWidget {
  final Project activeProject;
  final List<StandingPoint>? currentStandingPoints;
  const StandingPointsPage(
      {super.key, required this.activeProject, this.currentStandingPoints});

  @override
  State<StandingPointsPage> createState() => _StandingPointsPageState();
}

final AssetMapBitmap disabledIcon = AssetMapBitmap(
  'assets/standing_point_disabled_marker.png',
  width: 45,
  height: 45,
);
final AssetMapBitmap enabledIcon = AssetMapBitmap(
  'assets/standing_point_enabled_marker.png',
  width: 45,
  height: 45,
);

class _StandingPointsPageState extends State<StandingPointsPage> {
  DocumentReference? teamRef;
  GoogleMapController? mapController;
  LatLng _location = defaultLocation; // Default location
  bool _isLoading = true;
  final String _directions =
      "Select the standing points you want to use in this test. Then click confirm.";
  final Set<Polygon> _polygons = {}; // Set of polygons
  Set<Marker> _markers = {}; // Set of markers for points
  List<StandingPoint> _standingPoints = [];
  Marker? _currentMarker;
  static const double _bottomSheetHeight = 300;
  MapType _currentMapType = MapType.satellite; // Default map type
  final List<bool> _checkboxValues = [];
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
      _polygons.add( getProjectPolygon(widget.activeProject.polygonPoints));
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _markers =
          _setMarkersFromStandingPoints(widget.activeProject.standingPoints);
      _standingPoints = widget.activeProject.standingPoints.toList();
      if (widget.currentStandingPoints != null) {
        final List<StandingPoint> currentStandingPoints =
            widget.currentStandingPoints!;
        _loadCurrentStandingPoints(currentStandingPoints);
      }
      _isLoading = false;
    });
  }

  /// Takes a list of points and creates the default markers from their title
  /// and position.
  Set<Marker> _setMarkersFromStandingPoints(
      List<StandingPoint> standingPoints) {
    Set<Marker> markers = {};
    for (final standingPoint in standingPoints) {
      final markerId = MarkerId(standingPoint.toString());
      _checkboxValues.add(false);
      markers.add(
        Marker(
          markerId: markerId,
          position: standingPoint.location,
          icon: disabledIcon,
          infoWindow: InfoWindow(
            title: standingPoint.title,
            snippet: '${standingPoint.location.latitude.toStringAsFixed(5)},'
                ' ${standingPoint.location.latitude.toStringAsFixed(5)}',
          ),
          onTap: () {
            // Get matching marker from id and point index from marker point
            final Marker thisMarker =
                _markers.singleWhere((marker) => marker.markerId == markerId);
            final int listIndex = _standingPoints.indexWhere((standingPoint) =>
                standingPoint.location == thisMarker.position);

            // Update current marker and toggle this point's checkbox
            _currentMarker = thisMarker;
            _checkboxValues[listIndex] = !_checkboxValues[listIndex];
            _toggleMarker();
          },
        ),
      );
    }
    return markers;
  }

  /// Toggles the [_currentMarker] on or off.
  void _toggleMarker() {
    if (_currentMarker == null) return;
    // Adds either an enabled or disabled marker based on whether _currentMarker
    // is disabled or enabled.
    if (_currentMarker?.icon == enabledIcon) {
      setState(() {
        _markers.add(_currentMarker!.copyWith(iconParam: disabledIcon));
      });
    } else if (_currentMarker?.icon == disabledIcon) {
      setState(() {
        _markers.add(_currentMarker!.copyWith(iconParam: enabledIcon));
      });
    }
    // Remove the old outdated marker after the new marker has been added.
    setState(() {
      _markers.remove(_currentMarker);
    });
    _currentMarker = null;
  }

  void _loadCurrentStandingPoints(List<StandingPoint> currentStandingPoints) {
    for (final standingPoint in currentStandingPoints) {
      final Marker thisMarker = _markers
          .singleWhere((marker) => standingPoint.location == marker.position);
      final int listIndex = _standingPoints
          .indexWhere((point) => point.location == thisMarker.position);
      _currentMarker = thisMarker;
      _checkboxValues[listIndex] = !_checkboxValues[listIndex];
      _toggleMarker();
    }
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
                          padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                          onMapCreated: _onMapCreated,
                          initialCameraPosition:
                              CameraPosition(target: _location, zoom: 14.0),
                          polygons: _polygons,
                          markers: _markers,
                          mapType: _currentMapType, // Use current map type
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
                              left: 10.0,
                              bottom: _bottomSheetHeight + 50,
                            ),
                            child: FloatingActionButton(
                              heroTag: null,
                              onPressed: _toggleMapType,
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.map),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomSheet: Container(
          height: _bottomSheetHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0),
                child: SizedBox(
                  height: _bottomSheetHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 15.0,
                      right: 15.0,
                      bottom: 50.0,
                    ),
                    itemCount: _markers.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: [
                          index == 0 ? Divider() : SizedBox(),
                          CheckboxListTile(
                            title: Text(
                              _standingPoints[index].title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.fade),
                            ),
                            subtitle: Text(
                                '${_standingPoints[index].location.latitude.toStringAsFixed(5)},'
                                ' ${_standingPoints[index].location.longitude.toStringAsFixed(5)}'),
                            value: _checkboxValues[index],
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _checkboxValues[index] =
                                          !_checkboxValues[index];
                                    });
                                    _currentMarker = _markers.singleWhere(
                                        (marker) =>
                                            marker.position ==
                                            (_standingPoints[index].location));
                                    _location = _currentMarker!.position;
                                    _moveToLocation();
                                    _toggleMarker();
                                  },
                          ),
                          Divider(),
                        ],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(
                      height: 10,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FilledButton.icon(
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
                              if (_checkboxValues.length !=
                                  _standingPoints.length) {
                                throw Exception(
                                    "Checkbox values and standing points do not match!");
                              }
                              setState(() {
                                _isLoading = true;
                              });
                              List<StandingPoint> enabledPoints = [];
                              for (int i = 0; i < _standingPoints.length; i++) {
                                if (_checkboxValues[i]) {
                                  enabledPoints.add(_standingPoints[i]);
                                }
                              }
                              Navigator.pop(context, enabledPoints);
                            } catch (e, stacktrace) {
                              print(
                                  "Exception in confirming standing points (standing_points_page.dart): $e");
                              print("Stacktrace: $stacktrace");
                            }
                          },
                    label: Text('Confirm'),
                    icon: const Icon(Icons.check),
                    iconAlignment: IconAlignment.end,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}