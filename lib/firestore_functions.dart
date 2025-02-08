import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'db_schema_classes.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final User? _loggedInUser = FirebaseAuth.instance.currentUser;

// NOTE: When creating delete functionality, delete ALL instances of object.
// Make sure to delete references in other objects (i.e. deleting a team should
// delete it in the user's data). For simplicity, any objects that may be
// deleted should contain references to the objects which contain it.

class FirestoreFunctions {
  /// Gets the value of fullName from 'users' the document for the given uid.
  /// Contains error handling for every case starting from uid being null.
  /// This will always either return the successfully found name or throw
  /// an exception, so running this in a try-catch is strongly encouraged.
  static Future<String> getUserFullName(String? uid) async {
    try {
      if (uid == null) {
        throw Exception('no-user-id-found');
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String? fullName = userDoc['fullName'];
        if (fullName == null || fullName.isEmpty) {
          throw Exception('user-has-no-name');
        } else {
          return fullName;
        }
      } else {
        throw Exception('user-document-does-not-exist');
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}

/// Saves team after team creation in create_project_and_teams.dart. Takes in a
/// list of members to invite and the name of the team. User who created the
/// team is designated as owner. Projects list created to avoid retrieval
/// issues. Returns future of String of teamID.
Future<String> saveTeam(
    {required membersList, required String teamName}) async {
  String teamID = _firestore.collection('teams').doc().id;
  await _firestore.collection("teams").doc(teamID).set({
    'title': teamName,
    'creationTime': FieldValue.serverTimestamp(),
    // Saves document id as field _id
    'id': teamID,
    'projects': [],
    'teamMembers': FieldValue.arrayUnion([
      {'role': 'owner', 'user': _firestore.doc('users/${_loggedInUser?.uid}')}
    ]),
  });
  await _firestore.collection("users").doc(_loggedInUser?.uid).update({
    'teams': FieldValue.arrayUnion([_firestore.doc('/teams/$teamID')])
  });
  // Currently: invites team members only once team is created.
  for (Member members in membersList) {
    await _firestore.collection('users').doc(members.getUserID()).update({
      'invites': FieldValue.arrayUnion([_firestore.doc('/teams/$teamID')])
    });
  }

  // Debugging print statement.
  // print("Teams reference: ${_firestore.doc('/teams/$teamID')}");

  return teamID;
}

/// Saves project after project creation in create_project_and_teams.dart. Takes
/// fields for project: String projectTitle, String description,
/// DocumentReference teamRef, and List`<GeoPoint>` polygonPoints. Saves it in
/// teams collection too.
Future<Project> saveProject(
    {required String projectTitle,
    required String description,
    required DocumentReference? teamRef,
    required List<GeoPoint> polygonPoints}) async {
  Project tempProject;
  String projectID = _firestore.collection('projects').doc().id;

  if (teamRef == null) {
    throw Exception(
        "teamRef not defined when passed to saveProject() in firestore_functions.dart");
  }

  await _firestore.collection('projects').doc(projectID).set({
    'title': projectTitle,
    'creationTime': FieldValue.serverTimestamp(),
    // Saves document id as field _id
    'id': projectID,
    'team': teamRef,
    'description': description,
    'polygonPoints': polygonPoints,
  });

  await _firestore.doc('/${teamRef.path}').update({
    'projects': FieldValue.arrayUnion([_firestore.doc('/projects/$projectID')])
  });

  tempProject = Project(
    teamRef: teamRef,
    projectID: projectID,
    title: projectTitle,
    description: description,
    polygonPoints: polygonPoints,
  );

  // Debugging print statement.
  // print("Done in project creation. Putting /projects/$projectID into $teamRef.");

  return tempProject;
}

/// Retrieves project info from Firestore. Returns a Future`<Project>`. Takes
/// projectID. Uses projectID to retrieve info, then saves it into a Project
/// object for future use.
Future<Project> getProjectInfo(String projectID) async {
  late Project project;
  final DocumentSnapshot<Map<String, dynamic>> projectDoc;

  try {
    projectDoc = await _firestore.collection("projects").doc(projectID).get();
    project = Project(
      teamRef: projectDoc['team'],
      projectID: projectDoc['id'],
      title: projectDoc['title'],
      description: projectDoc['description'],
      polygonPoints: projectDoc['polygonPoints'],
    );
  } catch (e, stacktrace) {
    print('Exception retrieving teams: $e');
    print('Stacktrace: $stacktrace');
  }
  return project;
}

/// Calling this function returns a future reference to the currently selected
/// team. If retrieval throws an exception, then returns null. When implementing
/// this function, check for null before using value.
Future<DocumentReference?> getCurrentTeam() async {
  DocumentReference teamRef;
  final DocumentSnapshot<Map<String, dynamic>> userDoc;

  try {
    userDoc =
        await _firestore.collection('users').doc(_loggedInUser?.uid).get();
    teamRef = await userDoc['selectedTeam'];
  } catch (e) {
    print("Exception trying to getCurrentTeam(): $e");
    return null;
  }
  return teamRef;
}

/// Takes a team reference and returns a list of projects belonging to that
/// team. If the team contains no projects, returns an empty list. Otherwise
/// returns a future for a list of Project objects.
Future<List<Project>> getTeamProjects(DocumentReference teamRef) async {
  List<Project> projectList = [];
  final DocumentSnapshot<Map<String, dynamic>> teamDoc;
  Project tempProject;

  try {
    teamDoc = await _firestore.doc(teamRef.path).get();

    if (teamDoc.exists && teamDoc.data()!.containsKey('projects')) {
      for (var projectRef in teamDoc['projects']) {
        print("Project getting: $projectList");
        tempProject = await getProjectInfo(projectRef.id);
        projectList.add(tempProject);
      }
    }
  } catch (e, stacktrace) {
    print("Exception in firestore_functions.dart, getTeamProjects(): $e");
    print("Stacktrace: $stacktrace");
  }

  return projectList;
}

/// Fetches the current user's list of invites (team references). Extracts the
/// data from them and puts them into a Team object. Returns them as a future
/// of a list of Team objects. Checks to make sure document exists
/// and invites field properly created (should *always* be created, failsafe).
Future<List<Team>> getInvites() async {
  List<Team> teamInvites = [];
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  DocumentSnapshot<Map<String, dynamic>> teamDoc;

  try {
    userDoc =
        await _firestore.collection("users").doc(_loggedInUser?.uid).get();
    Team tempTeam;
    if (userDoc.exists && userDoc.data()!.containsKey('invites')) {
      for (DocumentReference teamRef in userDoc['invites']) {
        teamDoc = await _firestore.doc(teamRef.path).get();
        // TODO: Add admin name (where role = owner)
        if (teamDoc.exists) {
          tempTeam = Team(
            teamID: teamDoc['id'],
            title: teamDoc['title'],
            adminName: 'Temp',
          );

          teamInvites.add(tempTeam);
        }
      }
    }
  } catch (e, stacktrace) {
    print('Exception retrieving teams: $e');
    print('Stacktrace: $stacktrace');
  }

  return teamInvites;
}

/// Fetches the current user's list of teams (team references). Extracts the
/// data from them and puts them into a Team object. Returns them as a future
/// of a list of Team objects. Checks to make sure document exists
/// and teams field properly created (should *always* be created, failsafe).
Future<List<Team>> getTeamsIDs() async {
  List<Team> teams = [];
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  DocumentSnapshot<Map<String, dynamic>> teamDoc;

  try {
    userDoc =
        await _firestore.collection("users").doc(_loggedInUser?.uid).get();
    Team tempTeam;
    if (userDoc.exists && userDoc.data()!.containsKey('teams')) {
      for (DocumentReference teamRef in userDoc['teams']) {
        teamDoc = await _firestore.doc(teamRef.path).get();

        // TODO: Add num projects, members list instead of adminName
        tempTeam = Team(
          teamID: teamDoc['id'],
          title: teamDoc['title'],
          adminName: 'Temp',
        );

        teams.add(tempTeam);
      }
    }
  } catch (e, stacktrace) {
    print('Exception retrieving teams: $e');
    print('Stacktrace: $stacktrace');
  }

  return teams;
}

/// Removes the invite from the user. Checks if the user exists and has invites
/// field (*always* should). Makes sure that the invites field contains the
/// invite being deleted. If so removes it from database.
Future<void> removeInviteFromUser(String teamID) async {
  final DocumentReference<Map<String, dynamic>> userRef;
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  final DocumentReference<Map<String, dynamic>> teamRef;

  try {
    userRef = _firestore.collection('users').doc('${_loggedInUser?.uid}');
    userDoc = await userRef.get();
    teamRef = _firestore.doc('teams/$teamID');

    if (userDoc.exists && userDoc.data()!.containsKey('invites')) {
      if (userDoc.data()!['invites'].contains(teamRef)) {
        // Remove invite from invites field
        userRef.update({
          'invites': FieldValue.arrayRemove([teamRef]),
        });
      } else {
        // TODO: Display a message to user:
        print("Error in addUserToTeam()! No invite matching that id.");
      }
    }
  } catch (e, stacktrace) {
    print('Exception accepting team invite: $e');
    print('Stacktrace: $stacktrace');
  }
}

/// Adds user to team when they accept the invite. Checks if the user exists,
/// has invites field (*always* should), and the team still exists. If so, adds
/// user to teams collection and remove invite from the user's database. If
/// team no longer exists, removes invite from user's account without joining.
Future<void> addUserToTeam(String teamID) async {
  final DocumentReference<Map<String, dynamic>> userRef;
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  final DocumentReference<Map<String, dynamic>> teamRef;
  final DocumentSnapshot<Map<String, dynamic>> teamDoc;

  try {
    userRef = _firestore.collection('users').doc('${_loggedInUser?.uid}');
    userDoc = await userRef.get();
    teamRef = _firestore.doc('teams/$teamID');
    teamDoc = await teamRef.get();

    if (userDoc.exists && userDoc.data()!.containsKey('invites')) {
      if (userDoc.data()!['invites'].contains(teamRef)) {
        if (teamDoc.exists) {
          // Add team to teams field, remove from invites field
          userRef.update({
            'teams': FieldValue.arrayUnion([teamRef]),
            'invites': FieldValue.arrayRemove([teamRef]),
          });
          teamRef.update({
            'teamMembers': FieldValue.arrayUnion([
              {
                'role': 'user',
                'user': _firestore.doc('users/${_loggedInUser?.uid}')
              }
            ]),
          });
        } else {
          // TODO: Display a message to user:
          print("Team no longer exists. Deleting invite.");
          userRef.update({
            'invites': FieldValue.arrayRemove([teamRef]),
          });
        }
      } else {
        print("Error in addUserToTeam()! No invite matching that id.");
      }
    }
  } catch (e, stacktrace) {
    print('Exception accepting team invite: $e');
    print('Stacktrace: $stacktrace');
  }
}
