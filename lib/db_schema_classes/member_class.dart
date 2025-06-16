import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:p2b/db_schema_classes/team_class.dart';
import 'package:p2b/db_schema_classes/team_invite_class.dart';

import '../login_screen.dart';
import 'misc_class_stuff.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class Member with JsonToString implements FirestoreDocument {
  static const String collectionIDStatic = 'users';

  static final CollectionReference<Member> converterRef =
      _firestore.collection(collectionIDStatic).withConverter<Member>(
            fromFirestore: (snapshot, _) => Member.fromJson(snapshot.data()!),
            toFirestore: (member, _) => member.toJson(),
          );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Member> get ref => converterRef.doc(id);

  final String id;
  String fullName = '';
  String email = '';
  final Timestamp creationTime;
  List<DocumentReference> teamInviteRefs;
  List<TeamInvite>? teamInvites;
  List<DocumentReference> teamRefs;
  List<Team>? teams;
  DocumentReference? selectedTeamRef; // Null if user is not on any teams
  Team? selectedTeam;
  String profileImageUrl = '';

  Member({
    required this.id,
    required this.fullName,
    required this.email,
    Timestamp? creationTime,
    List<DocumentReference>? teamInviteRefs,
    this.teamInvites,
    List<DocumentReference>? teamRefs,
    this.teams,
    this.selectedTeamRef,
    this.selectedTeam,
    this.profileImageUrl = '',
  })  : creationTime = creationTime ?? Timestamp.now(),
        teamInviteRefs = teamInviteRefs ?? <DocumentReference>[],
        teamRefs = teamRefs ?? <DocumentReference>[];

  factory Member.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'id': String id,
          'fullName': String fullName,
          'email': String email,
          'creationTime': Timestamp creationTime,
          'invites': List invites,
          'teams': List teams,
          'selectedTeam': DocumentReference? selectedTeam,
          'profileImageUrl': String profileImageUrl,
        }) {
      return Member(
        id: id,
        fullName: fullName,
        email: email,
        creationTime: creationTime,
        teamInviteRefs: List<DocumentReference>.from(invites),
        teamRefs: List<DocumentReference>.from(teams),
        selectedTeamRef: selectedTeam,
        profileImageUrl: profileImageUrl,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'creationTime': creationTime,
      'invites': teamInviteRefs,
      'teams': teamRefs,
      'selectedTeam': selectedTeamRef,
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Returns a Member object from the given [DocumentReference].
  ///
  /// Do not give this a [DocumentReference] of uncertain origin or something
  /// very strange will probably happen. Undocumented behavior or whatever.
  Future<Member?> get(DocumentReference ref) async {
    try {
      final doc = await converterRef.doc(ref.id).get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        return null;
      }
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to get member because of exception: $e');
    }
  }

  Future<bool> delete() async {
    // TODO implement user delete
    throw UnimplementedError();
  }

  Future<void> update() async {
    await ref.update(toJson());
  }

  /// Creates a [Member] from the given [User], adds it to Firestore, and sends
  /// email verification.
  ///
  /// This should only be called after a [User] has been created with
  /// `email` and `password`, and that User has had its profile updated
  /// with a `displayName`.
  static Future<Member> createNew(
      String fullName, String email, String password) async {
    try {
      // Create user with email and password.
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      // Add user's full name to profile.
      await user?.updateProfile(displayName: fullName);

      // Create Member from info.
      final member =
          Member(id: user!.uid, fullName: fullName, email: user.email!);

      // Save member to Firestore.
      await converterRef.doc(member.id).set(member);

      await user.sendEmailVerification();
      return member;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to create user because of exception: $e');
    }
  }

  /// Attempts to create a [Member] from given [User] data in Firestore.
  ///
  /// This also performs some login-time updates to the document, such as
  /// updating `email` if it has been changed in FirebaseAuth and updating
  /// `lastLogin` to the current time.
  static Future<Member> login(User user) async {
    final userRef = converterRef.doc(user.uid);

    try {
      return await _firestore.runTransaction<Member>((transaction) async {
        final userDoc = await transaction.get<Member>(userRef);
        final member = userDoc.data()!;

        // Update email in Firestore to new email in Auth if they are different.
        // This is done on login because there does not seem to be a way to
        // listen for when the user has verified their new email address after
        // changing it, which would be the ideal time to update the email
        // in Firestore.
        if (member.email != user.email) {
          member.email = user.email!;
          transaction.update(member.ref, member.toJson());
        }

        transaction
            .update(userRef, {'lastLogin': FieldValue.serverTimestamp()});
        return member;
      });
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to login because of exception: $e');
    }
  }

  static void logOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Sends to login screen and removes everything else from nav stack
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route route) => false);
      } else {
        throw Exception('context-unmounted');
      }
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log out failed. Try again.')),
      );
    }
  }

  Future<String> addProfileImage(File imageFile) async {
    try {
      final profileImageRef =
          FirebaseStorage.instance.ref().child('profile_images/$id');
      await profileImageRef.putFile(imageFile);
      final downloadUrl = await profileImageRef.getDownloadURL();

      profileImageUrl = downloadUrl;
      await update();

      print('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e, s) {
      print('Error uploading profile image: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to add profile image because of exception: $e');
    }
  }

  static Future<List<Member>> queryByFullName(String searchText) async {
    try {
      // Use all uppercase text to get broader/non case-sensitive results.
      final textAsUppercase = searchText.toUpperCase();
      final queryResult = await converterRef
          .where('fullName', isGreaterThanOrEqualTo: textAsUppercase)
          .get();

      final snapshotList = queryResult.docs;
      final memberList = [for (final snapshot in snapshotList) snapshot.data()];

      // Remove remaining members where names don't contain
      // the search string because query is too broad.
      memberList.removeWhere(
          (member) => !member.fullName.toUpperCase().contains(textAsUppercase));

      return memberList;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to query fullName because of exception: $e');
    }
  }

  /// Sets [Team] object [selectedTeam] with data retrieved with
  /// [selectedTeamRef], and also returns the resulting [Team] object.
  ///
  /// Only intended to be used once when first logged in and it has not yet
  /// been loaded, leaving [selectedTeam] null.
  ///
  /// Returns null if [selectedTeamRef] is null, or the `DocumentSnapshot`
  /// retrieved for it comes back null.
  Future<Team?> loadSelectedTeamInfo() async {
    try {
      if (teamRefs.isEmpty) {
        // No teams, selected are both null.
        selectedTeam = null;
        teams = [];
        if (selectedTeamRef == null) return selectedTeam;
        selectedTeamRef = null;
      } else if (selectedTeamRef == null) {
        // Has teams but none selected, select first team.
        selectedTeamRef = teamRefs.first;
        selectedTeam = await Team.get(selectedTeamRef!);
        if (selectedTeam != null) teams ??= [selectedTeam!];
      } else if (!teamRefs.contains(selectedTeamRef)) {
        // Selected team is not in teams, select first team.
        selectedTeamRef = teamRefs.first;
        selectedTeam = await Team.get(selectedTeamRef!);
        if (selectedTeam != null) teams ??= [selectedTeam!];
      } else {
        // Base case, just get the selected team.
        selectedTeam = await Team.get(selectedTeamRef!);
        if (selectedTeam != null) teams ??= [selectedTeam!];
        return selectedTeam;
      }

      update();
      return selectedTeam;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to get selectedTeam because of exception: $e');
    }
  }

  Future<List<Team>> loadTeamsInfo() async {
    try {
      // If refs list is empty, set teams list to empty and return.
      if (teamRefs.isEmpty) {
        if (teams == null) {
          teams = [];
          return teams!;
        }

        teams!.clear();
        return teams!;
      }

      // Refs not empty, retrieve info for teams.
      List<Team> newTeamList = [];
      for (final ref in teamRefs) {
        final teamDoc = await Team.converterRef.doc(ref.id).get();
        if (teamDoc.exists) {
          newTeamList.add(teamDoc.data()!);
        }
      }

      teams?.clear();
      teams = newTeamList.toList();
      return teams!;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to get teams because of exception: $e');
    }
  }

  Future<List<TeamInvite>> loadTeamInvitesInfo() async {
    try {
      // If refs list is empty, set invites list to empty and return.
      if (teamInviteRefs.isEmpty) {
        if (teamInvites == null) {
          teamInvites = [];
          return teamInvites!;
        }

        teamInvites!.clear();
        return teamInvites!;
      }

      // Refs not empty, retrieve info for invites.
      List<TeamInvite> newInviteList = [];
      for (final ref in teamInviteRefs) {
        final TeamInvite? invite = await TeamInvite.fromTeamRef(ref);
        if (invite != null) {
          newInviteList.add(invite);
        }
      }

      // Remove inviteRefs of teams that no longer exist.
      // Also updates invites in Firestore if any are removed.
      bool didChange = false;
      final List<String> newInviteTeamIDList = [
        for (final invite in newInviteList) invite.team.id,
      ];
      teamInviteRefs.removeWhere((inviteRef) {
        final test = !newInviteTeamIDList.contains(inviteRef.id);
        if (test) didChange = true;
        return test;
      });
      if (didChange) update();

      teamInvites?.clear();
      teamInvites = newInviteList.toList();
      return teamInvites!;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to get team invites because of exception: $e');
    }
  }
}
