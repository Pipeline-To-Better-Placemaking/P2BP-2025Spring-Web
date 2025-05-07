import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:p2b/db_schema_classes/project_class.dart';
import 'package:p2b/extensions.dart';

import 'member_class.dart';
import 'misc_class_stuff.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class Team with JsonToString implements FirestoreDocument {
  static const String collectionIDStatic = 'teams';

  static final CollectionReference<Team> converterRef =
      _firestore.collection(collectionIDStatic).withConverter<Team>(
            fromFirestore: (snapshot, _) => Team.fromJson(snapshot.data()!),
            toFirestore: (team, _) => team.toJson(),
          );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Team> get ref => converterRef.doc(id);

  final String id;
  String title = '';
  RoleMap<DocumentReference> memberRefMap;
  RoleMap<Member>? memberMap;
  List<DocumentReference> projectRefs;
  List<Project>? projects;
  String coverImageUrl = '';
  final Timestamp creationTime;

  Team({
    required this.id,
    required this.title,
    required this.memberRefMap,
    this.memberMap,
    List<DocumentReference>? projectRefs,
    this.projects,
    this.coverImageUrl = '',
    Timestamp? creationTime,
  })  : creationTime = creationTime ?? Timestamp.now(),
        projectRefs = projectRefs ?? <DocumentReference>[];

  factory Team.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'id': String id,
          'title': String title,
          'creationTime': Timestamp creationTime,
          'coverImageUrl': String coverImageUrl,
          'membersByRole': Map<String, Object?> membersByRole,
          'projects': List projects,
        }) {
      return Team(
        id: id,
        title: title,
        creationTime: creationTime,
        coverImageUrl: coverImageUrl,
        memberRefMap: <GroupRole, List<DocumentReference>>{
          for (final role in membersByRole.keys)
            GroupRole.values.byName(role):
                List<DocumentReference>.from(membersByRole[role]! as List)
        },
        projectRefs: List<DocumentReference>.from(projects),
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'membersByRole': memberRefMap.keysEnumToName(),
      'creationTime': creationTime,
      'projects': projectRefs,
      'coverImageUrl': coverImageUrl,
    };
  }

  static Future<Team?> get(DocumentReference ref) async {
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
      throw Exception('Failed to get team because of exception: $e');
    }
  }

  Future<bool> delete() async {
    try {
      await loadProjectsInfo();

      // Delete each project including all nested elements via builtin method.
      for (final project in projects!) {
        await project.delete();
      }

      // Delete cover image from storage if present.
      if (coverImageUrl.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.ref();
        final coverImageRef = storageRef.child('team_covers/$id');
        await coverImageRef.delete();
      }

      _firestore.runTransaction((transaction) async {
        // Delete references to this team from every member.
        for (final memberRef in memberRefMap.toSingleList()) {
          transaction.update(memberRef, {
            'teams': FieldValue.arrayRemove([ref]),
          });
          print('deleted ref from user ${memberRef.id}');
        }

        // Delete team.
        transaction.delete(ref);
        print('Success in Team.delete()! Deleted team: $title with ID $id');
      });
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      return false;
    }
    return true;
  }

  Future<void> update() async {
    await ref.update(toJson());
  }

  /// Create new team from given values and save ref and [Team] to owner's
  /// lists.
  ///
  /// This internally creates the team in Firestore, adds the reference to the
  /// owner's teams list in Firestore, and sends all the invites to users in
  /// Firestore. And then updates everything locally for the current user too.
  static Future<Team> createNew({
    required String teamTitle,
    required Member teamOwner,
    required List<Member> inviteList,
    File? coverImage,
  }) async {
    String coverImageUrl = '';

    try {
      final String teamID = Team.converterRef.doc().id;

      // Make memberRefMap with owner in place and other roles as empty list.
      final RoleMap<DocumentReference> memberRefMap = {
        for (final role in GroupRole.values) role: [],
      };
      memberRefMap[GroupRole.owner]!.add(teamOwner.ref);

      // Make memberMap with owner because we can.
      final RoleMap<Member> memberMap = {
        for (final role in GroupRole.values) role: [],
      };
      memberMap[GroupRole.owner]!.add(teamOwner);

      // Upload and get link for cover image.
      if (coverImage != null) {
        final storageRef = FirebaseStorage.instance.ref();
        final coverImageRef = storageRef.child('team_covers/$teamID');
        await coverImageRef.putFile(coverImage);
        coverImageUrl = await coverImageRef.getDownloadURL();
      }

      // Construct Team.
      final Team team = Team(
        id: teamID,
        title: teamTitle,
        memberRefMap: memberRefMap,
        memberMap: memberMap,
        coverImageUrl: coverImageUrl,
      );

      // Update Firestore with new team, add reference to new team to owner's
      // teams list, and send invites to all invited users.
      await _firestore.runTransaction((transaction) async {
        // Create team in Firestore.
        transaction.set(team.ref, team);
        await team.ref.set(team);

        // Finally, add this new Team to owner's local teams lists and return it.
        teamOwner.teamRefs.add(team.ref);
        teamOwner.teams ??= [];
        teamOwner.teams!.add(team);
        transaction.update(teamOwner.ref, teamOwner.toJson());

        // Send invites.
        for (final member in inviteList) {
          transaction.update(member.ref, {
            'invites': FieldValue.arrayUnion([team.ref]),
          });
        }
      });

      return team;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to create team because of exception: $e');
    }
  }

  Future<String> addCoverImage(File imageFile) async {
    try {
      final coverImageRef = FirebaseStorage.instance.ref('team_covers/$id');
      await coverImageRef.putFile(imageFile);
      final downloadUrl = await coverImageRef.getDownloadURL();

      coverImageUrl = downloadUrl;
      await update();

      print('Cover image uploaded successfully: $coverImageUrl');
      return coverImageUrl;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to add cover image because of exception: $e');
    }
  }

  /// Removes current [Member] of [Team] from the [Team].
  void removeMember(Member member) {
    try {
      // Remove references to Team from Member.
      member.teamRefs.removeWhere((ref) => ref.id == id);
      member.teams?.removeWhere((team) => team.id == id);

      // Remove references to Member from Team.
      for (final role in GroupRole.values) {
        memberRefMap[role]!.removeWhere((ref) => ref.id == member.id);
        memberMap?[role]!.removeWhere((mem) => mem.id == member.id);
      }

      // Update Firestore.
      _firestore.runTransaction((transaction) async {
        member.update();
        update();
      });
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
    }
  }

  /// Updates [projects] to contain Projects
  Future<List<Project>> loadProjectsInfo() async {
    try {
      // Sets projects to empty list and returns if refs is empty.
      if (projectRefs.isEmpty) {
        if (projects == null) {
          projects = [];
          return projects!;
        }

        projects!.clear();
        return projects!;
      }

      // Refs not empty, actually retrieve project info.
      List<Project> newProjectList = [];
      List<DocumentReference> refDeleteList = [];
      for (final projectRef in projectRefs) {
        final projectDoc = await Project.converterRef.doc(projectRef.id).get();
        if (projectDoc.exists) {
          newProjectList.add(projectDoc.data()!);
          newProjectList.last.team = this;
        } else {
          refDeleteList.add(projectRef);
        }
      }
      for (final deleteRef in refDeleteList) {
        projectRefs.removeWhere((projectRef) => projectRef.id == deleteRef.id);
        ref.update({
          'projects': FieldValue.arrayRemove([deleteRef]),
        });
      }

      projects?.clear();
      projects = newProjectList.toList();
      return projects!;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to get projects because of exception: $e');
    }
  }

  Future<RoleMap<Member>> loadMembersInfo() async {
    try {
      if (memberRefMap.isEmpty) {
        if (memberMap == null) {
          memberMap = {};
          return memberMap!;
        }

        memberMap!.clear();
        return memberMap!;
      }

      // Refs not empty, retrieve member info.
      RoleMap<Member> newMemberMap = {
        for (final role in GroupRole.values) role: [],
      };
      for (final role in GroupRole.values) {
        for (final ref in memberRefMap[role]!) {
          final memberDoc = await Member.converterRef.doc(ref.id).get();
          if (memberDoc.exists) {
            // Add each member to appropriate role list.
            newMemberMap[role]!.add(memberDoc.data()!);
          }
        }
      }

      memberMap?.clear();
      memberMap = newMemberMap;
      return memberMap!;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to get members because of exception: $e');
    }
  }
}
