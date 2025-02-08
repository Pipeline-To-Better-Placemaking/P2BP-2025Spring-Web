import 'package:flutter/material.dart';
import 'package:p2b/project_map_creation.dart';
import 'package:provider/provider.dart';
import 'homepage_state.dart';
import 'create_project_and_teams.dart';
import 'compare_project.dart';
import 'settings_page.dart';
import 'teams_and_invites_page.dart';
import 'results_panel.dart';
import 'edit_project_panel.dart';
import 'project_map_creation.dart'; // Import the project creation page
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _getUserFirstName();
  }

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
              //const ProjectMapCreation(), // Added the Project Creation Page
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
                  Align(alignment: Alignment.topCenter),
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Image.asset('assets/bell-03.png'),
                          onPressed: () {
                            Navigator.pushReplacement(
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
                                builder: (context) =>
                                    const TeamsAndInvitesPage(),
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
                            'Hello,\n$_firstName',
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
              padding: const EdgeInsets.only(right: 5, top: 20),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.3,
              ),
              itemCount: 3,
              itemBuilder: (context, index) {
                final projectDetails = [
                  {
                    'image': 'assets/RedHouse.png',
                    'title': 'Project Eola',
                    'team': 'Team: Eola Design Group'
                  },
                  {
                    'image': 'assets/PinkHouse.png',
                    'title': 'Project Neocity',
                    'team': 'Team: New Horizons Placemakers'
                  },
                  {
                    'image': 'assets/RedHouse.png',
                    'title': 'Project Knight Library',
                    'team': 'Team: Lake Nona Design Group'
                  },
                ];
                final details = projectDetails[index];
                return buildProjectCard(
                  context,
                  details['image']!,
                  details['title']!,
                  details['team']!,
                );
              },
            ),
            const SizedBox(height: 150),
          ],
        ),
      ),
    );
  }

  Widget buildProjectCard(
    BuildContext context,
    String bannerImage,
    String projectName,
    String teamName,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                    projectName,
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
          ],
        ),
      ),
    );
  }
}
