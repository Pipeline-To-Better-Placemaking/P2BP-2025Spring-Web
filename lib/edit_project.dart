import 'package:flutter/material.dart';
import 'themes.dart';
import 'widgets.dart';

// TODO: Change text pick color from purple
class EditProjectPanel extends StatefulWidget {
  const EditProjectPanel({super.key});

  @override
  State<EditProjectPanel> createState() => _EditProjectPanel();
}

class _EditProjectPanel extends State<EditProjectPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            showEditProjectModalSheet(context);
          },
          child: const Text('Open bottom sheet'),
        ),
      ),
    );
  }
}

void showEditProjectModalSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return buildEditSheet(context);
    },
  );
}

// Function to return the content of the modal sheet for the Edit Button.
// Button should: propagate fields with relevant information then, on save,
// send that information to database. On cancel, clear fields and close.
Padding buildEditSheet(BuildContext context) {
  return Padding(
    // Padding for keyboard opening
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: SingleChildScrollView(
      child: Container(
        // Container decoration- rounded corners and gradient
        decoration: BoxDecoration(
          gradient: defaultGrad,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
        ),
        child: Column(
          children: [
            // Creates little indicator on top of sheet
            const BarIndicator(),
            Column(
              children: [
                ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: <Widget>[
                    // Text for title of sheet
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        "Edit Project",
                        style: TextStyle(
                            color: Colors.yellow[700],
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project name text field
                        Expanded(
                          flex: 2,
                          child: Container(
                            // alignment: Alignment.center,
                            padding: const EdgeInsets.only(bottom: 20),
                            margin: const EdgeInsets.only(left: 20),
                            child: const EditProjectTextBox(
                              maxLength: 60,
                              maxLines: 2,
                              minLines: 1,
                              labelText: 'Project Name',
                            ),
                          ),
                        ),

                        // Add photo button
                        const Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 27.0,
                                backgroundColor: Color(0xFFFFCC00),
                                child: Center(
                                  child:
                                      Icon(Icons.add_photo_alternate, size: 37),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Text(
                                  'Update Cover',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Project description text field
                    Container(
                      padding: const EdgeInsets.only(bottom: 20),
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      child: const EditProjectTextBox(
                        maxLength: 240,
                        maxLines: 4,
                        minLines: 3,
                        labelText: 'Project Description',
                      ),
                    ),
                    Row(
                      children: [
                        // Update map button
                        Container(
                          alignment: Alignment.topLeft,
                          margin: const EdgeInsets.only(left: 20, right: 5),
                          child: EditButton(
                            text: 'Update Map',
                            foregroundColor: Colors.black,
                            backgroundColor: const Color(0xFFFFCC00),
                            icon: const Icon(Icons.gps_fixed),
                            // TODO: edit w/ actual function
                            onPressed: () {},
                          ),
                        ),

                        // TODO: should be on same level as save button?
                        // Delete project button
                        Container(
                          alignment: Alignment.topLeft,
                          margin: const EdgeInsets.only(left: 5, right: 20),
                          child: EditButton(
                            text: 'Delete Project',
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            icon: const Icon(Icons.delete),
                            // TODO: edit w/ actual function
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Save changes button
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 170, top: 20, bottom: 20),
                          child: EditButton(
                            text: 'Save Changes',
                            foregroundColor: Colors.black,
                            backgroundColor: const Color(0xFFFFCC00),
                            icon: const Icon(Icons.save),
                            // TODO: edit w/ actual function
                            onPressed: () {},
                          ),
                        ),

                        // Cancel text inkwell pressable
                        InkWell(
                          child: const Padding(
                            padding:
                                EdgeInsets.only(left: 20, top: 20, bottom: 20),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 16, color: Color(0xFFFFD700)),
                            ),
                          ),
                          onTap: () {},
                        )
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}