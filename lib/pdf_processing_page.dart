import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/firestore_functions.dart';
import 'package:flutter/services.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';

class PdfProcessingPage extends StatefulWidget {
  final Project activeProject;
  const PdfProcessingPage({super.key, required this.activeProject});

  @override
  State<PdfProcessingPage> createState() => _PdfProcessingPageState();
}

class _PdfProcessingPageState extends State<PdfProcessingPage> {
  List<IndividualGoogleMap> mapWidgets = [];

  @override
  void initState() {
    _initMaps();
    super.initState();
  }

  Future<void> _initMaps() async {
    mapWidgets = await getAllMapsWidgets();
  }

  Future<List<IndividualGoogleMap>> getAllMapsWidgets() async {
    List<IndividualGoogleMap> mapsWidgets = [];
    List<Test> tests = [];
    if (widget.activeProject.tests == null) {
      await widget.activeProject.loadAllTestData();
    }
    tests = widget.activeProject.tests ?? [];
    for (Test test in tests) {
      mapsWidgets.add(IndividualGoogleMap(
        projectPolygon: getProjectPolygon(widget.activeProject.polygonPoints),
      ));
    }
    return mapsWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: mapWidgets,
    );
  }
}

class IndividualGoogleMap extends StatefulWidget {
  final Polygon projectPolygon;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final Set<Circle> circles;

  const IndividualGoogleMap({
    super.key,
    required this.projectPolygon,
    this.polygons = const {},
    this.polylines = const {},
    this.markers = const {},
    this.circles = const {},
  });

  @override
  State<IndividualGoogleMap> createState() => _IndividualGoogleMapState();
}

class _IndividualGoogleMapState extends State<IndividualGoogleMap> {
  late GoogleMapController mapController;
  late final Uint8List _mapSnapshot;
  LatLng _location = defaultLocation;
  double _zoom = 18;
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _polygons = widget.polygons;
    _polylines = widget.polylines;
    _markers = widget.markers;
    _circles = widget.circles;
    _location = getPolygonCentroid(_polygons.first);
    _zoom =
        getIdealZoom(_polygons.first.toMPLatLngList(), _location.toMPLatLng());
    _zoom--;
  }

  Future<Uint8List> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    _moveToLocation();
    try {
      return _mapSnapshot = (await controller.takeSnapshot())!;
    } catch (e, stacktrace) {
      print(e);
      print("Stacktrace: $stacktrace");
      throw Exception();
    }
  }

  /// Moves camera to project location.
  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: 300,
        height: 300,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _location,
            zoom: _zoom,
          ),
          polygons: {..._polygons, widget.projectPolygon},
          polylines: _polylines,
          markers: _markers,
          circles: _circles,
          liteModeEnabled: true,

          // Disable gestures and buttons to mimic a static image.
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          myLocationButtonEnabled: false,
          zoomGesturesEnabled: false,
          scrollGesturesEnabled: false,
          padding: EdgeInsets.all(100),
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
      ),
    );
  }
}
