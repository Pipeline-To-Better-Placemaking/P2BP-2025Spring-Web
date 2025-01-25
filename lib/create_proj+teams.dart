import 'package:flutter/material.dart';
import 'widgets.dart';
import 'themes.dart';
import 'search_loc.dart';

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
        // Top switch between Projects/Teams
        appBar: AppBar(
          title: const Text('Placeholder'),
        ),
        // Creation screens
        body: SingleChildScrollView(
          child: Center(
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cover Photo',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 5),
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
            const SizedBox(height: 15.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Project Name',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 5),
            const CreationTextBox(
              maxLength: 60,
              labelText: 'Project Name',
              maxLines: 1,
              minLines: 1,
            ),
            const SizedBox(height: 10.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Project Description',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 5),
            const CreationTextBox(
              maxLength: 240,
              labelText: 'Project Description',
              maxLines: 3,
              minLines: 3,
            ),
            const SizedBox(height: 10.0),
            Align(
              alignment: Alignment.bottomRight,
              child: EditButton(
                text: 'Next',
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF4871AE),
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SearchScreen()));
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
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 75.0, bottom: 5),
                  child: Text(
                    'Team Photo',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 75.0, bottom: 5),
                  child: Text(
                    'Team Color',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 75.0),
                    child: PhotoUpload(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 75.0),
                    child: Column(
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
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Team Name',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            const CreationTextBox(
              maxLength: 60,
              labelText: 'Team Name',
              maxLines: 1,
              minLines: 1,
            ),
            const SizedBox(height: 10.0),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Members',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 5.0),
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
            const SizedBox(height: 10.0),
            Align(
              alignment: Alignment.bottomRight,
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
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
        ),
        width: 30,
        height: 30,
      ),
    );
  }
}