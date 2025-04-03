import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/firestore_functions.dart';
import 'package:flutter/services.dart';
import 'package:p2b/pdf_output.dart';
import 'db_schema_classes.dart';
import 'google_maps_functions.dart';
import 'package:screenshot/screenshot.dart';

class PdfProcessingPage extends StatefulWidget {
  final Project activeProject;
  const PdfProcessingPage({super.key, required this.activeProject});

  @override
  State<PdfProcessingPage> createState() => _PdfProcessingPageState();
}

class _PdfProcessingPageState extends State<PdfProcessingPage> {
  late GoogleMapController mapController;
  List<ScreenshotController> screenshotController = [];
  LatLng _location = defaultLocation;
  double _zoom = 18;
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  List<Test> tests = [];
  List<Uint8List> _mapImages = [];
  late final Polygon _projectPolygon;

  @override
  void initState() {
    _initMaps();
    _projectPolygon = getProjectPolygon(widget.activeProject.polygonPoints);
    _location = getPolygonCentroid(_projectPolygon);
    _zoom =
        getIdealZoom(_projectPolygon.toMPLatLngList(), _location.toMPLatLng());
    _zoom--;
    super.initState();
  }

  /// Moves camera to project location.
  void _moveToLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _location, zoom: _zoom),
      ),
    );
  }

  Future<void> _initMaps() async {
    tests = await loadProject();
    setState(() {});
  }

  Future<List<Test>> loadProject() async {
    return (await widget.activeProject.loadAllTestData()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 350,
          width: 350,
          child: ListView.builder(
            itemCount: tests.length,
            itemBuilder: (BuildContext context, int index) {
              screenshotController.add(ScreenshotController());
              return Screenshot(
                controller: screenshotController[index],
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: GoogleMap(
                    onMapCreated: (controller) async {
                      mapController = controller;
                      _mapImages.add((await screenshotController[index]
                          .capture(delay: Duration(seconds: 1)))!);
                      _moveToLocation();
                      print("$index vs ${tests.length - 1}");
                      if (index == tests.length - 1 && context.mounted) {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfReportPage(
                                activeProject: widget.activeProject),
                          ),
                        );
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _location,
                      zoom: _zoom,
                    ),
                    polygons: {_projectPolygon},

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
            },
          ),
        ),
      ],
    );
  }
}
