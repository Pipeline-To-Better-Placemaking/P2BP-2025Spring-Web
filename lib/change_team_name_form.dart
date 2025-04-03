import 'package:flutter/material.dart';
import 'theme.dart';
import 'widgets.dart';

class ChangeTeamNameForm extends StatefulWidget {
  const ChangeTeamNameForm({super.key});

  @override
  State<ChangeTeamNameForm> createState() => _ChangeTeamNameFormState();
}

class _ChangeTeamNameFormState extends State<ChangeTeamNameForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
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
            child: Column(
              children: [
                const BarIndicator(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 80),
                    Text(
                      "Edit Team Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          Navigator.pop(context, _teamNameController.text);
                        },
                        child: Text(
                          "Done",
                          style: TextStyle(
                            color: Color(0xFF62B6FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                    child: TextFormField(
                      controller: _teamNameController,
                      cursorColor: Colors.white,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        label: Padding(
                          padding: const EdgeInsets.only(bottom: 200.0),
                          child: Text(
                            "Name",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54)),
                        prefix: SizedBox(width: 20.0),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a new team name';
                        }
                        if (value.length < 3) {
                          return 'Team name must be at least 3 characters long';
                        }
                        return null;
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
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}