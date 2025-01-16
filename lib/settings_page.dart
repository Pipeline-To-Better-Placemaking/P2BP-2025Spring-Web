import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'widgets.dart';
import 'change_password.dart';
import 'bug_report.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        //TODO: Relic from Mobile
        //bottomNavigationBar: const BottomFloatingNavBar(),
        body: ListTileTheme(
          tileColor: Colors.blue,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          iconColor: Colors.white,
          textColor: Colors.white,
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              children: <Widget>[
                Column(
                  children: <Widget>[
                    ProfileIconEditStack(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Actual functionality
                      },
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Appearance'),
                const SizedBox(height: 10),
                const DarkModeSwitchListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.format_size),
                  title: Text('Font Size'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Account'),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.gpp_maybe),
                  title: Text('Change Password'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Account Privacy'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    /* TODO: create privacy policy page/writeup in
                        accordance with Google Play Store requirements.
                     */
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Delete Account'),
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  onTap: () {
                    // TODO: confirmation page or popup, then
                    // TODO: actual backend functionality to delete account
                  },
                ),
                const SizedBox(height: 20),
                Text('Support'),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help Center'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  onTap: () {
                    _launchUrl(_faqURL);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Submit a bug report'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubmitBugReportPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log Out'),
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DarkModeSwitchListTile extends StatefulWidget {
  final ShapeBorder shape;

  const DarkModeSwitchListTile({super.key, required this.shape});

  @override
  State<DarkModeSwitchListTile> createState() => _DarkModeSwitchListTileState();
}

class _DarkModeSwitchListTileState extends State<DarkModeSwitchListTile> {
  /* TODO: Add functionality to get initial state when opening the app from
      previous settings or account or something, and to actually change the
      app's visuals accordingly.
  */
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      shape: widget.shape,
      activeTrackColor: Colors.yellow[600],
      secondary: const Icon(Icons.dark_mode_outlined),
      title: const Text('Dark Mode'),
      value: _isDarkMode,
      onChanged: (bool value) {
        setState(() {
          _isDarkMode = value;
        });
      },
    );
  }
}

class ProfileIconEditStack extends StatefulWidget {
  const ProfileIconEditStack({super.key});

  @override
  State<ProfileIconEditStack> createState() => _ProfileIconEditStackState();
}

class _ProfileIconEditStackState extends State<ProfileIconEditStack> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        CircleAvatar(
          // TODO: Add getting profile image from backend
          backgroundColor: Colors.black12,
          radius: 32,
          // Initials of account holder example
          child: const Text('RG'),
          /* Might make final default profile icon similar to this format
              but dynamically getting the initials based on account ofc
           */
        ),
        Positioned(
          bottom: 1,
          right: 1,
          child: InkResponse(
            highlightShape: BoxShape.circle,
            onTap: () {
              /* TODO: Functionality to pick a photo, and then send that to firebase
                  to be saved as new profile icon and then get it from there to
                  display updated icon in this widget immediately
               */
            },
            child: Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(50),
                ),
                color: Colors.yellow[600],
              ),
              child: Icon(
                Icons.edit_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Links to old site FAQ for the time being
final Uri _faqURL = Uri.parse('https://better-placemaking.web.app/faq');

// Currently does nothing~
Future<void> _launchUrl(Uri url) async {
  //if (!await launchUrl(url)) {
  //  throw Exception('Could not launch $url');
  }