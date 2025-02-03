import 'package:flutter/material.dart';
import 'teams_settings_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'db_schema_classes.dart';

class TeamsAndInvitesPage extends StatefulWidget {
  const TeamsAndInvitesPage({super.key});

  @override
  State<TeamsAndInvitesPage> createState() => _TeamsAndInvitesPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? loggedInUser = FirebaseAuth.instance.currentUser;

class _TeamsAndInvitesPageState extends State<TeamsAndInvitesPage> {
  List<Team> teams = [];
  List invites = [];
  int teamsCount = 0;
  int invitesCount = 0;
  int selectedIndex = 0;

  void getTeamsIDs() {
    try {
      _firestore.collection("users").doc(loggedInUser?.uid).get().then(
        (querySnapshot) {
          Team tempTeam;
          for (var reference in querySnapshot.data()?['teams']) {
            _firestore.doc(reference.path).get().then((teamQuerySnapshot) {
              // TODO: Add num projects, members list instead of adminName
              tempTeam = Team(
                  teamID: teamQuerySnapshot['id'],
                  title: teamQuerySnapshot['title'],
                  adminName: 'Temp');
              teams.add(tempTeam);
              setState(() {
                teamsCount = teams.length;
              });
            });
          }
        },
        onError: (e) => print("Error completing: $e"),
      );
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  void getInvites() {
    try {
      _firestore.collection("users").doc(loggedInUser?.uid).get().then(
        (querySnapshot) {
          Team tempTeam;
          for (var reference in querySnapshot.data()?['invites']) {
            _firestore.doc(reference.path).get().then((teamQuerySnapshot) {
              // TODO: Add admin name.
              tempTeam = Team(
                  teamID: teamQuerySnapshot['id'],
                  title: teamQuerySnapshot['title'],
                  adminName: 'Temp');
              invites.add(tempTeam);
              setState(() {
                invitesCount = invites.length;
              });
            });
          }
        },
        onError: (e) => print("Error completing: $e"),
      );
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  @override
  void initState() {
    super.initState();
    getTeamsIDs();
    getInvites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              labelColor: Colors.blue,
              indicatorColor: Colors.blue,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  child: Text(
                    'Teams',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Tab(
                  child: Text(
                    'Invites',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          // TODO: make pull down refresh?
          body: TabBarView(
            children: [
              teamsCount > 0
                  ? ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 35,
                        right: 35,
                        top: 50,
                        bottom: 20,
                      ),
                      itemCount: teamsCount,
                      itemBuilder: (BuildContext context, int index) {
                        return buildContainer(
                            index: index,
                            color: Colors.blue,
                            numProjects: 12, //<-- TODO: edit
                            teamName: teams[index].title,
                            teamID: teams[index].teamID);
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(
                        height: 50,
                      ),
                    )
                  : Center(
                      child: Text(
                          "You have no teams! Join a team or create one first."),
                    ),

              // Iterate through list of projects, each being a card.
              // Update variables each time with: color, team name, num of
              // projects, and members list from database.
              invitesCount > 0
                  ? ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 35,
                        right: 35,
                        top: 25,
                        bottom: 25,
                      ),
                      itemCount: invitesCount,
                      itemBuilder: (BuildContext context, int index) {
                        return InviteCard(
                          color: Colors.blue,
                          name: invites[index].adminName,
                          teamName: invites[index].title,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(
                        height: 25,
                      ),
                    )
                  : const Center(child: Text('You have no invites!')),
            ],
          ),
        ),
      ),
    );
  }

  Container buildContainer(
      {required int index,
      required Color color,
      required int numProjects,
      required String teamName,
      required String teamID}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 200,
      child: Row(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 10.0, bottom: 10.0, right: 5.0, top: 5.0),
              child: Tooltip(
                message: "Select team",
                child: InkWell(
                  child: selectedIndex == index
                      ? const Icon(Icons.radio_button_on)
                      : const Icon(Icons.radio_button_off),
                  onTap: () {
                    _firestore
                        .collection('users')
                        .doc(loggedInUser?.uid)
                        .update({
                      'selectedTeam': _firestore.doc('/teams/$teamID'),
                    });
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
              ),
            ),
          ),
          const CircleAvatar(
            radius: 35,
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Team: '),
                      TextSpan(
                        text: teamName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text.rich(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$numProjects ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: 'Projects'),
                    ],
                  ),
                ),
                const Row(
                  children: [
                    Text(
                      'Members: ',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
              tooltip: 'Open team settings',
              onPressed: () {
                // TODO: Actual function
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TeamSettingsScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InviteCard extends StatelessWidget {
  final Color color;
  final String name;
  final String teamName;
  // TODO: final List<Members> members; (for cover photo, not implemented yet)

  const InviteCard({
    super.key,
    required this.color,
    required this.name,
    required this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(width: 15),
          const CircleAvatar(
            radius: 25,
          ),
          Flexible(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Text.rich(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' has invited you to join: '),
                        TextSpan(
                          text: teamName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Accept invitation',
                        color: Colors.white,
                        onPressed: () {
                          // TODO: Actual function
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Deny invitation',
                        color: Colors.white,
                        onPressed: () {
                          // TODO: Actual function
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
        ],
      ),
    );
  }
}