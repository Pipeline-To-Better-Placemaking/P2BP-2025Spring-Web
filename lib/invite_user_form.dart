/*import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets.dart';

import 'db_schema_classes.dart';
import 'firestore_functions.dart';

class InviteUserForm extends StatefulWidget {
  final Team activeTeam;

  const InviteUserForm({super.key, required this.activeTeam});

  @override
  State<InviteUserForm> createState() => _InviteUserFormState();
}

class _InviteUserFormState extends State<InviteUserForm> {
  late final List<Member> membersList;
  List<Member> membersSearch = [];
  int itemCount = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getMembersList();
  }

  // Retrieves all members and removes ones already in the team and sets membersList
  Future<void> _getMembersList() async {
    try {
      final allMemberList = await getMembersList();
      final teamMemberList = await getTeamMembers(widget.activeTeam.teamID);
      membersList = allMemberList
          .where((member) => !(teamMemberList
              .any((teamMember) => teamMember.userID == member.userID)))
          .toList();
      setState(() {
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      print("Error in create_project_and_teams, _getMembersList(): $e");
      print("Stacktrace: $stacktrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: Container(
          decoration: BoxDecoration(
            gradient: defaultGrad,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24.0),
              topRight: Radius.circular(24.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const BarIndicator(),
              Center(
                child: Text(
                  'Invite Users to this Team',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Search Members',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  labelText: 'Members',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
                onChanged: (memberText) {
                  setState(() {
                    if (memberText.length > 2) {
                      membersSearch = searchMembers(membersList, memberText);
                      itemCount = membersSearch.length;
                    } else {
                      itemCount = 0;
                    }
                  });
                },
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: itemCount > 0
                    ? ListView.separated(
                        itemBuilder: (context, index) => buildInviteCard(
                            member: membersSearch[index], index: index),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: itemCount)
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Text(
                            'No users matching criteria. '
                            'Enter at least 3 characters to search.',
                            style: TextStyle(color: Colors.white),
                          ),
              ),
              SizedBox(height: 20),
              InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: placeYellow),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: 30),
            ],
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
              child: Text(member.fullName),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: memberInviteButton(index: index, member: member),
            ),
          ],
        ),
      ),
    );
  }

  InkWell memberInviteButton({required int index, required Member member}) {
    return InkWell(
      child: Text(member.invited ? "Invite sent!" : "Invite"),
      onTap: () {
        setState(() {
          if (!member.invited) {
            sendInviteToUser(member.userID, widget.activeTeam.teamID);
            member.invited = true;
          }
        });
      },
    );
  }
} */