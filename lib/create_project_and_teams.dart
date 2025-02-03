import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/homepage.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';
import 'main.dart';
import 'themes.dart';
import 'search_location_screen.dart';
import 'db_schema_classes.dart';
import 'widgets.dart';
import 'home_screen.dart';

// For page selection switch. 0 = project, 1 = team.
enum PageView { project, team }

class CreateProjectAndTeamsPage extends StatefulWidget {
  const CreateProjectAndTeamsPage({super.key});

  @override
  State<CreateProjectAndTeamsPage> createState() =>
      _CreateProjectAndTeamsPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? loggedInUser = FirebaseAuth.instance.currentUser;

String saveTeam({required membersList, required String teamName}) {
  String teamID = _firestore.collection('teams').doc().id;
  if (teamName.length > 3) {
    _firestore.collection("teams").doc(teamID).set({
      'title': teamName,
      'creationTime': FieldValue.serverTimestamp(),
      // Saves document id as field _id
      'id': teamID,
      'teamMembers': FieldValue.arrayUnion([
        {'role': 'owner', 'user': _firestore.doc('users/${loggedInUser?.uid}')}
      ]),
    }).then((documentSnapshot) => print("Data awith ID: $teamID"));
    _firestore.collection("users").doc(loggedInUser?.uid).update({
      'teams': FieldValue.arrayUnion([_firestore.doc('/teams/$teamID')])
    });
    // TODO Currently: invites team members only once team is created.
    for (Member members in membersList) {
      _firestore.collection('users').doc(members.getUserID()).update({
        'invites': FieldValue.arrayUnion([_firestore.doc('/teams/$teamID')])
      });
    }
  } else {
    print("Name too short"); // <-- TODO: change to field display error on app
  }
  print(_firestore.doc('/teams/$teamID'));

  return teamID;
}

String saveProject({required membersList, required String projectTitle}) {
  String projectID = _firestore.collection('projects').doc().id;
  if (projectTitle.length > 3) {
    _firestore.collection('projects').doc().set({
      'title': projectTitle,
      'creationTime': FieldValue.serverTimestamp(),
      // Saves document id as field _id
      'id': projectID,
      //'team': getCurrentTeam(),
    });
  } else {
    print("Name too short"); // <-- TODO: change to field display error on app
  }
  print(_firestore.doc('/projects/$projectID'));

  return projectID;
}

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
      maintainBottomViewPadding: true,
      child: Scaffold(
        // Top switch between Projects/Teams
        appBar: AppBar(),
        // Creation screens
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                // Switch at top to switch between create project and team pages.
                SegmentedButton(
                  selectedIcon: const Icon(Icons.check_circle),
                  style: SegmentedButton.styleFrom(
                    iconColor: Colors.white,
                    backgroundColor: const Color(0xFF4871AE),
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
                SizedBox(height: MediaQuery.of(context).size.height * .025),

                // Changes page between two widgets: The CreateProjectWidget and CreateTeamWidget.
                // These widgets display their respective screens to create either a project or team.
                pages[pageSelection.index],

                SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateProjectWidget extends StatefulWidget {
  const CreateProjectWidget({
    super.key,
  });

  @override
  State<CreateProjectWidget> createState() => _CreateProjectWidgetState();
}

class _CreateProjectWidgetState extends State<CreateProjectWidget> {
  // TODO: add cover photo?
  String projectDescription = '';
  String projectTitle = '';
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
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
                  height: 130,
                  icon: Icons.add_photo_alternate,
                  circular: false,
                  onTap: () {
                    // TODO: Actual function (Photo Upload)
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
                CreationTextBox(
                  maxLength: 60,
                  labelText: 'Project Name',
                  maxLines: 1,
                  minLines: 1,
                  errorMessage:
                      'Project names must be at least 3 characters long.',
                  onChanged: (titleText) {
                    setState(() {
                      projectTitle = titleText;
                    });
                  },
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
                CreationTextBox(
                  maxLength: 240,
                  labelText: 'Project Description',
                  maxLines: 3,
                  minLines: 3,
                  errorMessage:
                      'Project descriptions must be at least 3 characters long.',
                  onChanged: (descriptionText) {
                    setState(() {
                      projectDescription = descriptionText;
                    });
                  },
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
                      if (_formKey.currentState!.validate()) {
                        Project partialProject = Project.partialProject(
                            title: projectTitle,
                            description: projectDescription);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchScreen(
                                    partialProjectData: partialProject)));
                      } // function
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateTeamWidget extends StatefulWidget {
  const CreateTeamWidget({
    super.key,
  });

  @override
  State<CreateTeamWidget> createState() => _CreateTeamWidgetState();
}

List<Member> searchMembers(List<Member> membersList, String text) {
  membersList = membersList
      .where((member) =>
          member.getFullName().toLowerCase().startsWith(text.toLowerCase()))
      .toList();
  print('membersList: $membersList');
  return membersList.isNotEmpty ? membersList : [];
}

class _CreateTeamWidgetState extends State<CreateTeamWidget> {
  List<Member> membersList = [];
  List<Member> membersSearch = [];
  List<Member> invitedMembers = [];
  String teamName = '';
  int itemCount = 0;
  final _formKey = GlobalKey<FormState>();
  String teamID = '';

  @override
  initState() {
    super.initState();
    teamID = _firestore.collection('teams').doc().id;
    _firestore.collection('users').where('createdAt', isNull: false).get().then(
      (querySnapshot) {
        Member tempMember;
        for (var document in querySnapshot.docs) {
          if (document.id != loggedInUser?.uid) {
            tempMember = Member(
                userID: document.id, fullName: document.data()['fullName']);
            membersList.add(tempMember);
          }
        }
        print("Successfully completed");
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 25.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          'Team Photo',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.blue[900],
                          ),
                        ),
                        SizedBox(height: 5),
                        PhotoUpload(
                          width: 75,
                          height: 75,
                          icon: Icons.add_photo_alternate,
                          circular: true,
                          onTap: () {
                            // TODO: Actual function (Photo Upload)
                            print('Test');
                            return;
                          },
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          'Team Color',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.blue[900],
                          ),
                        ),
                        SizedBox(height: 5),
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
                  ],
                ),
                SizedBox(height: 10),
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
                CreationTextBox(
                  maxLength: 60,
                  labelText: 'Team Name',
                  maxLines: 1,
                  minLines: 1,
                  errorMessage:
                      'Team names must be at least 3 characters long.',
                  onChanged: (teamText) {
                    teamName = teamText;
                  },
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
                  onChanged: (memberText) {
                    setState(() {
                      if (memberText.length > 2) {
                        membersSearch = searchMembers(membersList, memberText);
                        itemCount = membersSearch.length;
                      } else {
                        itemCount = 0;
                      }
                    });
                    print('Members text field: $memberText');
                  },
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: 250,
                  child: itemCount > 0
                      ? ListView.separated(
                          itemCount: itemCount,
                          padding: const EdgeInsets.only(
                            left: 5,
                            right: 5,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return buildInviteCard(
                                member: membersSearch[index], index: index);
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(
                            height: 10,
                          ),
                        )
                      : const Center(
                          child: Text(
                              'No users matching criteria. Enter at least 3 characters to search.'),
                        ),
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
                      if (_formKey.currentState!.validate()) {
                        // TODO: If the form is valid, display a snackbar, await database
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Processing Data')),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamsAndInvitesPage(),
                          ),
                        );
                      }
                      saveTeam(membersList: invitedMembers, teamName: teamName);
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card buildInviteCard({required Member member, required int index}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            CircleAvatar(),
            SizedBox(width: 15),
            Expanded(
              child: Text(member.getFullName()),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: memberInviteButton(
                  teamID: teamID, index: index, member: member),
            ),
          ],
        ),
      ),
    );
  }

  InkWell memberInviteButton(
      {required int index, required String teamID, required Member member}) {
    return InkWell(
      child: Text(member.getInvited() == true ? "Invite sent!" : "Invite"),
      onTap: () {
        setState(() {
          if (member.getInvited() == false) {
            member.setInvited(true);
            invitedMembers.add(member);
          }
        });
      },
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