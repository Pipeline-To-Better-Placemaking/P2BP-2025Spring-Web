import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget peopleInPlaceInstructions() {
  return RichText(
    text: TextSpan(
      style: TextStyle(fontSize: 16, color: Colors.black),
      children: [
        TextSpan(text: "1. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "After starting the activity, tap the screen inside the boundary to begin placing data points.\n"),
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
                "After placing a point, a menu will appear that will allow you to classify the age, gender, activity type, "
                "and current posture of the person you are logging.\n"),
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
                "Once logged, this individual will be represented on the map via a color coded marker based on posture type.\n"),
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
        TextSpan(text: "Tapping the "),
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
                " button will bring up a menu displaying each logged point. Here, you can delete individual points or all points, "
                "or view the marker color legend.\n"),
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
                  "Recorded Points",
                  Color.fromARGB(255, 189, 159, 228).withValues(alpha: 0.9),
                  BoxShape.circle,
                  Border.all(color: Color(0xFF5A3E85), width: 2),
                  Color(0xFF5A3E85),
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