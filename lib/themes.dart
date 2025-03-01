import 'package:flutter/material.dart';

// Color constants:
/// Default color used when test buttons are disabled.
const Color disabledGrey = Color(0xCD6C6C6C);

/// Transparency for test hint text (or, the directions at the top of the
/// test map screen).
const Color directionsTransparency = Color(0xDFDDE6F2);

/// Default yellow color, used mainly for text on blue gradient background.
const Color placeYellow = Color(0xFFFFD31F);

const LinearGradient defaultGrad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    Color(0xFF0A2A88),
    Color(0xFF62B6FF),
  ],
);

final LinearGradient verticalBlueGrad = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[
    Colors.blue[900]!,
    Colors.blueAccent,
  ],
);

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