import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

import 'db_schema_classes/member_class.dart';
import 'db_schema_classes/project_class.dart';
import 'google_maps_functions.dart';

/// Bar Indicator for the Sliding Up Panels (Edit Project, Results)
class BarIndicator extends StatelessWidget {
  final Color color;
  final double topPadding;
  final double bottomPadding;

  const BarIndicator({
    super.key,
    this.color = Colors.white60,
    this.topPadding = 8,
    this.bottomPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}

/// Text Boxes used in Edit Project. With correct text counters, alignment, and
/// coloring.
class EditProjectTextBox extends StatelessWidget {
  final int maxLength;
  final int maxLines;
  final int minLines;
  final String labelText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final FloatingLabelBehavior? floatingLabelBehavior;

  const EditProjectTextBox({
    super.key,
    required this.maxLength,
    required this.labelText,
    required this.maxLines,
    required this.minLines,
    required this.controller,
    this.validator,
    this.floatingLabelBehavior,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextFormField(
        validator: validator,
        controller: controller,
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
          floatingLabelBehavior: floatingLabelBehavior,
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

/// Icon buttons used in Edit Project Panel. Rounded buttons with icon alignment
/// set to end. 15 padding on left and right.
class EditButton extends StatelessWidget {
  final String text;
  final Color foregroundColor;
  final Color backgroundColor;
  final Icon? icon;
  final VoidCallback? onPressed;
  final Color iconColor;
  final IconAlignment iconAlignment;
  final OutlinedBorder? shape;

  const EditButton({
    super.key,
    required this.text,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
    this.icon,
    this.iconColor = Colors.white,
    this.iconAlignment = IconAlignment.end,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.only(left: 15, right: 15),
        shape: shape,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        disabledBackgroundColor: disabledGrey,
      ),
      onPressed: onPressed,
      label: Text(text),
      icon: icon,
      iconAlignment: iconAlignment,
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
  final Color? textThemeColor;
  final String? Function(String?)? validator;

  const CreationTextBox({
    super.key,
    required this.maxLength,
    required this.labelText,
    required this.maxLines,
    required this.minLines,
    this.onChanged,
    this.icon,
    this.errorMessage,
    this.textThemeColor,
    this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: textThemeColor ?? Colors.blue,
            selectionHandleColor: textThemeColor ?? Colors.blue,
          ),
        ),
        child: TextFormField(
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black),
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          cursorColor: const Color(0xFF585A6A),
          validator: validator ??
              (value) {
                if (errorMessage != null &&
                    (value == null || value.length < 3)) {
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
  final GestureTapCallback onTap;
  final bool circular;
  final Color backgroundColor;

  const PhotoUpload({
    super.key,
    required this.width,
    required this.height,
    required this.icon,
    required this.onTap,
    required this.circular,
    this.backgroundColor = const Color(0x2A000000),
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
                color: backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6A89B8)),
              )
            : BoxDecoration(
                color: backgroundColor,
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
  final InputDecoration? decoration;
  final TextEditingController? controller;
  final String? forceErrorText;
  final bool? obscureText;
  final void Function(String)? onChanged;
  final Color? textColor;
  final String? Function(String?)? validator;

  const PasswordTextFormField({
    super.key,
    this.decoration,
    this.controller,
    this.forceErrorText,
    this.obscureText,
    this.onChanged,
    this.textColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: TextStyle(color: textColor ?? Colors.white),
      obscureText: obscureText ?? true,
      enableSuggestions: false,
      autocorrect: false,
      autovalidateMode: AutovalidateMode.disabled,
      decoration: decoration ??
          InputDecoration().applyDefaults(ThemeData().inputDecorationTheme),
      controller: controller,
      forceErrorText: forceErrorText,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class DialogTextBox extends StatelessWidget {
  final int? maxLength;
  final String labelText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatter;
  final bool? autofocus;
  final ValueChanged? onChanged;
  final Icon? icon;
  final String? errorMessage;
  final int? minChars;
  final TextAlign? textAlign;

  /// Text form field used for dialog boxes.
  ///
  /// Enter an [errorMessage] for error validation. Put in a form for validation.
  /// Takes a [maxLength], [labelText] and optional [errorMessage], [icon], and
  /// [onChanged]. Optional [minChars] parameter to specify the minimum number of
  /// characters for validation (default: 3)
  const DialogTextBox({
    super.key,
    this.maxLength,
    required this.labelText,
    this.onChanged,
    this.icon,
    this.errorMessage,
    this.minChars,
    this.keyboardType,
    this.inputFormatter,
    this.autofocus,
    this.textAlign,
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
          textAlign: textAlign ?? TextAlign.left,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatter,
          autofocus: autofocus ?? false,
          style: const TextStyle(color: Colors.black),
          maxLength: maxLength,
          cursorColor: const Color(0xFF585A6A),
          validator: (value) {
            if (errorMessage != null &&
                (value == null || value.length < (minChars ?? 3))) {
              return errorMessage ??
                  'Error, insufficient input (validator error message not set)';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: icon,
            alignLabelWithHint: true,
            counterStyle: const TextStyle(color: Colors.black),
            errorBorder: UnderlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFD32F2F),
                width: 2,
              ),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                width: 1.5,
                color: Color(0xFF6A89B8),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
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

class TimerButtonAndDisplay extends StatelessWidget {
  const TimerButtonAndDisplay({
    super.key,
    required this.onPressed,
    required this.isTestRunning,
    required this.remainingSeconds,
  });

  final void Function()? onPressed;
  final bool isTestRunning;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        spacing: 10,
        children: <Widget>[
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: disabledGreyAlt,
                disabledForegroundColor: Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: isTestRunning ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onPressed: onPressed,
              child: Text(
                isTestRunning ? 'Stop' : 'Start',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Container(
            height: 40,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              textAlign: TextAlign.center,
              formatTime(remainingSeconds),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class TimerEndDialog extends StatelessWidget {
  /// Dialog displayed when timer runs out.
  const TimerEndDialog(
      {required this.onSubmit, required this.onBack, super.key});
  final VoidCallback? onSubmit;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Center(
          child: Text(
        "Time's Up!",
        style: TextStyle(fontWeight: FontWeight.bold),
      )),
      content: Center(
          child: Text(
        "Would you like to submit your data?",
        style: TextStyle(fontSize: 15),
      )),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: TextButton(
                onPressed: onBack,
                child: Text("No, take me back."),
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: onSubmit,
                child: Text("Yes, submit."),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CircularIconMapButton extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Widget icon;
  final void Function() onPressed;

  /// Circular button used on top of `GoogleMap` widget.
  const CircularIconMapButton({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}

class OutsideBoundsWarning extends StatelessWidget {
  /// Warning used when point placed outside project polygon on test.
  const OutsideBoundsWarning({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100.0,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Please place points inside the boundary.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class ColorLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  /// A row with a small circle of [color] followed by [Text(label)].
  const ColorLegendItem({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Template for menu used for viewing a list of placed data
/// elements in a test and optionally removing some or all of them.
class DataEditMenu extends StatelessWidget {
  /// Multiplier of height of context used for overall container height.
  /// Should be a value between 0 and 1 inclusive (probably not 0).
  final double? heightMultiplier;
  final String title;
  final List<Widget> colorLegendItems;
  final ListView placedDataList;

  /// Callback used with 'X' button in top right corner. Intended to
  /// close/make invisible this menu.
  final void Function() onPressedCloseMenu;

  /// Callback used with 'Clear All' button at bottom of menu.
  /// Intended to delete all placed data elements in the list.
  final void Function() onPressedClearAll;

  const DataEditMenu({
    super.key,
    this.heightMultiplier,
    required this.title,
    required this.colorLegendItems,
    required this.placedDataList,
    required this.onPressedCloseMenu,
    required this.onPressedClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * (heightMultiplier ?? 0.5),
      decoration: BoxDecoration(
        color: Color(0xFFC5CFDD).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF2F6DCF),
          width: 2,
        ),
      ),
      padding: EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Align(
            // Slightly closer to center than topRight alignment
            alignment: Alignment(0.95, -0.95),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(0xFFD1D7E1).withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFF2F6DCF),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    spreadRadius: 0.5,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: Icon(
                  Icons.close,
                  color: Color(0xFF2F6DCF),
                ),
                onPressed: onPressedCloseMenu,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: colorLegendItems,
                ),
              ),
              SizedBox(height: 8),
              Divider(
                thickness: 2,
                color: Color(0xFF2F6DCF),
              ),
              SizedBox(height: 8),
              Expanded(
                child: placedDataList,
              ),
              // Bottom row with only a Clear All button.
              UnconstrainedBox(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: onPressedClearAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Clear All',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.close, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TestFinishDialog extends StatelessWidget {
  /// Dialog for test finish confirmation.
  ///
  /// Takes only an [onNext] parameter. This should contain the function to be
  /// called when finish the test (i.e. saving the data, pushing to the next
  /// page).
  const TestFinishDialog({
    super.key,
    required this.onNext,
  });

  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Column(
        children: [
          Text(
            "Finish",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        "This will leave the test. Only continue if you are finished with this test.",
        style: TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.clip,
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("No, take me back.")),
        TextButton(onPressed: onNext, child: Text("Yes, finish."))
      ],
    );
  }
}

class GenericConfirmationDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final String titleText;
  final String contentText;
  final String declineText;
  final String confirmText;
  final TextStyle? declineTextStyle;
  final TextStyle? confirmTextStyle;

  const GenericConfirmationDialog({
    super.key,
    this.onConfirm,
    required this.titleText,
    required this.contentText,
    required this.declineText,
    required this.confirmText,
    this.declineTextStyle,
    this.confirmTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Center(
        child: Text(
          titleText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      content: Text(
        contentText,
        style: TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.clip,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(declineText),
        ),
        TextButton(
            onPressed: onConfirm,
            child: Text(
              confirmText,
              style: confirmTextStyle ?? TextStyle(color: Colors.red[700]),
            )),
      ],
    );
  }
}

// Reused implementation(s) of GenericConfirmationDialog.
Future<bool?> showDeleteProjectDialog({
  required BuildContext context,
  required Project project,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => GenericConfirmationDialog(
      titleText: 'Delete Project?',
      contentText:
          'This will delete the selected project and all the tests within it. '
          'This cannot be undone. '
          'Are you absolutely certain you want to delete this project?',
      declineText: 'No, go back',
      confirmText: 'Yes, delete it',
      onConfirm: () async {
        await project.delete();

        if (!context.mounted) return;
        Navigator.pop(context, true);
      },
    ),
  );
}

class DirectionsButton extends StatelessWidget {
  /// Directions widget used for tests.
  ///
  /// Pass through a [visibility] variable. This should be of type [bool] and
  /// control the visibility of the directions. The [onTap] function passed
  /// should toggle the [visibility] boolean in a [setState]. It may do other
  /// things on top of this if desired.
  /// Should be placed in a Column w/ other widgets (delete mode, map type)
  const DirectionsButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: defaultGrad,
          color: directionsTransparency),
      child: IconButton(
          color: Colors.white,
          onPressed: onTap,
          icon: Icon(
            Icons.help_outline,
            size: 35,
          )),
    );
  }
}

class DirectionsText extends StatelessWidget {
  const DirectionsText({
    super.key,
    this.onTap,
    required this.text,
  });

  final VoidCallback? onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: directionsTransparency,
            gradient: defaultGrad,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          )),
    );
  }
}

class VisibilitySwitch extends StatelessWidget {
  /// Visibility switch widget for tests page.
  ///
  /// Toggles visibility for the old shapes on test pages. Takes in a [visibility]
  /// variable and an [onChanged] function. The [onChanged] function is of type
  /// [Function(bool)?]. It takes a [bool] parameter and should change the
  /// [visibility] variable to the value of the [bool] parameter. Should be in a
  /// [setState].
  const VisibilitySwitch({
    super.key,
    required bool visibility,
    this.onChanged,
  }) : _visibility = visibility;

  final bool _visibility;
  final Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: defaultGrad,
          color: directionsTransparency,
          borderRadius: BorderRadius.all(Radius.circular(15))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 7.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Visibility:",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Tooltip(
              message: "Toggle Visibility of Old Shapes",
              child: Switch(
                // This bool value toggles the switch.
                value: _visibility,
                activeTrackColor: placeYellow,
                inactiveThumbColor: placeYellow,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestButton extends StatelessWidget {
  /// Test button used for test bottom sheets.
  ///
  /// Takes a [buttonText] parameter for the button text and [onPressed]
  /// parameter for the function. Takes an optional [flex] parameter for flex of
  /// button. Defaults to a flex of 1 if null.
  const TestButton({
    this.flex,
    this.backgroundColor,
    required this.buttonText,
    required this.onPressed,
    super.key,
  });

  final Color? backgroundColor;
  final int? flex;
  final String buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex ?? 1,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: disabledGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: onPressed,
        child: Center(
            child: Text(
          buttonText,
          textAlign: TextAlign.center,
        )),
      ),
    );
  }
}

/// Generic modal bottom sheet for tests.
///
/// Takes a [title] and [subtitle] to display above the [contentList].
/// The [subtitle] is optional, and will default to none.
/// The format starts with a centered title, then subtitle under that. Then,
/// some spacing, and then [contentList] is rendered under this. This
/// [contentList] should contain all buttons and categories needed for the
/// sheet. Then a cancel inkwell, which will use the [onCancel] parameter.
void showTestModalGeneric(BuildContext context,
    {required VoidCallback? onCancel,
    required String title,
    required String? subtitle,
    required List<Widget> contentList}) {
  showModalBottomSheet<void>(
      sheetAnimationStyle:
          AnimationStyle(reverseDuration: Duration(milliseconds: 100)),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: Container(
              // Container decoration- rounded corners and gradient
              decoration: BoxDecoration(
                gradient: formGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BarIndicator(),
                    Center(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: p2bpBlue,
                        ),
                      ),
                    ),
                    subtitle != null
                        ? Center(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : SizedBox(),
                    subtitle != null ? SizedBox(height: 10) : SizedBox(),
                    ...contentList,
                    SizedBox(height: 15),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: InkWell(
                        onTap: onCancel,
                        child: Padding(
                          padding: EdgeInsets.only(right: 20, bottom: 0),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: p2bpBlue),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      });
}

class TestErrorText extends StatelessWidget {
  /// Error text for test pages.
  ///
  /// Displays a text error at bottom of screen with the text specified by the
  /// [text] parameter. Defaults to point placed outside of polygon error text.
  const TestErrorText({
    super.key,
    this.text,
    this.padding,
  });

  final String? text;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red[900],
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text ?? 'You have placed a point outside of the project area!',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[50],
            ),
          ),
        ),
      ),
    );
  }
}

enum CustomTab { project, team }

/// Segmented Tab for Projects and Teams View V2
class CustomSegmentedTab extends StatefulWidget {
  final CustomTab selectedTab;
  final ValueChanged<CustomTab> onTabSelected;

  const CustomSegmentedTab({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  State<CustomSegmentedTab> createState() => _CustomSegmentedTabState();
}

class _CustomSegmentedTabState extends State<CustomSegmentedTab> {
  // Cache styles and decorations outside the build method
  final TextStyle selectedStyle = const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  final TextStyle unselectedStyle = const TextStyle(
    color: Color(0xFFB6D1EC),
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Create a container decoration once
  final containerDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(60),
    gradient: verticalBlueGrad,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        offset: Offset(0, 4),
        blurRadius: 12,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(120),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(8.0),
          decoration: containerDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RepaintBoundary(
                child: _buildSegment(
                  tab: CustomTab.project,
                  label: 'PROJECT',
                ),
              ),
              RepaintBoundary(
                child: _buildSegment(
                  tab: CustomTab.team,
                  label: 'TEAM',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment({required CustomTab tab, required String label}) {
    final bool isSelected = (widget.selectedTab == tab);

    // Selected tab: white text
    final TextStyle selectedStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    // Unselected tab: B6D1EC
    final TextStyle unselectedStyle = const TextStyle(
      color: Color(0xFFB6D1EC),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    return GestureDetector(
      onTap: () => widget.onTabSelected(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: isSelected ? selectedStyle : unselectedStyle,
        ),
      ),
    );
  }
}

class MemberInviteCard extends StatelessWidget {
  final Member member;
  final bool invited;
  final VoidCallback inviteMember;

  const MemberInviteCard({
    super.key,
    required this.member,
    required this.invited,
    required this.inviteMember,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            CircleAvatar(),
            SizedBox(width: 15),
            Expanded(
              child: Text(member.fullName),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: inviteMember,
                child: Text(invited ? "Invite sent!" : "Invite"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}