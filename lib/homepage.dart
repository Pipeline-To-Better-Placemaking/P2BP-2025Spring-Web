import 'package:flutter/material.dart';
import 'package:p2b/db_schema_classes/member_class.dart';
import 'create_project_and_teams.dart';
import 'db_schema_classes/team_class.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';
import 'results_page.dart';
import 'edit_project_panel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_details_page.dart';
import 'db_schema_classes/project_class.dart';
import 'theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  final Member member;
  const HomePage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return HomePageBody(member: member);
  }
}

class HomePageBody extends StatefulWidget {
  final Member member;
  const HomePageBody({super.key, required this.member});

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
  Team? _currentTeam;
  String _currentPage = "Home";
  String teamName = 'Team Name';

  @override
  void initState() {
    super.initState();
    _getUserFirstName();
    _populateProjects();
    _loadCurrentPage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _populateProjects() async {
    try {
      _currentTeam = await widget.member.loadSelectedTeamInfo();
      if (_currentTeam == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _projectList = await _currentTeam!.loadProjectsInfo();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e, s) {
      print("Error in _populateProjects(): $e");
      print('Stacktrace: $s');
    }
  }

  Future<void> _getUserFirstName() async {
    try {
      String fullName = widget.member.fullName;
      String firstName = fullName.split(' ').first;
      if (_firstName != firstName) {
        setState(() {
          _firstName = firstName;
        });
      }
    } catch (e) {
      if (!mounted) return;
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
          CreateProjectAndTeamsPage(
            member: widget.member,
          ),
          SettingsPage(member: widget.member),
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
                              builder: (context) => TeamsAndInvitesPage(
                                member: widget.member,
                              ),
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
            child: _projectList.isNotEmpty
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
                    itemCount: _projectList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final project = _projectList[index];
                      return buildProjectCard(
                        context: context,
                        bannerImage: 'assets/RedHouse.png',
                        project: project,
                        teamName: project.team!.title,
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
            await project.loadAllTestInfo();
          }
          if (!context.mounted) return;
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
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 24),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: MediaQuery.of(context).viewInsets,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 600,
                                        minWidth: 300,
                                      ),
                                      child: SingleChildScrollView(
                                        child:
                                            EditProjectForm(activeProject: project),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
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
                              await project.loadAllTestInfo();
                            }
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ResultsPage(activeProject: project),
                              ),
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
