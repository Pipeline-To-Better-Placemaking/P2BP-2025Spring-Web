import 'package:flutter/material.dart';

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
  final Color iconColor;

  const EditButton({
    super.key,
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.icon,
    required this.onPressed,
    this.iconColor = Colors.white,
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
        iconColor: iconColor,
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
  final String? errorMessage;

  const CreationTextBox({
    super.key,
    required this.maxLength,
    required this.labelText,
    required this.maxLines,
    required this.minLines,
    this.onChanged,
    this.icon,
    this.errorMessage,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
              selectionColor: Colors.blue, selectionHandleColor: Colors.blue),
        ),
        child: TextFormField(
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black),
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          cursorColor: const Color(0xFF585A6A),
          validator: (value) {
            // TODO: custom error check parameter?
            if (errorMessage != null && (value == null || value.length < 3)) {
              // TODO: eventually require error message?
              return errorMessage ??
                  'Error, insufficient input (validator error message not set)';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: icon,
            alignLabelWithHint: true,
            counterStyle: const TextStyle(color: Colors.black),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(
                color: Color(0xFFD32F2F),
                width: 2,
              ),
            ),
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

// Square drop/upload area widget, with variable size and icon.
// Requires width, height, function, and IconData (in format: Icons.<icon_name>)
class PhotoUpload extends StatelessWidget {
  final double width;
  final double height;
  final IconData icon;
  final bool circular;
  final GestureTapCallback onTap;

  const PhotoUpload({
    super.key,
    required this.width,
    required this.height,
    required this.icon,
    required this.onTap,
    required this.circular,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: circular
            ? BoxDecoration(
                color: const Color(0x2A000000),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6A89B8)),
              )
            : BoxDecoration(
                color: const Color(0x2A000000),
                shape: BoxShape.rectangle,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: const Color(0xFF6A89B8)),
              ),
        child: Icon(
          icon,
          size: circular ? ((width + height) / 4) : ((width + height) / 10),
        ),
      ),
    );
  }
}

class PasswordTextFormField extends StatelessWidget {
  final InputDecoration _decoration;
  final TextEditingController? _controller;
  final String? _forceErrorText;
  final bool _obscureText;
  final void Function(String)? _onChanged;

  PasswordTextFormField({
    super.key,
    decoration,
    controller,
    forceErrorText,
    obscureText,
    onChanged,
  })  : _decoration = decoration ??
            InputDecoration().applyDefaults(ThemeData().inputDecorationTheme),
        _controller = controller,
        _forceErrorText = forceErrorText,
        _obscureText = obscureText ?? true,
        _onChanged = onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: _obscureText,
      enableSuggestions: false,
      autocorrect: false,
      autovalidateMode: AutovalidateMode.disabled,
      decoration: _decoration,
      controller: _controller,
      forceErrorText: _forceErrorText,
      onChanged: _onChanged,
    );
  }
}