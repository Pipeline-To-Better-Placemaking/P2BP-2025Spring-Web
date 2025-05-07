import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:p2b/db_schema_classes/member_class.dart';
import 'manage_team_bottom_sheet.dart';
import 'project_list_widget.dart';
import 'dart:ui';
import 'db_schema_classes/team_class.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'theme.dart';
import 'change_team_name_bottom_sheet.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TeamSettingsScreen extends StatefulWidget {
  final Team activeTeam;

  const TeamSettingsScreen(
      {super.key, required this.activeTeam, required Member member});

  @override
  State<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends State<TeamSettingsScreen> {
  bool isMultiSelectMode = false;
  Set<int> selectedProjects = {};

  /// Call this method to toggle multi-select mode
  void toggleMultiSelect() {
    setState(() {
      isMultiSelectMode = !isMultiSelectMode;
      if (!isMultiSelectMode) {
        selectedProjects.clear();
      }
    });
  }

  void toggleProjectSelection(int index) {
    setState(() {
      if (selectedProjects.contains(index)) {
        selectedProjects.remove(index);
      } else {
        selectedProjects.add(index);
      }
    });
  }

  void handleProjectTap(int index) {}

  void _showInviteDialog(BuildContext context) {
    String email = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Invite User"),
          content: TextField(
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              email = value;
            },
            decoration: InputDecoration(
              labelText: "Email Address",
              hintText: "example@domain.com",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle sending invitation here.
                // For example, call your invite API with the entered email.
                print("Sending invitation to $email");
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Send Invitation"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamNameAndMembers() {
    return SizedBox(
      // Height is 72 to match profile avatar on left of row
      height: 72,
      // Width of 206 is exactly the width used by all the Positioned stuff
      width: 206,
      child: Column(
        children: [
          Text(
            widget.activeTeam.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: Stack(
              clipBehavior:
                  Clip.none, // Allows the edit button to overflow slightly
              children: [
                // Overlapping team members
                for (int index = 0; index < 6; index++)
                  Positioned(
                    left: index * 24.0, // Overlap amount
                    child: CircleAvatar(
                      radius: 16,
                      // TODO: Add team member photos
                    ),
                  ),
                // Edit button overlapping the last avatar
                Positioned(
                  // Overlap position for the last avatar
                  left: 5 * 24.0 + 20,
                  // Adjust for proper vertical alignment
                  top: 12,
                  child: GestureDetector(
                    onTap: () {
                      // Open team edit functionality
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled:
                            true, // allows the sheet to be fully draggable
                        backgroundColor: Colors
                            .transparent, // makes the sheet's corners rounded if desired
                        builder: (BuildContext context) {
                          return DraggableScrollableSheet(
                            // initial height as 50% of screen height
                            initialChildSize: 0.7,
                            // minimum height when dragged down
                            minChildSize: 0.3,
                            // maximum height when dragged up
                            maxChildSize: 0.9,
                            builder: (BuildContext context,
                                ScrollController scrollController) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: defaultGrad,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16.0),
                                    topRight: Radius.circular(16.0),
                                  ),
                                ),
                                child: ManageTeamBottomSheet(),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Invite button to the right of the Team Members Profile Avatars
                Positioned(
                  // Place the invite button to the right of the team avatars
                  left: 6 * 24.0 + 20,
                  // Align with the team avatars vertically
                  top: -6,
                  child: ElevatedButton(
                    onPressed: () {
                      _showInviteDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(30, 25),
                      backgroundColor: Colors.blue,
                    ),
                    child: Icon(
                      Icons.person_add, // Invite icon
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _settingsButtonPressed(BuildContext context) async {
    // Calculate button position and menu placement.
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);
    final double buttonWidth = button.size.width;
    final double buttonHeight = button.size.height;

    // Define your desired menu width.
    const double menuWidth = 250;

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
    final double top = buttonPosition.dy + buttonHeight - 2;
    // Custom pop up menu with frosted glass style design
    final int? value = await showGeneralDialog<int>(
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
                        color: Color.fromRGBO(47, 109, 207, 0.85),
                        child: IntrinsicWidth(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 'Change Project' button
                              InkWell(
                                onTap: () => Navigator.of(context).pop(0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Edit Team Name",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                      ),
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
                                          "Change Team Color",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      Icon(
                                        Icons.palette_outlined,
                                        color: Colors.white,
                                      ),
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
                                          "Select Projects",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                      ),
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
                                          "Archive Team",
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        FontAwesomeIcons.boxArchive,
                                        color: Colors.white,
                                      ),
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
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Delete Team",
                                          style: TextStyle(
                                            color: Color(0xFFFD6265),
                                            fontWeight: FontWeight.bold,
                                          ),
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
    );
    if (!context.mounted) {
      return;
    }
    // Handle menu selection.
    if (value != null) {
      if (value == 0) {
        print("Edit Team Name");
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
                  child: ChangeTeamNameBottomSheet(),
                  // Replace this ListView with your desired content
                );
              },
            );
          },
        );
      } else if (value == 1) {
        print("Change Team Color");
      } else if (value == 2) {
        print("Select Projects");
        // Toggle multi-select mode on the project list
        toggleMultiSelect();
      } else if (value == 3) {
        print("Archive Team");
      } else if (value == 4) {
        print("Delete Team");
        showDialog(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.5), // Optional overlay
          builder: (BuildContext context) {
            return Dialog(
              // mimics native AlertDialog margin
              insetPadding: EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 24.0,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ClipRRect(
                // default AlertDialog uses a small radius
                borderRadius: BorderRadius.circular(18.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    // similar to AlertDialog's content padding
                    padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 14.0),
                    decoration: BoxDecoration(
                      // frosted glass effect
                      color: p2bpBlue.withValues(alpha: 0.55),
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
                          "Are you sure you want to delete this team and all associated projects?",
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
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Changes Android status bar to white
        statusBarIconBrightness: Brightness.dark,
        // Changes iOS status bar to white
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A2A88),
                    Color(0xFF62B6FF),
                  ],
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row with Back Arrow and Settings buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            // Add back navigation
                            Navigator.pop(context);
                          },
                        ),
                        // Push settings icon to the right edge of the screen
                        Spacer(),
                        // Settings button with quick action menu
                        Builder(builder: (context) {
                          return IconButton(
                            icon: Image.asset('assets/Filter_Icon.png'),
                            onPressed: () => _settingsButtonPressed(context),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  // Profile Avatar and Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Profile Avatar on the left
                        Flexible(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                // TODO: Add actual image
                              ),
                              GestureDetector(
                                onTap: () async {
                                  // Open image edit functionality
                                  final XFile? pickedFile = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    final File imageFile =
                                        File(pickedFile.path);
                                    // Now you have the image file, and you can submit or process it.
                                    print("Image selected: ${imageFile.path}");
                                  } else {
                                    print("No image selected.");
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue,
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Column with Team Name and Team Members Row
                        _buildTeamNameAndMembers(),
                      ],
                    ),
                  ),
                  SizedBox(height: 48),
                  // Project Title and Create New Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Projects',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        isMultiSelectMode
                            ? Row(
                                children: [
                                  TextButton(
                                    child: Text(
                                      'Done',
                                      style: TextStyle(
                                          color: Color(0xFF62B6FF),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      // Cancel multi-select mode
                                      toggleMultiSelect();
                                    },
                                  ),
                                  SizedBox(width: 5),
                                  ElevatedButton(
                                    // Creates new project. If Multi-Select Mode active, changes to a delete button
                                    onPressed: isMultiSelectMode
                                        ? (selectedProjects.isEmpty
                                            ? null
                                            : () {
                                                // Deletion logic here.
                                              })
                                        : () {
                                            // Create new project logic here.
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: isMultiSelectMode
                                          ? Colors.red
                                          : Colors.blue,
                                      minimumSize: Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: isMultiSelectMode
                                          ? Text('Delete',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white))
                                          : Text(
                                              'Create New',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ),
                                    ),
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                // Creates new project. If Multi-Select Mode active, changes to a delete button
                                onPressed: () {
                                  // Create new project logic here.
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //       builder: (context) =>
                                  //           CreateNewProjectsOnlyScreen()),
                                  // );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.blue,
                                  minimumSize: Size(0, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'Create New',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Project List
                  Expanded(
                    child: ProjectListWidget(
                      isMultiSelectMode: isMultiSelectMode,
                      selectedProjects: selectedProjects,
                      onToggleSelection: toggleProjectSelection,
                      onProjectTap: handleProjectTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
