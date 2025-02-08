import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'db_schema_classes.dart';

// IMPORTANT: When navigating to this page, pass in project details. Use
// getProjectInfo() from firestore_functions.dart to retrieve project object w/ data.
// *Note: project is returned as future. Must await response before passing.
class CreateProjectDetails extends StatefulWidget {
  final Project projectData;
  const CreateProjectDetails({super.key, required this.projectData});

  @override
  State<CreateProjectDetails> createState() => _CreateProjectDetailsState();
}

User? loggedInUser = FirebaseAuth.instance.currentUser;

class _CreateProjectDetailsState extends State<CreateProjectDetails> {
  int itemCount = 10;
  bool _isLoading = false;
  Project? project;

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
            //Image(image:,),
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
                      // foregroundColor: foregroundColor,
                      // backgroundColor: backgroundColor,
                    ),
                    onPressed: () => {
                      // TODO: Function (research activity)
                    },
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
                // TODO: change depending on size of description box.
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
                        itemBuilder: (BuildContext context, int index) {
                          return TestCard();
                        },
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(
                          height: 10,
                        ),
                      )
                    : _isLoading == true
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
  const TestCard({
    super.key,
  });

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
                tooltip: 'Open team settings',
                onPressed: () {
                  // TODO: Actual function (chevron right, project details)
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => TeamSettingsScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}