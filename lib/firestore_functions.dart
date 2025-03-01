import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'db_schema_classes.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final User? _loggedInUser = FirebaseAuth.instance.currentUser;

// NOTE: When creating delete functionality, delete ALL instances of object.
// Make sure to delete references in other objects (i.e. deleting a team should
// delete it in the user's data). For simplicity, any objects that may be
// deleted should contain references to the objects which contain it.

/// Gets the value of fullName from the 'users' document for the given uid.
/// Contains error handling for every case starting from uid being null.
/// This will always either return the successfully found name or throw
/// an exception, so running this in a try-catch is strongly encouraged.
Future<String> getUserFullName(String? uid) async {
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

  // Debugging print statement:
  // print("Teams reference: ${_firestore.doc('/teams/$teamID')}");

  return teamID;
}

/// Saves project after project creation in create_project_and_teams.dart. Takes
/// fields for project: `String` projectTitle, `String` description,
/// `DocumentReference` teamRef, and `List<GeoPoint>` polygonPoints. Saves it in
/// teams collection too.
Future<Project> saveProject({
  required String projectTitle,
  required String description,
  required DocumentReference? teamRef,
  required List<GeoPoint> polygonPoints,
  required num polygonArea,
}) async {
  Project tempProject;
  String projectID = _firestore.collection('projects').doc().id;

  if (teamRef == null) {
    throw Exception(
        "teamRef not defined when passed to saveProject() in firestore_functions.dart");
  }

  await _firestore.collection('projects').doc(projectID).set({
    'title': projectTitle,
    'creationTime': FieldValue.serverTimestamp(),
    'id': projectID,
    'team': teamRef,
    'description': description,
    'polygonPoints': polygonPoints,
    'polygonArea': polygonArea,
    'tests': [],
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
    polygonArea: polygonArea,
    tests: [],
  );

  // Debugging print statement.
  // print("Done in project creation. Putting /projects/$projectID into $teamRef.");

  return tempProject;
}

/// Retrieves project info from Firestore. Returns a `Future<Project>`. Takes
/// projectID. Uses projectID to retrieve info, then saves it into a Project
/// object for future use.
Future<Project> getProjectInfo(String projectID) async {
  late Project project;
  final DocumentSnapshot<Map<String, dynamic>> projectDoc;

  try {
    projectDoc = await _firestore.collection("projects").doc(projectID).get();
    if (projectDoc.exists && projectDoc.data()!.containsKey('polygonArea')) {
      // Create List of Tests from List of DocumentReferences
      List<Test> testList = [];
      // TODO: maybe remove 'tests' check after DB purge or something
      if (projectDoc.data()!.containsKey('tests')) {
        for (final ref in projectDoc['tests']) {
          testList.add(await getTestInfo(ref));
        }
      }

      project = Project(
        teamRef: projectDoc['team'],
        projectID: projectDoc['id'],
        title: projectDoc['title'],
        description: projectDoc['description'],
        polygonPoints: projectDoc['polygonPoints'],
        polygonArea: projectDoc['polygonArea'],
        creationTime: projectDoc['creationTime'],
        tests: testList,
      );
    } else {
      print(
          'Error in firestore_functions: Either project does not exist in Firestore or polygonArea is not initialized');
      print('Project exists? ${projectDoc.exists}.');
    }
  } catch (e, stacktrace) {
    print('Exception retrieving project: $e');
    print('Stacktrace: $stacktrace');
  }
  return project;
}

/// Calling this function returns a future reference to the currently selected
/// team. If retrieval throws an exception, then returns `null`. When
/// implementing this function, check for `null` before using value.
Future<DocumentReference?> getCurrentTeam() async {
  DocumentReference? teamRef;
  final DocumentSnapshot<Map<String, dynamic>> userDoc;

  try {
    userDoc =
        await _firestore.collection('users').doc(_loggedInUser?.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('selectedTeam')) {
      teamRef = await userDoc['selectedTeam'];
    }
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
/// data from them and puts them into a `Team` object. Returns them as a future
/// of a list of `Team` objects. Checks to make sure document exists
/// and invites field properly created (should *always* be created, failsafe).
Future<List<Team>> getInvites() async {
  List<Team> teamInvites = [];
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  DocumentSnapshot<Map<String, dynamic>> teamDoc;
  DocumentSnapshot<Map<String, dynamic>> adminDoc;

  try {
    userDoc =
        await _firestore.collection("users").doc(_loggedInUser?.uid).get();
    Team tempTeam;

    if (userDoc.exists && userDoc.data()!.containsKey('invites')) {
      for (DocumentReference teamRef in userDoc['invites']) {
        teamDoc = await _firestore.doc(teamRef.path).get();
        if (teamDoc.exists && teamDoc.data()!.containsKey('teamMembers')) {
          adminDoc = await teamDoc['teamMembers']
              .where((team) => team.containsValue('owner') == true)
              .first['user']
              .get();
          tempTeam = Team.teamInvite(
            teamID: teamDoc['id'],
            title: teamDoc['title'],
            adminName: adminDoc['fullName'],
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
/// data from them and puts them into a `Team` object. Returns them as a future
/// of a list of `Team` objects. Checks to make sure document exists
/// and teams field properly created (should *always* be created, failsafe).
Future<List<Team>> getTeamsIDs() async {
  List<Team> teams = [];
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  DocumentSnapshot<Map<String, dynamic>> teamDoc;
  // For later use, members in Team:
  // List<DocumentSnapshot<Map<String, dynamic>>> memberDocs;

  try {
    userDoc =
        await _firestore.collection("users").doc(_loggedInUser?.uid).get();
    Team tempTeam;
    if (userDoc.exists && userDoc.data()!.containsKey('teams')) {
      for (DocumentReference teamRef in userDoc['teams']) {
        teamDoc = await _firestore.doc(teamRef.path).get();
        // TODO: Add members list instead of adminName
        // Note: must contain projects *field* to display teams.
        if (teamDoc.exists && teamDoc.data()!.containsKey('projects')) {
          tempTeam = Team(
            teamID: teamDoc['id'],
            title: teamDoc['title'],
            adminName: 'Temp',
            projects: teamDoc['projects'],
            numProjects: teamDoc['projects'].length,
          );
          teams.add(tempTeam);
        }
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

/// Fetches the list of all users in database. Used for inviting members to
/// to teams. Extracts the name and ID from them and puts them into a list of
/// `Member` objects. Returns them as a future of a list of Member objects.
/// Excludes current, logged in user. List can then be queried accordingly.
Future<List<Member>> getMembersList() async {
  List<Member> membersList = [];
  final QuerySnapshot<Map<String, dynamic>> usersQuery;

  try {
    usersQuery = await _firestore
        .collection('users')
        .where('creationTime', isNull: false)
        .get();
    Member tempMember;
    for (DocumentSnapshot<Map<String, dynamic>> document in usersQuery.docs) {
      if (document.id != _loggedInUser?.uid) {
        tempMember =
            Member(userID: document.id, fullName: document.data()!['fullName']);
        membersList.add(tempMember);
      }
    }
  } catch (e, stacktrace) {
    print('Exception loading list of members: $e');
    print('Stacktrace: $stacktrace');
  }
  return membersList;
}

/// Creates a new [Test] from scratch and inserts it into Firestore.
///
/// The [testID] is generated here to be used in the [Test] constructor.
///
/// Returns the [Test] object representing the instance just inserted
/// to Firestore.
Future<Test> saveTest({
  required String title,
  required Timestamp scheduledTime,
  required DocumentReference? projectRef,
  required String collectionID,
}) async {
  Test tempTest;

  if (projectRef == null) {
    throw Exception('projectRef not defined when passed to createTest()');
  }

  // Generates test document ID
  String testID = _firestore.collection(collectionID).doc().id;

  // Creates Test object
  tempTest = Test.createNew(
    title: title,
    testID: testID,
    scheduledTime: scheduledTime,
    projectRef: projectRef,
    collectionID: collectionID,
  );

  // Inserts Test to Firestore
  await _firestore.collection(collectionID).doc(testID).set({
    'title': title,
    'id': testID,
    'scheduledTime': scheduledTime,
    'project': projectRef,
    'data': tempTest.data,
    'creationTime': tempTest.creationTime,
    'maxResearchers': tempTest.maxResearchers,
    'isCompleted': false,
  });

  // Adds a reference to the Test to the relevant Project in Firestore
  await _firestore.doc('/${projectRef.path}').update({
    'tests': FieldValue.arrayUnion([_firestore.doc('/$collectionID/$testID')])
  });

  return tempTest;
}

/// Retrieves test info from Firestore.
///
/// When successful, this returns a
/// [Future] of a [Test] containing all info
/// from the desired test.
///
/// Returns null if there is an error.
Future<Test> getTestInfo(
    DocumentReference<Map<String, dynamic>> testRef) async {
  late Test test;
  final DocumentSnapshot<Map<String, dynamic>> testDoc;

  try {
    testDoc = await testRef.get();
    if (testDoc.exists && testDoc.data()!.containsKey('scheduledTime')) {
      test = Test.recreateFromDoc(testDoc);
    } else {
      if (!testDoc.exists) {
        throw Exception('test-does-not-exist');
      } else {
        throw Exception('retrieved-test-is-invalid');
      }
    }
  } catch (e, stacktrace) {
    print('Exception retrieving : $e');
    print('Stacktrace: $stacktrace');
  }

  print('Test from getTestInfo: $test'); // debug
  return test;
}

extension GeoPointConversion on GeoPoint {
  LatLng toLatLng() {
    return LatLng(this.latitude, this.longitude);
  }
}

extension LatLngConversion on LatLng {
  GeoPoint toGeoPoint() {
    return GeoPoint(this.latitude, this.longitude);
  }
}