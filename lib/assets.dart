import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'db_schema_classes.dart';

  final AssetMapBitmap catMarkerIcon = AssetMapBitmap(
    'assets/cat_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap dogMarkerIcon = AssetMapBitmap(
    'assets/dog_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap birdMarkerIcon = AssetMapBitmap(
    'assets/bird_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap duckMarkerIcon = AssetMapBitmap(
    'assets/duck_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap rabbitMarkerIcon = AssetMapBitmap(
    'assets/rabbit_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap squirrelMarkerIcon = AssetMapBitmap(
    'assets/squirrel_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap turtleMarkerIcon = AssetMapBitmap(
    'assets/turtle_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap otherAnimalMarker = AssetMapBitmap(
    'assets/other_marker.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap buildingMarkerIcon = AssetMapBitmap(
    'assets/building-light.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap rythimicMarkerIcon = AssetMapBitmap(
    'assets/rythimic-light.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap taskMarkerIcon = AssetMapBitmap(
    'assets/task-light.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap maintenanceMisconductMarkerIcon = AssetMapBitmap(
    'assets/maintenance-misconduct.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap behaviorMisconducttMarkerIcon = AssetMapBitmap(
    'assets/behavior-misconduct.png',
    width: 25,
    height: 25,
  );

  final AssetMapBitmap peopleMarkerIcon = AssetMapBitmap(
    'assets/people.png',
    width: 40,
    height: 40,
  );

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

  final Map<LightType, AssetMapBitmap> lightingProfileIconMap = {
    for (final light in LightType.values)
      light: AssetMapBitmap(
        light.iconName,
        width: 36,
        height: 36,
      )
  };

  final Map<MisconductType, AssetMapBitmap> absenceOfOrderIconMap = {
    for (final misconduct in MisconductType.values)
      misconduct: AssetMapBitmap(
        misconduct.iconName,
        width: 36,
        height: 36,
      )
  };

  final Map<AnimalType, AssetMapBitmap> naturePrevalenceAnimalIconMap = {
    for (final animal in AnimalType.values)
      animal: AssetMapBitmap(
        NaturePrevalenceTest.assetDirectoryPath + animal.iconName,
        width: 25,
        height: 25,
      )
  };

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