import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'db_schema_classes.dart';

final AssetMapBitmap tempMarkerIcon = AssetMapBitmap(
  'assets/temp_point_marker.png',
  width: 40,
  height: 40,
);
final AssetMapBitmap standingPointDisabledIcon = AssetMapBitmap(
  'assets/standing_point_disabled.png',
  width: 48,
  height: 48,
);
final AssetMapBitmap standingPointEnabledIcon = AssetMapBitmap(
  'assets/standing_point_enabled.png',
  width: 48,
  height: 48,
);
final AssetMapBitmap standingPointActiveIcon = AssetMapBitmap(
  'assets/standing_point_active.png',
  width: 48,
  height: 48,
);
final Map<(PostureType, GenderType), AssetMapBitmap> peopleInPlaceIconMap = {
  for (final posture in PostureType.values)
    for (final gender in GenderType.values)
      (posture, gender): AssetMapBitmap(
        'assets/test_specific/people_in_place/'
        '${posture.iconNameSegment}_${gender.iconNameSegment}_marker.png',
        width: 36,
        height: 36,
      )
};
final Map<ActivityTypeInMotion, AssetMapBitmap> peopleInMotionIconMap = {
  for (final value in ActivityTypeInMotion.values)
    value: AssetMapBitmap(value.iconName, width: 24, height: 24)
};