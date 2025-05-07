import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

import 'db_schema_classes/misc_class_stuff.dart';
import 'google_maps_functions.dart';

extension GeoPointConversion on GeoPoint {
  /// Takes a [GeoPoint] representation of a point and converts it to a
  /// [LatLng]. Returns that [LatLng].
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

extension LatLngConversion on LatLng {
  /// Takes a [LatLng] representation of a point and converts it to a
  /// [GeoPoint]. Returns that [GeoPoint].
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }

  mp.LatLng toMPLatLng() {
    return mp.LatLng(latitude, longitude);
  }
}

extension LatLngListConversion on List<LatLng> {
  /// Extension function on [List`<LatLng>`]. Converts the list to a list of
  /// [GeoPoint]s for storing in Firestore. Returns the [List`<GeoPoint>`].
  List<GeoPoint> toGeoPointList() {
    List<GeoPoint> newGeoPointList = [];
    forEach((coordinate) {
      newGeoPointList.add(GeoPoint(coordinate.latitude, coordinate.longitude));
    });
    return newGeoPointList;
  }

  List<mp.LatLng> toMPLatLng() {
    List<mp.LatLng> newMPLatLngList = [];
    forEach((point) =>
        newMPLatLngList.add(mp.LatLng(point.latitude, point.longitude)));
    return newMPLatLngList;
  }
}

extension GeoPointListConversion on List<GeoPoint> {
  /// Extension function on [List]`<`[GeoPoint]`>`. Converts the list to a list
  /// of [LatLng]s for use locally in application. Returns the
  /// [List]`<`[LatLng]`>`.
  List<LatLng> toLatLngList() {
    List<LatLng> newLatLngList = [];
    forEach((coordinate) {
      newLatLngList.add(LatLng(coordinate.latitude, coordinate.longitude));
    });
    return newLatLngList;
  }
}

extension PolygonHelpers on Polygon {
  /// Extension function on [Polygon]. Takes a [Polygon] and converts it to a
  /// list of [GeoPoint]s for Firestore storing. Returns the
  /// [List]`<`[GeoPoint]`>`.
  List<GeoPoint> toGeoPointList() {
    List<GeoPoint> geoPointRepresentation = [];
    if (points.isEmpty) return geoPointRepresentation;
    for (var point in points) {
      geoPointRepresentation.add(GeoPoint(point.latitude, point.longitude));
    }
    return geoPointRepresentation;
  }

  /// Extension function on [Polygon]. Takes a [Polygon] and converts it to a
  /// list of [mp.LatLng]s for maps toolkit functions. Returns the
  /// [List]`<`[mp.LatLng]`>`.
  List<mp.LatLng> toMPLatLngList() {
    List<mp.LatLng> latLngRepresentation = [];
    if (points.isEmpty) return latLngRepresentation;
    for (var point in points) {
      latLngRepresentation.add(mp.LatLng(point.latitude, point.longitude));
    }
    return latLngRepresentation;
  }

  /// Returns the area covered by this polygon in square feet.
  double getAreaInSquareFeet() {
    return (mp.SphericalUtil.computeArea(toMPLatLngList()) *
            pow(feetPerMeter, 2))
        .toDouble();
  }
}

extension PolylineHelpers on Polyline {
  /// Extension function on [Polyline]. Takes a [Polyline] and converts it to a
  /// list of [GeoPoint]s for Firestore storing. Returns the
  /// [List]`<`[GeoPoint]`>`.
  List<GeoPoint> toGeoPointList() {
    List<GeoPoint> geoPointRepresentation = [];
    if (points.isEmpty) return geoPointRepresentation;
    for (var point in points) {
      geoPointRepresentation.add(GeoPoint(point.latitude, point.longitude));
    }
    return geoPointRepresentation;
  }

  /// Extension function on [Polyline]. Takes a [Polyline] and converts it to a
  /// list of [mp.LatLng]s for maps toolkit functions. Returns the
  /// [List]`<`[mp.LatLng]`>`.
  List<mp.LatLng> toMPLatLngList() {
    List<mp.LatLng> latLngRepresentation = [];
    if (points.isEmpty) return latLngRepresentation;
    for (var point in points) {
      latLngRepresentation.add(mp.LatLng(point.latitude, point.longitude));
    }
    return latLngRepresentation;
  }

  /// Returns the length of this polyline in feet.
  double getLengthInFeet() {
    return (mp.SphericalUtil.computeLength(toMPLatLngList()) * feetPerMeter)
        .toDouble();
  }
}

extension DynamicLatLngExtraction on List<dynamic> {
  /// Extension function on [List]`<`[dynamic]`>`. Takes any objects of type
  /// [GeoPoint] out of the list, converts them to [LatLng], and returns a new
  /// [List]`<`[LatLng]`>`. Primarily used when Firestore returns a
  /// [List]`<`[dynamic]`>`, to extract the coordinates for further use.
  List<LatLng> toLatLngList() {
    List<LatLng> newLatLngList = [];
    forEach((coordinate) {
      if (coordinate.runtimeType == GeoPoint) {
        newLatLngList.add(LatLng(coordinate.latitude, coordinate.longitude));
      }
      if (coordinate.runtimeType == LatLng) {
        newLatLngList.add(coordinate);
      }
    });
    return newLatLngList;
  }
}

extension EnumToName<E extends Enum> on Map<E, Object?> {
  Map<String, Object?> keysEnumToName() {
    return {for (final key in keys) key.name: this[key]};
  }
}

extension RoleMapSimplify<T> on RoleMap<T> {
  List<T> toSingleList() {
    return [for (final role in GroupRole.values) ...?this[role]];
  }
}
