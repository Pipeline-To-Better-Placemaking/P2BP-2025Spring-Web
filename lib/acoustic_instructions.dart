import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Widget acousticInstructions() {
  return RichText(
    text: TextSpan(
      style: TextStyle(fontSize: 16, color: Colors.black),
      children: [
        TextSpan(text: "1. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "Once you start the activity, you will be prompted to begin listening to the sounds of the surrounding area.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "2. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "After a set amount of time, you'll be asked to enter the decibel level and select the types of sounds you heard.\n"),
        TextSpan(text: "   • ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "There are 6 main types to choose from: Water, Traffic, People, Animals, Wind,and Music.\n"),
        TextSpan(text: "   • ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "You can also enter your own sound type if none of the six options apply.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "3. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "After entering your choices, you'll be asked to choose the main sound source from your selected options.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(
          text: "4. ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
            text:
                "Once you’ve submitted this data, a new interval will begin. This cycle repeats for a set number of intervals"
                " determined by the administrator.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(
          text: "5. ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
            text:
                "Upon submitting your data for the current cycle, you'll be prompted to move to the next standing point "
                "and repeat the process. This continues until you've completed all standing points on the map.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(
          text: "6. ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

Widget buildLegends() {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Define horizontal spacing between items:
      const double spacing = 16;
      // Calculate the width for each legend item so that 2 items per row fit:
      double itemWidth = (constraints.maxWidth - spacing) / 2;
      return Column(
        children: [
          Text(
            "What the Buttons Do:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              legendItem(
                  Icons.layers,
                  "Toggle Map View",
                  Color.fromARGB(255, 126, 173, 128).withValues(alpha: 0.9),
                  BoxShape.circle,
                  Border.all(color: Color(0xFF2D6040), width: 2),
                  Color(0xFF2D6040),
                  itemWidth),
              legendItem(
                  FontAwesomeIcons.info,
                  "Toggle Instructions",
                  Color.fromARGB(255, 186, 207, 235).withValues(alpha: 0.9),
                  BoxShape.circle,
                  Border.all(
                    color: Color(0xFF37597D),
                    width: 2,
                  ),
                  Color(0xFF37597D),
                  itemWidth),
            ],
          ),
        ],
      );
    },
  );
}

Widget legendItem(IconData icon, String label, Color buttonColor,
    BoxShape buttonShape, Border border, Color iconColor, double width) {
  return Container(
    width: width,
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: buttonShape,
            border: border,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 15,
              color: iconColor,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}

Widget activityColorsRow() {
  return Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      buildActivityColorItem("Standing", Color(0xFF4285f4)),
      buildActivityColorItem("Sitting", Color(0xFF28a745)),
      buildActivityColorItem("Laying Down", Color(0xFFc41484)),
      buildActivityColorItem("Squatting", Color(0xFF6f42c1)),
    ],
  );
}

Widget buildActivityColorItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 14)),
    ],
  );
}