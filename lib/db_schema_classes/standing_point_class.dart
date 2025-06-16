import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/extensions.dart';

import 'misc_class_stuff.dart';

class StandingPoint with JsonToString {
  late final LatLng location;
  late final String title;

  StandingPoint({required this.location, required this.title});

  factory StandingPoint.fromJson(Map<String, dynamic> data) {
    if (data
        case {
          'point': GeoPoint location,
          'title': String title,
        }) {
      return StandingPoint(location: location.toLatLng(), title: title);
    }
    throw FormatException('Invalid JSON: $data', data);
  }

  @override
  Map<String, Object> toJson() {
    return {
      'point': location.toGeoPoint(),
      'title': title,
    };
  }

  static List<StandingPoint> fromJsonList(List points) {
    List<StandingPoint> output = [];
    for (final point in points) {
      if (point is Map<String, dynamic>) {
        output.add(StandingPoint.fromJson(point));
      }
    }
    return output;
  }
}

extension StandingPointListHelpers on List<StandingPoint> {
  List<Map<String, Object>> toJsonList() {
    return [for (final point in this) point.toJson()];
  }
}
