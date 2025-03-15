import 'package:flutter/material.dart';

LinearGradient defaultGrad = const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    Color(0xFF0A2A88),
    Color(0xFF62B6FF),
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

// Floating bottom navigation bar to be invoked with every page that has a navigation bar.
class BottomFloatingNavBar extends StatelessWidget {
  const BottomFloatingNavBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 20, left: 10, right: 10),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(
            Radius.circular(50.0),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(50.0),
          ),
          child: BottomNavigationBar(
            // TODO: Fix colors
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.blue,
            selectedItemColor: Colors.yellow,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                backgroundColor: Colors.blue,
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                backgroundColor: Colors.blue,
                // TODO: which icon?
                icon: Icon(Icons.short_text),
                label: 'Projects',
              ),
              BottomNavigationBarItem(
                backgroundColor: Colors.blue,
                icon: Icon(Icons.add_circle_outline),
                label: 'Add Project or Team',
              ),
              BottomNavigationBarItem(
                backgroundColor: Colors.blue,
                icon: Icon(Icons.bar_chart),
                label: 'Results',
              ),
              BottomNavigationBarItem(
                backgroundColor: Colors.blue,
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bar Indicator for the Sliding Up Panels (Edit Project, Results)
class BarIndicator extends StatelessWidget {
  const BarIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}

// Text Boxes used in Edit Project. With correct text counters, alignment, and
// coloring.
class EditProjectTextBox extends StatelessWidget {
  final int maxLength;
  final int maxLines;
  final int minLines;
  final String labelText;

  const EditProjectTextBox(
      {super.key,
      required this.maxLength,
      required this.labelText,
      required this.maxLines,
      required this.minLines});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        style: const TextStyle(color: Colors.white),
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        cursorColor: Colors.white10,
        decoration: InputDecoration(
          alignLabelWithHint: true,
          counterStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          labelText: labelText,
          floatingLabelAlignment: FloatingLabelAlignment.start,
          floatingLabelStyle: const TextStyle(
            color: Colors.white,
          ),
          labelStyle: const TextStyle(
            color: Colors.white60,
          ),
        ),
      ),
    );
  }
}

// Icon buttons used in Edit Project Panel. Rounded buttons with icon alignment
// set to end. 15 padding on left and right.
class EditButton extends StatelessWidget {
  final String text;
  final Color foregroundColor;
  final Color backgroundColor;
  final Icon icon;
  final Function onPressed;

  const EditButton({
    super.key,
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.only(left: 15, right: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
      ),
      onPressed: () => onPressed(),
      label: Text(text),
      icon: icon,
      iconAlignment: IconAlignment.end,
    );
  }
}

class CreationTextBox extends StatelessWidget {
  final int maxLength;
  final int maxLines;
  final int minLines;
  final String labelText;
  final ValueChanged? onChanged;
  final Icon? icon;

  const CreationTextBox({
    super.key,
    required this.maxLength,
    required this.labelText,
    required this.maxLines,
    required this.minLines,
    this.onChanged,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Colors.blue, selectionHandleColor: Colors.blue),
        ),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black),
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          cursorColor: const Color(0xFF585A6A),
          decoration: InputDecoration(
            prefixIcon: icon,
            alignLabelWithHint: true,
            counterStyle: const TextStyle(color: Colors.black),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                width: 1.5,
                color: Color(0xFF6A89B8),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                width: 2,
                color: Color(0xFF5C78A1),
              ),
            ),
            hintText: labelText,
            hintStyle: const TextStyle(
              fontWeight: FontWeight.w300,
              color: Color(0xA9000000),
            ),
          ),
        ),
      ),
    );
  }
}