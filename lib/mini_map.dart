import 'package:flutter/material.dart';
import 'db_schema_classes.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firestore_functions.dart';
import 'google_maps_functions.dart';

class MiniMap extends StatefulWidget {
  final Project activeProject;
  const MiniMap({super.key, required this.activeProject});

  @override
  State<MiniMap> createState() => _MiniMapState();
}

/// Mini Map view for ProjectDetailsPage that shows users a preview of the
/// project's polygon representing the project area. Has potential to be
/// converted into an expandable map screen that allows the user to view
/// past test results via a visibility toggle per test type. Future teams
/// could probably implement this if we don't get around to it.
class _MiniMapState extends State<MiniMap> {
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  final LatLng _currentLocation = defaultLocation;
  double _zoom = 18;
  final Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
    _location = getPolygonCentroid(_polygons.first);
    _zoom =
        getIdealZoom(_polygons.first.toMPLatLngList(), _location.toMPLatLng());
    _zoom--;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation();
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Static map container
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: _zoom,
              ),
              polygons: _polygons,
              liteModeEnabled: true,
              myLocationButtonEnabled: false,

              // Disable gestures to mimic a static image.
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            // Dimmed Overlay
            child: Container(
              width: double.infinity,
              height: 200,
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}