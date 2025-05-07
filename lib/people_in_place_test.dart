import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';
import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/people_in_place_test_class.dart';
import 'people_in_place_instructions.dart';
import 'theme.dart';
import 'widgets.dart';

import 'assets.dart';
import 'google_maps_functions.dart';

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
  bool _isTestRunning = false;
  bool _outsidePoint = false;
  bool _isPointsMenuVisible = false;
  bool _directionsVisible = true;

  double _zoom = 18;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  MapType _currentMapType = MapType.satellite;

  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  final List<LatLng> _loggedPoints = [];
  final Set<Marker> _standingPointMarkers = {};

  final PeopleInPlaceData _newData = PeopleInPlaceData.empty();

  int _remainingSeconds = -1;
  Timer? _timer;
  Timer? _outsidePointTimer;

  MarkerId? _openMarkerId;

  @override
  void initState() {
    super.initState();
    _polygons.add(widget.activeProject.polygon.clone());
    _location = getPolygonCentroid(_polygons.first);
    _zoom = getIdealZoom(
      _polygons.first.toMPLatLngList(),
      _location.toMPLatLng(),
    );
    _remainingSeconds = widget.activeTest.testDuration;
    for (final point in widget.activeTest.standingPoints) {
      _standingPointMarkers.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point.location,
        icon: standingPointDisabledIcon,
        consumeTapEvents: true,
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("PostFrameCallback fired");
      _showInstructionOverlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    super.dispose();
  }

  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
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
              width: double.maxFinite,
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
                    Navigator.pop(context);
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

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _moveToCurrentLocation();
  }

  /// Moves camera to project location.
  void _moveToCurrentLocation() {
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

  Future<void> _handleMapTap(LatLng point) async {
    // If point is outside the project boundary, display error message
    if (!isPointInsidePolygon(point, _polygons.first)) {
      setState(() {
        _outsidePoint = true;
      });
    }

    // Show bottom sheet for classification
    final PersonInPlace? person = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFFDDE6F2),
      builder: (context) => _DescriptionForm(location: point),
    );
    if (person == null) {
      _outsidePointTimer?.cancel();
      _outsidePointTimer = Timer(Duration(seconds: 3), () {
        setState(() {
          _outsidePoint = false;
        });
      });
      return;
    }

    final MarkerId markerId = MarkerId(point.toString());

    // Add this data point to set of visible markers and other data lists.
    setState(() {
      _markers.add(person.marker.copyWith(
        infoWindowParam: InfoWindow(
            title: 'Age: ${person.ageRange.displayName}',
            snippet: 'Gender: ${person.gender.displayName}\n'
                'Activities: ${[
              for (final activity in person.activities) activity.displayName
            ]}\n'
                'Posture: ${person.posture.displayName}'),
        onTapParam: () {
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
      ));

      _loggedPoints.add(person.marker.position);
      _newData.persons.add(person);
    });

    if (_outsidePoint) {
      _outsidePointTimer?.cancel();
      _outsidePointTimer = Timer(Duration(seconds: 3), () {
        setState(() {
          _outsidePoint = false;
        });
      });
    }
  }

  void _startTest() {
    setState(() {
      _isTestRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isTestRunning = false;
          timer.cancel();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return TimerEndDialog(onSubmit: () {
                Navigator.pop(context);
                _endTest();
              }, onBack: () {
                setState(() {
                  _remainingSeconds = widget.activeTest.testDuration;
                });
                Navigator.pop(context);
              });
            },
          );
        }
      });
    });
  }

  void _endTest() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (_currentMapType == MapType.normal)
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _location,
                  zoom: _zoom,
                ),
                markers: {..._standingPointMarkers, ..._markers},
                polygons: _polygons,
                onTap: (_isTestRunning) ? _handleMapTap : null,
                mapType: _currentMapType,
                myLocationButtonEnabled: false,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TimerButtonAndDisplay(
                      onPressed: () {
                        setState(() {
                          if (_isTestRunning) {
                            setState(() {
                              _isTestRunning = false;
                              _timer?.cancel();
                            });
                          } else {
                            _startTest();
                          }
                        });
                      },
                      isTestRunning: _isTestRunning,
                      remainingSeconds: _remainingSeconds,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _directionsVisible
                          ? DirectionsText(
                              onTap: () {
                                setState(() {
                                  _directionsVisible = !_directionsVisible;
                                });
                              },
                              text: 'Tap to log data point.',
                            )
                          : SizedBox(),
                    ),
                    SizedBox(width: 15),
                    Column(
                      spacing: 10,
                      children: <Widget>[
                        DirectionsButton(
                          onTap: () {
                            setState(() {
                              _directionsVisible = !_directionsVisible;
                            });
                          },
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              const Color(0xFF7EAD80).withValues(alpha: 0.9),
                          borderColor: Color(0xFF2D6040),
                          onPressed: _toggleMapType,
                          icon: Center(
                            child: Icon(Icons.layers, color: Color(0xFF2D6040)),
                          ),
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFBACFEB).withValues(alpha: 0.9),
                          borderColor: Color(0xFF37597D),
                          onPressed: _showInstructionOverlay,
                          icon: Center(
                            child: Icon(
                              FontAwesomeIcons.info,
                              color: Color(0xFF37597D),
                            ),
                          ),
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFBD9FE4).withValues(alpha: 0.9),
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
                      ],
                    )
                  ],
                ),
              ),
            ),
            if (_outsidePoint)
              TestErrorText(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 150),
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
            '${person.marker.position.latitude.toStringAsFixed(4)}, '
            '${person.marker.position.longitude.toStringAsFixed(4)}',
            textAlign: TextAlign.left,
          ),
          trailing: IconButton(
            icon:
                const Icon(FontAwesomeIcons.trashCan, color: Color(0xFFD32F2F)),
            onPressed: () {
              setState(() {
                // Construct the markerId the same way it was created.
                final markerId = MarkerId(person.marker.position.toString());
                // Remove the marker from the markers set.
                _markers.removeWhere((marker) => marker.markerId == markerId);
                // Remove the point from data.
                _newData.persons.removeAt(index);
                // Remove the point from the list.
                _loggedPoints
                    .removeWhere((point) => point == person.marker.position);
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
  final List<bool> _selectedActivities = List.generate(
      ActivityTypeInPlace.values.length, (index) => false,
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

    person = PersonInPlace.fromLatLng(
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
