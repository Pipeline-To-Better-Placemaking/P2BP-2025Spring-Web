import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'assets.dart';
import 'package:uuid/uuid.dart';

class VisualizedResults {
  bool isVisible;
  bool isComplete;
  String testID;
  String collectionID;
  String testName;
  DateTime scheduledTime;

  Set<Marker> markers;
  Set<Polyline> polylines;
  Set<Polygon> polygons;
  Set<Circle> soundCircle;

  VisualizedResults({
    required this.testID,
    required this.collectionID,
    required this.testName,
    required this.scheduledTime, // Default value
    this.isVisible = false,
    this.isComplete = false,
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.soundCircle = const {},
  });

  /// Factory constructor to create a TestMapData object from Firebase
  static Future<VisualizedResults> fromFirebase(
      String testID, String collectionID, Map<String, dynamic> data) async {
    String collectionName = collectionID.split('/').first;
    //var polygonData = <List<LatLng>>[];
    List<List<LatLng>> additionalPolygonData = [];
    Set<Polygon> polygonsWithColor = {};
    List<dynamic> vegetationPolygonData = [];
    List<dynamic> waterBodyPolygonData = [];
    List<dynamic> materialPolygonData = [];
    List<dynamic> shelterPolygonData = [];

    Set<Polyline> polylinesWithColor = {};
    Set<Marker> markerIcons = {};
    Set<Circle> soundCircle = {};

    if (collectionName == "nature_prevalence_tests") {
      // Extract polygon data from the nested 'design' array
      var designData = data['data']?['vegetation']?['design'];
      var nativeData = data['data']?['vegetation']?['native'];
      var openFieldData = data['data']?['vegetation']?['openField'];
      var otherVegetationData = data['data']?['vegetation']?['other'];

      // Extract water body data
      var lakeData = data['data']?['waterBody']?['lake'];
      var oceanData = data['data']?['waterBody']?['ocean'];
      var riverData = data['data']?['waterBody']?['river'];
      var swampData = data['data']?['waterBody']?['swamp'];

      // Collect additional polygon data from native, openField, and other vegetation
      vegetationPolygonData
          .addAll(_extractPolygonsFromData(designData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          vegetationPolygonData, testID, collectionName, "design"));

      vegetationPolygonData
          .addAll(_extractPolygonsFromData(nativeData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          vegetationPolygonData, testID, collectionName, "native"));

      vegetationPolygonData
          .addAll(_extractPolygonsFromData(openFieldData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          vegetationPolygonData, testID, collectionName, "openField"));

      vegetationPolygonData.addAll(
          _extractPolygonsFromData(otherVegetationData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          vegetationPolygonData, testID, collectionName, "otherVegetation"));

      // Collect additional polygon data from water bodies (lake, ocean, river, swamp)
      waterBodyPolygonData
          .addAll(_extractPolygonsFromData(lakeData, collectionName));
      polygonsWithColor.addAll(
          _parsePolygons(waterBodyPolygonData, testID, collectionName, "lake"));

      waterBodyPolygonData
          .addAll(_extractPolygonsFromData(oceanData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          waterBodyPolygonData, testID, collectionName, "ocean"));

      waterBodyPolygonData
          .addAll(_extractPolygonsFromData(riverData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          waterBodyPolygonData, testID, collectionName, "river"));

      waterBodyPolygonData
          .addAll(_extractPolygonsFromData(swampData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          waterBodyPolygonData, testID, collectionName, "swamp"));
    } else if (collectionName == "identifying_access_tests") {
      var parkingData = data['data']?['parking'];
      additionalPolygonData.addAll(
          _extractPolygonsFromDataIdentifyingAccessTests(
              parkingData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(
          additionalPolygonData, testID, collectionName, "parking"));
    } else if (collectionName == "spatial_boundaries_tests") {
      /// Materials
      var concreteData = data['data']?['material']?['concrete'];
      var deckingData = data['data']?['material']?['decking'];
      var naturalData = data['data']?['material']?['natural'];
      var paversData = data['data']?['material']?['pavers'];
      var tileData = data['data']?['material']?['tile'];

      /// Shelter
      var canopyData = data['data']?['shelter']?['canopy'];
      var constructedData = data['data']?['shelter']?['constructed'];
      var furnitureData = data['data']?['shelter']?['furniture'];
      var temporaryData = data['data']?['shelter']?['temporary'];
      var treeData = data['data']?['shelter']?['tree'];

      /// Materials
      materialPolygonData
          .addAll(_extractPolygonsFromData(concreteData, collectionName));
      materialPolygonData
          .addAll(_extractPolygonsFromData(deckingData, collectionName));
      materialPolygonData
          .addAll(_extractPolygonsFromData(naturalData, collectionName));
      materialPolygonData
          .addAll(_extractPolygonsFromData(paversData, collectionName));
      materialPolygonData
          .addAll(_extractPolygonsFromData(tileData, collectionName));

      /// Shelter
      shelterPolygonData
          .addAll(_extractPolygonsFromData(canopyData, collectionName));
      shelterPolygonData
          .addAll(_extractPolygonsFromData(constructedData, collectionName));
      shelterPolygonData
          .addAll(_extractPolygonsFromData(furnitureData, collectionName));
      shelterPolygonData
          .addAll(_extractPolygonsFromData(temporaryData, collectionName));
      shelterPolygonData
          .addAll(_extractPolygonsFromData(treeData, collectionName));

      polygonsWithColor.addAll(_parsePolygons(
          materialPolygonData, testID, collectionName, "material"));
      polygonsWithColor.addAll(_parsePolygons(
          shelterPolygonData, testID, collectionName, "shelter"));
    }

    // **Fetch polylines from Firebase based on the collectionIDs**
    List<Map<String, dynamic>> fetchedPolylines = [];

    // Fetch polylines for the Identifying Access Tests collection
    if (collectionName == "identifying_access_tests") {
      fetchedPolylines = await loadPathsFromFirebaseIdentifyingAccessTests(
          testID, collectionName);
      polylinesWithColor
          .addAll(_parsePolylines(fetchedPolylines, collectionName, "black"));
    }
    // Fetch polylines for the Spatial Boundaries Tests collection
    else if (collectionName == "spatial_boundaries_tests") {
      fetchedPolylines = await loadPathsFromFirebaseSpatialBoundariesTests(
          testID, collectionName);
      polylinesWithColor.addAll(
          _parsePolylines(fetchedPolylines, collectionName, "constructed"));
    }
    // Fetch polylines for the People in Motion tests collection
    else if (collectionName == "people_in_motion_tests") {
      fetchedPolylines = await loadPathsFromFirebasePeopleInMotionTests(
          testID, collectionName, "activityOnWheels");
      polylinesWithColor.addAll(_parsePolylines(
          fetchedPolylines, collectionName, "activityOnWheels"));

      fetchedPolylines = await loadPathsFromFirebasePeopleInMotionTests(
          testID, collectionName, "handicapAssistedWheels");
      polylinesWithColor.addAll(_parsePolylines(
          fetchedPolylines, collectionName, "handicapAssistedWheels"));

      fetchedPolylines = await loadPathsFromFirebasePeopleInMotionTests(
          testID, collectionName, "running");
      polylinesWithColor
          .addAll(_parsePolylines(fetchedPolylines, collectionName, "running"));

      fetchedPolylines = await loadPathsFromFirebasePeopleInMotionTests(
          testID, collectionName, "swimming");
      polylinesWithColor.addAll(
          _parsePolylines(fetchedPolylines, collectionName, "swimming"));

      fetchedPolylines = await loadPathsFromFirebasePeopleInMotionTests(
          testID, collectionName, "walking");
      polylinesWithColor
          .addAll(_parsePolylines(fetchedPolylines, collectionName, "walking"));
    } else if (collectionName == "section_cutter_tests") {
      fetchedPolylines =
          await loadPathsFromFirebaseSectionCutterTests(testID, collectionName);
      polylinesWithColor
          .addAll(_parsePolylines(fetchedPolylines, collectionName, "section"));
    }

    /// Fetching markers with its own unique icons on the map being displayed
    /// Absence of Order Test
    if (collectionName == "absence_of_order_tests") {
      print("Absence");

      /// Extracting behaviorPoints
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['behavior'] as List<dynamic>? ?? [])
            .map((behaviorPoint) {
          var location = behaviorPoint?['location'];
          if (location != null) {
            return LatLng(location.latitude, location.longitude);
          }
          return null;
        }).whereType<LatLng>(),
      ], "behavior"));

      /// Extracting maintenancePoints
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['maintenance'] as List<dynamic>? ?? [])
            .map((maintenancePoint) {
          var location = maintenancePoint?['location'];
          if (location != null) {
            return LatLng(location.latitude, location.longitude);
          }
          return null;
        }).whereType<LatLng>()
      ], "maintenance"));
    }

    /// Acoustic Profile Test
    else if (collectionName == "acoustic_profile_tests") {
      /// Extracting the location of where the test is being done
      soundCircle.addAll(_parseSoundCircle(
          [...(data['data']?['dataPoints'] as List<dynamic>? ?? [])]));
    }

    /// People in Place test
    else if (collectionName == "people_in_place_tests") {
      /// Extracting the location of the place the test happens
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['persons'] as List<dynamic>? ?? [])
            .map((standingPoint) {
          var location = standingPoint?['location'];
          if (location != null) {
            return LatLng(location.latitude, location.longitude);
          }
          return null;
        }).whereType<LatLng>()
      ], "people"));
    }

    /// Lighting Profile Test
    else if (collectionName == "lighting_profile_tests") {
      /// Extracting building, rhythmic, and task data
      markerIcons.addAll(_parseMarkers(
          [...(data['data']?['building'] as List<dynamic>? ?? [])],
          "building"));
      markerIcons.addAll(_parseMarkers(
          [...(data['data']?['rhythmic'] as List<dynamic>? ?? [])],
          "rhythmic"));
      markerIcons.addAll(_parseMarkers(
          [...(data['data']?['task'] as List<dynamic>? ?? [])], "task"));
    }

    /// Nature Prevalence Test
    else if (collectionName == "nature_prevalence_tests") {
      /// Extracting domesticated animal data points
      /// Extracting cat data point
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['domesticated']?['cat'] is List
            ? (data['data']?['animal']?['domesticated']?['cat'] as List)
                .map((point) {
                return LatLng(point.latitude, point.longitude);
              }).toList()
            : [])
      ], "cat"));

      /// Extracting dog data point
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['domesticated']?['dog'] is List
            ? (data['data']?['animal']?['domesticated']?['dog'] as List)
                .map((point) {
                return LatLng(point.latitude, point.longitude);
              }).toList()
            : [])
      ], "dog"));

      /// Extracting other data point
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['domesticated']?['other'] is List
            ? (data['data']?['animal']?['domesticated']?['other'] as List)
                .map((point) {
                return LatLng(
                    point['point'].latitude, point['point'].longitude);
              }).toList()
            : []),
      ], "other"));

      /// Extracting Wild Animal data points
      /// Extracting bird data points
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['wild']?['bird'] is List
            ? (data['data']?['animal']?['wild']?['bird'] as List).map((point) {
                return LatLng(point.latitude, point.longitude);
              }).toList()
            : [])
      ], "bird"));

      /// Extracting duck data points
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['wild']?['duck'] is List
            ? (data['data']?['animal']?['wild']?['duck'] as List).map((point) {
                return LatLng(point.latitude, point.longitude);
              }).toList()
            : [])
      ], "duck"));

      /// Extracting rabbit data points
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['wild']?['rabbit'] is List
            ? (data['data']?['animal']?['wild']?['rabbit'] as List)
                .map((point) {
                return LatLng(point.latitude, point.longitude);
              }).toList()
            : [])
      ], "rabbit"));

      /// Extracting squirrel data points
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['wild']?['squirrel'] is List
            ? (data['data']?['animal']?['wild']?['squirrel'] as List)
                .map((point) {
                return LatLng(point.latitude, point.longitude);
              }).toList()
            : [])
      ], "squirrel"));
      markerIcons.addAll(_parseMarkers([
        ...(data['data']?['animal']?['wild']?['turtle'] is List
            ? (data['data']?['animal']?['wild']?['turtle'] as List)
                .map((point) {
                return LatLng(point.latitude, point.longitude);
              }).toList()
            : [])
      ], "turtle"));
    }

    return VisualizedResults(
      testID: testID,
      collectionID: collectionID,
      testName: data['title'],
      isComplete: data['isComplete'] ?? false,
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate() ??
          DateTime(1970, 1, 1), // Convert Firestore Timestamp to DateTime
      markers: markerIcons,
      polylines: polylinesWithColor,
      polygons: polygonsWithColor,
      soundCircle: soundCircle,
    );
  }

  /// Generic marker parsing function
  static Set<Marker> _parseMarkers(List<dynamic> markersData, String icon) {
    BitmapDescriptor markerIcon =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    Set<Marker> resultMarkers = {};

    /// To get the correct asset for each tests to help identify what each point means
    switch (icon) {
      case 'behavior':
        markerIcon = behaviorMisconducttMarkerIcon;
        break;
      case 'maintenance':
        markerIcon = maintenanceMisconductMarkerIcon;
        break;
      case 'acoustic':
        markerIcon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        break;
      case 'people':
        markerIcon = peopleMarkerIcon;
        break;
      case 'building':
        markerIcon = buildingMarkerIcon;
        break;
      case 'rhythmic':
        markerIcon = rythimicMarkerIcon;
        break;
      case 'task':
        markerIcon = taskMarkerIcon;
        break;
      case 'cat':
        markerIcon = catMarkerIcon;
        break;
      case 'dog':
        markerIcon = dogMarkerIcon;
        break;
      case 'other':
        markerIcon = otherAnimalMarker;
        break;
      case 'bird':
        markerIcon = birdMarkerIcon;
        break;
      case 'duck':
        markerIcon = duckMarkerIcon;
        break;
      case 'rabbit':
        markerIcon = rabbitMarkerIcon;
        break;
      case 'squirrel':
        markerIcon = squirrelMarkerIcon;
        break;
      case 'turtle':
        markerIcon = turtleMarkerIcon;
        break;
    }

    final random = Random(); // Create a random instance outside the loop
    for (var marker in markersData) {
      final randomId =
          random.nextInt(1000000); // Generate a random number for each marker

      resultMarkers.add(Marker(
        markerId: MarkerId(
            "${marker.latitude}_${marker.longitude}_${icon}_$randomId"),
        position: LatLng(marker.latitude, marker.longitude),
        icon: markerIcon,
      ));
    }
    return resultMarkers;
  }

  static Set<Circle> _parseSoundCircle(List<dynamic> soundData) {
    Set<Circle> soundCircles = {};
    Map<String, int> locationCounts = {}; // To track overlapping locations
    var uuid = Uuid(); // Create an instance of Uuid

    for (var dataPoint in soundData) {
      var location = dataPoint?['standingPoint']?['point'];
      var measurements = dataPoint?['measurements'] as List<dynamic>? ?? [];

      if (location == null || measurements.isEmpty) continue;

      // Compute average decibel level
      double totalDecibels = 0;
      Map<String, int> soundTypeCounts = {};

      for (var measurement in measurements) {
        var decibels = measurement['decibels'] as num?;
        var mainSoundType = measurement['mainSoundType'] as String?;

        if (decibels != null) {
          totalDecibels += decibels;
        }

        if (mainSoundType != null) {
          soundTypeCounts[mainSoundType] =
              (soundTypeCounts[mainSoundType] ?? 0) + 1;
        }
      }

      double avgDecibels = totalDecibels / measurements.length;

      // Determine the most common mainSoundType
      String dominantSound = soundTypeCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Assign color based on dominant sound type
      Color soundColor = _getSoundTypeColor(dominantSound);

      // Track how many circles exist at this location
      String locationKey = "${location.latitude},${location.longitude}";
      int index = locationCounts[locationKey] ?? 0;
      locationCounts[locationKey] = index + 1;

      // Increase opacity for each additional overlapping circle
      double opacityFactor =
          (0.2 + (index * 0.1)).clamp(0, 1); // Min 20%, max 100%

      // Instead of soundColor.red, soundColor.green, soundColor.blue
      Color fillColor = Color.fromARGB(
        (opacityFactor * 255).toInt(), // Calculate opacity based on the factor
        0, // Red channel (0 for no color)
        0, // Green channel (0 for no color)
        0, // Blue channel (0 for no color)
      );

      // Create a circle with a random CircleId
      soundCircles.add(
        Circle(
          circleId:
              CircleId(uuid.v4()), // Use uuid.v4() to generate a random ID
          center: LatLng(location.latitude, location.longitude),
          radius: avgDecibels * 3, // Example scaling factor
          fillColor: fillColor,
          strokeWidth: 4,
          strokeColor: soundColor,
        ),
      );
    }

    return soundCircles;
  }

  static Color _getSoundTypeColor(String soundType) {
    switch (soundType.toLowerCase()) {
      case "wind":
        return Colors.blue;
      case "traffic":
        return Colors.red;
      case "people":
        return Colors.green;
      case "music":
        return Colors.purple;
      case "other":
        return Colors.grey;
      default:
        return Colors.black; // Fallback color
    }
  }

  /// Generic polyline parsing function
  static Set<Polyline> _parsePolylines(List<dynamic> polylinesData,
      String collectionName, String polylineColor) {
    return polylinesData.map((polyline) {
      List<LatLng> points = (polyline['points'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList();

      Color color = Color(0xFF000000);

      switch (polylineColor) {
        case 'black':
          color = Color.fromARGB(255, 0, 0, 0); // Black
          break;
        case 'constructed':
          color = Color.fromARGB(255, 224, 64, 251);
          break;
        case 'activityOnWheels':
          color = Colors.orange;
          break;
        case 'running':
          color = Colors.red;
          break;
        case 'swimming':
          color = Colors.cyan;
          break;
        case 'walking':
          color = Colors.teal;
          break;
        case 'handicapAssistedWheels':
          color = Colors.purple;
          break;
        case 'section':
          color = Colors.green;
          break;
      }

      return Polyline(
        polylineId: PolylineId(polyline['id']),
        points: points, // List of LatLng points
        color: color, // Set a color for the polyline
        width: 3, // Set the width of the polyline
      );
    }).toSet();
  }

  /// Identifying Access Tests
  /// For getting polylines
  static Future<List<Map<String, dynamic>>>
      loadPathsFromFirebaseIdentifyingAccessTests(
          String testID, String collectionName) async {
    List<Map<String, dynamic>> polylinesData = [];

    try {
      // Fetch the specific document by testID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('identifying_access_tests')
          .doc(testID) // Use the testID to fetch the specific document
          .get();

      if (!snapshot.exists) {
        return polylinesData; // Return empty list if no document is found
      }

      Map<String, dynamic> polylineData =
          snapshot.data() as Map<String, dynamic>;

      // Handle different categories (bikeRack, parking, etc.)
      var categories = [
        'bikeRack',
        'parking',
        'taxiAndRideShare',
        'transportStation'
      ]; // Add other categories as needed
      for (var category in categories) {
        var categoryData = polylineData['data']?[category];
        if (categoryData != null && categoryData is List) {
          // Loop through each path in this category
          for (var pathData in categoryData) {
            var pathInfo = pathData['pathInfo'];

            if (pathInfo is Map<String, dynamic>) {
              List<Map<String, double>> points =
                  (pathInfo['path'] as List).map((point) {
                if (point is GeoPoint) {
                  return {'lat': point.latitude, 'lng': point.longitude};
                }
                return {'lat': 0.0, 'lng': 0.0}; // Handle invalid points
              }).toList();

              // Remove duplicates from points
              List<Map<String, double>> uniquePoints = points.toSet().toList();

              if (uniquePoints.isNotEmpty) {
                // Generate a random ID
                String randomId = Random().nextInt(1000000).toString();

                // Generate unique ID with random ID
                polylinesData.add({
                  'id':
                      "${snapshot.id}_${category}_${pathData['category']}_${categoryData.indexOf(pathData)}_$randomId", // Unique ID for each path
                  'testType': collectionName,
                  'category': category,
                  'categoryLabel': pathData['category'] ?? 'unknown',
                  'points': uniquePoints, // Use the deduplicated points
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error loading paths: $e");
    }

    return polylinesData;
  }

  /// Spatial Boundaries Test
  /// For getting polylines
  static Future<List<Map<String, dynamic>>>
      loadPathsFromFirebaseSpatialBoundariesTests(
          String testID, String collectionName) async {
    List<Map<String, dynamic>> polylinesData = [];

    try {
      // Fetch the specific document by testID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('spatial_boundaries_tests')
          .doc(testID) // Use the testID to fetch the specific document
          .get();

      if (!snapshot.exists) {
        return polylinesData; // Return empty list if no document is found
      }

      Map<String, dynamic> polylineData =
          snapshot.data() as Map<String, dynamic>;

      // Handle different categories (bikeRack, parking, etc.)
      var categories = [
        'buildingWall',
        'curb',
        'fence',
        'partialWall',
        'planter'
      ]; // Add other categories as needed
      for (var category in categories) {
        var categoryData = polylineData['data']?['constructed']?[category];
        if (categoryData != null && categoryData is List) {
          // Loop through each path in this category
          for (var pathData in categoryData) {
            var pathInfo = pathData;

            if (pathInfo is Map<String, dynamic>) {
              List<Map<String, double>> points =
                  (pathInfo['polyline'] as List).map((point) {
                if (point is GeoPoint) {
                  return {'lat': point.latitude, 'lng': point.longitude};
                }
                return {'lat': 0.0, 'lng': 0.0}; // Handle invalid points
              }).toList();

              // Remove duplicates from points
              List<Map<String, double>> uniquePoints = points.toSet().toList();

              if (uniquePoints.isNotEmpty) {
                // Generate a random ID
                String randomId = Random().nextInt(1000000).toString();

                // Generate unique ID with random ID
                polylinesData.add({
                  'id':
                      "${snapshot.id}_${category}_${pathData['category']}_${categoryData.indexOf(pathData)}_$randomId", // Unique ID for each path
                  'category': category,
                  'categoryLabel': pathData['category'] ?? 'unknown',
                  'points': uniquePoints, // Use the deduplicated points
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error loading paths: $e");
    }

    return polylinesData;
  }

  /// People In Motion Test
  /// For getting polylines
  static Future<List<Map<String, dynamic>>>
      loadPathsFromFirebasePeopleInMotionTests(
          String testID, String collectionName, String category) async {
    List<Map<String, dynamic>> polylinesData = [];

    try {
      // Fetch the specific document by testID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('people_in_motion_tests')
          .doc(testID) // Use the testID to fetch the specific document
          .get();

      if (!snapshot.exists) {
        // No document found for testID
        return polylinesData; // Return empty list if no document is found
      }

      Map<String, dynamic> polylineData =
          snapshot.data() as Map<String, dynamic>;

      // Categories of paths
      var categoryData = polylineData['data']?[category];
      if (categoryData != null && categoryData is List) {
        // If it's a list, iterate over the items
        for (var pathData in categoryData) {
          var pathInfo = pathData;

          // If pathInfo is a valid Map, process the polyline
          if (pathInfo is Map<String, dynamic>) {
            List<Map<String, double>> points =
                (pathInfo['polyline'] as List).map((point) {
              if (point is GeoPoint) {
                return {'lat': point.latitude, 'lng': point.longitude};
              }
              return {'lat': 0.0, 'lng': 0.0}; // Handle invalid points
            }).toList();

            // Remove duplicates from points
            List<Map<String, double>> uniquePoints = points.toSet().toList();

            if (uniquePoints.isNotEmpty) {
              // Generate a random ID
              String randomId = Random().nextInt(1000000).toString();

              // Generate unique ID with random ID
              polylinesData.add({
                'id':
                    "${snapshot.id}_${category}_${pathData['category']}_${categoryData.indexOf(pathData)}_$randomId", // Unique ID for each path
                'category': category,
                'categoryLabel': pathData['category'] ?? 'unknown',
                'points': uniquePoints, // Use the deduplicated points
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error loading paths: $e");
    }

    return polylinesData;
  }

  /// Section Cutter Test
  /// For getting the section line
  static Future<List<Map<String, dynamic>>>
      loadPathsFromFirebaseSectionCutterTests(
          String testID, String collectionName) async {
    List<Map<String, dynamic>> polylinesData = [];

    try {
      // Fetch the specific document by testID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('section_cutter_tests')
          .doc(testID)
          .get();

      if (!snapshot.exists) {
        // No document found for testID
        return polylinesData; // Return empty list if no document is found
      }

      Map<String, dynamic> polylineData =
          snapshot.data() as Map<String, dynamic>;

      // Extract linePoints (which is now a simple list of GeoPoints)
      var linePoints = polylineData['linePoints'];
      if (linePoints != null && linePoints is List) {
        List<Map<String, double>> points = linePoints.map((point) {
          if (point is GeoPoint) {
            return {'lat': point.latitude, 'lng': point.longitude};
          }
          return {'lat': 0.0, 'lng': 0.0}; // Handle invalid points
        }).toList();

        // Remove duplicates from points
        List<Map<String, double>> uniquePoints = points.toSet().toList();

        if (uniquePoints.isNotEmpty) {
          // Generate a random ID
          String randomId = Random().nextInt(1000000).toString();

          polylinesData.add({
            'id': "${snapshot.id}_$randomId",
            'points': uniquePoints, // Use the deduplicated points
          });
        }
      }
    } catch (e) {
      print("Error loading paths: $e");
    }

    return polylinesData;
  }

  /// Helper method to extract polygons from various categories (e.g., native, lake, etc.)
  /// Nature Prevalence Test/Spatial Boundaries Test for Polygons
  static List<List<LatLng>> _extractPolygonsFromData(
      dynamic data, String collectionName) {
    List<List<LatLng>> polygonData = [];

    if (data != null && data is List) {
      for (var item in data) {
        if (item['polygon'] != null && item['polygon'] is List) {
          polygonData.add(List<LatLng>.from(item['polygon'].map((point) {
            if (point is GeoPoint) {
              return LatLng(
                  point.latitude, point.longitude); // Convert to LatLng
            }
            return null;
          }).whereType<LatLng>()));
        }
      }
    }

    return polygonData;
  }

  /// Identifying Access Test for Polygons
  static List<List<LatLng>> _extractPolygonsFromDataIdentifyingAccessTests(
      dynamic data, String collectionName) {
    List<List<LatLng>> polygonData = [];

    if (data != null && data is List) {
      for (var item in data) {
        if (item['polygonInfo']?['polygon'] != null &&
            item['polygonInfo']?['polygon'] is List) {
          polygonData.add(
              List<LatLng>.from(item['polygonInfo']?['polygon'].map((point) {
            if (point is GeoPoint) {
              return LatLng(
                  point.latitude, point.longitude); // Convert to LatLng
            }
            return null;
          }).whereType<LatLng>()));
        }
      }
    }

    return polygonData;
  }

  /// Generic parsing Polygon function
  static Set<Polygon> _parsePolygons(List<dynamic> polygonData, String testID,
      String collectionName, String polygonColor) {
    Set<Polygon> polygons = <Polygon>{};

    Color strokeColor = Color(0xFF000000);
    Color fillColor = Color.fromRGBO(0, 0, 0, 0.2);

    /// Assign colors based on category
    switch (polygonColor) {
      case 'design':
        strokeColor = Color.fromARGB(101, 109, 253, 117);
        fillColor = Color.fromARGB(51, 109, 253, 117);
        break;
      case 'native':
        strokeColor = Color.fromARGB(101, 8, 172, 18);
        fillColor = Color.fromARGB(51, 8, 172, 18);
        break;
      case 'openField':
        strokeColor = Color.fromARGB(101, 199, 255, 128);
        fillColor = Color.fromARGB(51, 199, 255, 128);
        break;
      case 'otherVegetation':
        strokeColor = Color.fromARGB(108, 0, 255, 60);
        fillColor = Color.fromARGB(51, 0, 255, 60);
      case 'ocean':
        strokeColor = Color.fromARGB(101, 16, 32, 255);
        fillColor = Color.fromARGB(51, 16, 32, 255);
      case 'river':
        strokeColor = Color.fromARGB(101, 98, 83, 234);
        fillColor = Color.fromARGB(51, 98, 83, 234);
      case 'lake':
        strokeColor = Color.fromARGB(101, 47, 179, 221);
        fillColor = Color.fromARGB(51, 47, 179, 221);
      case 'swamp':
        strokeColor = Color.fromARGB(101, 0, 149, 149);
        fillColor = Color.fromARGB(51, 0, 149, 149);
      case 'parking':
        strokeColor = Color.fromARGB(255, 0, 0, 0);
        fillColor = Color.fromARGB(51, 0, 0, 0);
      case 'material':
        strokeColor = Color.fromARGB(255, 0, 137, 123);
        fillColor = Color.fromARGB(51, 0, 137, 123);
      case 'shelter':
        strokeColor = Color.fromARGB(255, 245, 124, 0);
        fillColor = Color.fromARGB(51, 245, 124, 0);
    }

    if (polygonData.isNotEmpty) {
      for (var item in polygonData) {
        // Check if the item is a List of LatLng
        if (item is List<LatLng>) {
          // Generate a unique polygon ID using testID, timestamp, randomness, and polygons.length
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          String randomId = Random().nextInt(1000000).toString();

          polygons.add(Polygon(
            polygonId: PolygonId(
                "polygon_${collectionName}_${testID}_${polygonColor}_${timestamp}_${randomId}_${polygons.length}"),
            points: item,
            strokeColor: strokeColor,
            fillColor: fillColor,
            strokeWidth: 5, // Set the stroke width (adjust as needed)
          ));
        }
      }
    }

    return polygons;
  }
}
