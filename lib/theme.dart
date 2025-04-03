import 'package:flutter/material.dart';
import 'custom_material_colors.dart';

// Color constants:
/// Default color used when test buttons are disabled.
const Color disabledGrey = Color(0xCD6C6C6C);

/// Disabled button color with no transparency.
const Color disabledGreyAlt = Color(0xFF5A5A5A);

/// Transparency for test hint text (or, the directions at the top of the
/// test map screen).
const Color directionsTransparency = Color(0xDFDDE6F2);

/// Default yellow color, used mainly for text on blue gradient background.
const Color placeYellow = Color(0xFFFFD31F);

/// Primary blue color used across the app
final MaterialColor p2bpBlue = generateMaterialColor(const Color(0xFF2F6DCF));

/// Primary accent color, used for buttons on screens with default gradient background
final MaterialColor p2bpBlueAccent =
    generateMaterialColor(const Color(0xFF62B6FF));

/// Dark blue color used for default gradient
final MaterialColor p2bpDarkBlue =
    generateMaterialColor(const Color(0xFF0A2A88));

/// Primary yellow color used across the app
final MaterialColor p2bpYellow = generateMaterialColor(const Color(0xFFFFCC00));

/// Primary bottom sheet background color when a gradient is not used
final MaterialColor bottomSheetBlue =
    generateMaterialColor(const Color(0xFFDDE6F2));

final LinearGradient defaultGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    p2bpDarkBlue,
    p2bpBlueAccent,
  ],
);

final LinearGradient verticalBlueGrad = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[
    p2bpDarkBlue,
    p2bpBlueAccent,
  ],
);

const LinearGradient formGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFDDE6F2),
    Color(0xFFBACFEB),
  ],
);

/// Style for buttons on Test pages that are not toggleable
/// requiring custom conditional color values.
final ButtonStyle testButtonStyle = FilledButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 15),
  foregroundColor: Colors.black,
  backgroundColor: Color(0xFFE3EBF4),
  disabledBackgroundColor: Color(0xCD6C6C6C),
  iconColor: Colors.black,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
    side: BorderSide.none,
    // BorderSide(color: Color(0xFFB0C4DE), width: 2)
  ),
  textStyle: TextStyle(fontSize: 14),
);

class ChipLabelColor extends Color implements WidgetStateColor {
  const ChipLabelColor() : super(_default);

  static const int _default = 0xFF000000;

  @override
  Color resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return Colors.white;
    }
    return Colors.black;
  }
}

// List<ThemeData> appThemes = [
//   ThemeData(
//     //
//   ),
//
//   ThemeData(
//     //backgroundColor: Colors.grey,
//   ),
//
//   ThemeData(
//     //backgroundColor: Colors.grey,
//   ),
//
//   ThemeData(
//     //backgroundColor: Colors.grey,
//   ),
// ]

// GRADIENT: start = 0xFF0A2A88 end = 0x62B6FF  (top left to bottom right)
// Button color = 0xFFFFCC00
// TEXT COLOR = 0xFF333333
// TEXT LINK COLOR = 0xFFFFD700