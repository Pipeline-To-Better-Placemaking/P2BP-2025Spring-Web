import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class ChangeProjectNameForm extends StatefulWidget {
  const ChangeProjectNameForm({super.key});

  @override
  State<ChangeProjectNameForm> createState() => _ChangeProjectNameFormState();
}

class _ChangeProjectNameFormState extends State<ChangeProjectNameForm> {
  TimeOfDay? _selectedTime;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _activityNameController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    _activityNameController.dispose();
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
              Text("Edit Project Name",
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
                controller: _activityNameController,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                    label: Padding(
                      padding: const EdgeInsets.only(bottom: 200.0),
                      child: Text(
                        "Project Name",
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
                  "Choose a name that clearly represents your project's purpose or objectives.",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(height: 20),
                Text(
                  "Use a title that’s easy to recognize for collaborators and aligns with your project’s goals. If this is a client project, consider including the client’s name or a relevant keyword.",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(height: 20),
                Text(
                  "A well-chosen project name helps with organization and ensures team members can easily identify it.",
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