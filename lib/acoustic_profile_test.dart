import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';
import 'acoustic_instructions.dart';
import 'assets.dart';
import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/acoustic_profile_test_class.dart';
import 'db_schema_classes/standing_point_class.dart';
import 'google_maps_functions.dart';
import 'theme.dart';
import 'widgets.dart';

/// AcousticProfileTestPage displays a Google Map (with the project polygon)
/// in the background and uses a timer to prompt the researcher for sound
/// measurements at fixed intervals.
class AcousticProfileTestPage extends StatefulWidget {
  final Project activeProject;
  final AcousticProfileTest activeTest;

  const AcousticProfileTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<AcousticProfileTestPage> createState() =>
      _AcousticProfileTestPageState();
}

class _AcousticProfileTestPageState extends State<AcousticProfileTestPage> {
  bool _isIntervalCycleRunning = false;
  bool _isErrorTextShown = false;
  bool _isTestComplete = false;
  bool _directionsVisible = true;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  double _zoom = 18;
  MapType _currentMapType = MapType.satellite;

  final Set<Polygon> _polygons = {};
  final Set<Circle> _circles = <Circle>{};
  Set<Marker> _markers = {};
  late final List<StandingPoint> _standingPoints;

  Timer? _timer;
  int _intervalDuration = -1;
  int _intervalCount = -1;
  int _remainingSeconds = 0;
  int _intervalsRemaining = 0;

  // List to store acoustic measurements for each interval.
  final Map<MarkerId, bool> _standingPointCompletionStatus = {};
  Marker? _activeMarker;

  final AcousticProfileData _newData = AcousticProfileData.empty();

  @override
  void initState() {
    super.initState();
    _polygons.add(widget.activeProject.polygon.clone());
    _location = getPolygonCentroid(_polygons.first);
    _zoom = getIdealZoom(
      _polygons.first.toMPLatLngList(),
      _location.toMPLatLng(),
    );
    _intervalDuration = widget.activeTest.intervalDuration;
    _intervalCount = widget.activeTest.intervalCount;
    _intervalsRemaining = _intervalCount;
    _standingPoints = widget.activeTest.standingPoints.toList();
    // Create an AcousticDataPoint in _newData for each standing point.
    for (final point in _standingPoints) {
      _newData.dataPoints.add(AcousticDataPoint(
        standingPoint: point,
        measurements: [],
      ));
    }
    _markers = _buildStandingPointMarkers();
  }

  /// Creates a marker for each standing point and returns that set of markers.
  Set<Marker> _buildStandingPointMarkers() {
    Set<Marker> markers = {};
    for (final point in _standingPoints) {
      final markerId = MarkerId(point.location.toString());
      _standingPointCompletionStatus[markerId] = false;

      markers.add(
        Marker(
          markerId: markerId,
          position: point.location,
          icon: standingPointDisabledIcon,
          infoWindow: InfoWindow(
            title: point.title,
            snippet: '${point.location.latitude.toStringAsFixed(5)},'
                ' ${point.location.longitude.toStringAsFixed(5)}',
          ),
          onTap: () {
            // Only allow selection if this point is incomplete.
            if (_standingPointCompletionStatus[markerId] == false) {
              final Marker thisMarker = _markers
                  .singleWhere(((marker) => marker.markerId == markerId));
              _setActiveMarker(thisMarker);
            }
          },
        ),
      );
    }
    return markers;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Toggle the map type between normal and satellite view.
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
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

  /// Sets given marker as [_activeMarker] as long as it is incomplete.
  ///
  /// This includes exchanging the marker's icon for the [_activeIcon].
  void _setActiveMarker(Marker marker) {
    if (marker.icon == standingPointDisabledIcon) {
      // If activeMarker already set then change icon back to incomplete.
      if (_activeMarker != null) {
        final newMarker =
            _activeMarker!.copyWith(iconParam: standingPointDisabledIcon);
        setState(() {
          _markers.add(newMarker);
          _markers.remove(_activeMarker);
        });
      }
      // Change selected marker icon to active icon and assign to _activeMarker.
      final newActiveMarker =
          marker.copyWith(iconParam: standingPointActiveIcon);
      setState(() {
        _markers.add(newActiveMarker);
        _activeMarker = newActiveMarker;
        _markers.remove(marker);
      });
    } else if (marker.icon == standingPointEnabledIcon) {
      print('_setActiveMarker called on complete marker');
      return;
    } else if (marker.icon == standingPointActiveIcon) {
      print('_setActiveMarker called on active marker');
      return;
    }
  }

  void _startIntervalCycles() async {
    // Find dataPoint connected to selected marker.
    final thisDataPoint = _newData.dataPoints.singleWhere((dataPoint) =>
        dataPoint.standingPoint.location == _activeMarker!.position);

    setState(() {
      _isIntervalCycleRunning = true;
      _intervalsRemaining = _intervalCount;
      _remainingSeconds = _intervalDuration;
    });

    while (_intervalsRemaining > 0) {
      setState(() {
        _intervalsRemaining--;
        _remainingSeconds = _intervalDuration;
      });

      // Start timer and wait for it to end before proceeding.
      _timer = _startIntervalTimer();
      while (_timer!.isActive) {
        await Future.delayed(Duration(seconds: 1));
      }
      if (!mounted) return;

      final measurement = await _doBottomSheetSequence();

      // If user closed a sheet without entering data then show error
      // and restart interval.
      if (measurement == null) {
        setState(() {
          _isErrorTextShown = true;
          _intervalsRemaining++;
        });
        continue;
      } else {
        setState(() {
          _isErrorTextShown = false;
        });
      }

      // Add measurement to _newData.
      if (thisDataPoint.measurements.length < _intervalCount) {
        thisDataPoint.measurements.add(measurement);
        print('_newData: $_newData');
      } else {
        throw Exception('More measurements than intervals somehow');
      }
    }

    // Reset values related to cycle and then change this marker to complete.
    setState(() {
      _isIntervalCycleRunning = false;
      _intervalsRemaining = _intervalCount;
      _remainingSeconds = 0;
    });
    final newMarker =
        _activeMarker!.copyWith(iconParam: standingPointEnabledIcon);
    _standingPointCompletionStatus[_activeMarker!.markerId] = true;
    setState(() {
      _markers.add(newMarker);
      _markers.remove(_activeMarker);
      _activeMarker = null;
    });

    if (_standingPointCompletionStatus.values.every((status) => status)) {
      _endTest();
    }
  }

  Timer _startIntervalTimer() {
    return Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        setState(() {
          timer.cancel();
        });
      }
    });
  }

  Future<AcousticMeasurement?> _doBottomSheetSequence() async {
    // 1. Bottom sheet for Sound Decibel Level.
    if (!mounted) return null;
    final decibels = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      backgroundColor: const Color(0xFFDDE6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: MediaQuery.viewInsetsOf(context) + const EdgeInsets.all(16),
          child: _DecibelLevelForm(),
        );
      },
    );
    if (decibels == null) return null;

    // 2. Bottom sheet for Sound Types (multi-select).
    if (!mounted) return null;
    final soundTypeDescription =
        await showModalBottomSheet<(Set<SoundType>, String)>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      backgroundColor: const Color(0xFFDDE6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: MediaQuery.viewInsetsOf(context) + const EdgeInsets.all(16),
          child: _SoundTypeForm(),
        );
      },
    );
    if (soundTypeDescription == null) return null;
    final Set<SoundType> selectedSoundTypes = soundTypeDescription.$1;
    final String otherText = soundTypeDescription.$2;

    // 3. Bottom sheet for Main Sound Type (single-select).
    if (!mounted) return null;
    final mainSoundType = await showModalBottomSheet<SoundType>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFDDE6F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Padding(
          padding: MediaQuery.viewInsetsOf(context) + const EdgeInsets.all(16),
          child: _MainSoundTypeForm(selectedSoundTypes),
        );
      },
    );
    if (mainSoundType == null) return null;

    // Construct an AcousticMeasurement using the collected data.
    return AcousticMeasurement(
      decibels: decibels,
      soundTypes: selectedSoundTypes,
      mainSoundType: mainSoundType,
      other: otherText,
    );
  }

  /// Finalize the interval cycle by stopping the test-running state.
  /// Process and aggregate the measurement data for each standing point:
  /// - Calculate average decibel values.
  /// - Draw a circle around the point representing the data as a 'heat map'
  /// Update the completed status of each standing point
  /// If all points are completed, navigate to the Project Details Page
  Future<void> _endTest() async {
    _timer?.cancel();
    widget.activeTest.submitData(_newData);
    _isTestComplete = true;
    await Future.delayed(Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// Displays an instruction overlay that explains how Acoustic Profile works.
  /// This overlay is shown immediately when the screen loads.
  void _showInstructionOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.05,
              vertical: screenSize.height * 0.005),
          actionsPadding: EdgeInsets.zero,
          title: const Text(
            'How It Works:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: screenSize.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  acousticInstructions(),
                  buildLegends(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: const [
                    Checkbox(value: false, onChanged: null),
                    Text("Don't show this again next time"),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _getDirections() {
    if (!_isTestComplete) {
      if (_isErrorTextShown) {
        return 'No information given. Please do '
            'not close bottom pane without submitting.';
      } else {
        if (_activeMarker == null) {
          return 'Tap one of the marked standing points to begin '
              'measurements at that location.';
        } else {
          if (!_isIntervalCycleRunning) {
            return 'Press Start once you have arrived at the selected location.';
          } else {
            return 'Listen carefully to your surroundings.';
          }
        }
      }
    } else {
      return 'Test completed! Now returning to previous screen.';
    }
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
                markers: _markers,
                polygons: _polygons,
                circles: _circles,
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
                    Column(
                      spacing: 10,
                      children: <Widget>[
                        TimerButtonAndDisplay(
                          onPressed: (!_isIntervalCycleRunning &&
                                  _activeMarker != null)
                              ? () {
                                  setState(() {
                                    if (_isIntervalCycleRunning) {
                                      setState(() {
                                        _isIntervalCycleRunning = false;
                                        _timer?.cancel();
                                      });
                                    } else {
                                      _startIntervalCycles();
                                    }
                                  });
                                }
                              : null,
                          isTestRunning: _isIntervalCycleRunning,
                          remainingSeconds: _remainingSeconds,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_intervalCount - _intervalsRemaining} / $_intervalCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
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
                              text: _getDirections(),
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
                          icon: Icon(
                            Icons.layers,
                            color: Color(0xFF2D6040),
                          ),
                        ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFBACFEB).withValues(alpha: 0.9),
                          borderColor: Color(0xFF37597D),
                          onPressed: _showInstructionOverlay,
                          icon: Icon(
                            FontAwesomeIcons.info,
                            color: Color(0xFF37597D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecibelLevelForm extends StatefulWidget {
  @override
  State<_DecibelLevelForm> createState() => _DecibelLevelFormState();
}

class _DecibelLevelFormState extends State<_DecibelLevelForm> {
  final TextEditingController decibelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    decibelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sound Decibel Level',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 250,
              child: TextFormField(
                textAlign: TextAlign.center,
                controller: decibelController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  label: Center(child: Text('Enter decibel value')),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a value';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: p2bpBlue),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(
                    context, double.parse(decibelController.text.trim()));
              }
            },
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundTypeForm extends StatefulWidget {
  @override
  State<_SoundTypeForm> createState() => _SoundTypeFormState();
}

class _SoundTypeFormState extends State<_SoundTypeForm> {
  final Set<SoundType> _selections = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otherController = TextEditingController();
  static final List<SoundType> _chipSoundTypeList = List.generate(
      SoundType.values.length - 1, (index) => SoundType.values[index]);
  bool _isOtherSelected = false;

  void _submitDescription() {
    // Validate the "Other" field if its chip is selected.
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      (
        _selections,
        (_selections.contains(SoundType.other))
            ? _otherController.text.trim()
            : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isOtherSelected = _selections.contains(SoundType.other);
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sound Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select all of the sounds you heard during the measurement',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3, // Three columns
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 1,
              crossAxisSpacing: 2,
              padding: const EdgeInsets.only(bottom: 8),
              childAspectRatio:
                  2, // Adjust to change the height/width ratio of each cell
              children: _chipSoundTypeList.map((type) {
                final bool isSelected = _selections.contains(type);
                return ChoiceChip(
                  // TODO why not FilterChip?
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selections.add(type);
                      } else {
                        _selections.remove(type);
                      }
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Pill shape
                    side: BorderSide(
                      color: isSelected ? p2bpBlue : Color(0xFFB0C4DE),
                      width: 2.0,
                    ),
                  ),
                  selectedColor: p2bpBlue.shade100,
                  backgroundColor: Color(0xFFE3EBF4),
                );
              }).toList(),
            ),
            // Other option text field and select button.
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _otherController,
                    enabled: _isOtherSelected,
                    decoration: InputDecoration(
                      labelText: 'Other',
                      suffixIcon: _otherController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _otherController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    // Validate only if the chip is selected
                    validator: (value) {
                      if (_isOtherSelected &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Always display the chip; disable it if there's no text.
                ChoiceChip(
                  label: Text('Other'),
                  selected: _isOtherSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selections.add(SoundType.other);
                      } else {
                        _selections.remove(SoundType.other);
                      }
                    });
                  },
                  backgroundColor: Color(0xFFE3EBF4),
                  disabledColor: Color(0xFFE3EBF4),
                  selectedColor: p2bpBlue.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _isOtherSelected ? p2bpBlue : Color(0xFFB0C4DE),
                      width: 2.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: p2bpBlue),
              onPressed: (_selections.isNotEmpty) ? _submitDescription : null,
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainSoundTypeForm extends StatefulWidget {
  final Set<SoundType> selectedSoundTypes;

  const _MainSoundTypeForm(this.selectedSoundTypes);

  @override
  State<_MainSoundTypeForm> createState() => _MainSoundTypeFormState();
}

class _MainSoundTypeFormState extends State<_MainSoundTypeForm> {
  SoundType? selectedMainSound;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Main Sound Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the main source of sound that you heard during the measurement',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3, // Three columns
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Prevent scrolling inside the sheet
          mainAxisSpacing: 1,
          crossAxisSpacing: 2,
          padding: const EdgeInsets.only(bottom: 8),
          childAspectRatio:
              2, // Adjust to change the height/width ratio of each cell
          children: widget.selectedSoundTypes.map((type) {
            final bool isSelected = selectedMainSound == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedMainSound = selected ? type : null;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? p2bpBlue : Color(0xFFB0C4DE),
                  width: 2.0,
                ),
              ),
              selectedColor: p2bpBlue.shade100,
              backgroundColor: Color(0xFFE3EBF4),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: p2bpBlue),
          onPressed: (selectedMainSound != null)
              ? () {
                  Navigator.pop(context, selectedMainSound);
                }
              : null,
          child: const Text('Submit', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
