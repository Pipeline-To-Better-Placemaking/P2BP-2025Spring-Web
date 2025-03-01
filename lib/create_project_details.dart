import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'section_cutter_test.dart';
import 'db_schema_classes.dart';
import 'firestore_functions.dart';

class CreateProjectDetails extends StatefulWidget {
  final Project projectData;

  /// IMPORTANT: When navigating to this page, pass in project details. Use
  /// `getProjectInfo()` from firestore_functions.dart to retrieve project
  /// object w/ data.
  /// <br/>Note: project is returned as future, await return before passing.
  const CreateProjectDetails({super.key, required this.projectData});

  @override
  State<CreateProjectDetails> createState() => _CreateProjectDetailsState();
}

User? loggedInUser = FirebaseAuth.instance.currentUser;

class _CreateProjectDetailsState extends State<CreateProjectDetails> {
  int itemCount = 10;
  bool _isLoading = false;
  Project? project;
  User? loggedInUser = FirebaseAuth.instance.currentUser;

  void _showCreateActivityPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String activityName = "";
        TimeOfDay? selectedTime;
        String? selectedActivity;
        List<String> activities = [
          "Absence of Order",
          "Acoustic Profile",
          "Community Survey",
          "Identifying Access",
          "Lighting Profile",
          "Nature Prevalence",
          "People in Motion",
          "People in Place",
          "Section Cutter",
          "Spatial Boundaries",
        ];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Create Activity"),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              content: Container(
                width: 350,
                height: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: "Activity Name"),
                      onChanged: (value) {
                        activityName = value;
                      },
                    ),
                    SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          initialEntryMode: TimePickerEntryMode.input,
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Start Time",
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : "Enter Time",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Activity Type"),
                      value: selectedActivity,
                      hint: Text("Select an Activity"),
                      items: activities.map((String activity) {
                        return DropdownMenuItem(
                          value: activity,
                          child: Text(activity),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedActivity = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Save activity logic
                  },
                  child: Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: .5),
                  bottom: BorderSide(color: Colors.white, width: .5),
                ),
                color: Color(0x22535455),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    widget.projectData.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.edit),
                    ),
                  ),
                )
              ],
            ),
            SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  'Project Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              flex: 0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: .5),
                    bottom: BorderSide(color: Colors.white, width: .5),
                  ),
                  color: Color(0x22535455),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 5.0),
                  child: Text.rich(
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      text: "${widget.projectData.description}\n\n\n",
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Research Activities",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: _showCreateActivityPopup,
                    label: Text('Create'),
                    icon: Icon(Icons.add),
                    iconAlignment: IconAlignment.end,
                  )
                ],
              ),
            ),
            Expanded(
              flex: 0,
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: Color(0x22535455),
                  border: Border(
                    top: BorderSide(color: Colors.white, width: .5),
                  ),
                ),
                child: itemCount > 0
                    ? ListView.separated(
                        itemCount: itemCount,
                        padding: const EdgeInsets.only(
                          left: 15,
                          right: 15,
                          top: 25,
                          bottom: 30,
                        ),
                        itemBuilder: (BuildContext context, int index) =>
                            TestCard(projectData: widget.projectData),
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 10),
                      )
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Center(
                            child: Text(
                                'No research activities. Create one first!'),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestCard extends StatelessWidget {
  final Project projectData;
  const TestCard({super.key, required this.projectData});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: <Widget>[
            // TODO: change corresponding to test type
            CircleAvatar(),
            SizedBox(width: 15),
            Expanded(
              child: Text("Placeholder (Research activity)"),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.blue,
                ),
                tooltip: 'Start test',
                onPressed: () async {
                  // TODO: Function (research activity)
                  final SectionCutterTest? test =
                      Test.castTo<SectionCutterTest>(await getTestInfo(
                          FirebaseFirestore.instance
                              .collection(SectionCutterTest.collectionIDStatic)
                              .doc('bBoihCszZAHf2FmHzoln')));
                  if (test != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return SectionCutter(
                            projectData: projectData, activeTest: test);
                      }),
                    );
                  } else {
                    print('something went wrong with getTestInfo for Section');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}