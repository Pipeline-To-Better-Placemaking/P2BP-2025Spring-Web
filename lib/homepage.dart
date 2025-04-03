import 'package:flutter/material.dart';
import 'create_project_and_teams.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_functions.dart';
import 'project_details_page.dart';
import 'db_schema_classes.dart';
import 'theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePageBody();
  }
}

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageBodyState createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  String _firstName = 'User';
  DocumentReference? teamRef;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<Project> _projectList = [];
  int _projectsCount = 0;
  bool _isLoading = true;
  String _currentPage = "Home";
  String _currentTeamId = '';

  @override
  void initState() {
    super.initState();
    _getUserFirstName();
    _populateProjects();
    _loadCurrentPage();
  }

  Future<void> _populateProjects() async {
    try {
      teamRef = await getCurrentTeam();
      if (teamRef != null) {
        String newTeamId = teamRef!.id;
        if (_currentTeamId != newTeamId) {
          _currentTeamId = newTeamId;
          _projectList = await getTeamProjects(teamRef!);
          setState(() {
            _projectsCount = _projectList.length;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error in _populateProjects(): $e");
    }
  }

  Future<void> _getUserFirstName() async {
    try {
      String fullName = await getUserFullName(_currentUser?.uid);
      String firstName = fullName.split(' ').first;
      if (_firstName != firstName) {
        setState(() {
          _firstName = firstName;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred while retrieving your name: $e')),
      );
    }
  }

  // Save the current page index
  Future<void> _saveCurrentPage(String page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentPage', page);
  }

  // Load the saved page on startup
  Future<void> _loadCurrentPage() async {
    final prefs = await SharedPreferences.getInstance();
    String savedPage = prefs.getString('currentPage') ??
        'Home'; // Default to 'Home' if no page is saved
    setState(() {
      _currentPage = savedPage;
    });
    _populateProjects(); // Populate the projects based on the page
  }

  // Update the page and save the current page
  void _updatePage(String newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _saveCurrentPage(newPage); // Save the current page when it changes
    _populateProjects(); // Call your project population method if necessary
  }

  int _getPageIndex(String currentPage) {
    switch (currentPage) {
      case 'Home':
        return 0;
      case 'Create':
        return 1;
      case 'Settings':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => _updatePage("Home"),
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text('Home', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => _updatePage("Create"),
            icon: const Icon(Icons.add_circle, color: Colors.white),
            label: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => _updatePage("Settings"),
            icon: const Icon(Icons.settings, color: Colors.white),
            label:
                const Text('Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: IndexedStack(
        index: _getPageIndex(_currentPage),
        children: [
          SizedBox.expand(child: _buildHomeContent(context)),
          const CreateProjectAndTeamsPage(),
          const SettingsPage(),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Positioned(
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                  padding: const EdgeInsets.only(
                      top: 50), // Increased padding to avoid overlap
                  child: SizedBox(
                    width: double.infinity,
                    child: ShaderMask(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5, top: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: ShaderMask(
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
            ),
          ),
          const SizedBox(height: 20),

          // Prevent GridView overflow
          Expanded(
            child: _projectsCount > 0
                ? GridView.builder(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 25,
                      bottom: 25,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 25,
                      childAspectRatio: 2,
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
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "You have no projects! Join or create a team first.",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget buildProjectCard({
    required BuildContext context,
    required String bannerImage,
    required Project project,
    required String teamName,
    required int index,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          if (project.tests == null) {
            await project.loadAllTestData();
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailsPage(activeProject: project),
            ),
          );
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final double cardWidth = maxWidth > 800
                ? 800
                : maxWidth * 0.01; // Dynamically adjust card width

            return Container(
              width: cardWidth,
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
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFCC00),
                          ),
                        ),
                        const SizedBox(height: 5),
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
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      right: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            showEditProjectDialog(context);
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
                        ElevatedButton(
                          onPressed: () async {
                            if (project.tests == null) {
                              await project.loadAllTestData();
                            }
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ResultsPage(activeProject: project)),
                            );
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
            );
          },
        ),
      ),
    );
  }
}
