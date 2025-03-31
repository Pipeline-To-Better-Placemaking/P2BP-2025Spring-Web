import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'theme.dart';
import 'widgets.dart';
import 'google_maps_functions.dart';
import 'firestore_functions.dart';
import 'db_schema_classes.dart';
import 'people_in_place_instructions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

bool isPointInsidePolygon(LatLng point, Polygon polygon) {
  List<mp.LatLng> polygonPoints = polygon.points
      .map((p) => mp.LatLng(p.latitude, p.longitude))
      .toList();

  return mp.PolygonUtil.containsLocation(
      mp.LatLng(point.latitude, point.longitude), polygonPoints, false);
}

class PeopleInPlaceTestPage extends StatefulWidget {
  final Project activeProject;
  final PeopleInPlaceTest activeTest;

  const PeopleInPlaceTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<PeopleInPlaceTestPage> createState() => _PeopleInPlaceTestPageState();
}

class _PeopleInPlaceTestPageState extends State<PeopleInPlaceTestPage> {
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  bool _isLoading = true;
  Timer? _hintTimer;
  bool _showHint = false;
  bool _isTestRunning = false;
  int _remainingSeconds = 300;
  Timer? _timer;
  Set<Polygon> _polygons = {}; // Set of polygons
  MapType _currentMapType = MapType.normal; // Default map type
  bool _showErrorMessage = false;
  bool _isPointsMenuVisible = false;
  List<mp.LatLng> _projectArea = [];

  final Set<Marker> _markers = {}; // Set of markers for points
  final List<LatLng> _loggedPoints = [];

  final Set<Marker> _standingPointMarkers = {};

  final PeopleInPlaceData _newData = PeopleInPlaceData();

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Custom marker icons
  BitmapDescriptor? standingPointMarker;

  // Male Markers
  BitmapDescriptor? standingMaleMarker;
  BitmapDescriptor? sittingMaleMarker;
  BitmapDescriptor? layingMaleMarker;
  BitmapDescriptor? squattingMaleMarker;

  // Female Markers
  BitmapDescriptor? standingFemaleMarker;
  BitmapDescriptor? sittingFemaleMarker;
  BitmapDescriptor? layingFemaleMarker;
  BitmapDescriptor? squattingFemaleMarker;

  // N/A Markers
  BitmapDescriptor? standingNAMarker;
  BitmapDescriptor? sittingNAMarker;
  BitmapDescriptor? layingNAMarker;
  BitmapDescriptor? squattingNAMarker;
  bool _customMarkersLoaded = false;

  MarkerId? _openMarkerId;

  @override
  void initState() {
    super.initState();
    _initProjectArea();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _loadCustomMarkers();
      _showInstructionOverlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
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

  // Function to load custom marker icons using AssetMapBitmap.
  Future<void> _loadCustomMarkers() async {
    final ImageConfiguration configuration =
        createLocalImageConfiguration(context);
    try {
      standingPointMarker = await AssetMapBitmap.create(
        configuration,
        'assets/standing_point_disabled_marker.png',
        width: 36,
        height: 36,
      );
      standingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_male_marker.png',
        width: 36,
        height: 36,
      );
      sittingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_male_marker.png',
        width: 36,
        height: 36,
      );
      layingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_male_marker.png',
        width: 36,
        height: 36,
      );
      squattingMaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_male_marker.png',
        width: 36,
        height: 36,
      );
      standingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_female_marker.png',
        width: 36,
        height: 36,
      );
      sittingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_female_marker.png',
        width: 36,
        height: 36,
      );
      layingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_female_marker.png',
        width: 36,
        height: 36,
      );
      squattingFemaleMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_female_marker.png',
        width: 36,
        height: 36,
      );
      standingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/standing_na_marker.png',
        width: 36,
        height: 36,
      );
      sittingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/sitting_na_marker.png',
        width: 36,
        height: 36,
      );
      layingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/laying_na_marker.png',
        width: 36,
        height: 36,
      );
      squattingNAMarker = await AssetMapBitmap.create(
        configuration,
        'assets/custom_icons/test_specific/people_in_place/squatting_na_marker.png',
        width: 36,
        height: 36,
      );
      setState(() {
        _customMarkersLoaded = true;
        _buildStandingPointMarkers();
      });
    } catch (e, s) {
      print("Error loading custom markers: $e");
      print("Stacktrace: $s");
    }
  }

  void _buildStandingPointMarkers() {
    for (final point in widget.activeTest.standingPoints) {
      _standingPointMarkers.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point.location,
        icon: standingPointMarker!,
      ));
    }
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: MediaQuery.of(context).size.height * 0.005),
          actionsPadding: EdgeInsets.zero,
          title: Text(
            'How It Works:',
            style: TextStyle(
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  peopleInPlaceInstructions(),
                  SizedBox(height: 10),
                  buildLegends(),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (_) {},
                    ),
                    Text("Don't show this again next time"),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _resetHintTimer() {
    // Cancel any existing timer.
    _hintTimer?.cancel();
    // Hide the hint if it was showing.
    setState(() {
      _showHint = false;
    });
    // Start a new timer.
    _hintTimer = Timer(Duration(seconds: 10), () {
      setState(() {
        _showHint = true;
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      if (widget.activeProject.polygonPoints.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bounds = getLatLngBounds(
              widget.activeProject.polygonPoints.toLatLngList());
          if (bounds != null) {
            mapController
                .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          }
        });
      } else {
        _moveToCurrentLocation(); // Ensure the map is centered on the current location
      }
    });
  }

  void _moveToCurrentLocation() {
    mapController.animateCamera(
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

  BitmapDescriptor _getMarkerIcon(String key) {
    switch (key) {
      case 'standing_male':
        return standingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'sitting_male':
        return sittingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'layingDown_male':
        return layingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'squatting_male':
        return squattingMaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'standing_female':
        return standingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'sitting_female':
        return sittingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'layingDown_female':
        return layingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'squatting_female':
        return squattingFemaleMarker ?? BitmapDescriptor.defaultMarker;
      case 'standing_nonbinary' || 'standing_unspecified':
        return standingNAMarker ?? BitmapDescriptor.defaultMarker;
      case 'sitting_nonbinary' || 'sitting_unspecified':
        return sittingNAMarker ?? BitmapDescriptor.defaultMarker;
      case 'layingDown_nonbinary' || 'layingDown_unspecified':
        return layingNAMarker ?? BitmapDescriptor.defaultMarker;
      default:
        return squattingNAMarker ?? BitmapDescriptor.defaultMarker;
    }
  }

  // Tap handler for People In Place
  Future<void> _handleMapTap(LatLng point) async {
    _resetHintTimer();
    // If point is outside the project boundary, display error message
    if (!isPointInsidePolygon(point, _polygons.first)) {
      setState(() {
        _showErrorMessage = true;
      });
      Timer(Duration(seconds: 3), () {
        setState(() {
          _showErrorMessage = false;
        });
      });
    }
    // Check if custom markers are loaded
    if (!_customMarkersLoaded) {
      print("Custom markers not loaded yet. Please wait.");
      return; // Prevent creating markers if not loaded
    }
    // Show bottom sheet for classification
    final PersonInPlace? person = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      builder: (context) => _DescriptionForm(location: point),
    );
    if (person == null) return;

    final MarkerId markerId = MarkerId(point.toString());

    final key = '${person.posture.name}_${person.gender.name}';
    BitmapDescriptor markerIcon = _getMarkerIcon(key);

    // Add this data point to set of visible markers and other data lists.
    setState(() {
      _markers.add(
        Marker(
          markerId: markerId,
          position: point,
          icon: markerIcon,
          infoWindow: InfoWindow(
              title: 'Age: ${person.ageRange.displayName}', // for example
              snippet: 'Gender: ${person.gender.displayName}\n'
                  'Activities: ${[
                for (final activity in person.activities) activity.displayName
              ]}\n'
                  'Posture: ${person.posture.displayName}'),
          onTap: () {
            // Use a short delay to ensure the marker is rendered,
            // then show its info window using the same markerId.
            if (_openMarkerId == markerId) {
              mapController.hideMarkerInfoWindow(markerId);
              setState(() {
                _openMarkerId = null;
              });
            } else {
              Future.delayed(Duration(milliseconds: 300), () {
                mapController.showMarkerInfoWindow(markerId);
                setState(() {
                  _openMarkerId = markerId;
                });
              });
            }
          },
        ),
      );

      _loggedPoints.add(person.location);
      _newData.persons.add(person);
    });
  }

  // Method to start the test and timer
  void _startTest() {
    setState(() {
      _isTestRunning = true;
      _remainingSeconds = 300;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds <= 0) {
          timer.cancel();
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  void _endTest() {
    _isTestRunning = false;
    _timer?.cancel();
    _hintTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          systemOverlayStyle:
              SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 100,
          // Start/End button on the left
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20), // Rounded rectangle shape.
                ),
                backgroundColor: _isTestRunning ? Colors.red : Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                if (_isTestRunning) {
                  _endTest();
                } else {
                  _startTest();
                }
              },
              child: Text(
                _isTestRunning ? 'End' : 'Start',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          // Persistent prompt in the middle with a translucent background.
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tap to log data point',
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          centerTitle: true,
          // Timer on the right
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatTime(_remainingSeconds),
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _location,
                zoom: 14.0,
              ),
              markers: {..._standingPointMarkers, ..._markers},
              polygons: _polygons,
              onTap: _handleMapTap,
              mapType: _currentMapType,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
            if (_showErrorMessage) OutsideBoundsWarning(),
            // Buttons in top right corner of map below timer.
            // Button for toggling map type.
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 8.0,
              right: 20.0,
              child: CircularIconMapButton(
                backgroundColor: const Color(0xFF7EAD80).withValues(alpha: 0.9),
                borderColor: Color(0xFF2D6040),
                onPressed: _toggleMapType,
                icon: Center(
                  child: Icon(Icons.layers, color: Color(0xFF2D6040)),
                ),
              ),
            ),
            // Button for toggling instructions.
            if (!_isLoading)
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 70.0,
                right: 20,
                child: CircularIconMapButton(
                  backgroundColor: Color(0xFFBACFEB).withValues(alpha: 0.9),
                  borderColor: Color(0xFF37597D),
                  onPressed: _showInstructionOverlay,
                  icon: Center(
                    child: Icon(
                      FontAwesomeIcons.info,
                      color: Color(0xFF37597D),
                    ),
                  ),
                ),
              ),
            // Button for toggling points menu.
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 132.0,
              right: 20.0,
              child: CircularIconMapButton(
                backgroundColor: Color(0xFFBD9FE4).withValues(alpha: 0.9),
                borderColor: Color(0xFF5A3E85),
                onPressed: () {
                  setState(() {
                    _isPointsMenuVisible = !_isPointsMenuVisible;
                  });
                },
                icon: Icon(
                  FontAwesomeIcons.locationDot,
                  color: Color(0xFF5A3E85),
                ),
              ),
            ),
            if (_isPointsMenuVisible)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: DataEditMenu(
                    title: 'Marker Color Guide',
                    colorLegendItems: [
                      for (final type in PostureType.values)
                        ColorLegendItem(
                          label: type.displayName,
                          color: type.color,
                        ),
                    ],
                    placedDataList: _buildPlacedPointList(),
                    onPressedCloseMenu: () => setState(
                        () => _isPointsMenuVisible = !_isPointsMenuVisible),
                    onPressedClearAll: () {
                      setState(() {
                        // Clear all logged points.
                        _loggedPoints.clear();
                        _newData.persons.clear();
                        // Remove all associated markers.
                        _markers.clear();
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ListView _buildPlacedPointList() {
    Map<PostureType, int> typeCounter = {};
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _newData.persons.length,
      itemBuilder: (context, index) {
        final person = _newData.persons[index];
        // Increment this type's count
        typeCounter.update(person.posture, (i) => i + 1, ifAbsent: () => 1);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(
            '${person.posture.displayName} Person ${typeCounter[person.posture]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${person.location.latitude.toStringAsFixed(4)}, '
            '${person.location.longitude.toStringAsFixed(4)}',
            textAlign: TextAlign.left,
          ),
          trailing: IconButton(
            icon:
                const Icon(FontAwesomeIcons.trashCan, color: Color(0xFFD32F2F)),
            onPressed: () {
              setState(() {
                // Construct the markerId the same way it was created.
                final markerId = MarkerId(person.location.toString());
                // Remove the marker from the markers set.
                _markers.removeWhere((marker) => marker.markerId == markerId);
                // Remove the point from data.
                _newData.persons.removeAt(index);
                // Remove the point from the list.
                _loggedPoints.removeWhere((point) => point == person.location);
              });
            },
          ),
        );
      },
    );
  }
}

class _DescriptionForm extends StatefulWidget {
  final LatLng location;

  const _DescriptionForm({required this.location});

  @override
  State<_DescriptionForm> createState() => _DescriptionFormState();
}

class _DescriptionFormState extends State<_DescriptionForm> {
  static const TextStyle boldTextStyle = TextStyle(fontWeight: FontWeight.bold);

  int? _selectedAgeRange;
  int? _selectedGender;
  final List<bool> _selectedActivities = List.of(
      [for (final _ in ActivityTypeInPlace.values) false],
      growable: false);
  int? _selectedPosture;

  void _submitDescription() {
    final PersonInPlace person;

    // Converts activity bool list to type set
    List<ActivityTypeInPlace> types = ActivityTypeInPlace.values;
    Set<ActivityTypeInPlace> activities = {};
    for (int i = 0; i < types.length; i += 1) {
      if (_selectedActivities[i]) {
        activities.add(types[i]);
      }
    }

    person = PersonInPlace(
      location: widget.location,
      ageRange: AgeRangeType.values[_selectedAgeRange!],
      gender: GenderType.values[_selectedGender!],
      activities: activities,
      posture: PostureType.values[_selectedPosture!],
    );

    Navigator.pop(context, person);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Theme(
        data: theme.copyWith(
          chipTheme: theme.chipTheme.copyWith(
            showCheckmark: false,
            backgroundColor: Colors.grey[200],
            selectedColor: Colors.blue,
            labelStyle: TextStyle(
              color: ChipLabelColor(),
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Centered header text.
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Data',
                        style: boldTextStyle.copyWith(fontSize: 24),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age group.
                  Text(
                    'Age',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(
                      AgeRangeType.values.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(AgeRangeType.values[index].displayName),
                          selected: _selectedAgeRange == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedAgeRange = selected ? index : null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Gender group.
                  Text(
                    'Gender',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(
                      GenderType.values.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(GenderType.values[index].displayName),
                          selected: _selectedGender == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedGender = selected ? index : null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Activity group.
                  Text(
                    'Activities',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(
                      ActivityTypeInPlace.values.length,
                      (index) {
                        return FilterChip(
                          label: Text(
                              ActivityTypeInPlace.values[index].displayName),
                          selected: _selectedActivities[index],
                          onSelected: (selected) {
                            setState(() {
                              _selectedActivities[index] =
                                  !_selectedActivities[index];
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Posture group.
                  Text(
                    'Posture',
                    style: boldTextStyle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: List<Widget>.generate(
                      PostureType.values.length,
                      (index) {
                        return ChoiceChip(
                          label: Text(PostureType.values[index].displayName),
                          selected: _selectedPosture == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPosture = selected ? index : null;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_selectedAgeRange != null &&
                        _selectedGender != null &&
                        _selectedActivities.contains(true) &&
                        _selectedPosture != null)
                    ? _submitDescription
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}