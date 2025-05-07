import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:p2b/extensions.dart';
import 'assets.dart';
import 'theme.dart';
import 'widgets.dart';

import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/nature_prevalence_test_class.dart';
import 'google_maps_functions.dart';

class NaturePrevalenceTestPage extends StatefulWidget {
  final Project activeProject;
  final NaturePrevalenceTest activeTest;

  /// IMPORTANT: When navigating to this page, pass in project details. The
  /// project details page already contains project info, so you should use
  /// that data.
  const NaturePrevalenceTestPage(
      {super.key, required this.activeProject, required this.activeTest});

  @override
  State<NaturePrevalenceTestPage> createState() =>
      _NaturePrevalenceTestPageState();
}

class _NaturePrevalenceTestPageState extends State<NaturePrevalenceTestPage> {
  bool _isTestRunning = false;
  bool _polygonMode = false;
  bool _pointMode = false;
  bool _outsidePoint = false;
  bool _deleteMode = false;
  String _errorText = 'You tried to place a point outside of the project area!';

  double _zoom = 18;
  late final Polygon _projectPolygon;
  List<mp.LatLng> _projectArea = [];
  String _directions = "Choose a category.";
  bool _directionsVisible = true;
  static const double _bottomSheetHeight = 320;
  late DocumentReference teamRef;
  late GoogleMapController mapController;
  LatLng _location = defaultLocation; // Default location
  List<LatLng> _polygonPoints = []; // Points for the polygon
  final Set<Polygon> _polygons = {}; // Set of polygons
  final Set<Marker> _markers = {}; // Set of markers for points
  Set<Marker> _polygonMarkers = {}; // Set of markers for polygon creation
  MapType _currentMapType = MapType.satellite; // Default map type
  bool _oldVisibility = true;

  Timer? _timer;
  Timer? _outsidePointTimer;
  int _remainingSeconds = -1;

  final List<Animal> _animalData = [];
  final List<Vegetation> _vegetationData = [];
  final List<WaterBody> _waterBodyData = [];
  WeatherData? _weatherData;

  AnimalType? _animalType;
  VegetationType? _vegetationType;
  WaterBodyType? _waterBodyType;
  Map<NatureType, Type> natureToSpecific = {
    NatureType.animal: AnimalType,
    NatureType.vegetation: VegetationType,
    NatureType.waterBody: WaterBodyType,
  };
  NatureType? _natureType;
  String? _otherType;

  @override
  void initState() {
    super.initState();
    _projectPolygon = widget.activeProject.polygon.clone();
    _location = getPolygonCentroid(_projectPolygon);
    _projectArea = _projectPolygon.toMPLatLngList();
    _zoom = getIdealZoom(_projectArea, _location.toMPLatLng()) - 0.4;
    _remainingSeconds = widget.activeTest.testDuration;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setWeatherData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    super.dispose();
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

  /// Cancels timer, compiles and submits data, and then pops test page.
  void _endTest() {
    _timer?.cancel();
    _outsidePointTimer?.cancel();
    final NaturePrevalenceData natureData = NaturePrevalenceData(
      animals: _animalData,
      waterBodies: _waterBodyData,
      vegetation: _vegetationData,
      weather: _weatherData,
    );
    widget.activeTest.submitData(natureData);
    Navigator.pop(context);
  }

  /// Sets all type variables to null.
  ///
  /// Called after finishing data placement.
  void _clearTypes() {
    _natureType = null;
    _animalType = null;
    _vegetationType = null;
    _waterBodyType = null;
    _otherType = null;
    _polygonMode = false;
    _pointMode = false;
    _directions = 'Choose a category. Or, click finish to submit.';
  }

  Object? _getCurrentTypeName() {
    switch (_natureType) {
      case null:
        throw Exception("Type not chosen! "
            "_natureType is null and _getCurrentType() has been invoked.");
      case NatureType.vegetation:
        return _vegetationType;
      case NatureType.waterBody:
        return _waterBodyType;
      case NatureType.animal:
        return _animalType;
    }
  }

  void _setWeatherData() async {
    WeatherData? weatherData;

    try {
      weatherData = await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return WeatherDialog();
          });
      if (weatherData == null && mounted) {
        Navigator.pop(context);
      } else {
        _weatherData = weatherData;
      }
    } catch (e, stacktrace) {
      print('Error in nature_prevalence_test.dart, _setWeatherData(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _chooseWaterBodyType(WaterBodyType waterBodyType) {
    setState(() {
      _natureType = NatureType.waterBody;
      _waterBodyType = waterBodyType;
      _polygonMode = true;
      _directions =
          'Place points to create an outline, then click confirm shape to build the polygon.';
    });
  }

  void showModalWaterBody(BuildContext context) {
    _showTestModalGeneric(
      context,
      title: 'Select the Body of Water',
      subtitle: 'Then mark the boundary on the map.',
      contentList: <Widget>[
        Text(
          'Body of Water Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Ocean',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.ocean);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Lake',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.lake);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'River',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.river);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        SizedBox(height: 5),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Swamp',
              onPressed: () {
                _chooseWaterBodyType(WaterBodyType.swamp);
                Navigator.pop(context);
              },
            ),
            Flexible(
              flex: 1,
              child: SizedBox(),
            ),
            Flexible(
              flex: 1,
              child: SizedBox(),
            ),
          ],
        ),
      ],
    );
  }

  void _chooseVegetationType(VegetationType vegetationType) {
    setState(() {
      _natureType = NatureType.vegetation;
      _vegetationType = vegetationType;
      _polygonMode = true;
      _directions =
          'Place points to create an outline, then click confirm shape to build the polygon.';
    });
  }

  void showModalVegetation(BuildContext context) {
    _showTestModalGeneric(
      context,
      title: 'Vegetation Type',
      subtitle: 'Then mark the boundaries on the map',
      contentList: <Widget>[
        Text(
          'Vegetation Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Native',
              onPressed: () {
                _chooseVegetationType(VegetationType.native);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Design',
              onPressed: () {
                _chooseVegetationType(VegetationType.design);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Open Field',
              onPressed: () {
                _chooseVegetationType(VegetationType.openField);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _chooseAnimalType(AnimalType animalType) {
    setState(() {
      _natureType = NatureType.animal;
      _animalType = animalType;
      _pointMode = true;
      _directions = 'Place a point where you see the ${animalType.name}.';
    });
  }

  void _showTestModalGeneric(BuildContext context,
      {required String title,
      required String? subtitle,
      required List<Widget> contentList}) {
    showTestModalGeneric(
      context,
      onCancel: () {
        setState(() {
          _clearTypes();
        });
        Navigator.pop(context);
      },
      title: title,
      subtitle: subtitle,
      contentList: contentList,
    );
  }

  void showModalAnimal(BuildContext context) {
    _showTestModalGeneric(
      context,
      title: 'What animal do you see?',
      subtitle: null,
      contentList: <Widget>[
        Text(
          'Domesticated',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Cat',
              onPressed: () {
                _chooseAnimalType(AnimalType.cat);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Dog',
              onPressed: () {
                _chooseAnimalType(AnimalType.dog);
                Navigator.pop(context);
              },
            ),
            Flexible(flex: 1, child: SizedBox()),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Wild',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Squirrel',
              onPressed: () {
                _chooseAnimalType(AnimalType.squirrel);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Bird',
              onPressed: () {
                _chooseAnimalType(AnimalType.bird);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Rabbit',
              onPressed: () {
                _chooseAnimalType(AnimalType.rabbit);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        Row(
          spacing: 20,
          children: <Widget>[
            TestButton(
              buttonText: 'Turtle',
              onPressed: () {
                _chooseAnimalType(AnimalType.turtle);
                Navigator.pop(context);
              },
            ),
            TestButton(
              buttonText: 'Duck',
              onPressed: () {
                _chooseAnimalType(AnimalType.duck);
                Navigator.pop(context);
              },
            ),
            Flexible(flex: 1, child: SizedBox()),
          ],
        ),
        SizedBox(height: 20),
        Text(
          'Other',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Row(
          spacing: 10,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: (otherText) {
                  _otherType = otherText;
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  labelText: 'Enter animal name',
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _natureType = NatureType.animal;
                    _animalType = AnimalType.other;
                    _pointMode = true;
                    _directions = 'Place a point where you see the animal.';
                  });
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Submit other',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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

  Future<void> _togglePoint(LatLng point) async {
    try {
      if (!isPointInsidePolygon(point, _projectPolygon)) {
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
      if (_pointMode) _pointTap(point);
      if (_polygonMode) _polygonTap(point);
    } catch (e, stacktrace) {
      print('Error in nature_prevalence_test.dart, _togglePoint(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _polygonTap(LatLng point) {
    if (_getCurrentTypeName() == null) return;
    final markerId = MarkerId(point.toString());
    setState(() {
      _polygonPoints.add(point);
      _polygonMarkers.add(
        Marker(
          markerId: markerId,
          position: point,
          consumeTapEvents: _deleteMode,
          icon: tempMarkerIcon,
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

  void _pointTap(LatLng point) {
    Object? type = _getCurrentTypeName();
    if (type != null && type is AnimalType) {
      final Marker dataMarker = Animal.newMarker(point, type, _otherType);
      final Marker displayMarker = dataMarker.copyWith(
        consumeTapEventsParam: _deleteMode,
        onTapParam: () {
          if (_pointMode || _polygonMode) return;
          // If the marker is tapped again, it will be removed
          if (_deleteMode) {
            _animalData.removeWhere(
                (animal) => animal.marker.markerId == dataMarker.markerId);
            setState(() {
              _markers.removeWhere(
                  (marker) => marker.markerId == dataMarker.markerId);
              _deleteMode = false;
            });
          }
        },
      );
      setState(() {
        _markers.add(displayMarker);
        _directions = 'Choose a category. Or, click finish to submit.';
      });
      _animalData.add(Animal(
        animalType: _animalType!,
        marker: dataMarker,
        otherName: _otherType,
      ));
      _pointMode = false;
      _clearTypes();
    }
  }

  void _finalizePolygon() {
    Polygon tempPolygon;
    try {
      if (_natureType == NatureType.vegetation) {
        tempPolygon = finalizePolygon(
          _polygonPoints,
          strokeColor: _vegetationType!.color,
        );
        // Create polygon.
        _polygons.add(tempPolygon);
        _vegetationData.add(Vegetation(
            vegetationType: _vegetationType!,
            polygon: tempPolygon,
            otherName: _otherType));
      } else if (_natureType == NatureType.waterBody) {
        tempPolygon =
            finalizePolygon(_polygonPoints, strokeColor: _waterBodyType!.color);
        // Create polygon.
        _polygons.add(tempPolygon);
        _waterBodyData.add(
            WaterBody(waterBodyType: _waterBodyType!, polygon: tempPolygon));
      } else {
        throw Exception("Invalid nature type in _finalizePolygon(), "
            "_natureType = $_natureType");
      }
      // Clears polygon points and enter add points mode.
      _polygonPoints = [];

      // Clear markers from screen.
      setState(() {
        _polygonMarkers.clear();
        _polygonMode = false;
        _clearTypes();
      });
    } catch (e, stacktrace) {
      print('Exception in _finalize_polygon(): $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = (_currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal);
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
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                padding: EdgeInsets.only(bottom: _bottomSheetHeight),
                onMapCreated: _onMapCreated,
                initialCameraPosition:
                    CameraPosition(target: _location, zoom: 14),
                polygons: (_oldVisibility || _polygons.isEmpty)
                    ? {..._polygons, _projectPolygon}
                    : {_polygons.last, _projectPolygon},
                markers: (_oldVisibility || _markers.isEmpty)
                    ? {..._markers, ..._polygonMarkers}
                    : {_markers.last, ..._polygonMarkers},
                onTap: (_pointMode || _polygonMode) ? _togglePoint : null,
                mapType: _currentMapType, // Use current map type
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
                        if (_isTestRunning) {
                          setState(() {
                            _isTestRunning = false;
                            _timer?.cancel();
                            _clearTypes();
                          });
                        } else {
                          _startTest();
                        }
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
                              text: _directions)
                          : SizedBox(),
                    ),
                    SizedBox(width: 15),
                    Column(
                      spacing: 10,
                      children: [
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
                        if (!_polygonMode && !_pointMode)
                          CircularIconMapButton(
                            borderColor: Color(0xFF2D6040),
                            onPressed: () {
                              setState(() {
                                _deleteMode = !_deleteMode;
                                if (_deleteMode == true) {
                                  _outsidePoint = false;
                                  _errorText = 'You are in delete mode.';
                                } else {
                                  _outsidePoint = false;
                                  _errorText =
                                      'You tried to place a point outside of the project area!';
                                }
                              });
                            },
                            backgroundColor:
                                _deleteMode ? Colors.blue : Colors.red,
                            icon: Icon(
                              _deleteMode ? Icons.location_on : Icons.delete,
                              size: 30,
                            ),
                          ),
                        CircularIconMapButton(
                          backgroundColor:
                              Color(0xFFE4E9EF).withValues(alpha: 0.9),
                          borderColor: const Color(0xFF4A5D75),
                          onPressed: () {
                            setState(() {
                              _oldVisibility = !_oldVisibility;
                            });
                          },
                          icon: Icon(
                            _oldVisibility
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 30,
                            color: const Color(0xFF4A5D75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_outsidePoint || _deleteMode)
              TestErrorText(
                text: _errorText,
                padding:
                    EdgeInsets.fromLTRB(50, 0, 50, _bottomSheetHeight + 20),
              ),
          ],
        ),
        bottomSheet: SizedBox(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'Nature Prevalence',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: placeYellow,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Natural Boundaries',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      spacing: 10,
                      children: [
                        DisplayModalButton(
                          onPressed: (_pointMode ||
                                  _polygonMode ||
                                  _deleteMode ||
                                  !_isTestRunning)
                              ? null
                              : () {
                                  showModalWaterBody(context);
                                },
                          text: 'Body of Water',
                          icon: Icon(Icons.water),
                        ),
                        DisplayModalButton(
                            onPressed: (_pointMode ||
                                    _polygonMode ||
                                    _deleteMode ||
                                    !_isTestRunning)
                                ? null
                                : () {
                                    showModalVegetation(context);
                                  },
                            text: 'Vegetation',
                            icon: Icon(Icons.grass)),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'Animals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 10,
                      children: [
                        DisplayModalButton(
                          onPressed: (_pointMode ||
                                  _polygonMode ||
                                  _deleteMode ||
                                  !_isTestRunning)
                              ? null
                              : () {
                                  showModalAnimal(context);
                                },
                          text: 'Animal',
                          icon: Icon(Icons.pets),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        spacing: 10,
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              spacing: 10,
                              children: <Widget>[
                                Flexible(
                                  child: EditButton(
                                    text: 'Confirm Shape',
                                    foregroundColor: Colors.green,
                                    backgroundColor: Colors.white,
                                    icon: const Icon(Icons.check),
                                    iconColor: Colors.green,
                                    onPressed: (_polygonMode &&
                                            _polygonPoints.length >= 3 &&
                                            !_deleteMode)
                                        ? () {
                                            _finalizePolygon();
                                            setState(() {
                                              _directions =
                                                  'Choose a category. Or, click finish if done.';
                                            });
                                          }
                                        : null,
                                  ),
                                ),
                                Flexible(
                                  child: EditButton(
                                    text: 'Cancel',
                                    foregroundColor: Colors.red,
                                    backgroundColor: Colors.white,
                                    icon: const Icon(Icons.cancel),
                                    iconColor: Colors.red,
                                    onPressed: ((_pointMode || _polygonMode) &&
                                            !_deleteMode)
                                        ? () {
                                            setState(() {
                                              _pointMode = false;
                                              _polygonMode = false;
                                              _polygonMarkers = {};
                                              _clearTypes();
                                            });
                                            _polygonPoints = [];
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            flex: 0,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: EditButton(
                                text: 'Finish',
                                foregroundColor: Colors.black,
                                backgroundColor: Colors.white,
                                icon: const Icon(Icons.chevron_right,
                                    color: Colors.black),
                                onPressed: (_pointMode ||
                                        _polygonMode ||
                                        _deleteMode ||
                                        _isTestRunning)
                                    ? null
                                    : () {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return TestFinishDialog(
                                                  onNext: () {
                                                Navigator.pop(context);
                                                _endTest();
                                              });
                                            });
                                      },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DisplayModalButton extends StatelessWidget {
  const DisplayModalButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.only(left: 15, right: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          iconColor: Colors.black,
          disabledBackgroundColor: disabledGrey,
        ),
        onPressed: onPressed,
        label: Text(text),
        icon: icon,
        iconAlignment: IconAlignment.end,
      ),
    );
  }
}

class WeatherDialog extends StatefulWidget {
  const WeatherDialog({super.key});

  @override
  State<WeatherDialog> createState() => _WeatherDialogState();
}

class _WeatherDialogState extends State<WeatherDialog> {
  WeatherData? weatherData;
  double? temperature;
  bool erroredTemp = false;
  bool erroredSelect = false;
  Map<WeatherType, bool> selectedMap = {
    for (final weather in WeatherType.values) weather: false
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(
            'Weather',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        spacing: 5,
        children: [
          Text(
            'Temperature',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Flexible(
                child: DialogTextBox(
                  textAlign: TextAlign.center,
                  inputFormatter: [
                    FilteringTextInputFormatter.allow(RegExp('[1234567890.-]'))
                  ],
                  keyboardType: TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  maxLength: 6,
                  labelText: 'Temp.',
                  onChanged: (inputText) {
                    setState(() {
                      erroredTemp = false;
                    });
                    temperature = double.tryParse(inputText);
                  },
                ),
              ),
              Flexible(
                  child: Text(
                '°F',
                style: TextStyle(fontSize: 14),
              ))
            ],
          ),
          erroredTemp
              ? Text(
                  "Please input a value!",
                  style: TextStyle(color: Colors.red[900]),
                )
              : SizedBox(),
          SizedBox(height: 30),
          Center(
            child: Text(
              "Type",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Row(
            spacing: 5,
            children: <Widget>[
              TestButton(
                buttonText: "Sunny",
                backgroundColor:
                    selectedMap[WeatherType.sunny] == true ? Colors.blue : null,
                onPressed: () {
                  setState(() {
                    erroredSelect = false;
                    selectedMap[WeatherType.sunny] =
                        !selectedMap[WeatherType.sunny]!;
                  });
                },
              ),
              TestButton(
                buttonText: "Rainy",
                backgroundColor:
                    selectedMap[WeatherType.rainy] == true ? Colors.blue : null,
                onPressed: () {
                  setState(() {
                    erroredSelect = false;
                    selectedMap[WeatherType.rainy] =
                        !selectedMap[WeatherType.rainy]!;
                  });
                },
              )
            ],
          ),
          Row(
            spacing: 5,
            children: <Widget>[
              TestButton(
                buttonText: "Windy",
                backgroundColor:
                    selectedMap[WeatherType.windy] == true ? Colors.blue : null,
                onPressed: () {
                  setState(() {
                    erroredSelect = false;
                    selectedMap[WeatherType.windy] =
                        !selectedMap[WeatherType.windy]!;
                  });
                },
              ),
              TestButton(
                buttonText: "Stormy",
                backgroundColor: selectedMap[WeatherType.stormy] == true
                    ? Colors.blue
                    : null,
                onPressed: () {
                  setState(() {
                    erroredSelect = false;
                    selectedMap[WeatherType.stormy] =
                        !selectedMap[WeatherType.stormy]!;
                  });
                },
              )
            ],
          ),
          Row(
            spacing: 5,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              TestButton(
                flex: 2,
                buttonText: "Cloudy",
                backgroundColor: selectedMap[WeatherType.cloudy] == true
                    ? Colors.blue
                    : null,
                onPressed: () {
                  setState(() {
                    erroredSelect = false;
                    selectedMap[WeatherType.cloudy] =
                        !selectedMap[WeatherType.cloudy]!;
                  });
                },
              ),
              Spacer(),
            ],
          ),
          erroredSelect
              ? Text(
                  "Please select a type!",
                  style: TextStyle(color: Colors.red[900]),
                )
              : SizedBox(),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            List<WeatherType> selectedWeather = [];
            for (WeatherType weatherType in selectedMap.keys) {
              if (selectedMap[weatherType] != null &&
                  selectedMap[weatherType] == true) {
                selectedWeather.add(weatherType);
              }
            }
            if (temperature == null) {
              setState(() {
                erroredTemp = true;
              });
            }
            print(erroredSelect);
            if (selectedWeather.isEmpty) {
              print("\n");
              setState(() {
                erroredSelect = true;
              });
            }
            if (erroredSelect || erroredTemp) {
              return;
            }
            weatherData = WeatherData(
                weatherTypes: selectedWeather.toSet(), temp: temperature!);
            Navigator.pop(context, weatherData);
            print('${weatherData!.weatherTypes} temp: $temperature');
          },
          child: const Text('Next'),
        ),
      ],
    );
  }
}
