import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:p2b/db_schema_classes/standing_point_class.dart';
import 'package:p2b/db_schema_classes/team_class.dart';
import 'package:p2b/db_schema_classes/test_class.dart';
import 'package:p2b/extensions.dart';

import 'member_class.dart';
import 'misc_class_stuff.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class Project with JsonToString implements FirestoreDocument {
  static const String collectionIDStatic = 'projects';

  static final CollectionReference<Project> converterRef =
      _firestore.collection(collectionIDStatic).withConverter<Project>(
            fromFirestore: (snapshot, _) => Project.fromJson(snapshot.data()!),
            toFirestore: (project, _) => project.toJson(),
          );

  @override
  String get collectionID => collectionIDStatic;

  @override
  DocumentReference<Project> get ref => converterRef.doc(id);

  final String id;
  String title = '';
  String description = '';
  String address = '';
  final DocumentReference teamRef;
  Team? team;
  final Map<GroupRole, List<DocumentReference>> memberRefMap;
  Map<GroupRole, List<Member>>? memberMap;
  final Polygon polygon;
  final double polygonArea;
  List<DocumentReference> testRefs;
  List<Test>? tests;
  String coverImageUrl = '';
  final List<StandingPoint> standingPoints;
  final Timestamp creationTime;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.teamRef,
    required this.memberRefMap,
    required this.polygon,
    required this.standingPoints,
    this.team,
    this.memberMap,
    double? polygonArea,
    List<DocumentReference>? testRefs,
    this.tests,
    this.coverImageUrl = '',
    Timestamp? creationTime,
  })  : creationTime = creationTime ?? Timestamp.now(),
        polygonArea = polygonArea ?? polygon.getAreaInSquareFeet(),
        testRefs = testRefs ?? <DocumentReference>[];

  factory Project.fromJson(Map<String, Object?> json) {
    if (json
        case {
          'id': String id,
          'title': String title,
          'description': String description,
          'address': String address,
          'creationTime': Timestamp creationTime,
          'team': DocumentReference team,
          'membersByRole': Map<String, Object?> membersByRole,
          'polygonPoints': List<Object?> polygonPoints,
          'polygonArea': double polygonArea,
          'standingPoints': List standingPoints,
          'tests': List<Object?> tests,
          'coverImageUrl': String coverImageUrl,
        }) {
      final List<LatLng> points =
          List<GeoPoint>.from(polygonPoints).toLatLngList();
      return Project(
        id: id,
        title: title,
        description: description,
        address: address,
        creationTime: creationTime,
        teamRef: team,
        memberRefMap: <GroupRole, List<DocumentReference>>{
          for (final role in membersByRole.keys)
            if (elevatedRoles.contains(GroupRole.values.byName(role)))
              GroupRole.values.byName(role):
                  List<DocumentReference>.from(membersByRole[role]! as List)
        },
        polygon: Polygon(
          polygonId: PolygonId(points.toString()),
          points: points,
          strokeWidth: 1,
          strokeColor: Colors.red,
          fillColor: Color(0x52F34236),
        ),
        polygonArea: polygonArea,
        standingPoints: StandingPoint.fromJsonList(standingPoints),
        testRefs: List<DocumentReference>.from(tests),
        coverImageUrl: coverImageUrl,
      );
    }
    throw FormatException('Invalid JSON: $json', json);
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'address': address,
      'creationTime': creationTime,
      'team': teamRef,
      'membersByRole': memberRefMap.keysEnumToName(),
      'polygonPoints': polygon.toGeoPointList(),
      'polygonArea': polygonArea,
      'standingPoints': standingPoints.toJsonList(),
      'tests': testRefs,
      'coverImageUrl': coverImageUrl,
    };
  }

  static Future<Project?> get(DocumentReference ref) async {
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
      throw Exception('Failed to get project because of exception: $e');
    }
  }

  Future<bool> delete() async {
    try {
      // Delete cover image from storage if present.
      if (coverImageUrl.isNotEmpty) {
        final storageRef = FirebaseStorage.instance.ref();
        final coverImageRef = storageRef.child('project_covers/$id');
        await coverImageRef.delete();
      }

      _firestore.runTransaction((transaction) async {
        // Deletes each test belonging to this project.
        for (final testRef in testRefs) {
          transaction.delete(testRef);
          print('deleted test ${testRef.id}');
        }

        // Delete reference to this project from the team it belongs to.
        team!.projects?.removeWhere((project) => project.id == id);
        team!.projectRefs.removeWhere((projectRef) => projectRef.id == id);
        transaction.update(team!.ref, team!.toJson());

        // Delete this project.
        transaction.delete(ref);
        print('deleted project $id');
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

  static Future<Project> createNew({
    required String title,
    required String description,
    required String address,
    required Team team,
    required Member owner,
    required Polygon polygon,
    required List<StandingPoint> standingPoints,
    File? coverImage,
  }) async {
    String coverImageUrl = '';

    try {
      final String projectID = Project.converterRef.doc().id;

      // Make memberRefMap with only elevated roles. Only owner for now.
      final RoleMap<DocumentReference> memberRefMap = {
        for (final role in elevatedRoles) role: [],
      };
      memberRefMap[GroupRole.owner]!.add(owner.ref);

      // Make memberMap too because we can.
      final RoleMap<Member> memberMap = {
        for (final role in elevatedRoles) role: [owner],
      };
      memberMap[GroupRole.owner]!.add(owner);

      // Upload and get link for cover image.
      if (coverImage != null) {
        final storageRef = FirebaseStorage.instance.ref();
        final coverImageRef = storageRef.child('project_covers/$projectID');
        await coverImageRef.putFile(coverImage);
        coverImageUrl = await coverImageRef.getDownloadURL();
      }

      // Construct Project.
      final Project project = Project(
        id: projectID,
        title: title,
        description: description,
        address: address,
        teamRef: team.ref,
        team: team,
        memberRefMap: memberRefMap,
        polygon: polygon,
        standingPoints: standingPoints,
        coverImageUrl: coverImageUrl,
      );

      // Add project to team locally.
      team.projectRefs.add(project.ref);
      team.projects?.add(project);

      // Add the project and update the team's projects list in Firestore.
      await _firestore.runTransaction((transaction) async {
        transaction.set(project.ref, project);
        transaction.update(team.ref, team.toJson());
      });

      return project;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to create project because of exception: $e');
    }
  }

  Future<String> addCoverImage(File imageFile) async {
    try {
      final coverImageRef = FirebaseStorage.instance.ref('project_covers/$id');
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

  Future<Team> loadTeamInfo() async {
    try {
      final teamDoc = await Team.converterRef.doc(teamRef.id).get();
      team = teamDoc.data();
      return team!;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to load team info because of exception: $e');
    }
  }

  Future<List<Test>> loadAllTestInfo() async {
    try {
      if (testRefs.isEmpty) {
        if (tests == null) {
          tests = [];
          return tests!;
        }

        tests!.clear();
        return tests!;
      }

      final List<Test> newTestList = [];
      for (final ref in testRefs) {
        final testDoc = await _firestore.doc(ref.path).get();
        if (testDoc.exists) {
          newTestList.add(Test.recreateFromDoc(testDoc));
        }
      }

      tests = newTestList.toList();
      return tests!;
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to load test info because of exception: $e');
    }
  }
}
