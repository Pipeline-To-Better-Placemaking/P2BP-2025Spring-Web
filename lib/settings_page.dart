import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'change_email_page.dart';
import 'change_name_page.dart';
import 'login_screen.dart';
import 'db_schema_classes/member_class.dart';
import 'theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'change_password_page.dart';
import 'strings.dart';
import 'submit_bug_report_page.dart';

class SettingsPage extends StatefulWidget {
  final Member member;
  const SettingsPage({super.key, required this.member});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Signs out of this account and returns to login screen.
  void _signOutUser(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Sends to login screen and removes everything else from nav stack
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route route) => false);
      } else {
        throw Exception('context-unmounted');
      }
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log out failed. Try again.')),
      );
    }
  }

  /// Builds and displays confirmation dialog for signing out of account.
  Future<void> _signOutConfirmDialogBuilder(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Are you sure?'),
        titlePadding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
        ),
        content: const Text(Strings.signOutConfirmText),
        contentPadding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 10,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, go back'),
          ),
          TextButton(
            onPressed: () => _signOutUser(context),
            child: const Text('Yes, log me out'),
          ),
        ],
        actionsPadding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
  }

  /// Currently does same as _signOutUser, need to implement deletion.
  ///
  /// Deletes the account being used along with all references to it from DB.
  ///
  /// Sends user back to login screen after deletion.
  // void _deleteAccount(BuildContext context) async {
  //   try {
  //     // TODO: actually delete account and all references to it.
  //     await FirebaseAuth.instance.signOut();
  //     if (context.mounted) {
  //       // Sends to login screen and removes everything else from nav stack
  //       Navigator.pushNamedAndRemoveUntil(
  //           context, '/login', (Route route) => false);
  //     } else {
  //       throw Exception('context-unmounted');
  //     }
  //   } catch (e) {
  //     print('Error signing out: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Log out failed. Try again.')),
  //     );
  //   }
  // }

  /// Builds and displays confirmation dialog for deleting account.
  // Future<void> _deleteAccountConfirmDialogBuilder(BuildContext context) async {
  //   // TODO: better confirmation like user has to type their email or something
  //   return showDialog<void>(
  //     context: context,
  //     builder: (BuildContext context) => AlertDialog(
  //       title: const Text('Are you sure?'),
  //       titlePadding: EdgeInsets.only(
  //         left: 20,
  //         right: 20,
  //         top: 20,
  //       ),
  //       content: const Text(Strings.deleteAccountConfirmText),
  //       contentPadding: EdgeInsets.only(
  //         left: 20,
  //         right: 20,
  //         top: 16,
  //         bottom: 10,
  //       ),
  //       actions: <Widget>[
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('No, go back'),
  //         ),
  //         TextButton(
  //           onPressed: () => _deleteAccount(context),
  //           child: const Text('Yes, delete my account'),
  //         ),
  //       ],
  //       actionsPadding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
  //       actionsAlignment: MainAxisAlignment.end,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      tileColor: p2bpBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      iconColor: Colors.white,
      textColor: Colors.white,
      child: DefaultTextStyle(
        style: TextStyle(
          color: p2bpBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          children: <Widget>[
            Column(
              children: <Widget>[
                ProfileIconEditStack(
                  member: widget.member,
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 18),

            // TODO: Implement Dark Mode after Committee
            // const Text('Appearance'),
            // const SizedBox(height: 10),
            // DarkModeSwitchListTile(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            // ),
            // const SizedBox(height: 20),

            const Text('Account'),
            const SizedBox(height: 10),
            // TODO: make modular widget or set of widgets for groups of
            //  ListTiles like this that automatically rounds the corners
            //  of the top and bottom ones like is done here?
            ListTile(
              leading: Icon(Icons.badge_outlined),
              title: Text('Change Name'),
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
                    builder: (context) => ChangeNamePage(
                      member: widget.member,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.alternate_email),
              title: Text('Change Email Address'),
              trailing: Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangeEmailPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.gpp_maybe),
              title: Text('Change Password'),
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
                    builder: (context) => const ChangePasswordPage(),
                  ),
                );
              },
            ),

            // ListTile(
            //   leading: Icon(Icons.lock_outline),
            //   title: Text('Account Privacy'),
            //   trailing: Icon(Icons.chevron_right),
            //   onTap: () {
            //     /* TODO: create privacy policy page/writeup in
            //           accordance with Google Play Store requirements.
            //        */
            //   },
            // ),

            // TODO: Implement delete account after committee
            // ListTile(
            //   leading: Icon(Icons.lock_outline),
            //   title: Text('Delete Account'),
            //   iconColor: criticalRed,
            //   textColor: criticalRed,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.only(
            //       bottomLeft: Radius.circular(10),
            //       bottomRight: Radius.circular(10),
            //     ),
            //   ),
            //   onTap: () => _deleteAccountConfirmDialogBuilder(context),
            // ),

            const SizedBox(height: 20),
            const Text('Support'),
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
              iconColor: criticalRed,
              textColor: criticalRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () => _signOutConfirmDialogBuilder(context),
            ),
            const SizedBox(height: 150),
          ],
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
      activeTrackColor: p2bpYellowAccent,
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
  final Member member;
  const ProfileIconEditStack({super.key, required this.member});

  @override
  State<ProfileIconEditStack> createState() => _ProfileIconEditStackState();
}

class _ProfileIconEditStackState extends State<ProfileIconEditStack> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late Future<String> _initials;

  // Gets the user's initials via their full name from firebase
  Future<String> _getUserInitials() async {
    String result = '';

    try {
      // Get user's full name from firebase
      final String fullName = widget.member.fullName;

      // Adds the first letter of each word of the full name to result string
      final splitFullNameList = fullName.split(' ');
      for (var word in splitFullNameList) {
        result += word.substring(0, 1).toUpperCase();
      }
      return result;
    } catch (e) {
      if (!mounted) return result;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'An error occurred while trying to load your profile icon: $e',
          ),
        ),
      );
      return 'Err';
    }
  }

  @override
  void initState() {
    super.initState();
    _initials = _getUserInitials();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // TODO: modify below FutureBuilder for profile icon uploaded by user
        // Shows profile icon based on state of Future.
        // Gets user's initials and has fallback. Planned to get image
        // previously uploaded by user if there is one.
        FutureBuilder<String>(
          future: _initials,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return CircleAvatar(
                backgroundColor: Colors.black12,
                radius: 32,
                // Initials of account holder example
                child: Text(snapshot.data!),
              );
            } else {
              return CircleAvatar(
                backgroundColor: Colors.black12,
                radius: 32,
                // Initials of account holder example
                child: Text('...'),
              );
            }
          },
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
                color: p2bpYellowAccent,
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

Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}
