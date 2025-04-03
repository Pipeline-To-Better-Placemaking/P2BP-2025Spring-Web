import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/firestore_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'google_maps_functions.dart';

Future<Uint8List> generateMapImage({
  Set<Polygon> polygons = const {},
  Set<Polyline> polylines = const {},
  Set<Marker> markers = const {},
  Set<Circle> circles = const {},
  required Polygon projectPolygon,
}) async {
  late GoogleMapController mapController;
  late Uint8List mapSnapshot;
  ScreenshotController screenshotController = ScreenshotController();
  LatLng location = getPolygonCentroid(projectPolygon);
  double zoom =
      getIdealZoom(projectPolygon.toMPLatLngList(), location.toMPLatLng());
  zoom--;

  // TODO: Figure out how to build this to trigger the snapshot

  GoogleMap(
    onMapCreated: (GoogleMapController controller) async {
      print("Map has been created");
      mapController = controller;
      try {
        mapSnapshot = (await mapController.takeSnapshot())!;
        print("Done!");
        print(mapSnapshot);
      } catch (e, stacktrace) {
        print(e);
        print("Stacktrace: $stacktrace");
      }
    },
    initialCameraPosition: CameraPosition(
      target: location,
      zoom: zoom,
    ),
    polygons: {...polygons, projectPolygon},
    polylines: polylines,
    markers: markers,
    circles: circles,
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
  );

  return mapSnapshot;
}