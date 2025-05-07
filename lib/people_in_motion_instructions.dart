import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget peopleInMotionInstructions() {
  return RichText(
    text: TextSpan(
      style: TextStyle(fontSize: 16, color: Colors.black),
      children: [
        TextSpan(text: "1. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "Tap the "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF9800).withValues(alpha: 0.9),
              border: Border.all(color: Color(0xFF8C2F00), width: 2),
            ),
            child: Center(
              child: Icon(FontAwesomeIcons.pen,
                  size: 14, color: Color(0xFF8C2F00)),
            ),
          ),
        ),
        TextSpan(
          text:
              " button to begin tracing points along the route. After each consecutive point placed, a gray line will automatically appear to connect them.\n",
        ),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "2. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "While tracing, a menu will appear with two options:\n"),
        // Bullet point for Cancel
        TextSpan(text: "   • "),
        TextSpan(text: "If you make a mistake, tap "),
        TextSpan(
            text: "Cancel ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "to clear your current path and start over.\n"),
        // Bullet point for Confirm
        TextSpan(text: "   • "),
        TextSpan(text: "If you're done tracing, tap "),
        TextSpan(
          text: "Confirm ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(
            text: "to store the route and assign an activity type to it.\n"),
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
                "Confirmed routes are color coded by activity type; tap the "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBD9FE4).withValues(alpha: 0.9),
              border: Border.all(color: Color(0xFF5A3E85), width: 2),
            ),
            child: Center(
              child: Icon(FontAwesomeIcons.locationDot,
                  size: 14, color: Color(0xFF5A3E85)),
            ),
          ),
        ),
        TextSpan(
            text:
                " button to see the color legend and view your recorded routes.\n"),
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
            text: "If you finish before the activity period ends, tap the "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 32,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "End",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        TextSpan(
            text:
                " button to conclude the activity and save all recorded data.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "Note: ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "Once a path is confirmed, it "),
        TextSpan(
            text: "cannot ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "be edited.")
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
              legendItem(
                  FontAwesomeIcons.locationDot,
                  "Recorded Routes",
                  Color.fromARGB(255, 189, 159, 228).withValues(alpha: 0.9),
                  BoxShape.circle,
                  Border.all(color: Color(0xFF5A3E85), width: 2),
                  Color(0xFF5A3E85),
                  itemWidth),
              legendItem(
                  FontAwesomeIcons.pen,
                  "Tracing Mode",
                  Color(0xFFFF9800).withValues(alpha: 0.9),
                  BoxShape.circle,
                  Border.all(color: Color(0xFF8C2F00), width: 2),
                  Color(0xFF8C2F00),
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
  return SizedBox(
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