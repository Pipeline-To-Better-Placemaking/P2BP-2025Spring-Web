import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'show_project_options_dialog.dart';
import 'db_schema_classes.dart';
import 'package:flutter/services.dart';
import 'create_test_form.dart';
import 'theme.dart';
import 'firestore_functions.dart';

class ProjectDetailsPage extends StatefulWidget {
  final Project projectData;

  /// IMPORTANT: When navigating to this page, pass in project details. Use
  /// `getProjectInfo()` from firestore_functions.dart to retrieve project
  /// object w/ data.
  /// <br/>Note: project is returned as future, await return before passing.
  const ProjectDetailsPage({super.key, required this.projectData});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
User? loggedInUser = FirebaseAuth.instance.currentUser;

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late int _testCount;
  bool _isLoading = true;
  Project? project;
  late Widget _testListView;

  @override
  Widget build(BuildContext context) {
    _testCount = widget.projectData.tests!.length;
    _testListView = _buildTestListView();
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            automaticallyImplyLeading: false, // Disable default back arrow
            leadingWidth: 48,
            systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.white,
                statusBarIconBrightness:
                    Brightness.dark, // Changes Android status bar to white
                statusBarBrightness:
                    Brightness.dark), // Changes iOS status bar to white
            // Custom back arrow button
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                // Opaque circle container for visibility
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets
                      .zero, // Removes internal padding from IconButton
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.arrow_back,
                      color: Color(0xFF2F6DCF), size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            // 'Edit Options' button overlaid on right side of cover photo
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Builder(
                  builder: (context) {
                    return Container(
                      // Opaque circle container for visibility
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(
                          Icons.more_vert,
                          color: Color(0xFF2F6DCF),
                        ),
                        onPressed: () => showProjectOptionsDialog(context),
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: <Widget>[
                // Banner image
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: .5),
                    ),
                    color: Color(0xFF999999),
                  ),
                ),
              ]),
            ),
          ),
          SliverList(delegate: SliverChildListDelegate([_getPageBody()])),
        ],
      ),
    );
  }

  Widget _getPageBody() {
    return Container(
      decoration: BoxDecoration(gradient: defaultGrad),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'Project Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white, width: .5),
                    bottom: BorderSide(color: Colors.white, width: .5),
                  ),
                  color: Color(0x699F9F9F),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 5.0),
                  child: Text.rich(
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(text: "${widget.projectData.description}\n\n\n"),
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Center(
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Color(0x699F9F9F),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x98474747),
                        spreadRadius: 3,
                        blurRadius: 3,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 50, vertical: 77.5),
                    child: SizedBox(
                      width: 200,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          // foregroundColor: foregroundColor,
                          backgroundColor: Colors.black,
                        ),
                        onPressed: () => {
                          // TODO: Function
                        },
                        label: Text('View Project Area'),
                        icon: Icon(Icons.location_on),
                        iconAlignment: IconAlignment.start,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 25.0, vertical: 20.0),
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
                        backgroundColor: Color(0xFF62B6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        // foregroundColor: foregroundColor,
                        // backgroundColor: backgroundColor,
                      ),
                      onPressed: _showCreateTestModal,
                      label: Text('Create'),
                      icon: Icon(Icons.add),
                      iconAlignment: IconAlignment.end,
                    )
                  ],
                ),
              ),
              Container(
                // TODO: change depending on size of description box.
                height: 350,
                decoration: BoxDecoration(
                  color: Color(0x22535455),
                  border: Border(
                    top: BorderSide(color: Colors.white, width: .5),
                  ),
                ),
                child: _isLoading == true
                    ? const Center(child: CircularProgressIndicator())
                    : _testCount > 0
                        ? _testListView
                        : const Center(
                            child: Text(
                                'No research activities. Create one first!')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTestModal() async {
    final Map<String, dynamic> newTestInfo = await showDialog(
      context: context,
      barrierDismissible: false, // Disallows dismissal by tapping outside the dialog
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            height: 560, // You can adjust the height based on your content
            width: 600,  // Adjust the width of the dialog
            child: CreateTestForm(),
          ),
        );
      },
    );

    final Test test = await saveTest(
      title: newTestInfo['title'],
      scheduledTime: newTestInfo['scheduledTime'],
      projectRef:_firestore.collection('projects').doc(widget.projectData.projectID),
      collectionID: newTestInfo['collectionID'],
      );
      setState(() {
        widget.projectData.tests?.add(test);
      });
  }

  Widget _buildTestListView() {
    Widget list = ListView.separated(
      itemCount: _testCount,
      padding: const EdgeInsets.only(
        left: 15,
        right: 15,
        top: 25,
        bottom: 30,
      ),
      itemBuilder: (BuildContext context, int index) => TestCard(
        test: widget.projectData.tests![index],
        project: widget.projectData,
      ),
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 10),
    );
    setState(() {
      _isLoading = false;
    });
    return list;
  }
}

const Map<Type, String> _testInitialsMap = {
  LightingProfileTest: 'LP',
  SectionCutterTest: 'SC',
  IdentifyingAccessTest: 'IA',
  //PeopleInPlaceTest: 'PP',
  //PeopleInMotionTest: 'PM',
};

class TestCard extends StatelessWidget {
  final Test test;
  final Project project;

  const TestCard({
    super.key,
    required this.test,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: <Widget>[
            // TODO: change corresponding to test type
            CircleAvatar(
              child: Text(_testInitialsMap[test.runtimeType] ?? ''),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Text(test.title),
            ),
            if (_testInitialsMap[test.runtimeType] == 'SC')
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.blue,
                ),
                tooltip: 'Open team settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => test.getPage(project)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}