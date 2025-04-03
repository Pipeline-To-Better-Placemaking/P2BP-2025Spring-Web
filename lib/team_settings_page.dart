/*import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'change_team_name_form.dart';
import 'firestore_functions.dart';
import 'invite_user_form.dart';
import 'manage_team_bottom_sheet.dart';
import 'widgets.dart';

import 'db_schema_classes.dart';
import 'project_details_page.dart';
import 'theme.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class TeamSettingsPage extends StatefulWidget {
  final Team activeTeam;

  const TeamSettingsPage({super.key, required this.activeTeam});

  @override
  State<TeamSettingsPage> createState() => _TeamSettingsPageState();
}

class _TeamSettingsPageState extends State<TeamSettingsPage> {
  bool _isLoading = true;
  bool isMultiSelectMode = false;
  Set<Project> selectedProjects = {};

  late final List<Project> projects;

  @override
  void initState() {
    super.initState();
    _getProjects();
  }

  Future<void> _getProjects() async {
    projects = await getTeamProjects(
        _firestore.collection('teams').doc(widget.activeTeam.teamID));
    setState(() {
      _isLoading = false;
    });
  }

  /// Call this method to toggle multi-select mode
  void toggleMultiSelect() {
    setState(() {
      isMultiSelectMode = !isMultiSelectMode;
      if (!isMultiSelectMode) {
        selectedProjects.clear();
      }
    });
  }

  void toggleProjectSelection(Project project) {
    setState(() {
      if (selectedProjects.contains(project)) {
        selectedProjects.remove(project);
      } else {
        selectedProjects.add(project);
      }
    });
  }

  Widget _deleteProjectsDialog() {
    return GenericConfirmationDialog(
      titleText: 'Delete Projects?',
      contentText:
          'This will delete all selected projects and the tests within them. '
          'This cannot be undone. '
          'Are you absolutely certain you want to delete all these projects?',
      declineText: 'No, go back',
      confirmText: 'Yes, delete them',
      onConfirm: () async {
        for (final project in selectedProjects) {
          await deleteProject(project);
          projects.remove(project);
        }

        if (!mounted) return;
        Navigator.pop(context);
        setState(() {
          // Rebuild projects list after changes
        });
      },
    );
  }

  Widget _deleteTeamDialog() {
    return GenericConfirmationDialog(
      titleText: 'Delete This Team?',
      contentText: 'This will delete the currently selected team as well as '
          'well as all projects within it, and the tests within those '
          'projects. This cannot be undone. '
          'Are you absolutely certain you want to delete this team?',
      declineText: 'No, go back',
      confirmText: 'Yes, delete this team',
      onConfirm: () async {
        final success = await deleteTeam(widget.activeTeam);
        if (success == true) {
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.pop(context, true);
        } else {
          if (!mounted) return;
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light
            .copyWith(statusBarColor: Colors.transparent),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        forceMaterialTransparency: true,
        actionsPadding: EdgeInsets.symmetric(horizontal: 4),
        actions: [
          _SettingsMenuButton(
            editNameCallback: () async {
              final String? newName = await showModalBottomSheet<String>(
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                context: context,
                builder: (context) => ChangeTeamNameForm(),
              );

              if (newName == null) return;
              _firestore
                  .collection('teams')
                  .doc(widget.activeTeam.teamID)
                  .update({'title': newName});
              setState(() {
                widget.activeTeam.title = newName;
              });
            },
            selectProjectsCallback: toggleMultiSelect,
            deleteTeamCallback: () {
              showDialog(
                context: context,
                builder: (context) => _deleteTeamDialog(),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: defaultGrad),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar and Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _AvatarAndTitleRow(
                  title: widget.activeTeam.title,
                  inviteCallback: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (context) =>
                          InviteUserForm(activeTeam: widget.activeTeam),
                    );
                    // _showInviteDialog(context);
                  },
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
                    if (isMultiSelectMode)
                      Row(
                        children: [
                          TextButton(
                            onPressed: toggleMultiSelect,
                            child: Text(
                              'Done',
                              style: TextStyle(
                                  color: Color(0xFF62B6FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: selectedProjects.isEmpty
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          _deleteProjectsDialog(),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  isMultiSelectMode ? Colors.red : Colors.blue,
                              minimumSize: Size(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
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
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      bool isSelected =
                          selectedProjects.contains(projects[index]);
                      return Column(
                        children: [
                          _ProjectListTile(
                            isMultiSelectMode: isMultiSelectMode,
                            isSelected: isSelected,
                            project: projects[index],
                            toggleProjectSelection: toggleProjectSelection,
                          ),
                          if (isMultiSelectMode)
                            Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                              thickness: 1,
                              indent: 50,
                              endIndent: 16,
                            )
                          else
                            Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectListTile extends StatelessWidget {
  final bool isMultiSelectMode;
  final bool isSelected;
  final Project project;
  final void Function(Project) toggleProjectSelection;

  const _ProjectListTile({
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.project,
    required this.toggleProjectSelection,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // If in multi-select mode, show bubble for selecting project.
      leading: isMultiSelectMode
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => toggleProjectSelection(project),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Color(0xFF62B6FF)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                SizedBox(width: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/RedHouse.png', // Replace with project image
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/RedHouse.png', // Replace with project image
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(
        project.title,
        style: TextStyle(color: Colors.white),
      ),
      // Hide trailing chevron when in multi-select mode
      trailing: isMultiSelectMode
          ? null
          : Icon(Icons.chevron_right, color: Colors.white),
      onTap: () {
        if (isMultiSelectMode) {
          toggleProjectSelection(project);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsPage(
                activeProject: project,
              ),
            ),
          );
        }
      },
    );
  }
}

class _SettingsMenuButton extends StatelessWidget {
  final VoidCallback? editNameCallback;
  // final VoidCallback? changeColorCallback;
  final VoidCallback? selectProjectsCallback;
  // final VoidCallback? archiveTeamCallback;
  final VoidCallback? deleteTeamCallback;

  const _SettingsMenuButton({
    this.editNameCallback,
    // this.changeColorCallback,
    this.selectProjectsCallback,
    // this.archiveTeamCallback,
    this.deleteTeamCallback,
  });

  static const ButtonStyle paddingButtonStyle = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)));
  static const TextStyle whiteText = TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      style: MenuStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        )),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      children: <Widget>[
        SubmenuButton(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            )),
            visualDensity:
                VisualDensity(horizontal: VisualDensity.minimumDensity),
          ),
          menuStyle: MenuStyle(
            backgroundColor:
                WidgetStatePropertyAll(p2bpBlue.withValues(alpha: 0.85)),
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          menuChildren: [
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon: Icon(
                Icons.edit_outlined,
                color: Colors.white,
              ),
              onPressed: editNameCallback,
              child: Text(
                'Edit Team Name',
                style: whiteText,
              ),
            ),
            Divider(color: Colors.white54, height: 1),
            // MenuItemButton(
            //   style: paddingButtonStyle,
            //   trailingIcon: Icon(
            //     Icons.palette_outlined,
            //     color: Colors.white,
            //   ),
            //   onPressed: changeColorCallback,
            //   child: Text(
            //     'Change Team Color',
            //     style: whiteText,
            //   ),
            // ),
            // Divider(color: Colors.white54, height: 1),
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon: Icon(
                Icons.check_circle_outlined,
                color: Colors.white,
              ),
              onPressed: selectProjectsCallback,
              child: Text(
                'Select Projects',
                style: whiteText,
              ),
            ),
            Divider(color: Colors.white54, height: 1),
            // MenuItemButton(
            //   style: paddingButtonStyle,
            //   trailingIcon: Icon(
            //     Icons.inventory_2_outlined,
            //     color: Colors.white,
            //   ),
            //   onPressed: archiveTeamCallback,
            //   child: Text(
            //     'Archive Team',
            //     style: whiteText,
            //   ),
            // ),
            // Divider(color: Colors.white54, height: 1),
            MenuItemButton(
              style: paddingButtonStyle,
              trailingIcon:
                  Icon(Icons.delete_outlined, color: Color(0xFFFD6265)),
              onPressed: deleteTeamCallback,
              child: Text(
                'Delete Team',
                style: TextStyle(color: Color(0xFFFD6265)),
              ),
            ),
          ],
          child: Icon(
            Icons.tune_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _AvatarAndTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback inviteCallback;

  const _AvatarAndTitleRow({required this.title, required this.inviteCallback});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                    final File imageFile = File(pickedFile.path);
                    // TODO: Submit image or something.
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
        SizedBox(
          // Height is 72 to match profile avatar on left of row
          height: 72,
          // Width of 206 is exactly the width used by all the Positioned stuff
          width: 206,
          child: Column(
            children: [
              Text(
                title,
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
                  clipBehavior: Clip.none,
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
                        onPressed: inviteCallback,
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
        ),
      ],
    );
  }
} */