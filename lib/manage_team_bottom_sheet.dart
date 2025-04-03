import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import 'theme.dart';

class ManageTeamBottomSheet extends StatefulWidget {
  @override
  _ManageTeamBottomSheetState createState() => _ManageTeamBottomSheetState();
}

class _ManageTeamBottomSheetState extends State<ManageTeamBottomSheet> {
// Sample list of team member names.
  final List<String> teamMembers = [
    "Clifford St. John", // Team Admin
    "Andrew Zhao",
    "Michael Cubero",
    "Ryan Giunta",
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Pill notch
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          SizedBox(height: 20),
          // New content: List of team members.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label for the first member.
                Padding(
                  padding: const EdgeInsets.only(left: 55.0),
                  child: Text(
                    "Team Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/admin_image.png'), // Admin image.
                  ),
                  title: Text(
                    teamMembers[0],
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Icon(
                      FontAwesomeIcons.crown,
                      color: Color(0xFFFFCC00),
                    ),
                  ),
                ),
                Divider(
                  color: Colors.white.withValues(alpha: 0.3),
                  thickness: 1,
                ),
                // The rest of the team members.
                ...teamMembers.sublist(1).asMap().entries.map((entry) {
                  int index = entry.key; // index in the sublist (0-based)
                  String member = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete Icon
                            GestureDetector(
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.black.withValues(
                                      alpha: 0.5), // Optional overlay
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      insetPadding: EdgeInsets.symmetric(
                                          horizontal: 40.0,
                                          vertical:
                                              24.0), // mimics native AlertDialog margin
                                      backgroundColor: Colors.transparent,
                                      elevation: 0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            18.0), // default AlertDialog uses a small radius
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            padding: EdgeInsets.fromLTRB(
                                                24.0,
                                                20.0,
                                                24.0,
                                                14.0), // similar to AlertDialog's content padding
                                            decoration: BoxDecoration(
                                              color: p2bpBlue.withValues(
                                                  alpha:
                                                      0.65), // frosted glass effect
                                              borderRadius:
                                                  BorderRadius.circular(18.0),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Remove Team Member",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                          color: Colors.white),
                                                ),
                                                SizedBox(height: 20),
                                                RichText(
                                                  text: TextSpan(
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                            color:
                                                                Colors.white70),
                                                    children: [
                                                      TextSpan(
                                                          text:
                                                              "Are you sure you want to remove "),
                                                      TextSpan(
                                                        text:
                                                            "[insert team member here]",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      TextSpan(text: "?"),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(),
                                                      child: Text("Cancel",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        // Execute deletion logic here
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text("Remove",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
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
                              },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            SizedBox(
                                width:
                                    20), // spacing between delete icon and avatar
                            // Circle Avatar
                            CircleAvatar(
                              backgroundImage:
                                  AssetImage('assets/member_image.png'),
                            ),
                          ],
                        ),
                        title: Text(
                          member,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Divider(
                        color: Colors.white.withValues(alpha: 0.3),
                        thickness: 1,
                        indent: 50.0,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}