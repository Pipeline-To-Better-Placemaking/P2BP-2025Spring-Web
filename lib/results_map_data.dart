import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

class VisualizedResults {
  bool isVisible;
  String testID;
  String collectionID;
  String testName;
  Set<Marker> markers;
  Set<Polyline> polylines;
  Set<Polygon> polygons;

  VisualizedResults({
    required this.testID,
    required this.collectionID,
    required this.testName,
    this.isVisible = false,
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
  });

  /// Factory constructor to create a TestMapData object from Firebase
  static Future<VisualizedResults> fromFirebase(String testID, String collectionID, Map<String, dynamic> data) async {
    
    String collectionName = collectionID.split('/').first;
    //var polygonData = <List<LatLng>>[];
    List<List<LatLng>> additionalPolygonData = [];
    Set<Polygon> polygonsWithColor = {};
    List<dynamic> vegetationPolygonData = [];
    List<dynamic> waterBodyPolygonData = [];
    List<dynamic> materialPolygonData = [];
    List<dynamic> shelterPolygonData = [];

    Set<Polyline> polylinesWithColor = {};

    if (collectionName == "nature_prevalence_tests")
    {
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
      vegetationPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(designData, collectionName));
      vegetationPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(nativeData, collectionName));
      vegetationPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(openFieldData, collectionName));
      vegetationPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(otherVegetationData, collectionName));

      // Collect additional polygon data from water bodies (lake, ocean, river, swamp)
      waterBodyPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(lakeData, collectionName));
      waterBodyPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(oceanData, collectionName));
      waterBodyPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(riverData, collectionName));
      waterBodyPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(swampData, collectionName));

      polygonsWithColor.addAll(_parsePolygons(vegetationPolygonData, testID, collectionName, "vegetation"));
      polygonsWithColor.addAll(_parsePolygons(waterBodyPolygonData, testID, collectionName, "waterBody"));
    }
    else if (collectionName == "identifying_access_tests")
    {
      var parkingData = data['data']?['parking'];
      additionalPolygonData.addAll(_extractPolygonsFromDataIdentifyingAccessTests(parkingData, collectionName));
      polygonsWithColor.addAll(_parsePolygons(additionalPolygonData, testID, collectionName, "black"));
    }
    else if (collectionName == "spatial_boundaries_tests")
    {
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
      materialPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(concreteData, collectionName));
      materialPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(deckingData, collectionName));
      materialPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(naturalData, collectionName));
      materialPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(paversData, collectionName));
      materialPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(tileData, collectionName));

      /// Shelter
      shelterPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(canopyData, collectionName));
      shelterPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(constructedData, collectionName));
      shelterPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(furnitureData, collectionName));
      shelterPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(temporaryData, collectionName));
      shelterPolygonData.addAll(_extractPolygonsFromDataNaturePrevalenceTests(treeData, collectionName));

      polygonsWithColor.addAll(_parsePolygons(materialPolygonData, testID, collectionName, "material"));
      polygonsWithColor.addAll(_parsePolygons(shelterPolygonData, testID, collectionName, "shelter"));
    }

    // **Fetch polylines from Firebase based on the collectionIDs**
    List<Map<String, dynamic>> fetchedPolylines = [];

    // Fetch polylines for the Identifying Access Tests collection
    if (collectionName == "identifying_access_tests") {
      fetchedPolylines = await loadPathsFromFirebaseIdentifyingAccessTests(testID, collectionName);
      polylinesWithColor.addAll(_parsePolylines(fetchedPolylines, collectionName, "red"));
    } 
    // Fetch polylines for the Spatial Boundaries Tests collection
    else if (collectionName == "spatial_boundaries_tests") {
      fetchedPolylines = await loadPathsFromFirebaseSpatialBoundariesTests(testID, collectionName);
      polylinesWithColor.addAll(_parsePolylines(fetchedPolylines, collectionName, "brown"));
    }
    // Fetch polylines for the People in Motion tests collection
    else if (collectionName == "people_in_motion_tests")
    {
      fetchedPolylines = await loadPathsFromFirebasePeopleInMotionTests(testID, collectionName);
      polylinesWithColor.addAll(_parsePolylines(fetchedPolylines, collectionName, "indigo"));
    }

    return VisualizedResults(
      testID: testID,
      collectionID: collectionID,
      testName: data['title'],
      markers: _parseMarkers([
        /// Absence of Order Test
        /// Extracting behaviorPoints
        ...(data['data']?['behaviorPoints'] as List<dynamic>? ?? []).map((behaviorPoint) {
          var location = behaviorPoint?['location'];
          if (location != null) {
            return LatLng(location.latitude, location.longitude);
          }
          return null;
        }).whereType<LatLng>(),

        /// Extracting maintenancePoints
        ...(data['data']?['maintenancePoints'] as List<dynamic>? ?? []).map((maintenancePoint) {
          var location = maintenancePoint?['location'];
          if (location != null) {
            return LatLng(location.latitude, location.longitude);
          }
          return null;
        }).whereType<LatLng>(),

        /// Acoustic Profile Test
        /// Extract standingPoint from dataPoints
        ...(data['data']?['dataPoints'] as List<dynamic>? ?? []).map((standingPoint) {
          var location = standingPoint?['standingPoint']?['point'];
          if (location != null) {
            return LatLng(location.latitude, location.longitude);
          }
          return null;
        }).whereType<LatLng>(),

        /// People in Place Test
        /// Extracting standingPoints
        ...(data['data']?['persons'] as List<dynamic>? ?? []).map((standingPoint) {
          var location = standingPoint?['location'];
          if (location != null) {
            return LatLng(location.latitude, location.longitude);
          }
          return null;
        }).whereType<LatLng>(),

        /// Lighting Profile Test
        ...(data['data']?['building'] as List<dynamic>? ?? []),
        ...(data['data']?['rhythmic'] as List<dynamic>? ?? []),
        ...(data['data']?['task'] as List<dynamic>? ?? []),

        /// For Domesticated Animals (cat, dog, other)
        ...(data['data']?['animal']?['domesticated']?['cat'] is List ? 
            (data['data']?['animal']?['domesticated']?['cat'] as List)
                .map((point) {
                  return LatLng(point.latitude, point.longitude);
                }).toList() : []),

        ...(data['data']?['animal']?['domesticated']?['dog'] is List ? 
            (data['data']?['animal']?['domesticated']?['dog'] as List)
                .map((point) {
                  return LatLng(point.latitude, point.longitude);
                }).toList() : []),

        ...(data['data']?['animal']?['domesticated']?['other'] is List ? 
            (data['data']?['animal']?['domesticated']?['other'] as List)
                .map((point) {
                  return LatLng(point['point'].latitude, point['point'].longitude);
                }).toList() : []),

        /// For Wild Animals (bird, duck, rabbit, squirrel, turtle)
        ...(data['data']?['animal']?['wild']?['bird'] is List ? 
            (data['data']?['animal']?['wild']?['bird'] as List)
                .map((point) {
                  return LatLng(point.latitude, point.longitude);
                }).toList() : []),

        ...(data['data']?['animal']?['wild']?['duck'] is List ? 
            (data['data']?['animal']?['wild']?['duck'] as List)
                .map((point) {
                  return LatLng(point.latitude, point.longitude);
                }).toList() : []),

        ...(data['data']?['animal']?['wild']?['rabbit'] is List ? 
            (data['data']?['animal']?['wild']?['rabbit'] as List)
                .map((point) {
                  return LatLng(point.latitude, point.longitude);
                }).toList() : []),

        ...(data['data']?['animal']?['wild']?['squirrel'] is List ? 
            (data['data']?['animal']?['wild']?['squirrel'] as List)
                .map((point) {
                  return LatLng(point.latitude, point.longitude);
                }).toList() : []),

        ...(data['data']?['animal']?['wild']?['turtle'] is List ? 
            (data['data']?['animal']?['wild']?['turtle'] as List)
                .map((point) {
                  return LatLng(point.latitude, point.longitude);
                }).toList() : []),
      ]),
      polylines:polylinesWithColor,
      polygons: polygonsWithColor,
    );
  }

  /// Generic marker parsing function
  static Set<Marker> _parseMarkers(List<dynamic> markersData) {
    Set<Marker> resultMarkers = {};
    final random = Random(); // Create a random instance outside the loop
    for (var marker in markersData) {
        final randomId = random.nextInt(1000000); // Generate a random number for each marker

        resultMarkers.add(Marker(
           markerId: MarkerId("${marker.latitude}_${marker.longitude}_$randomId"),
          position: LatLng(marker.latitude, marker.longitude),
        ));
    }
    return resultMarkers;
  }

  /// Generic polyline parsing function
  static Set<Polyline> _parsePolylines(List<dynamic> polylinesData, String collectionName, String polylineColor) {
    return polylinesData.map((polyline) {
      List<LatLng> points = (polyline['points'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList();
      
      Color color = Color(0xFF000000);

      if (collectionName == "identifying_access_tests" && polylineColor == "red")
      {
        color = Color.fromARGB(255, 255, 0, 0); // Solid Redcolor = Color;
      }
      else if (collectionName == "spatial_boundaries_tests" && polylineColor == "brown")
      {
        color = Color.fromARGB(255, 139, 69, 19); // Solid Brown
      }
      else if (collectionName == "people_in_motion_tests" && polylineColor == "indigo")
      {
        color = Color.fromARGB(255, 149, 0, 255); // Solid Indigo
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
  static Future<List<Map<String, dynamic>>> loadPathsFromFirebaseIdentifyingAccessTests(String testID, String collectionName) async {
    List<Map<String, dynamic>> polylinesData = [];

    try {
      // Fetch the specific document by testID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('identifying_access_tests')
          .doc(testID) // Use the testID to fetch the specific document
          .get();

      if (!snapshot.exists) {
        //print("No document found for testID: $testID");
        return polylinesData; // Return empty list if no document is found
      }

      Map<String, dynamic> polylineData = snapshot.data() as Map<String, dynamic>;

      //print('Document Data: $polylineData');

      // Handle different categories (bikeRack, parking, etc.)
      var categories = ['bikeRack', 'parking', 'taxiAndRideShare', 'transportStation']; // Add other categories as needed
      for (var category in categories) {
        var categoryData = polylineData['data']?[category];
        if (categoryData != null && categoryData is List) {
          // Loop through each path in this category
          for (var pathData in categoryData) {
            var pathInfo = pathData['pathInfo'];
            if (pathInfo is String) {
              try {
                // If it's a string, attempt to decode it as JSON
                pathInfo = json.decode(pathInfo);
                print('Decoded pathInfo for $category: $pathInfo');
              } catch (e) {
                print('Error decoding pathInfo string for $category: $e');
              }
            }

            if (pathInfo is Map<String, dynamic>) {
              List<Map<String, double>> points = (pathInfo['path'] as List).map((point) {
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
                  'id': "${snapshot.id}_${category}_${pathData['category']}_${categoryData.indexOf(pathData)}_$randomId", // Unique ID for each path
                  'testType': collectionName,
                  'category': category,
                  'categoryLabel': pathData['category'] ?? 'unknown',
                  'points': uniquePoints, // Use the deduplicated points
                });
              }
            } else {
              //print('Unexpected pathInfo format for $category: $pathInfo');
            }
          }
        } else {
          //print('No data found for category: $category');
        }
      }
    } catch (e) {
      print("Error loading paths: $e");
    }

    return polylinesData;
  }

  /// Spatial Boundaries Test
  /// For getting polylines
  static Future<List<Map<String, dynamic>>> loadPathsFromFirebaseSpatialBoundariesTests(String testID, String collectionName) async {
    List<Map<String, dynamic>> polylinesData = [];

    try {
      // Fetch the specific document by testID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('spatial_boundaries_tests')
          .doc(testID) // Use the testID to fetch the specific document
          .get();

      if (!snapshot.exists) {
        //print("No document found for testID: $testID");
        return polylinesData; // Return empty list if no document is found
      }

      Map<String, dynamic> polylineData = snapshot.data() as Map<String, dynamic>;

      //print('Document Data: $polylineData');

      // Handle different categories (bikeRack, parking, etc.)
      var categories = ['buildingWall', 'curb', 'fench', 'partialWall', 'planter']; // Add other categories as needed
      for (var category in categories) {
        var categoryData = polylineData['data']?['constructed']?[category];
        if (categoryData != null && categoryData is List) {
          // Loop through each path in this category
          for (var pathData in categoryData) {
            var pathInfo = pathData;
            if (pathInfo is String) {
              try {
                // If it's a string, attempt to decode it as JSON
                pathInfo = json.decode(pathInfo);
                print('Decoded pathInfo for $category: $pathInfo');
              } catch (e) {
                print('Error decoding pathInfo string for $category: $e');
              }
            }

            if (pathInfo is Map<String, dynamic>) {
              List<Map<String, double>> points = (pathInfo['polyline'] as List).map((point) {
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
                  'id': "${snapshot.id}_${category}_${pathData['category']}_${categoryData.indexOf(pathData)}_$randomId", // Unique ID for each path
                  'category': category,
                  'categoryLabel': pathData['category'] ?? 'unknown',
                  'points': uniquePoints, // Use the deduplicated points
                });
              }
            } else {
              //print('Unexpected pathInfo format for $category: $pathInfo');
            }
          }
        } else {
          //print('No data found for category: $category');
        }
      }
    } catch (e) {
      print("Error loading paths: $e");
    }

    return polylinesData;
  }

  /// People In Motion Test
  /// For getting polylines
  static Future<List<Map<String, dynamic>>> loadPathsFromFirebasePeopleInMotionTests(String testID, String collectionName) async {
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

      Map<String, dynamic> polylineData = snapshot.data() as Map<String, dynamic>;

      // Categories of paths
      var categories = ['activityOnWheels', 'handicapAssistedWheels', 'running', 'swimming', 'walking']; // Add other categories as needed
      for (var category in categories) {
        var categoryData = polylineData['data']?[category];
        if (categoryData != null && categoryData is List) {
          // If it's a list, iterate over the items
          for (var pathData in categoryData) {
            var pathInfo = pathData;
            
            // Check if polyline is a string (and decode if needed)
            if (pathInfo is String) {
              try {
                pathInfo = json.decode(pathInfo);
              } catch (e) {
                print('Error decoding polyline string: $e');
              }
            }

            // If pathInfo is a valid Map, process the polyline
            if (pathInfo is Map<String, dynamic>) {
              List<Map<String, double>> points = (pathInfo['polyline'] as List).map((point) {
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
                  'id': "${snapshot.id}_${category}_${pathData['category']}_${categoryData.indexOf(pathData)}_$randomId", // Unique ID for each path
                  'category': category,
                  'categoryLabel': pathData['category'] ?? 'unknown',
                  'points': uniquePoints, // Use the deduplicated points
                });
              }
            } else {
              //print('Unexpected pathInfo format for $category: $pathInfo');
            }
          }
        } else {
          //print('No data found for category: $category');
        }
      }
    } catch (e) {
      print("Error loading paths: $e");
    }

    return polylinesData;
  }

  /// Helper method to extract polygons from various categories (e.g., native, lake, etc.)
  /// Nature Prevalence Test for Polygons
  static List<List<LatLng>> _extractPolygonsFromDataNaturePrevalenceTests(dynamic data, String collectionName) {
    List<List<LatLng>> polygonData = [];

    if (data != null && data is List) {
      for (var item in data) {
        if (item['polygon'] != null && item['polygon'] is List) {
          polygonData.add(List<LatLng>.from(item['polygon'].map((point) {
            if (point is GeoPoint) {
              return LatLng(point.latitude, point.longitude); // Convert to LatLng
            }
            return null;
          }).whereType<LatLng>()));
        }
      }
    }
    
    return polygonData;
  }

  /// Identifying Access Test for Polygons
  static List<List<LatLng>> _extractPolygonsFromDataIdentifyingAccessTests(dynamic data, String collectionName) {
    List<List<LatLng>> polygonData = [];

    if (data != null && data is List) {
      for (var item in data) {
        if (item['polygonInfo']?['polygon'] != null && item['polygonInfo']?['polygon'] is List) {
          polygonData.add(List<LatLng>.from(item['polygonInfo']?['polygon'].map((point) {
            if (point is GeoPoint) {
              return LatLng(point.latitude, point.longitude); // Convert to LatLng
            }
            return null;
          }).whereType<LatLng>()));
        }
        
      }
    }
    
    return polygonData;
  }

  /// Generic parsing Polygon function
  static Set<Polygon> _parsePolygons(List<dynamic> polygonData, String testID, String collectionName, String polygonColor) {
    Set<Polygon> polygons = <Polygon>{};

    Color strokeColor = Color(0xFF000000);
    Color fillColor = Color.fromRGBO(0, 0, 0, 0.2);

    if (polygonData.isNotEmpty) {
      for (var item in polygonData) {
        // Check if the item is a List of LatLng
        if (item is List<LatLng>) {
          //print("Raw item (LatLng list): $item");
          // Generate a unique polygon ID using testID, timestamp, randomness, and polygons.length
          String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          String randomId = Random().nextInt(1000000).toString();

          // Assign colors based on category
          if (collectionName == "nature_prevalence_tests" && polygonColor == "vegetation") 
          {
            if (polygonColor == "vegetation")
            {
              strokeColor = Color.fromRGBO(0, 255, 123, 1);
              fillColor = Color.fromRGBO(0, 255, 0, 0.2);
            }
            else if (polygonColor == "waterBody")
            {
              strokeColor = Color.fromRGBO(0, 0, 70, 1); // Dark blue
              fillColor = Color.fromRGBO(0, 0, 255, 0.2); // Light blue with 20% opacity
            }
          } 
          else if (collectionName == "spatial_boundaries_tests") 
          {
            if (polygonColor == "material")
            {
              strokeColor = Color.fromARGB(255, 128, 0, 128); // Standard Purple
              fillColor = Color.fromARGB(50, 128, 0, 128);  // Transparent Purple Fill
            }
            else if (polygonColor == "shelter")
            {
              strokeColor = Color.fromARGB(255, 204, 85, 0); // Deep Burnt Orange
              fillColor = Color.fromARGB(50, 204, 85, 0);  // Lighter Transparent Burnt Orange
            }
          }
          else if (collectionName == "identifying_access_tests")
          {
            strokeColor = Color.fromARGB(255, 168, 253, 1);
            fillColor = Color.fromRGBO(0, 0, 0, 0.2);
          }
          polygons.add(Polygon(
            polygonId: PolygonId("polygon_${collectionName}_${testID}_${timestamp}_${randomId}_${polygons.length}"),
            points: item,
            strokeColor: strokeColor,  // Red color
            fillColor: fillColor,  // Red with 20% opacity
            strokeWidth: 5,  // Set the stroke width (adjust as needed)
          ));
        }
      }
    }

    return polygons;
  }
}
