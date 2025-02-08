import 'package:flutter/material.dart';
import 'create_project_details.dart';
import 'db_schema_classes.dart';

class TeamSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Graident background
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
                // Top Row with Back Arrow and Settings butttons
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
                      Spacer(), // Push settings icon to the right edge of the screen

                      // Settings button with quick action menu
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: PopupMenuThemeData(
                            color: Color(0xFF2F6DCF),
                            textStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                        child: PopupMenuButton<int>(
                          icon: Image.asset('assets/Filter_Icon.png'),
                          onSelected: (int value) {
                            if (value == 0) {
                              // Edit team action
                              print("Edit Team");
                            } else if (value == 1) {
                              // Change color action
                              print("Change Team Color");
                            } else if (value == 2) {
                              print("Select Projects");
                            } else if (value == 3) {
                              // Delete team action
                              print("Delete Team");
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 0,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Edit Team",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Icon(Icons.edit_note_rounded,
                                      color: Colors.white),
                                ],
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 1,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text("Change Team Color",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  Icon(Icons.palette_outlined,
                                      color: Colors.white),
                                ],
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                                value: 2,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Select Projects",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.white),
                                  ],
                                )),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 3,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text("Delete Team",
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                  Icon(Icons.delete, color: Colors.red),
                                ],
                              ),
                            ),
                          ],
                          // Adjust the offset to position the menu directly below the settings button
                          offset:
                              Offset(0, 40), // Horizontal and vertical offset
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Profile Avatar and Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar on the left
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: AssetImage(
                                'assets/profile_image.jpg'), // Replace with actual image
                          ),
                          GestureDetector(
                            onTap: () {
                              // Open image edit functionality
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

                      SizedBox(width: 90), // Space between avatar and team name

                      // Column with Team Name and Team Members Row
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Text
                            Text(
                              'Lake Nona Design Group',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(
                                height:
                                    8), // Space between team name and avatars

                            // Team Members Row
                            SizedBox(
                              height: 36,
                              child: Stack(
                                  clipBehavior: Clip
                                      .none, // Allows the edit button to overlfow slightly
                                  children: [
                                    // Overlapping team members
                                    for (int index = 0; index < 6; index++)
                                      Positioned(
                                        left: index * 24.0, // Overlap amount
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundImage: AssetImage(
                                              'assets/member_$index.jpg'), // Replace with team member profile photos
                                        ),
                                      ),

                                    // Edit button overlapping the last avatar
                                    Positioned(
                                      left: 5 * 24.0 +
                                          20, // Overlap position for the last avatar
                                      top:
                                          12, // Adjust for proper vertical alignment
                                      child: GestureDetector(
                                        onTap: () {
                                          // Open team edit functionality
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
                                        left: 6 * 24.0 +
                                            20, // Place the invite button to the right of the team avatars
                                        top:
                                            -6, // Align with the team avatars vertically
                                        child: // Invite button
                                            ElevatedButton(
                                                onPressed: () {
                                                  // Invite functionality
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size(30, 25),
                                                  backgroundColor: Colors.blue,
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .person_add, // Invite icon
                                                  color: Colors.white,
                                                  size: 20,
                                                )))
                                  ]),
                            ),
                          ],
                        ),
                      ),
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
                      ElevatedButton(
                        onPressed: () {
                          // Add create new project logic
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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Create New',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Project List
                Expanded(
                  child: ListView.builder(
                    itemCount: 6, // Replace with project list length
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/RedHouse.png', // Replace with project image
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              'Project Title $index',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing:
                                Icon(Icons.chevron_right, color: Colors.white),
                            onTap: () {
                              // Navigate to project details
                              // TODO: Add project data via function returning project object
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateProjectDetails(
                                      projectData: Project.partialProject(
                                          title: 'No data sent',
                                          description:
                                              'Accessed without project data'),
                                    ),
                                  ));
                            }, // Replace with project title
                          ),
                          Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// IconButton(
//                         icon: Image.asset('assets/Filter_Icon.png'),
//                         onPressed: () {
//                           // Add settings/edit functionality
//                         },
//                       ),