import 'package:flutter/material.dart';

/// Returns a tinted color (lighter version) of the [color] by the given [factor].
/// [factor] should be between 0 (no change) and 1 (white).
Color tintColor(Color color, double factor) {
  // Convert normalized components to 0-255 ints.
  final int red = (color.r * 255).round();
  final int green = (color.g * 255).round();
  final int blue = (color.b * 255).round();
  return Color.fromRGBO(
    red + ((255 - red) * factor).round(),
    green + ((255 - green) * factor).round(),
    blue + ((255 - blue) * factor).round(),
    1,
  );
}

/// Returns a shaded color (darker version) of the [color] by the given [factor].
/// [factor] should be between 0 (no change) and 1 (black).
Color shadeColor(Color color, double factor) {
  final int red = (color.r * 255).round();
  final int green = (color.g * 255).round();
  final int blue = (color.b * 255).round();
  return Color.fromRGBO(
    (red * (1 - factor)).round(),
    (green * (1 - factor)).round(),
    (blue * (1 - factor)).round(),
    1,
  );
}

/// Extension method to convert a Color to a 32-bit ARGB integer.
extension ColorExtensions on Color {
  int toARGB32() {
    final int aInt = (a * 255).round() & 0xff;
    final int rInt = (r * 255).round() & 0xff;
    final int gInt = (g * 255).round() & 0xff;
    final int bInt = (b * 255).round() & 0xff;
    return (aInt << 24) | (rInt << 16) | (gInt << 8) | bInt;
  }
}

/// Generates a MaterialColor based on the [baseColor].
MaterialColor generateMaterialColor(Color baseColor) {
  return MaterialColor(
    baseColor.toARGB32(),
    <int, Color>{
      50: tintColor(baseColor, 0.9),
      100: tintColor(baseColor, 0.8),
      200: tintColor(baseColor, 0.6),
      300: tintColor(baseColor, 0.4),
      400: tintColor(baseColor, 0.2),
      500: baseColor,
      600: shadeColor(baseColor, 0.1),
      700: shadeColor(baseColor, 0.2),
      800: shadeColor(baseColor, 0.3),
      900: shadeColor(baseColor, 0.4),
    },
  );
}