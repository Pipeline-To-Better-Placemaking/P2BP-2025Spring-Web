import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget spatialBoundariesInstructions() {
  return RichText(
    text: TextSpan(
      style: TextStyle(fontSize: 16, color: Colors.black),
      children: [
        TextSpan(text: "1. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "After starting the activity, select a boundary type: "),
        TextSpan(
            text: "Constructed", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: ", "),
        TextSpan(
            text: "Material", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: ", "),
        TextSpan(text: "or "),
        TextSpan(
            text: "Shelter.\n", style: TextStyle(fontWeight: FontWeight.bold)),
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
                "After choosing a boundary type, select the subtype that best fits the structure.\n"),
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
                "Once your selection is locked in, tap on the map to place points outlining your boundary shape.\n"),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text("– ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TextSpan(text: "Polygon: Minimum "),
        TextSpan(text: "3 ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "Points\n"),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text("– ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TextSpan(text: "Polyline: Minimum "),
        TextSpan(text: "2 ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "points.\n"),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text("– ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TextSpan(text: "Tap a point again to remove it.\n"),
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
        TextSpan(text: "When you're done outlining your boundary, tap "),
        TextSpan(
            text: "'Confirm Shape' ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "to save your boundary.\n"),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text("– ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        TextSpan(text: "If necessary, you can tap "),
        TextSpan(
            text: "'Cancel' ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: "to reset and start over.\n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(text: "5. ", style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text:
                "Confirmed shapes are color coded by boundary type; tap the "),
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
              child: Icon(Icons.shape_line_rounded,
                  size: 14, color: Color(0xFF5A3E85)),
            ),
          ),
        ),
        TextSpan(
            text:
                " button to see the color legend and/or delete any of your recorded boundaries if necessary.\n"),
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
        TextSpan(text: "Tap the "),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 207, 211, 217)
                  .withValues(alpha: 0.9),
              border: Border.all(color: Color(0xFF4A5D75), width: 2),
            ),
            child: Center(
              child: Icon(
                Icons.visibility_off,
                size: 15,
                color: Color(0xFF4A5D75),
              ),
            ),
          ),
        ),
        TextSpan(
            text:
                " button to toggle the visibility of boundaries already defined on the map. \n"),
        WidgetSpan(
          child: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 13), // Creates a small "half newline" effect
            child: SizedBox.shrink(), // Invisible spacing element
          ),
        ),
        TextSpan(
          text: "7. ",
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
                const Color.fromARGB(255, 126, 173, 128).withValues(alpha: 0.9),
                BoxShape.circle,
                Border.all(color: const Color(0xFF2D6040), width: 2),
                const Color(0xFF2D6040),
                itemWidth,
              ),
              legendItem(
                FontAwesomeIcons.info,
                "Toggle Instructions",
                const Color.fromARGB(255, 186, 207, 235).withValues(alpha: 0.9),
                BoxShape.circle,
                Border.all(
                  color: const Color(0xFF37597D),
                  width: 2,
                ),
                const Color(0xFF37597D),
                itemWidth,
              ),
              legendItem(
                Icons.shape_line_rounded,
                "Recorded Boundaries",
                const Color.fromARGB(255, 189, 159, 228).withValues(alpha: 0.9),
                BoxShape.circle,
                Border.all(color: const Color(0xFF5A3E85), width: 2),
                const Color(0xFF5A3E85),
                itemWidth,
              ),
              legendItem(
                Icons.visibility_off,
                "Toggle Visibility",
                const Color.fromARGB(255, 207, 211, 217),
                BoxShape.circle,
                Border.all(color: const Color(0xFF4A5D75), width: 2),
                const Color(0xFF4A5D75),
                itemWidth,
                iconSize: 18,
              ),
            ],
          ),
        ],
      );
    },
  );
}

Widget legendItem(IconData icon, String label, Color buttonColor,
    BoxShape buttonShape, Border border, Color iconColor, double width,
    {Offset iconOffset = Offset.zero, double iconSize = 15}) {
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
            child: Transform.translate(
              offset: iconOffset,
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor,
              ),
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