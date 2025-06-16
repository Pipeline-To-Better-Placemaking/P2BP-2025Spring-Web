import 'package:flutter/material.dart';

class ChangeProjectDescriptionForm extends StatefulWidget {
  const ChangeProjectDescriptionForm({super.key});

  @override
  State<ChangeProjectDescriptionForm> createState() =>
      _ChangeProjectDescriptionFormState();
}

class _ChangeProjectDescriptionFormState
    extends State<ChangeProjectDescriptionForm> {
  TimeOfDay? _selectedTime;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _timeController.dispose();
    _descriptionController.dispose();
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
                width: 60,
              ),
              Text("Edit Project Description",
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
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 32.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              // Activity Name Input
              child: TextFormField(
                controller: _descriptionController,
                cursorColor: Colors.white,
                maxLength: 240,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                keyboardType: TextInputType.multiline,
                minLines: 6,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(color: Colors.white),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
                buildCounter: (
                  BuildContext context, {
                  required int currentLength,
                  required int? maxLength,
                  required bool isFocused,
                }) {
                  return Text(
                    '$currentLength/${maxLength ?? "∞"}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 26),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  "Provide a clear and concise summary of your project’s purpose, goals, and key details.",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                SizedBox(height: 20),
                Text(
                  "A well-written description helps collaborators understand the scope of the project and ensures clarity for future reference.",
                  textAlign: TextAlign.start,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}