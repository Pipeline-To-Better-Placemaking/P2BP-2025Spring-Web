import 'package:flutter/material.dart';
import 'theme.dart';

// For page selection switch. 0 = project, 1 = team.
enum PageView { project, team }



class CreateProjectAndTeamsPage extends StatefulWidget {
  const CreateProjectAndTeamsPage({super.key});

  @override
  State<CreateProjectAndTeamsPage> createState() =>
      _CreateProjectAndTeamsPageState();
}

// TODO: Align labels, standardize colors. Create teams page.
class _CreateProjectAndTeamsPageState extends State<CreateProjectAndTeamsPage> {
  PageView page = PageView.project;
  PageView pageSelection = PageView.project;
  final pages = [
    const CreateProjectWidget(),
    const CreateTeamWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF1C48A6),
        // Top switch between Projects/Teams
        appBar: AppBar(
          title: const Text('Create a New Team, or a New Project'),
        ),
        // Creation screens
        body: SingleChildScrollView(
          child: Center(
            child: Card(
              child: Column(
                children: <Widget>[
                  // Switch at top to switch between create project and team pages.
                  SegmentedButton(
                    selectedIcon: const Icon(Icons.check_circle),
                    style: SegmentedButton.styleFrom(
                      backgroundColor: const Color(0xFF3664B3),
                      foregroundColor: Colors.white70,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: const Color(0xFF2E5598),
                      side: const BorderSide(
                        width: 0,
                        color: Color(0xFF2180EA),
                      ),
                      elevation: 100,
                      visualDensity:
                          const VisualDensity(vertical: 1, horizontal: 1),
                    ),
                    segments: const <ButtonSegment>[
                      ButtonSegment(
                          value: PageView.project,
                          label: Text('Project'),
                          icon: Icon(Icons.developer_board)),
                      ButtonSegment(
                          value: PageView.team,
                          label: Text('Team'),
                          icon: Icon(Icons.people)),
                    ],
                    selected: {pageSelection},
                    onSelectionChanged: (Set newSelection) {
                      setState(() {
                        // By default there is only a single segment that can be
                        // selected at one time, so its value is always the first
                        // item in the selected set.
                        pageSelection = newSelection.first;
                      });
                    },
                  ),

                  // Spacing between button and container w/ pages.
                  const SizedBox(height: 100),

                  // Changes page between two widgets: The CreateProjectWidget and CreateTeamWidget.
                  // These widgets display their respective screens to create either a project or team.
                  pages[pageSelection.index],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateProjectWidget extends StatelessWidget {
  const CreateProjectWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 500,
      decoration: const BoxDecoration(
        color: Colors.white30,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: <Widget>[
            const Text(
              'Cover Photo',
              textAlign: TextAlign.left,
            ),
            // TODO: Extract to themes? move themes back to respective files
            PhotoUpload(
              width: 380,
              height: 125,
              icon: Icons.add_photo_alternate,
              circular: false,
              onTap: () {
                // TODO: Actual function
                print('Test');
                return;
              },
            ),
            const Text(
              'Project Name',
              textAlign: TextAlign.left,
            ),
            const CreationTextBox(
                maxLength: 60,
                labelText: 'Project Name',
                maxLines: 1,
                minLines: 1),
            const Text(
              'Project Description',
              textAlign: TextAlign.left,
            ),
            const CreationTextBox(
                maxLength: 240,
                labelText: 'Project Description',
                maxLines: 3,
                minLines: 3),
            Align(
              alignment: Alignment.centerRight,
              child: EditButton(
                text: 'Next',
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF4871AE),
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  // function
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CreateTeamWidget extends StatelessWidget {
  const CreateTeamWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 500,
      decoration: const BoxDecoration(
        color: Colors.white30,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: <Widget>[
            const Row(
              children: <Widget>[
                Text(
                  'Team Photo',
                  textAlign: TextAlign.left,
                ),
                Text(
                  'Team Color',
                  textAlign: TextAlign.left,
                ),
              ],
            ),
            Row(
              children: <Widget>[
                PhotoUpload(
                  width: 75,
                  height: 75,
                  icon: Icons.add_photo_alternate,
                  circular: true,
                  onTap: () {
                    // TODO: Actual function
                    print('Test');
                    return;
                  },
                ),
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ColorSelectCircle(
                          gradient: defaultGrad,
                        ),
                        ColorSelectCircle(
                          gradient: defaultGrad,
                        ),
                        ColorSelectCircle(
                          gradient: defaultGrad,
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        ColorSelectCircle(
                          gradient: defaultGrad,
                        ),
                        ColorSelectCircle(
                          gradient: defaultGrad,
                        ),
                        ColorSelectCircle(
                          gradient: defaultGrad,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Text(
              'Team Name',
              textAlign: TextAlign.left,
            ),
            const CreationTextBox(
                maxLength: 60,
                labelText: 'Team Name',
                maxLines: 1,
                minLines: 1),
            const Text(
              'Members',
              textAlign: TextAlign.left,
            ),
            CreationTextBox(
              maxLength: 60,
              labelText: 'Members',
              maxLines: 1,
              minLines: 1,
              icon: const Icon(Icons.search),
              onChanged: (text) {
                print('Members text field: $text');
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: EditButton(
                text: 'Create',
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF4871AE),
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  // function
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ColorSelectCircle extends StatelessWidget {
  final Gradient gradient;

  const ColorSelectCircle({
    super.key,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      width: 30,
      height: 30,
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
        ));
  }
}