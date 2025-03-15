import 'dart:io';
import 'dart:ui';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'themes.dart';
import 'change_project_description_form.dart';
import 'change_project_name_form.dart';

void showProjectOptionsDialog(BuildContext context) {
  // Calculate button position and menu placement.
  final RenderBox button = context.findRenderObject() as RenderBox;
  final Offset buttonPosition = button.localToGlobal(Offset.zero);
  final double buttonWidth = button.size.width;
  final double buttonHeight = button.size.height;

  // Define your desired menu width.
  const double menuWidth = 200;

  // Get the screen width.
  final double screenWidth = MediaQuery.of(context).size.width;

  // Calculate left offset so the menu is centered below the button.
  double left = buttonPosition.dx + (buttonWidth / 2) - (menuWidth / 2);

  // Right-edge padding
  const double rightPadding = 16.0;

  // Clamp the left offset so that the menu doesn't go offscreen (with right padding).
  if (left < 0) {
    left = 0;
  } else if (left + menuWidth > screenWidth - rightPadding) {
    left = screenWidth - rightPadding - menuWidth;
  }

  // Top offset so that pop up menu hovers slightly below button
  final double top = buttonPosition.dy + buttonHeight + 8.0;
  // Custom pop up menu with frosted glass style design
  showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: Colors.transparent, // No dimming.
    transitionDuration: Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          // Position the menu using the computed left and top.
          Positioned(
            left: left,
            top: top,
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox(
                width: menuWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      // #2F6DCF converted to RGB values
                      color: Color.fromRGBO(47, 109, 207, 0.7),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 'Change Project' button
                            InkWell(
                              onTap: () => Navigator.of(context).pop(0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Change Project Photo",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Icon(Icons.camera_alt, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                            Divider(color: Colors.white54, height: 1),
                            // 'Edit Project Name' button
                            InkWell(
                              onTap: () => Navigator.of(context).pop(1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Edit Project Name",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Icon(Icons.text_fields,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                            Divider(color: Colors.white54, height: 1),
                            // 'Edit Project Description' button
                            InkWell(
                              onTap: () => Navigator.of(context).pop(2),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Edit Project Description",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Icon(Icons.description,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                            Divider(color: Colors.white54, height: 1),
                            // 'Archive Project' button
                            InkWell(
                              onTap: () => Navigator.of(context).pop(3),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Archive Project",
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Icon(FontAwesomeIcons.boxArchive,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                            Divider(color: Colors.white54, height: 1),
                            // 'Delete Project' button
                            InkWell(
                              onTap: () => Navigator.of(context).pop(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Delete Project",
                                        style: TextStyle(
                                            color: Color(0xFFFD6265),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Icon(Icons.delete,
                                        color: Color(0xFFFD6265)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  ).then((value) async {
    if (value != null) {
      // Handle menu selection.
      if (value == 0) {
        print("Change Cover Photo");
        // Prompt the image picker
        final XFile? pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          final File imageFile = File(pickedFile.path);
          // Now you have the image file, and you can submit or process it.
          print("Image selected: ${imageFile.path}");
        } else {
          print("No image selected.");
        }
      } else if (value == 1) {
        print("Edit Project Name");
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // allows the sheet to be fully draggable
          backgroundColor: Colors
              .transparent, // makes the sheet's corners rounded if desired
          builder: (BuildContext context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7, // initial height as 50% of screen height
              minChildSize: 0.3, // minimum height when dragged down
              maxChildSize: 0.9, // maximum height when dragged up
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: defaultGrad,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: ChangeProjectNameForm(),

                  // Replace this ListView with your desired content
                );
              },
            );
          },
        );
      } else if (value == 2) {
        print("Edit Project Description");
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // allows the sheet to be fully draggable
          backgroundColor: Colors
              .transparent, // makes the sheet's corners rounded if desired
          builder: (BuildContext context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7, // initial height as 50% of screen height
              minChildSize: 0.3, // minimum height when dragged down
              maxChildSize: 0.9, // maximum height when dragged up
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: defaultGrad,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: ChangeProjectDescriptionForm(),
                );
              },
            );
          },
        );
      } else if (value == 3) {
        print("Archive Project");
        // TODO: Add archive functionality here
      } else if (value == 4) {
        print("Delete Project");
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.5), // Optional overlay
          builder: (BuildContext context) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 24.0), // mimics native AlertDialog margin
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    18.0), // default AlertDialog uses a small radius
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0,
                        14.0), // similar to AlertDialog's content padding
                    decoration: BoxDecoration(
                      color: Color(0xFF2F6DCF)
                          .withValues(alpha: 0.55), // frosted glass effect
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Confirm Deletion",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Are you sure you want to delete this project?",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("Cancel",
                                  style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () {
                                // Execute deletion logic here
                                Navigator.of(context).pop();
                              },
                              child: Text("Delete",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    }
  });
}