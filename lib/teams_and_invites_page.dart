import 'package:flutter/material.dart';
import 'teams_settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_functions.dart';
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
  List<Team> teamInvites = [];
  DocumentReference? currentTeam;
  bool _isLoadingTeams = true;
  bool _isLoadingInvites = true;
  int teamsCount = 0;
  int invitesCount = 0;
  int selectedIndex = 0;

  // Gets user info and once that is done gets teams and invites
  Future<void> _getInvites() async {
    try {
      teamInvites = await getInvites();
      setState(() {
        _isLoadingInvites = false;
        invitesCount = teamInvites.length;
      });
    } catch (e, stacktrace) {
      print('Exception retrieving invites: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  Future<void> _getTeams() async {
    try {
      teams = await getTeamsIDs();
      currentTeam = await getCurrentTeam();

      setState(() {
        if (currentTeam == null) {
          // No selected team:
          print("No team selected. Defaulting to first if available.");
          // TODO: Case if teams is not empty and not selected
          // await _firestore
          //     .collection('users')
          //     .doc(loggedInUser?.uid)
          //     .update({
          //   'selectedTeam': _firestore.doc('/teams/$teamID'),
          // });
          selectedIndex = -1;
        } else if (teams.isNotEmpty) {
          // A list of teams with a selected team:
          selectedIndex = teams.indexWhere(
              (team) => team.teamID.compareTo(currentTeam!.id) == 0);
        } else {
          // No teams but a selected team:
          selectedIndex = -1;
        }
        _isLoadingTeams = false;
        teamsCount = teams.length;
      });
    } catch (e, stacktrace) {
      print('Exception retrieving teams: $e');
      print('Stacktrace: $stacktrace');
    }
  }

  @override
  void initState() {
    super.initState();
    _getTeams();
    _getInvites();
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
          body: TabBarView(
            children: [
              teamsCount > 0
                  // If user has teams, display them
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await _getTeams();
                      },
                      child: ListView.separated(
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
                              numProjects: teams[index].numProjects,
                              team: teams[index]);
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(
                          height: 50,
                        ),
                      ),
                    )
                  : _isLoadingTeams
                      // If teams are loading display loading indicator
                      ? const Center(child: CircularProgressIndicator())
                      // Else display text to join a team
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _getTeams();
                          },
                          child: CustomScrollView(
                            slivers: <Widget>[
                              SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                      "You have no teams! Join or create one first."),
                                ),
                              ),
                            ],
                          ),
                        ),

              // Iterate through list of invites, each being a card.
              // Update variables each time with: color, team name, num of
              // projects, and members list from database.
              teamInvites.isNotEmpty
                  // If user has invites, display them
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await _getInvites();
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.only(
                          left: 35,
                          right: 35,
                          top: 25,
                          bottom: 25,
                        ),
                        itemCount: teamInvites.length,
                        itemBuilder: (BuildContext context, int index) {
                          return buildInviteCard(index);
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(
                          height: 25,
                        ),
                      ),
                    )
                  // Else if user does not have invites
                  : _isLoadingInvites
                      // If invites are loading, display loading indicator
                      ? const Center(child: CircularProgressIndicator())
                      // Else display text telling to refresh
                      : RefreshIndicator(
                          onRefresh: () async {
                            await _getInvites();
                          },
                          child: CustomScrollView(
                            slivers: <Widget>[
                              SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                      "You have no invites! Refresh the page."),
                                ),
                              ),
                            ],
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Container buildInviteCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(width: 15),
          const CircleAvatar(
            radius: 50,
          ),
          const SizedBox(width: 15),
          Flexible(
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    TextSpan(
                      children: [
                        TextSpan(
                          text: teamInvites[index].adminName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' has invited you to join: '),
                        TextSpan(
                          text: teamInvites[index].title,
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
                          // Add to database
                          addUserToTeam(teamInvites[index].teamID);
                          // Remove invite from screen
                          setState(() {
                            teamInvites.removeWhere((team) =>
                                team.teamID
                                    .compareTo(teamInvites[index].teamID) ==
                                0);
                            teamsCount = teamInvites.length;
                          });
                        },
                      ),
                      IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Decline invitation',
                          color: Colors.white,
                          onPressed: () {
                            // Remove invite from database
                            removeInviteFromUser(teamInvites[index].teamID);
                            // Remove invite from screen
                            setState(() {
                              teamInvites.removeWhere((team) =>
                                  team.teamID
                                      .compareTo(teamInvites[index].teamID) ==
                                  0);
                              teamsCount = teamInvites.length;
                            });
                          }),
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

  Container buildContainer({
    required int index,
    required Color color,
    required int numProjects,
    required Team team,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      height: 200,
      child: Row(
        children: <Widget>[
          InkWell(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10.0, bottom: 10.0, right: 5.0, top: 5.0),
                child: Tooltip(
                  message: "Select team",
                  child: selectedIndex == index
                      ? const Icon(Icons.radio_button_on)
                      : const Icon(Icons.radio_button_off),
                ),
              ),
            ),
            onTap: () async {
              await _firestore
                  .collection('users')
                  .doc(loggedInUser?.uid)
                  .update({
                'selectedTeam': _firestore.doc('/teams/${team.teamID}'),
              });
              setState(() {
                selectedIndex = index;
              });
              // Debugging print statement:
              // print("Index: $index, Title: ${teams[index].title}");
            },
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
                        text: team.title,
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
                // TODO: Actual function (chevron right, team settings)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TeamSettingsScreen(activeTeam: team)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}