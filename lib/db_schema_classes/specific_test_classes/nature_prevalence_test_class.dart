import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import '../../assets.dart';
import '../../nature_prevalence_test.dart';
import '../misc_class_stuff.dart';
import '../test_class.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

/// Enum for Nature Types. Used in Nature Prevalence test. Types include
/// [vegetation], [waterBody], and [animal].
enum NatureType { vegetation, waterBody, animal }

/// Enum for types of vegetation. Used in Nature Prevalence test. Types include
/// [native], [design], [openField], and [other].
enum VegetationType {
  native(Color(0x6508AC12)),
  design(Color(0x656DFD75)),
  openField(Color(0x65C7FF80)),
  other(Color(0x6C00FF3C));

  const VegetationType(this.color);

  final Color color;
}

/// Enum for types of bodies of water. Used in Nature Prevalence test. Types
/// include [ocean], [lake], [river], and [swamp].
enum WaterBodyType {
  ocean(Color(0x651020FF)),
  lake(Color(0x652FB3DD)),
  river(Color(0x656253EA)),
  swamp(Color(0x65009595));

  const WaterBodyType(this.color);

  final Color color;
}

/// Enum for types of animals. Used in Nature Prevalence test. Types include
/// [cat], [dog], [squirrel], [bird], [rabbit], [turtle], [duck], and [other].
/// </br> [cat] and [dog] are domestic, [other] is its own type, and all other
/// defined types are wild.
enum AnimalType implements DisplayNameEnum {
  cat(
    designation: AnimalDesignation.domesticated,
    displayName: 'Cat',
    iconName: 'cat_marker.png',
  ),
  dog(
    designation: AnimalDesignation.domesticated,
    displayName: 'Dog',
    iconName: 'dog_marker.png',
  ),
  squirrel(
    designation: AnimalDesignation.wild,
    displayName: 'Squirrel',
    iconName: 'squirrel_marker.png',
  ),
  bird(
    designation: AnimalDesignation.wild,
    displayName: 'Bird',
    iconName: 'bird_marker.png',
  ),
  rabbit(
    designation: AnimalDesignation.wild,
    displayName: 'Rabbit',
    iconName: 'rabbit_marker.png',
  ),
  turtle(
    designation: AnimalDesignation.wild,
    displayName: 'Turtle',
    iconName: 'turtle_marker.png',
  ),
  duck(
    designation: AnimalDesignation.wild,
    displayName: 'Duck',
    iconName: 'duck_marker.png',
  ),
  other(
    designation: AnimalDesignation.other,
    displayName: 'Other',
    iconName: 'other_marker.png',
  );

  const AnimalType({
    required this.designation,
    required this.displayName,
    required this.iconName,
  });

  final AnimalDesignation designation;
  @override
  final String displayName;
  final String iconName;
}

/// The following designations are used to differentiate types of animals. They
/// include [domesticated], [wild], and [other]
enum AnimalDesignation { domesticated, wild, other }

/// Types of weather for Nature Prevalence. Types include [sunny], [cloudy],
/// [rainy], [windy], and [stormy].
enum WeatherType {
  sunny,
  cloudy,
  rainy,
  windy,
  stormy;

  const WeatherType();

  static Set<WeatherType> setFromJson(Map<String, dynamic> json) {
    if (json
        case {
          'cloudy': bool cloudy,
          'rainy': bool rainy,
          'stormy': bool stormy,
          'sunny': bool sunny,
          'windy': bool windy,
        }) {
      return <WeatherType>{
        if (cloudy) WeatherType.cloudy,
        if (rainy) WeatherType.rainy,
        if (stormy) WeatherType.stormy,
        if (sunny) WeatherType.sunny,
        if (windy) WeatherType.windy,
      };
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  static Map<String, bool> setToJson(Set<WeatherType> set) {
    return {
      for (final type in WeatherType.values) type.name: set.contains(type)
    };
  }
}

/// Class for weather in Nature Prevalence Test. Implements enum type
/// [weather].
class WeatherData with JsonToString {
  final Set<WeatherType> weatherTypes;
  final double temp;

  WeatherData({required this.weatherTypes, required this.temp});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'temperature': double temperature,
          'weatherTypes': Map<String, dynamic> weatherTypes,
        }) {
      return WeatherData(
        temp: temperature,
        weatherTypes: WeatherType.setFromJson(weatherTypes),
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'temperature': temp,
      'weatherTypes': WeatherType.setToJson(weatherTypes),
    };
  }
}

/// Class for vegetation in Nature Prevalence Test. Implements enum type
/// [vegetation].
class Vegetation with JsonToString {
  static const NatureType natureType = NatureType.vegetation;

  final VegetationType vegetationType;
  final String? otherName;
  final Polygon polygon;
  final double polygonArea;

  /// For all vegetation, other or not, otherType is required. If the
  /// vegetation is of a defined type (i.e. not other) then set otherType equal
  /// to [null].
  /// </br> A [null] otherType will be ignored in convertToFirestoreData().
  Vegetation({
    required this.vegetationType,
    required this.otherName,
    required this.polygon,
  }) : polygonArea = polygon.getAreaInSquareFeet();

  Vegetation.recreate({
    required this.vegetationType,
    required this.otherName,
    required this.polygon,
    required this.polygonArea,
  });

  factory Vegetation.fromJsonAndType(
      Map<String, dynamic> json, VegetationType vegetationType) {
    if (vegetationType == VegetationType.other) {
      if (json
          case {
            'polygon': List polygon,
            'polygonArea': double polygonArea,
            'name': String name,
          }) {
        final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
        return Vegetation.recreate(
          vegetationType: vegetationType,
          otherName: name,
          polygon: Polygon(
            polygonId: PolygonId(points.toString()),
            points: points,
            fillColor: vegetationType.color,
          ),
          polygonArea: polygonArea,
        );
      }
    } else {
      if (json
          case {
            'polygon': List polygon,
            'polygonArea': double polygonArea,
          }) {
        final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
        return Vegetation.recreate(
          vegetationType: vegetationType,
          otherName: null,
          polygon: Polygon(
            polygonId: PolygonId(points.toString()),
            points: points,
            fillColor: vegetationType.color,
          ),
          polygonArea: polygonArea,
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    if (vegetationType == VegetationType.other && otherName != null) {
      return {
        'name': otherName!,
        'polygon': polygon.toGeoPointList(),
        'polygonArea': polygonArea,
      };
    } else {
      return {
        'polygon': polygon.toGeoPointList(),
        'polygonArea': polygonArea,
      };
    }
  }
}

/// Class for bodies of water in Nature Prevalence Test. Implements enum type
/// [waterBody].
class WaterBody with JsonToString {
  static const NatureType natureType = NatureType.waterBody;

  final WaterBodyType waterBodyType;
  final Polygon polygon;
  final double polygonArea;

  WaterBody({required this.waterBodyType, required this.polygon})
      : polygonArea = polygon.getAreaInSquareFeet();

  WaterBody.recreate({
    required this.waterBodyType,
    required this.polygon,
    required this.polygonArea,
  });

  factory WaterBody.fromJsonAndType(
      Map<String, dynamic> json, WaterBodyType waterBodyType) {
    if (json
        case {
          'polygon': List polygon,
          'polygonArea': double polygonArea,
        }) {
      final List<LatLng> points = List<GeoPoint>.from(polygon).toLatLngList();
      return WaterBody.recreate(
        waterBodyType: waterBodyType,
        polygon: Polygon(
          polygonId: PolygonId(points.toString()),
          points: points,
          fillColor: waterBodyType.color,
        ),
        polygonArea: polygonArea,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'polygon': polygon.toGeoPointList(),
      'polygonArea': polygonArea,
    };
  }
}

/// Class for animals in Nature Prevalence Test. Implements enum type [animal].
class Animal {
  static const NatureType natureType = NatureType.animal;

  final AnimalType animalType;
  final String? otherName;
  final Marker marker;

  /// For all animals, other or not, otherType is required. If the animal is
  /// of a defined type (i.e. not other) then set otherType equal to [null].
  /// </br> A [null] otherType will be ignored in convertToFirestoreData().
  Animal({
    required this.animalType,
    required this.otherName,
    required this.marker,
  });

  /// Creates a marker in the standard way intended for an instance of [Animal]
  /// from given arguments.
  static Marker newMarker(LatLng location, AnimalType animalType,
      [String? name]) {
    if (animalType == AnimalType.other && name == null) {
      throw Exception(
          'Animal.newMarker was used with incompatible name and animalType.');
    }
    return Marker(
      markerId: MarkerId(location.toString()),
      position: location,
      consumeTapEvents: false,
      infoWindow: InfoWindow(
          title: name ?? animalType.displayName,
          snippet: '(${location.latitude.toStringAsFixed(5)}, '
              '${location.longitude.toStringAsFixed(5)})'),
      icon: naturePrevalenceAnimalIconMap[animalType]!,
    );
  }

  factory Animal.fromJsonAndType(Object json, AnimalType animalType) {
    if (animalType == AnimalType.other && json is Map<String, dynamic>) {
      if (json
          case {
            'name': String name,
            'point': GeoPoint point,
          }) {
        final LatLng location = point.toLatLng();
        return Animal(
          animalType: animalType,
          otherName: name,
          marker: newMarker(location, animalType, name),
        );
      }
    } else {
      if (json is GeoPoint) {
        final LatLng location = json.toLatLng();
        return Animal(
          animalType: animalType,
          otherName: null,
          marker: newMarker(location, animalType),
        );
      }
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  Object toJsonOrGeoPoint() {
    if (animalType == AnimalType.other && otherName != null) {
      return {
        'name': otherName!,
        'point': marker.position.toGeoPoint(),
      };
    } else {
      return marker.position.toGeoPoint();
    }
  }

  @override
  String toString() {
    return toJsonOrGeoPoint().toString();
  }
}

/// Containing class for Nature Prevalence Test.
///
/// Contains a list of objects corresponding to the Nature Prevalence Test
/// types ([Animal], [WaterBody], [Vegetation]). Also implements the
/// [convertToFirestoreData()], which returns a map that is able to be inputted
/// directly into Firestore.
class NaturePrevalenceData with JsonToString {
  final List<Animal> animals;
  final List<WaterBody> waterBodies;
  final List<Vegetation> vegetation;
  WeatherData? weather;

  NaturePrevalenceData({
    required this.animals,
    required this.waterBodies,
    required this.vegetation,
    this.weather,
  });

  NaturePrevalenceData.empty()
      : animals = [],
        waterBodies = [],
        vegetation = [];

  factory NaturePrevalenceData.fromJson(Map<String, dynamic> json) {
    final List<Animal> animalList = [];
    final List<Vegetation> vegetationList = [];
    final List<WaterBody> waterBodyList = [];
    WeatherData? weatherData;

    if (json
        case {
          'animal': Map<String, dynamic> animal,
          'vegetation': Map<String, dynamic> vegetation,
          'waterBody': Map<String, dynamic> waterBody,
          'weather': Map<String, dynamic> weather,
        }) {
      if (animal
          case {
            'domesticated': Map<String, dynamic> domesticated,
            'wild': Map<String, dynamic> wild,
            'other': List other,
          }) {
        if (domesticated
            case {
              'cat': List cats,
              'dog': List dogs,
            }) {
          for (final cat in cats) {
            animalList.add(Animal.fromJsonAndType(cat, AnimalType.cat));
          }
          for (final dog in dogs) {
            animalList.add(Animal.fromJsonAndType(dog, AnimalType.dog));
          }
        }

        if (wild
            case {
              'bird': List birds,
              'duck': List ducks,
              'rabbit': List rabbits,
              'squirrel': List squirrels,
              'turtle': List turtles,
            }) {
          for (final bird in birds) {
            animalList.add(Animal.fromJsonAndType(bird, AnimalType.bird));
          }
          for (final duck in ducks) {
            animalList.add(Animal.fromJsonAndType(duck, AnimalType.duck));
          }
          for (final rabbit in rabbits) {
            animalList.add(Animal.fromJsonAndType(rabbit, AnimalType.rabbit));
          }
          for (final squirrel in squirrels) {
            animalList
                .add(Animal.fromJsonAndType(squirrel, AnimalType.squirrel));
          }
          for (final turtle in turtles) {
            animalList.add(Animal.fromJsonAndType(turtle, AnimalType.turtle));
          }
        }

        for (final animal in other) {
          animalList.add(Animal.fromJsonAndType(animal, AnimalType.other));
        }
      }

      if (vegetation
          case {
            'design': List design,
            'native': List native,
            'openField': List openField,
            'other': List other,
          }) {
        if (design.isNotEmpty) {
          for (final veg in design) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.design));
          }
        }
        if (native.isNotEmpty) {
          for (final veg in native) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.native));
          }
        }
        if (openField.isNotEmpty) {
          for (final veg in openField) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.openField));
          }
        }
        if (other.isNotEmpty) {
          for (final veg in other) {
            vegetationList
                .add(Vegetation.fromJsonAndType(veg, VegetationType.other));
          }
        }
      }

      if (waterBody
          case {
            'lake': List lakes,
            'ocean': List oceans,
            'river': List rivers,
            'swamp': List swamps,
          }) {
        if (lakes.isNotEmpty) {
          for (final lake in lakes) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(lake, WaterBodyType.lake));
          }
        }
        if (oceans.isNotEmpty) {
          for (final ocean in oceans) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(ocean, WaterBodyType.ocean));
          }
        }
        if (rivers.isNotEmpty) {
          for (final river in rivers) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(river, WaterBodyType.river));
          }
        }
        if (swamps.isNotEmpty) {
          for (final swamp in swamps) {
            waterBodyList
                .add(WaterBody.fromJsonAndType(swamp, WaterBodyType.swamp));
          }
        }
      }

      if (weather.isNotEmpty) {
        weatherData = WeatherData.fromJson(weather);
      }

      return NaturePrevalenceData(
        animals: animalList,
        waterBodies: waterBodyList,
        vegetation: vegetationList,
        weather: weatherData,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    final List<AnimalDesignation> animalDesignations = AnimalDesignation.values;
    final List<AnimalType> animalTypes = AnimalType.values;
    final List<WaterBodyType> waterBodyTypes = WaterBodyType.values;
    final List<VegetationType> vegetationTypes = VegetationType.values;

    final Map<String, Map<String, dynamic>> json = {
      NatureType.animal.name: {
        for (final designation in animalDesignations)
          designation.name: (designation == AnimalDesignation.other)
              ? []
              : {
                  for (final type in animalTypes)
                    if (type.designation == designation) type.name: []
                }
      },
      NatureType.waterBody.name: {
        for (final type in waterBodyTypes) type.name: <Map>[]
      },
      NatureType.vegetation.name: {
        for (final type in vegetationTypes) type.name: <Map>[]
      },
      'weather': {},
    };

    for (final animal in animals) {
      if (animal.animalType == AnimalType.other) {
        json[NatureType.animal.name]![animal.animalType.designation.name]
            .add(animal.toJsonOrGeoPoint());
      } else {
        json[NatureType.animal.name]![animal.animalType.designation.name]
                [animal.animalType.name]
            .add(animal.toJsonOrGeoPoint());
      }
    }
    for (final waterBody in waterBodies) {
      json[NatureType.waterBody.name]![waterBody.waterBodyType.name]
          .add(waterBody.toJson());
    }
    for (final veg in vegetation) {
      json[NatureType.vegetation.name]![veg.vegetationType.name]
          .add(veg.toJson());
    }
    if (weather != null) {
      json['weather'] = weather!.toJson();
    }

    return json;
  }
}

/// Class for Nature Prevalence test info and methods.
class NaturePrevalenceTest extends Test<NaturePrevalenceData>
    with JsonToString
    implements TimerTest {
  /// Static constant definition of collection ID for this test type.
  static const String collectionIDStatic = 'nature_prevalence_tests';
  static const String displayName = 'Nature Prevalence';

  static const String assetDirectoryPath =
      'assets/test_specific/nature_prevalence/';

  static final CollectionReference<NaturePrevalenceTest> converterRef =
      _firestore
          .collection(collectionIDStatic)
          .withConverter<NaturePrevalenceTest>(
            fromFirestore: (snapshot, _) =>
                NaturePrevalenceTest.fromJson(snapshot.data()!),
            toFirestore: (test, _) => test.toJson(),
          );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Object?> get ref => converterRef.doc(id);

  /// User defined test timer duration in seconds.
  @override
  final int testDuration;

  /// Creates a new [NaturePrevalenceTest] instance from the given arguments.
  NaturePrevalenceTest._({
    required super.title,
    required super.id,
    required super.scheduledTime,
    required super.projectRef,
    required super.data,
    super.creationTime,
    super.maxResearchers,
    super.isComplete,
    required this.testDuration,
  }) : super();

  /// Registers this class within the Maps required by class [Test].
  static void register() {
    // Register for creating new Nature Prevalence Tests
    Test.newTestConstructors[collectionIDStatic] = ({
      required String title,
      required String id,
      required Timestamp scheduledTime,
      required DocumentReference projectRef,
      List? standingPoints,
      int? testDuration,
      int? intervalDuration,
      int? intervalCount,
    }) =>
        NaturePrevalenceTest._(
          title: title,
          id: id,
          scheduledTime: scheduledTime,
          projectRef: projectRef,
          data: NaturePrevalenceData.empty(),
          testDuration: testDuration ?? -1,
        );

    // Register for recreating a Nature Prevalence Test from Firestore
    Test.recreateTestConstructors[collectionIDStatic] = (testDoc) {
      return NaturePrevalenceTest.fromJson(testDoc.data()!);
    };

    // Register for building a Nature Prevalence Test page
    Test.pageBuilders[NaturePrevalenceTest] =
        (project, test) => NaturePrevalenceTestPage(
              activeProject: project,
              activeTest: test as NaturePrevalenceTest,
            );

    Test.testInitialsMap[NaturePrevalenceTest] = 'NP';
    Test.timerTestCollectionIDs.add(collectionIDStatic);
  }

  /// Submits data to Firestore for Nature Prevalence Test.
  ///
  /// Unlike other tests, this [submitData()] function (for
  /// [NaturePrevalenceTest]) takes in a [NaturePrevalenceData] type.
  @override
  void submitData(NaturePrevalenceData data) async {
    try {
      await _firestore.collection(collectionID).doc(id).update({
        'data': data.toJson(),
        'isComplete': true,
      });

      this.data = data;
      isComplete = true;

      print('Success! In NaturePrevalenceTest.submitData. data = $data');
    } catch (e, stacktrace) {
      print("Exception in NaturePrevalenceTest.submitData(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  factory NaturePrevalenceTest.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'title': String title,
          'id': String id,
          'scheduledTime': Timestamp scheduledTime,
          'project': DocumentReference project,
          'data': Map<String, dynamic> data,
          'creationTime': Timestamp creationTime,
          'maxResearchers': int maxResearchers,
          'isComplete': bool isComplete,
          'testDuration': int testDuration,
        }) {
      return NaturePrevalenceTest._(
        title: title,
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project,
        data: NaturePrevalenceData.fromJson(data),
        creationTime: creationTime,
        maxResearchers: maxResearchers,
        isComplete: isComplete,
        testDuration: testDuration,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'title': title,
      'id': id,
      'scheduledTime': scheduledTime,
      'project': projectRef,
      'data': data.toJson(),
      'creationTime': creationTime,
      'maxResearchers': maxResearchers,
      'isComplete': isComplete,
      'testDuration': testDuration,
    };
  }
}
