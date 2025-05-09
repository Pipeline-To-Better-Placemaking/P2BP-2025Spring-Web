import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart';
import 'widgets.dart';
import 'project_details_page.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';
import 'google_maps_functions.dart';
import 'package:file_selector/file_selector.dart';

//import 'homepage.dart';

class SectionCutter extends StatefulWidget {
  final Project activeProject;
  final SectionCutterTest activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const SectionCutter({super.key, required this.activeTest, required this.activeProject});

  @override
  State<SectionCutter> createState() => _SectionCutterState();
}

const XTypeGroup acceptedFileTypes = XTypeGroup(
  label: 'section cutter uploads',
  extensions: <String>['jpg', 'png', 'pdf'],
);

class _SectionCutterState extends State<SectionCutter> {
  bool _isLoadingUpload = false;
  bool _uploaded = false;
  bool _isLoading = false;
  bool _failedToUpload = false;
  String _errorText = 'Failed to upload new image.';
  String _directions =
      "Go to designated section. Then upload the section drawing here.";
  XFile? sectionCutterFile;
  final double _bottomSheetHeight = 300;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  SectionCutterTest? currentTest;
  final Set<Polygon> _polygons = {}; // Set of polygons
  Set<Polyline> _polyline = {};
  List<LatLng> _sectionPoints = [];
  MapType _currentMapType = MapType.satellite; 

  Project? project;

  double _zoom = 14;

  @override
  void initState() {
    super.initState();
    initProjectArea();
  }

  /// Gets the project polygon, adds it to the current polygon list, and
  /// centers the map over it.
  void initProjectArea() {
    setState(() {
      _polygons.add(getProjectPolygon(widget.activeProject.polygonPoints));
      _location = getPolygonCentroid(_polygons.first);
      // Take some lattitude away to center considering bottom sheet.
      _location = LatLng(_location.latitude * .999999, _location.longitude);
      // TODO: dynamic zooming
      _sectionPoints = widget.activeTest!.linePoints.toLatLngList();
      _polyline = {
        Polyline(
          polylineId:
              PolylineId(DateTime.now().millisecondsSinceEpoch.toString()),
          points: _sectionPoints,
          color: Colors.green,
          width: 4,
        )
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToLocation(); // Ensure the map is centered on the current location
  }

  void _moveToLocation() {
    mapController.animateCamera(
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

  // This function triggers the dialog for file upload
  void _showFileUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Upload Section Cutter Drawing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _isLoadingUpload
                      ? CircularProgressIndicator()
                      : _uploaded
                          ? Icon(Icons.check, color: Colors.green)
                          : ElevatedButton.icon(
                              onPressed: () async {
                                sectionCutterFile = await openFile(
                                  acceptedTypeGroups: <XTypeGroup>[
                                    acceptedFileTypes
                                  ],
                                );
                                setState(() {
                                  _isLoadingUpload = true;
                                });
                                if (sectionCutterFile != null) {
                                  setState(() {
                                    _failedToUpload = false;
                                    _uploaded = true;
                                    _directions = "Click finish to finish test.";
                                  });
                                } else {
                                  setState(() {
                                    _failedToUpload = true;
                                    _errorText = 'Failed to upload new image.';
                                  });
                                  print("No file selected");
                                }
                                setState(() {
                                  _isLoadingUpload = false;
                                });
                              },
                              label: Text(
                                'Upload File',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              icon: _uploaded
                                  ? Icon(Icons.check)
                                  : Icon(Icons.upload_file),
                              iconAlignment: IconAlignment.end,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 20),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                  SizedBox(height: 20),
                  _failedToUpload
                      ? Text(
                          _errorText,
                          style: TextStyle(color: Colors.red),
                        )
                      : SizedBox(),
                  SizedBox(height: 20),
                  Text('Accepted formats: .png, .pdf, .jpg'),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Finish'),
                  onPressed: _isLoadingUpload
                      ? null
                      : () async {
                          if (sectionCutterFile == null) {
                            setState(() {
                              _failedToUpload = true;
                              _errorText =
                                  'No file uploaded. Please upload an image first.';
                            });
                            return;
                          }
                          setState(() {
                            _isLoadingUpload = true;
                          });
                          
                          Section data = await widget
                              .activeTest!
                              .saveXFile(sectionCutterFile!);
                          widget.activeTest!.submitData(data);

                          if (!context.mounted) return;

                          Navigator.pop(context);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailsPage(
                                activeProject: widget.activeProject,
                              ),
                            ),
                          );
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: _isLoadingUpload
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: GoogleMap(
                        padding: EdgeInsets.only(bottom: 50),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition:
                            CameraPosition(target: _location, zoom: 14),
                        polygons: _polygons,
                        polylines: _polyline,
                        mapType: _currentMapType,
                      ),
                    ),
                    // Back Button (conditionally colorized in 2D mode)
                    Positioned(
                      top: 20, // Position at the top left
                      left: 10, // Adjust the distance from the left
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back, 
                          color: _currentMapType == MapType.normal 
                              ? Colors.black // Back button black in 2D mode
                              : Colors.white, // Default color in other modes
                          size: 48, // Bigger size
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Go back to the previous screen
                        },
                      ),
                    ),
                    // Changing Map Type button
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 120, left: 10),
                        child: FloatingActionButton(
                          heroTag: null,
                          onPressed: _toggleMapType,
                          backgroundColor: Colors.green,
                          child: const Icon(Icons.map),
                        ),
                      ),
                    ),
                    // Directions for user
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
                                color: Color(0x1A000000),
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
                    // File Upload Button
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 50, left: 10),
                        child: FloatingActionButton(
                          onPressed: () => _showFileUploadDialog(context),
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.upload_file),
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
