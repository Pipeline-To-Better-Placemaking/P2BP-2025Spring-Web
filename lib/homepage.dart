import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'homepage_state.dart';
import 'create_project_and_teams.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';
import 'project_map_creation.dart'; // Import the project creation page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_functions.dart';
import 'create_project_details.dart';
import 'project_comparison_page.dart';
import 'themes.dart';
import 'db_schema_classes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomePageState()..loadState(),
      child: const HomePageBody(),
    );
  }
}

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  _HomePageBodyState createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  String _firstName = 'User';

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<Project> _projectList = [];
  int _projectsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserFirstName();
    _populateProjects();
  }

  Future<void> _populateProjects() async {
    DocumentReference? teamRef;

    try {
      teamRef = await getCurrentTeam();
      if (teamRef == null) {
        print(
            "Error populating projects in home_screen.dart. No selected team available.");
      } else {
        _projectList = await getTeamProjects(teamRef);
      }
      setState(() {
        _projectsCount = _projectList.length;
        _isLoading = false;
      });
    } catch (e) {
      print("Error in _populateProjects(): $e");
    }
  }

  // Gets name from DB, get the first word of that, then sets _firstName to it
  Future<void> _getUserFirstName() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String fullName = userDoc.get('fullName') ?? 'User';
          String firstName = fullName.split(' ').first;

          setState(() {
            _firstName = firstName;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving name: $e')),
      );
    }
  }

  final LinearGradient defaultGrad = const LinearGradient(
    colors: [Color(0xFF3874CB), Color(0xFF183769)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<HomePageState>(
      builder: (context, homePageState, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF2F6DCF),
            title: Image.asset(
              'assets/PTBP.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            actions: [
              TextButton.icon(
                onPressed: () => homePageState.updatePage("Home"),
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text('Home', style: TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => homePageState.updatePage("Create"),
                icon: const Icon(Icons.add_circle, color: Colors.white),
                label: const Text('Create', style: TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => homePageState.updatePage("Compare"),
                icon: const Icon(Icons.compare_arrows, color: Colors.white),
                label: const Text('Compare', style: TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => homePageState.updatePage("Settings"),
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text('Settings', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: IndexedStack(
            index: _getPageIndex(homePageState.currentPage),
            children: [
              _buildHomeContent(context),
              const CreateProjectAndTeamsPage(),
              const ProjectComparisonPage(),
              const SettingsPage(),
            ],
          ),
        );
      },
    );
  }

  int _getPageIndex(String currentPage) {
    switch (currentPage) {
      case 'Home':
        return 0;
      case 'Create':
        return 1;
      case 'Compare':
        return 2;
      case 'Settings':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'assets/P2BP_Logo.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Image.asset('assets/bell-03.png'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          },
                          iconSize: 24,
                        ),
                        IconButton(
                          icon: const Icon(Icons.group),
                          color: const Color(0xFF0A2A88),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TeamsAndInvitesPage(),
                              ),
                            );
                          },
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return defaultGrad.createShader(bounds);
                          },
                          child: Text(
                            'Hello, $_firstName',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return defaultGrad.createShader(bounds);
                    },
                    child: const Text(
                      'Your Projects',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _projectsCount > 0
                ? GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 25,
                      bottom: 25,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Define the number of columns
                      crossAxisSpacing: 15, // Spacing between columns
                      mainAxisSpacing: 25, // Spacing between rows
                      childAspectRatio: 1.25, // Adjust the height/width ratio of the cards
                    ),
                    itemCount: _projectsCount,
                    itemBuilder: (BuildContext context, int index) {
                      final project = _projectList[index];
                      return buildProjectCard(
                        context: context,
                        bannerImage: 'assets/RedHouse.png',
                        project: project,
                        teamName: 'Team: Eola Design Group',
                        index: index,
                      );
                    },
                  )
                : _isLoading == true
                    ? const Center(child: CircularProgressIndicator())
                    : Align(
                        alignment: Alignment.center,
                        child: Text(
                            "You have no projects! Join or create a team first."),
                      ),
          ],
        ),
      ),
    );
  }

  Widget buildProjectCard({
    required BuildContext context,
    required String bannerImage, // Image path for banner
    required Project project, // Project object containing project details
    required String teamName, // Team name
    required int index,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Match the container's corner radius
      ),
      child: InkWell(
        onTap: () async {
          // Fetch project details asynchronously
          Project tempProject = await getProjectInfo(project.projectID);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateProjectDetails(projectData: tempProject),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3874CB), Color(0xFF183769)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner image at the top
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  bannerImage,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              // Project details section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project name
                    Text(
                      project.title, // Use project title from the Project object
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Team name
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),
              ),
              // Optional buttons for actions like Edit and Results (can be customized)
              Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  right: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit Info button
                    OutlinedButton(
                      onPressed: () {
                        // Handle navigation to Edit menu
                        showEditProjectModalSheet(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFFCC00),
                          width: 2.0,
                        ),
                        foregroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Edit Info',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Results button
                    ElevatedButton(
                      onPressed: () {
                        // Handle navigation to Results menu
                        showResultsModalSheet(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D4076),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}