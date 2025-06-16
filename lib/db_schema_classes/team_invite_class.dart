import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2b/db_schema_classes/team_class.dart';

import 'member_class.dart';
import 'misc_class_stuff.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class TeamInvite {
  final Team team;
  final String ownerName;

  TeamInvite({
    required this.team,
    required this.ownerName,
  });

  static Future<TeamInvite?> fromTeamID(String teamID) async {
    final DocumentReference<Map<String, Object?>> teamRef =
        _firestore.collection('teams').doc(teamID);
    return await fromTeamRef(teamRef);
  }

  static Future<TeamInvite?> fromTeamRef(DocumentReference teamRef) async {
    final DocumentReference userRef;

    try {
      Team? team = await Team.get(teamRef);
      if (team != null) {
        userRef = team.memberRefMap[GroupRole.owner]!.first;
        final owner = await Member.converterRef.doc(userRef.id).get();
        if (owner.exists) {
          return TeamInvite(team: team, ownerName: owner.data()!.fullName);
        }
      }
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
    }
    return null;
  }

  static Future<void> sendToUser(Member member, Team team) async {
    try {
      await member.ref.update({
        'invites': FieldValue.arrayUnion([team.ref]),
      });
      print('Success in TeamInvite.sendToUser!');
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
    }
  }

  void accept(Member member) async {
    try {
      // Remove this invite and add team to local Member object.
      member.teamInviteRefs.removeWhere((invite) => invite.id == team.id);
      member.teamInvites?.removeWhere((invite) => invite.team.id == team.id);
      member.teamRefs.add(team.ref);
      member.teams?.add(team);

      // Add this Member to local Team object.
      team.memberRefMap[GroupRole.member]!.add(member.ref);
      team.memberMap?[GroupRole.member]!.add(member);

      // Update Firestore.
      await _firestore.runTransaction((transaction) async {
        await member.update();
        await team.update();
      });

      await _firestore.runTransaction((transaction) async {
        if (member.teams == null) await member.loadTeamsInfo();
        if (team.memberMap == null) await team.loadMembersInfo();
      });

      print('Success in invite.accept!');
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
    }
  }

  void decline(Member member) {
    try {
      // Remove invite from local Member object.
      member.teamInviteRefs.removeWhere((invite) => invite.id == team.id);
      member.teamInvites?.removeWhere((invite) => invite.team.id == team.id);

      // Update Firestore invites list to remove this invite.
      member.update();

      print('Success in TeamInvite.removeFromUser!');
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
    }
  }
}
