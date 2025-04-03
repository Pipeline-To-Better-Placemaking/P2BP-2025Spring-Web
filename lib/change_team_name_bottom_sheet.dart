import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class ChangeTeamNameBottomSheet extends StatefulWidget {
  const ChangeTeamNameBottomSheet({super.key});

  @override
  State<ChangeTeamNameBottomSheet> createState() =>
      _ChangeTeamNameBottomSheetState();
}

class _ChangeTeamNameBottomSheetState extends State<ChangeTeamNameBottomSheet> {
  TimeOfDay? _selectedTime;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 80,
              ),
              Text("Edit Team Name",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: () {
                    // Close the bottom sheet
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Done",
                    style: TextStyle(
                        color: Color(0xFF62B6FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 32.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              // Activity Name Input
              child: TextFormField(
                controller: _teamNameController,
                cursorColor: Colors.white,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                    label: Padding(
                      padding: const EdgeInsets.only(bottom: 200.0),
                      child: Text(
                        "Name",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white38)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54)),
                    prefix: SizedBox(width: 20.0)),
              ),
            ),
          ),
          SizedBox(height: 26),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  "Choose a name that reflects your team's purpose or projects.",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(height: 20),
                Text(
                  "Use a title that's recognizable to colleagues and relevant to your survey goals, or simply use your business name.",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(height: 20),
                Text(
                  "This helps keep your team easily identifiable to clients and collaborators.",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}