import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

import 'db_schema_classes.dart';
import 'google_maps_functions.dart';

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
  await _firestore.collection('teams').doc(teamID).set({
    'title': teamName,
    'creationTime': FieldValue.serverTimestamp(),
    // Saves document id as field _id
    'id': teamID,
    'projects': [],
    'teamMembers': FieldValue.arrayUnion([
      {'role': 'owner', 'user': _firestore.doc('users/${_loggedInUser?.uid}')}
    ]),
  });
  await _firestore.collection('users').doc(_loggedInUser?.uid).update({
    'teams': FieldValue.arrayUnion([_firestore.doc('/teams/$teamID')])
  });
  // Currently: invites team members only once team is created.
  for (Member members in membersList) {
    await _firestore.collection('users').doc(members.userID).update({
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
  required String address,
  required List<LatLng> polygonPoints,
  required List<StandingPoint> standingPoints,
  required num polygonArea,
}) async {
  late Project tempProject;

  try {
    DocumentReference projectAdmin =
        _firestore.doc('users/${_loggedInUser?.uid}');
    DocumentReference? teamRef = await getCurrentTeam();
    String projectID = _firestore.collection('projects').doc().id;
    if (teamRef == null) {
      throw Exception(
          "teamRef unable to be retrieved in firestore_functions.dart");
    }

    await _firestore.collection('projects').doc(projectID).set({
      'title': projectTitle,
      'creationTime': FieldValue.serverTimestamp(),
      'id': projectID,
      'team': teamRef,
      'projectAdmin': projectAdmin,
      'description': description,
      'address': address,
      'polygonPoints': polygonPoints.toGeoPointList(),
      'standingPoints': standingPoints.toJsonList(),
      'polygonArea': polygonArea,
      'tests': [],
    });

    await _firestore.doc('/${teamRef.path}').update({
      'projects':
          FieldValue.arrayUnion([_firestore.doc('/projects/$projectID')])
    });

    tempProject = Project(
      teamRef: teamRef,
      projectID: projectID,
      title: projectTitle,
      description: description,
      address: address,
      projectAdmin: projectAdmin,
      polygonPoints: polygonPoints,
      polygonArea: polygonArea,
      standingPoints: standingPoints,
      testRefs: [],
    );
  } catch (e, stacktrace) {
    print('Exception retrieving : $e');
    print('Stacktrace: $stacktrace');
  }
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
      // Create List of testRefs for Project
      List<DocumentReference<Map<String, dynamic>>> testRefs = [];
      if (projectDoc.data()!.containsKey('tests')) {
        for (final ref in projectDoc['tests']) {
          testRefs.add(ref);
        }
      }
      // TODO: Remove logic once confirmed standing points for all projects/address/admin
      if (projectDoc.data()!.containsKey('standingPoints') &&
          projectDoc.data()!.containsKey('address') &&
          projectDoc.data()!.containsKey('projectAdmin')) {
        project = Project(
          teamRef: projectDoc['team'],
          projectID: projectDoc['id'],
          projectAdmin: projectDoc['projectAdmin'],
          title: projectDoc['title'],
          address: projectDoc['address'],
          description: projectDoc['description'],
          polygonPoints: (projectDoc['polygonPoints'] as List).toLatLngList(),
          polygonArea: projectDoc['polygonArea'],
          standingPoints: [
            for (final standingPoint in projectDoc['standingPoints'])
              StandingPoint.fromJson(standingPoint)
          ],
          creationTime: projectDoc['creationTime'],
          testRefs: testRefs,
        );
      }
      // TODO: remove with database purge, along wtih above todo.
      else {
        project = Project(
          teamRef: projectDoc['team'],
          projectID: projectDoc['id'],
          projectAdmin: _firestore.doc("/users/dKp6KXIw2pMSedeYhob2McVi5Wn1"),
          title: projectDoc['title'],
          description: projectDoc['description'],
          address: 'Address not set...',
          polygonPoints: (projectDoc['polygonPoints'] as List).toLatLngList(),
          polygonArea: projectDoc['polygonArea'],
          standingPoints: [],
          creationTime: projectDoc['creationTime'],
          testRefs: testRefs,
        );
      }
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

Future<bool> deleteTeam(Team team) async {
  try {
    final DocumentReference<Map<String, dynamic>> teamRef =
        _firestore.collection('teams').doc(team.teamID);

    // Iterate through projects and delete tests within them, then the project.
    if (team.projects.isNotEmpty) {
      for (final projectRef in team.projects) {
        final DocumentSnapshot projectDoc = await projectRef.get();
        if (projectDoc.exists && projectDoc.data()! is Map<String, dynamic>) {
          final Map<String, dynamic> projectData =
              projectDoc.data()! as Map<String, dynamic>;
          if (projectData.containsKey('tests') &&
              projectData['tests'] is List) {
            final List<DocumentReference> testRefs =
                List<DocumentReference>.from(projectData['tests']);
            for (final testRef in testRefs) {
              await testRef.delete();
              print('deleted test ${testRef.id}');
            }
          }
        }
        await projectRef.delete();
        print('deleted project ${projectRef.id}');
      }
    }

    // Iterate through members of this team, deleting refs to this team.
    final teamMemberList = await getTeamMembers(team.teamID);
    if (teamMemberList.isNotEmpty) {
      for (final member in teamMemberList) {
        final DocumentReference userRef =
            _firestore.collection('users').doc(member.userID);
        await userRef.update({
          'teams': FieldValue.arrayRemove([teamRef])
        });
        print('deleted ref from user ${userRef.id}');
      }
    }

    // Delete team.
    await teamRef.delete();
    print('Success in deleteTeam! Deleted team: ${team.title} '
        'with ID ${team.teamID}');
  } catch (e, stacktrace) {
    print('Exception deleting team: $e');
    print('Stacktrace: $stacktrace');
    return false;
  }
  return true;
}

Future<bool> deleteProject(Project project) async {
  try {
    final DocumentReference<Map<String, dynamic>> projectRef =
        _firestore.collection('projects').doc(project.projectID);

    // Delete tests residing in this project.
    if (project.testRefs.isNotEmpty) {
      for (final testRef in project.testRefs) {
        await testRef.delete();
        print('deleted test ${testRef.id}');
      }
    }

    // Delete reference to this project from the team it resides in.
    await project.teamRef?.update({
      'projects': FieldValue.arrayRemove([projectRef])
    });

    // Delete project.
    await projectRef.delete();
    print('Success in deleteProject! Deleted project: ${project.title} '
        'with ID ${project.projectID}');
  } catch (e, stacktrace) {
    print('Exception deleting project: $e');
    print('Stacktrace: $stacktrace');
    return false;
  }
  return true;
}

Future<bool> deleteTest(Test test) async {
  try {
    final DocumentReference<Map<String, dynamic>> testRef =
        _firestore.collection(test.collectionID).doc(test.testID);

    // Delete reference to this test from the project it resides in
    await test.projectRef.update({
      'tests': FieldValue.arrayRemove([testRef])
    });

    // Delete test
    await testRef.delete();
    print('Success in deleteTest! Deleted test: $test');
  } catch (e, stacktrace) {
    print('Exception deleting test: $e');
    print('Stacktrace: $stacktrace');
    return false;
  }
  return true;
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
      if (userDoc.data()!.containsKey('teams') &&
          userDoc['teams'] is List &&
          userDoc['teams'].contains(userDoc['selectedTeam'])) {
        teamRef = userDoc['selectedTeam'];
      } else {
        _firestore
            .collection('users')
            .doc(_loggedInUser?.uid)
            .update({'selectedTeam': userDoc['teams'].first});
        teamRef = userDoc['teams'].first;
      }
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
            projects: List<DocumentReference>.from(teamDoc['projects']),
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

/// Retrieves a list of the members on team with the given ID and returns it.
Future<List<Member>> getTeamMembers(String teamID) async {
  final List<Member> members = [];

  try {
    final teamDoc = await _firestore.collection('teams').doc(teamID).get();
    if (teamDoc.exists && teamDoc.data()!.containsKey('projects')) {
      final List teamMembers =
          List<Map<String, dynamic>>.from(teamDoc['teamMembers']);
      if (teamMembers.isNotEmpty) {
        for (final Map map in teamMembers) {
          if (map.containsKey('user')) {
            final DocumentReference userRef = map['user'];
            final DocumentSnapshot userDoc = await userRef.get();
            if (userDoc.exists) {
              String? fullName = userDoc['fullName'];
              if (fullName != null && fullName.isNotEmpty) {
                members.add(Member(userID: userDoc.id, fullName: fullName));
              }
            }
          }
        }
      }
    }
  } catch (e, stacktrace) {
    print('Exception: $e');
    print('Stacktrace: $stacktrace');
  }

  return members;
}

/// Sends an invite to the given already existing team to the given user.
Future<void> sendInviteToUser(String userID, String teamID) async {
  await _firestore.collection('users').doc(userID).update({
    'invites': FieldValue.arrayUnion([_firestore.doc('/teams/$teamID')])
  });
  print('Success in sendInviteToUser!');
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

/// Remove user from team they are currently in.
Future<void> removeUserFromTeam(String userID, String teamID) async {
  final DocumentReference<Map<String, dynamic>> userRef;
  final DocumentReference<Map<String, dynamic>> teamRef;
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  final DocumentSnapshot<Map<String, dynamic>> teamDoc;

  try {
    userRef = _firestore.collection('users').doc(userID);
    teamRef = _firestore.collection('teams').doc(teamID);
    userDoc = await userRef.get();
    teamDoc = await teamRef.get();

    if (userDoc.exists && userDoc.data()!.containsKey('teams')) {
      if (userDoc.data()!['teams'].contains(teamRef)) {
        userRef.update({
          'teams': FieldValue.arrayRemove([teamRef]),
        });

        if (teamDoc.exists && teamDoc.data()!.containsKey('teamMembers')) {
          for (final member in teamDoc.data()!['teamMembers']) {
            if (member is Map<String, dynamic> && member.containsKey('user')) {
              if (member['user'] == userRef) {
                teamRef.update({
                  'teamMembers': FieldValue.arrayRemove([member]),
                });
                print('success deleting member $member from team');
              }
            }
          }
        }
      }
    }
  } catch (e, stacktrace) {
    print('Exception removing user from team: $e');
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

/// Searches member list for given String and returns the members matched.
List<Member> searchMembers(List<Member> membersList, String text) {
  membersList = membersList
      .where((member) =>
          member.fullName.toLowerCase().startsWith(text.toLowerCase()))
      .toList();

  return membersList.isNotEmpty ? membersList : [];
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
  List? standingPoints,
  int? testDuration,
  int? intervalDuration,
  int? intervalCount,
}) async {
  late final Test tempTest;

  try {
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
      standingPoints: standingPoints,
      testDuration: testDuration,
      intervalDuration: intervalDuration,
      intervalCount: intervalCount,
    );

    await tempTest.saveToFirestore();

    // Adds a reference to the Test to the relevant Project in Firestore
    await _firestore.doc('/${projectRef.path}').update({
      'tests': FieldValue.arrayUnion([_firestore.doc('/$collectionID/$testID')])
    });
  } catch (e, stacktrace) {
    print('Exception retrieving : $e');
    print('Stacktrace: $stacktrace');
  }

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
        throw Exception('test-does-not-exist (testRef: ${testRef.path})');
      } else {
        throw Exception('retrieved-test-is-invalid (testRef: ${testRef.path})');
      }
    }
  } catch (e, stacktrace) {
    print('Exception retrieving : $e');
    print('Stacktrace: $stacktrace');
  }

  return test;
}

extension GeoPointConversion on GeoPoint {
  /// Takes a [GeoPoint] representation of a point and converts it to a
  /// [LatLng]. Returns that [LatLng].
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}

extension LatLngConversion on LatLng {
  /// Takes a [LatLng] representation of a point and converts it to a
  /// [GeoPoint]. Returns that [GeoPoint].
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }

  mp.LatLng toMPLatLng() {
    return mp.LatLng(latitude, longitude);
  }
}

extension LatLngListConversion on List<LatLng> {
  /// Extension function on [List`<LatLng>`]. Converts the list to a list of
  /// [GeoPoint]s for storing in Firestore. Returns the [List`<GeoPoint>`].
  List<GeoPoint> toGeoPointList() {
    List<GeoPoint> newGeoPointList = [];
    forEach((coordinate) {
      newGeoPointList.add(GeoPoint(coordinate.latitude, coordinate.longitude));
    });
    return newGeoPointList;
  }

  List<mp.LatLng> toMPLatLng() {
    List<mp.LatLng> newMPLatLngList = [];
    forEach((point) =>
        newMPLatLngList.add(mp.LatLng(point.latitude, point.longitude)));
    return newMPLatLngList;
  }
}

extension GeoPointListConversion on List<GeoPoint> {
  /// Extension function on [List]`<`[GeoPoint]`>`. Converts the list to a list
  /// of [LatLng]s for use locally in application. Returns the
  /// [List]`<`[LatLng]`>`.
  List<LatLng> toLatLngList() {
    List<LatLng> newLatLngList = [];
    forEach((coordinate) {
      newLatLngList.add(LatLng(coordinate.latitude, coordinate.longitude));
    });
    return newLatLngList;
  }
}

extension PolygonHelpers on Polygon {
  /// Extension function on [Polygon]. Takes a [Polygon] and converts it to a
  /// list of [GeoPoint]s for Firestore storing. Returns the
  /// [List]`<`[GeoPoint]`>`.
  List<GeoPoint> toGeoPointList() {
    List<GeoPoint> geoPointRepresentation = [];
    if (points.isEmpty) return geoPointRepresentation;
    for (var point in points) {
      geoPointRepresentation.add(GeoPoint(point.latitude, point.longitude));
    }
    return geoPointRepresentation;
  }

  /// Extension function on [Polygon]. Takes a [Polygon] and converts it to a
  /// list of [mp.LatLng]s for maps toolkit functions. Returns the
  /// [List]`<`[mp.LatLng]`>`.
  List<mp.LatLng> toMPLatLngList() {
    List<mp.LatLng> latLngRepresentation = [];
    if (points.isEmpty) return latLngRepresentation;
    for (var point in points) {
      latLngRepresentation.add(mp.LatLng(point.latitude, point.longitude));
    }
    return latLngRepresentation;
  }

  /// Returns the area covered by this polygon in square feet.
  double getAreaInSquareFeet() {
    return (mp.SphericalUtil.computeArea(toMPLatLngList()) *
            pow(feetPerMeter, 2))
        .toDouble();
  }
}

extension PolylineHelpers on Polyline {
  /// Extension function on [Polyline]. Takes a [Polyline] and converts it to a
  /// list of [GeoPoint]s for Firestore storing. Returns the
  /// [List]`<`[GeoPoint]`>`.
  List<GeoPoint> toGeoPointList() {
    List<GeoPoint> geoPointRepresentation = [];
    if (points.isEmpty) return geoPointRepresentation;
    for (var point in points) {
      geoPointRepresentation.add(GeoPoint(point.latitude, point.longitude));
    }
    return geoPointRepresentation;
  }

  /// Extension function on [Polyline]. Takes a [Polyline] and converts it to a
  /// list of [mp.LatLng]s for maps toolkit functions. Returns the
  /// [List]`<`[mp.LatLng]`>`.
  List<mp.LatLng> toMPLatLngList() {
    List<mp.LatLng> latLngRepresentation = [];
    if (points.isEmpty) return latLngRepresentation;
    for (var point in points) {
      latLngRepresentation.add(mp.LatLng(point.latitude, point.longitude));
    }
    return latLngRepresentation;
  }

  /// Returns the length of this polyline in feet.
  double getLengthInFeet() {
    return (mp.SphericalUtil.computeLength(toMPLatLngList()) * feetPerMeter)
        .toDouble();
  }
}

extension DynamicLatLngExtraction on List<dynamic> {
  /// Extension function on [List]`<`[dynamic]`>`. Takes any objects of type
  /// [GeoPoint] out of the list, converts them to [LatLng], and returns a new
  /// [List]`<`[LatLng]`>`. Primarily used when Firestore returns a
  /// [List]`<`[dynamic]`>`, to extract the coordinates for further use.
  List<LatLng> toLatLngList() {
    List<LatLng> newLatLngList = [];
    forEach((coordinate) {
      if (coordinate.runtimeType == GeoPoint) {
        newLatLngList.add(LatLng(coordinate.latitude, coordinate.longitude));
      }
      if (coordinate.runtimeType == LatLng) {
        newLatLngList.add(coordinate);
      }
    });
    return newLatLngList;
  }
}
