import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2b/extensions.dart';
import 'theme.dart';
import 'widgets.dart';

import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/absence_of_order_test_class.dart';
import 'google_maps_functions.dart';

/// Returns a `List<TextButton>` using [options] as `Text` child.
/// [selectedList] should be a reference to a list containing the values
/// from [options] that should be selected by default (typically none).
/// [onPressed] is used for `onPressed` of all buttons.
List<Widget> buildToggleButtonList({
  required List<String> options,
  required List<String> selectedList,
  required void Function(String) onPressed,
}) {
  List<Widget> buttonList = options.map((option) {
    final bool isSelected = selectedList.contains(option);
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => onPressed(option),
      child: Text(option),
    );
  }).toList();
  return buttonList;
}

/// Page for completing and submitting data for an Absence of Order Test.
class AbsenceOfOrderTestPage extends StatefulWidget {
  final Project activeProject;
  final AbsenceOfOrderTest activeTest;

  const AbsenceOfOrderTestPage({
    super.key,
    required this.activeProject,
    required this.activeTest,
  });

  @override
  State<StatefulWidget> createState() => _AbsenceOfOrderTestPageState();
}

class _AbsenceOfOrderTestPageState extends State<AbsenceOfOrderTestPage> {
  bool _outsidePoint = false;
  bool _isTestRunning = false;
  bool _directionsVisible = true;
  bool _isDescriptionReady = false;

  late GoogleMapController mapController;
  LatLng _location = defaultLocation;
  double _zoom = 18;
  MapType _currentMapType = MapType.satellite; // Default map type
  List<mp.LatLng> _projectArea = [];
  final Set<Marker> _markers = {}; // Set of markers visible on map
  final Set<Polygon> _polygons = {}; // Set of polygons
  final AbsenceOfOrderData _newData = AbsenceOfOrderData.empty();
  dynamic _tempData;
  MisconductType? _tempDataType;

  Timer? _timer;
  Timer? _outsidePointTimer;
  int _remainingSeconds = -1;
  static const double _bottomSheetHeight = 185;

  @override
  void initState() {
    super.initState();
    _polygons.add(widget.activeProject.polygon.clone());
    _location = getPolygonCentroid(_polygons.first);
    _projectArea = _polygons.first.toMPLatLngList();
    _zoom = getIdealZoom(_projectArea, _location.toMPLatLng());
    _remainingSeconds = widget.activeTest.testDuration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    super.dispose();
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

  /// Toggles map type between satellite and normal
  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
    });
  }

  /// Places point on the map and adds that location and the description from
  /// [_tempData] to the appropriate `List` in [_newData].
  void _togglePoint(LatLng point) {
    try {
      if (!isPointInsidePolygon(point, _polygons.first)) {
        setState(() {
          _outsidePoint = true;
        });
        _outsidePointTimer?.cancel();
        _outsidePointTimer = Timer(Duration(seconds: 3), () {
          setState(() {
            _outsidePoint = false;
          });
        });
      }

      if (_tempDataType == MisconductType.behavior) {
        setState(() {
          _newData.behaviorList.add(
            BehaviorMisconduct.fromLatLng(point, _tempData.$1, _tempData.$2),
          );
          _markers.add(_newData.behaviorList.last.marker.copyWith(
            onTapParam: () {
              // If the marker is tapped again, it will be removed.
              _newData.behaviorList
                  .removeWhere((behavior) => behavior.marker.position == point);
              _markers.removeWhere(
                  (marker) => marker.markerId == MarkerId(point.toString()));
            },
          ));
          _tempDataType = null;
          _setTempData(null);
        });
      } else if (_tempDataType == MisconductType.maintenance) {
        setState(() {
          _newData.maintenanceList.add(
            MaintenanceMisconduct.fromLatLng(point, _tempData.$1, _tempData.$2),
          );
          _markers.add(_newData.maintenanceList.last.marker.copyWith(
            onTapParam: () {
              // If the marker is tapped again, it will be removed.
              _newData.maintenanceList.removeWhere(
                  (maintenance) => maintenance.marker.position == point);
              _markers.removeWhere(
                  (marker) => marker.markerId == MarkerId(point.toString()));
            },
          ));
          _tempDataType = null;
          _setTempData(null);
        });
      }
    } catch (e, stacktrace) {
      print('Error in absence_of_order_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
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
          _tempDataType = null;
          _setTempData(null);
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

  /// Cancels timer, submits data, and pops test page.
  void _endTest() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    widget.activeTest.submitData(_newData);
    Navigator.pop(context);
  }

  /// Uses [showModalBottomSheet] on [_BehaviorDescriptionForm] and then
  /// stores the results in [_tempData].
  void _doBehaviorModal(BuildContext context) async {
    final behavior = await showModalBottomSheet<(Set<BehaviorType>, String)?>(
      isScrollControlled: true,
      context: context,
      builder: (context) => _BehaviorDescriptionForm(),
    );
    if (behavior != null) _tempDataType = MisconductType.behavior;
    _setTempData(behavior);
  }

  /// Uses [showModalBottomSheet] on [_MaintenanceDescriptionForm] and then
  /// stores the results in [_tempData].
  void _doMaintenanceModal(BuildContext context) async {
    final maintenance =
        await showModalBottomSheet<(Set<MaintenanceType>, String)?>(
      isScrollControlled: true,
      context: context,
      builder: (context) => _MaintenanceDescriptionForm(),
    );
    if (maintenance != null) _tempDataType = MisconductType.maintenance;
    _setTempData(maintenance);
  }

  void _setTempData(dynamic data) {
    setState(() {
      _tempData = data;
      _isDescriptionReady = _tempData != null;
    });
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
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                onMapCreated: _onMapCreated,
                initialCameraPosition:
                    CameraPosition(target: _location, zoom: _zoom),
                markers: _markers,
                polygons: _polygons,
                onTap: _isDescriptionReady ? _togglePoint : null,
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
                              _tempDataType = null;
                              _setTempData(null);
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
                              text: !_isDescriptionReady
                                  ? 'Select a type of misconduct.'
                                  : 'Drop a pin where the misconduct is.',
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
                          backgroundColor: Colors.green,
                          borderColor: Color(0xFF2D6040),
                          onPressed: _toggleMapType,
                          icon: const Icon(Icons.map),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_outsidePoint)
              TestErrorText(
                padding:
                    EdgeInsets.fromLTRB(50, 0, 50, _bottomSheetHeight + 20),
              ),
          ],
        ),
        bottomSheet: SizedBox(
          height: _bottomSheetHeight,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
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
                    'Absence of Order Locator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: placeYellow,
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 10,
                  children: <Widget>[
                    Expanded(
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: (!_isDescriptionReady && _isTestRunning)
                            ? () {
                                _doBehaviorModal(context);
                              }
                            : null,
                        child: Text('Behavior'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        style: testButtonStyle,
                        onPressed: (!_isDescriptionReady && _isTestRunning)
                            ? () {
                                _doMaintenanceModal(context);
                              }
                            : null,
                        child: Text('Maintenance'),
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
                        onPressed: () => Navigator.pop(context),
                        label: Text('Back'),
                        icon: Icon(Icons.chevron_left),
                        iconAlignment: IconAlignment.start,
                      ),
                    ),
                    Flexible(
                      child: FilledButton.icon(
                        style: testButtonStyle,
                        onPressed: (!_isDescriptionReady && !_isTestRunning)
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      TestFinishDialog(onNext: () {
                                    Navigator.pop(context);
                                    _endTest();
                                  }),
                                );
                              }
                            : null,
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
      ),
    );
  }
}

/// Form for providing description of behavior misconduct.
///
/// This is only used with [showModalBottomSheet] when completing an
/// Absence of Order Test.
class _BehaviorDescriptionForm extends StatefulWidget {
  const _BehaviorDescriptionForm();

  @override
  State<_BehaviorDescriptionForm> createState() =>
      _BehaviorDescriptionFormState();
}

class _BehaviorDescriptionFormState extends State<_BehaviorDescriptionForm> {
  final GlobalKey<FormFieldState> _formFieldKey = GlobalKey<FormFieldState>();
  static final List<BehaviorType> _chipBehaviorTypeList = List.generate(
      BehaviorType.values.length - 1, (index) => BehaviorType.values[index]);

  late List<Widget> _buttonList;
  final Set<BehaviorType> _selectedBehaviors = <BehaviorType>{};
  final TextEditingController _otherTextController = TextEditingController();

  /// Validates the form and if successful pops this Modal Sheet and
  /// returns a [BehaviorPoint] containing data from this form.
  void _submitDescription() {
    // Validate 'other' text box and return if invalid
    if (!_formFieldKey.currentState!.validate()) {
      return;
    }

    final record = (
      _selectedBehaviors,
      (_selectedBehaviors.contains(BehaviorType.other))
          ? _otherTextController.text
          : '',
    );
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    _buttonList = <Widget>[
      for (final behavior in _chipBehaviorTypeList)
        FilterChip(
          label: SizedBox(
            height: 25,
            width: double.infinity,
            child: Center(child: Text(behavior.displayName)),
          ),
          selected: _selectedBehaviors.contains(behavior),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedBehaviors.add(behavior);
              } else {
                _selectedBehaviors.remove(behavior);
              }
            });
          },
        )
    ];
    if (_buttonList.length != 6) {
      print('buttonList in BehaviorDescriptionForm is wrong length');
      return SingleChildScrollView();
    }
    final ThemeData theme = Theme.of(context);
    return Theme(
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
        child: Padding(
          padding: MediaQuery.viewInsetsOf(context),
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
                children: <Widget>[
                  const BarIndicator(),
                  Center(
                    child: Text(
                      'Description of Misconduct',
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
                        'Select all of the following that describes the misconduct.',
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
                        child: _buttonList[0],
                      ),
                      Expanded(
                        flex: 1,
                        child: _buttonList[1],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: _buttonList[2],
                      ),
                      Expanded(
                        flex: 1,
                        child: _buttonList[3],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: _buttonList[4],
                      ),
                      Expanded(
                        flex: 1,
                        child: _buttonList[5],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: _formFieldKey,
                          enabled:
                              _selectedBehaviors.contains(BehaviorType.other),
                          controller: _otherTextController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            hintText: 'Other...',
                          ),
                          validator: (value) {
                            // If other button was selected verify text box is not empty
                            if (_selectedBehaviors
                                    .contains(BehaviorType.other) &&
                                (value == null || value.isEmpty)) {
                              return 'Please describe the misconduct.';
                            }
                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: FilterChip(
                          label: SizedBox(
                            height: 25,
                            width: double.infinity,
                            child: Center(
                              child: Text(BehaviorType.other.displayName),
                            ),
                          ),
                          selected:
                              _selectedBehaviors.contains(BehaviorType.other),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedBehaviors.add(BehaviorType.other);
                              } else {
                                _selectedBehaviors.remove(BehaviorType.other);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: FilledButton(
                          style: testButtonStyle,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                      ),
                      Flexible(
                        child: FilledButton(
                          style: testButtonStyle,
                          // Confirm button disabled when no option selected
                          onPressed: (_selectedBehaviors.isNotEmpty)
                              ? _submitDescription
                              : null,
                          child: Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Form for providing description of maintenance misconduct.
///
/// This is only used with [showModalBottomSheet] when completing an
/// Absence of Order Test.
class _MaintenanceDescriptionForm extends StatefulWidget {
  const _MaintenanceDescriptionForm();

  @override
  State<_MaintenanceDescriptionForm> createState() =>
      _MaintenanceDescriptionFormState();
}

class _MaintenanceDescriptionFormState
    extends State<_MaintenanceDescriptionForm> {
  final GlobalKey<FormFieldState> _formFieldKey = GlobalKey<FormFieldState>();
  static final List<MaintenanceType> _chipMaintenanceTypeList = List.generate(
      MaintenanceType.values.length - 1,
      (index) => MaintenanceType.values[index]);

  late List<Widget> _buttonList;
  final Set<MaintenanceType> _selectedMaintenances = <MaintenanceType>{};
  final TextEditingController _otherTextController = TextEditingController();

  /// Validates the form and if successful pops this Modal Sheet and
  /// returns a [MaintenancePoint] containing data from this form.
  void _submitDescription() {
    // Validate 'other' text box and return if invalid
    if (!_formFieldKey.currentState!.validate()) {
      return;
    }

    final record = (
      _selectedMaintenances,
      (_selectedMaintenances.contains(MaintenanceType.other))
          ? _otherTextController.text
          : '',
    );
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    _buttonList = <Widget>[
      for (final maintenance in _chipMaintenanceTypeList)
        FilterChip(
          label: SizedBox(
            height: 25,
            width: double.infinity,
            child: Center(child: Text(maintenance.displayName)),
          ),
          selected: _selectedMaintenances.contains(maintenance),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedMaintenances.add(maintenance);
              } else {
                _selectedMaintenances.remove(maintenance);
              }
            });
          },
        )
    ];
    if (_buttonList.length != 6) {
      print('buttonList in MaintenanceDescriptionForm is wrong length');
      return SingleChildScrollView();
    }
    final ThemeData theme = Theme.of(context);
    return Theme(
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
        child: Padding(
          padding: MediaQuery.viewInsetsOf(context),
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
                children: <Widget>[
                  const BarIndicator(),
                  Center(
                    child: Text(
                      'Description of Misconduct',
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
                        'Select all of the following that describes the misconduct.',
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
                        child: _buttonList[0],
                      ),
                      Expanded(
                        flex: 1,
                        child: _buttonList[1],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: _buttonList[2],
                      ),
                      Expanded(
                        flex: 1,
                        child: _buttonList[3],
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: _buttonList[4],
                      ),
                      Expanded(
                        flex: 1,
                        child: _buttonList[5],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: _formFieldKey,
                          enabled: _selectedMaintenances
                              .contains(MaintenanceType.other),
                          controller: _otherTextController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                            hintText: 'Other...',
                          ),
                          validator: (value) {
                            // If other button was selected verify text box is not empty
                            if (_selectedMaintenances
                                    .contains(MaintenanceType.other) &&
                                (value == null || value.isEmpty)) {
                              return 'Please describe the misconduct.';
                            }
                            return null;
                          },
                        ),
                      ),
                      Expanded(
                        child: FilterChip(
                          label: SizedBox(
                            height: 25,
                            width: double.infinity,
                            child: Center(
                              child: Text(MaintenanceType.other.displayName),
                            ),
                          ),
                          selected: _selectedMaintenances
                              .contains(MaintenanceType.other),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMaintenances
                                    .add(MaintenanceType.other);
                              } else {
                                _selectedMaintenances
                                    .remove(MaintenanceType.other);
                              }
                            });
                          },
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: FilledButton(
                          style: testButtonStyle,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'),
                        ),
                      ),
                      Flexible(
                        child: FilledButton(
                          style: testButtonStyle,
                          // Confirm button disabled when no option selected
                          onPressed: (_selectedMaintenances.isNotEmpty)
                              ? _submitDescription
                              : null,
                          child: Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
