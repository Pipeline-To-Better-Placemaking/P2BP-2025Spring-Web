import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'themes.dart';
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

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class _LightingProfileTestPageState extends State<LightingProfileTestPage> {
  bool _isLoading = true;
  bool _isTypeSelected = false;
  LightType? _selectedType;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  Set<Marker> _markers = {}; // Set of markers visible on map
  Set<Polygon> _polygons = {}; // Set of polygons

  LightToLatLngMap _allPointsMap = {
    LightType.rhythmic: {},
    LightType.building: {},
    LightType.task: {},
  };

  ButtonStyle _testButtonStyle = FilledButton.styleFrom();
  static const double _bottomSheetHeight = 250;

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
      print(_polygons);
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
        CameraPosition(target: _location, zoom: 14.0),
      ),
    );
  }

  /// Adds a `Marker` to the map and stores that same point in
  /// `_allPointsMap` to be submitted as test data later.
  ///
  /// This also resets the fields for selecting type so another can be
  /// selected after this point is placed.
  void _togglePoint(LatLng point) {
    _allPointsMap[_selectedType]?.add(point);
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
            _allPointsMap.updateAll((key, value) {
              value.remove(point);
              return value;
            });
            setState(() {
              _markers.removeWhere((marker) => marker.markerId == markerId);
            });
            print(_allPointsMap); // debug
          },
        ),
      );

      // Reset selected light type
      _setLightType(null);
    });

    print(_allPointsMap); // debug
  }

  /// Sets [_selectedType] to parameter `type` and [_isTypeSelected] to
  /// true if [type] is non-null and false otherwise.
  void _setLightType(LightType? type) {
    setState(() {
      _selectedType = type;
      _isTypeSelected = _selectedType != null;
    });
  }

  /// Toggles map type between satellite and normal
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Sets button style on each build based on width of context
  void _setButtonStyle() {
    _testButtonStyle = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      disabledBackgroundColor: Color(0xCD6C6C6C),
      iconColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: TextStyle(fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setButtonStyle();
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
                    Text(
                      'Light Types',
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
                          child: FilledButton(
                            style: _testButtonStyle,
                            onPressed: (_isTypeSelected)
                                ? null
                                : () => _setLightType(LightType.rhythmic),
                            child: Text('Rhythmic'),
                          ),
                        ),
                        Flexible(
                          child: FilledButton(
                            style: _testButtonStyle,
                            onPressed: (_isTypeSelected)
                                ? null
                                : () => _setLightType(LightType.building),
                            child: Text('Building'),
                          ),
                        ),
                        Flexible(
                          child: FilledButton(
                            style: _testButtonStyle,
                            onPressed: (_isTypeSelected)
                                ? null
                                : () => _setLightType(LightType.task),
                            child: Text('Task'),
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
                            style: _testButtonStyle,
                            onPressed: () => Navigator.pop(context),
                            label: Text('Back'),
                            icon: Icon(Icons.chevron_left),
                            iconAlignment: IconAlignment.start,
                          ),
                        ),
                        Flexible(
                          child: FilledButton.icon(
                            style: _testButtonStyle,
                            onPressed: () {
                              // TODO: check isComplete either before submitting or probably before starting test
                              widget.activeTest.submitData(_allPointsMap);
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
      ),
    );
  }
}