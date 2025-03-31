import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'firestore_functions.dart';
import 'theme.dart';
import 'google_maps_functions.dart';
import 'db_schema_classes.dart';

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
  bool _isLoading = true;
  bool _isTypeSelected = false;
  bool _outsidePoint = false;
  LightType? _selectedType;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  List<mp.LatLng> _projectArea = [];

  final Set<Marker> _markers = {}; // Set of markers visible on map
  Set<Polygon> _polygons = {}; // Set of polygons
  final LightingProfileData _newData = LightingProfileData();

  static const double _bottomSheetHeight = 300;

  @override
  void initState() {
    super.initState();
    _initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void _initProjectArea() {
    setState(() {
      _polygons = getProjectPolygon(widget.activeProject.polygonPoints);
      _location = getPolygonCentroid(_polygons.first);
      // Take some latitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      _projectArea = _polygons.first.toMPLatLngList();
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
        CameraPosition(target: _location, zoom: 14.0),
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
      if (!mp.PolygonUtil.containsLocation(
          mp.LatLng(point.latitude, point.longitude), _projectArea, true)) {
        setState(() {
          _outsidePoint = true;
        });
      }

      _newData.lights.add(Light(
        point: point,
        lightType: _selectedType!,
      ));
      final markerId = MarkerId(point.toString());
      setState(() {
        // Create marker
        _markers.add(
          Marker(
            markerId: markerId,
            position: point,
            consumeTapEvents: true,
            onTap: () {
              // If the marker is tapped again, it will be removed
              _newData.lights.removeWhere((light) => light.point == point);
              setState(() {
                _markers.removeWhere((marker) => marker.markerId == markerId);
              });
            },
          ),
        );
      });

      if (_outsidePoint) {
        // TODO: fix delay. delay will overlap with consecutive taps. this means taps do not necessarily refresh the timer and will end prematurely
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _outsidePoint = false;
        });
      }
    } catch (e, stacktrace) {
      print('Error in lighting_profile_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
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
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: GoogleMap(
                        padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 14),
                        markers: _markers,
                        polygons: _polygons,
                        onTap: _isTypeSelected ? _togglePoint : null,
                        mapType: _currentMapType,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          bottom: _bottomSheetHeight + 30,
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
        bottomSheet: _isLoading
            ? SizedBox()
            : SizedBox(
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
                          Center(
                            child: Text(
                              !_isTypeSelected
                                  ? 'Select a type of light.'
                                  : 'Drop a pin where the light is.',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
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
                                  onPressed: (_isTypeSelected)
                                      ? null
                                      : () => _setLightType(LightType.rhythmic),
                                  child: Text('Rhythmic'),
                                ),
                              ),
                              Expanded(
                                flex: 6,
                                child: FilledButton(
                                  style: testButtonStyle,
                                  onPressed: (_isTypeSelected)
                                      ? null
                                      : () => _setLightType(LightType.building),
                                  child: Text('Building'),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: FilledButton(
                                  style: testButtonStyle,
                                  onPressed: (_isTypeSelected)
                                      ? null
                                      : () => _setLightType(LightType.task),
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
                                  onPressed: (_isTypeSelected)
                                      ? null
                                      : () {
                                          // TODO: check isComplete either before submitting or probably before starting test
                                          widget.activeTest
                                              .submitData(_newData);
                                          Navigator.pop(context);
                                        },
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
                    _outsidePoint
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 30.0, horizontal: 100.0),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red[900],
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'You have placed a point outside of the project area!',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red[50],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(),
                  ],
                ),
              ),
      ),
    );
  }
}