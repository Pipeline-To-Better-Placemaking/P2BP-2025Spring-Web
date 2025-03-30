import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'firestore_functions.dart';
import 'theme.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
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
  bool _isLoading = true;
  bool _polygonMode = false;
  bool _polylineMode = false;
  bool _outsidePoint = false;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite; // Default map type
  List<mp.LatLng> _projectArea = [];

  Set<Polygon> _polygons = {}; // Set of polygons
  List<LatLng> _polygonPoints = []; // Points for the polygon
  Set<Marker> _polygonMarkers = {}; // Set of markers for polygon creation
  Set<Polyline> _polylines = {};
  Set<Marker> _polylineMarkers = {};
  List<LatLng> _polylinePoints = [];

  final SpatialBoundariesData _newData = SpatialBoundariesData();
  BoundaryType? _boundaryType;
  ConstructedBoundaryType? _constructedType;
  MaterialBoundaryType? _materialType;
  ShelterBoundaryType? _shelterType;

  static const List<String> _directionsList = [
    'Select a type of boundary.',
    'Outline the shape of the boundary with points, then click confirm shape when you are done.',
  ];
  late String _directionsActive;
  static const double _bottomSheetHeight = 320;

  @override
  void initState() {
    super.initState();
    _initProjectArea();
    _directionsActive = _directionsList[0];
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

  /// Moves camera to project location.
  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: 17.0),
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
  Future<void> _togglePoint(LatLng point) async {
    try {
      if (!mp.PolygonUtil.containsLocation(
          mp.LatLng(point.latitude, point.longitude), _projectArea, true)) {
        setState(() {
          _outsidePoint = true;
        });
      }
      if (_polygonMode) _polygonTap(point);
      if (_polylineMode) _polylineTap(point);
      if (_outsidePoint) {
        // TODO: fix delay. delay will overlap with consecutive taps. this means taps do not necessarily refresh the timer and will end prematurely
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _outsidePoint = false;
        });
      }
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
          consumeTapEvents: true,
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

  /// Convert markers to polygon and save the data to be submitted later.
  void _finalizePolygon() {
    Set<Polygon> tempPolygon;
    try {
      // Create polygon and add it to the visible set of polygons.
      tempPolygon = finalizePolygon(_polygonPoints);
      _polygons.add(tempPolygon.first);

      if (_boundaryType == BoundaryType.material && _materialType != null) {
        _newData.material.add(MaterialBoundary(
          polygon: tempPolygon.first,
          materialType: _materialType!,
        ));
      } else if (_boundaryType == BoundaryType.shelter &&
          _shelterType != null) {
        _newData.shelter.add(ShelterBoundary(
          polygon: tempPolygon.first,
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
    Polyline? tempPolyline;
    try {
      // Create polyline and add it to the visible set of polylines.
      tempPolyline = createPolyline(
        _polylinePoints,
        ConstructedBoundary.polylineColor,
      );
      if (tempPolyline == null) {
        throw Exception('Failed to create Polyline from given points.');
      }
      _polylines.add(tempPolyline);

      if (_boundaryType == BoundaryType.constructed &&
          _constructedType != null) {
        _newData.constructed.add(ConstructedBoundary(
          polyline: tempPolyline,
          constructedType: _constructedType!,
        ));
      } else {
        throw Exception('Invalid boundary type in _finalizePolyline(),'
            '_boundaryType = $_boundaryType');
      }

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                            CameraPosition(target: _location, zoom: 15),
                        markers: {..._polygonMarkers, ..._polylineMarkers},
                        polygons: _polygons,
                        polylines: _polylines,
                        onTap: _togglePoint,
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
                        children: <Widget>[
                          Center(
                            child: Text(
                              'Spatial Boundaries',
                              softWrap: true,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: placeYellow,
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Center(
                            child: Text(
                              _directionsActive,
                              softWrap: true,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
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
                                  onPressed: (_polygonMode || _polylineMode)
                                      ? null
                                      : () {
                                          _doConstructedModal(context);
                                        },
                                  child: Text('Constructed'),
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: FilledButton(
                                  style: testButtonStyle,
                                  onPressed: (_polygonMode || _polylineMode)
                                      ? null
                                      : () {
                                          _doMaterialModal(context);
                                        },
                                  child: Text('Material'),
                                ),
                              ),
                              Expanded(
                                flex: 7,
                                child: FilledButton(
                                  style: testButtonStyle,
                                  onPressed: (_polygonMode || _polylineMode)
                                      ? null
                                      : () {
                                          _doShelterModal(context);
                                        },
                                  child: Text('Shelter'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
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
                                  icon: const Icon(Icons.check),
                                  iconColor: Colors.green,
                                  onPressed: (_polygonMode &&
                                          _polygonPoints.length >= 3)
                                      ? _finalizePolygon
                                      : (_polylineMode &&
                                              _polylinePoints.length >= 2)
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
                                  onPressed: (_polygonMode || _polylineMode)
                                      ? null
                                      : () {
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
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const BarIndicator(),
                Center(
                  child: Text(
                    'Boundary Description',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select the best description for the boundary you marked.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
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
                  child: Divider(),
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
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const BarIndicator(),
                Center(
                  child: Text(
                    'Boundary Description',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select the best description for the boundary you marked.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
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
                  child: Divider(),
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
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const BarIndicator(),
                Center(
                  child: Text(
                    'Boundary Description',
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Center(
                    child: Text(
                      'Select the best description for the boundary you marked.',
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
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
                  child: Divider(),
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
      ),
    );
  }
}