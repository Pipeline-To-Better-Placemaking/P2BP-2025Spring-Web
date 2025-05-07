import 'package:flutter/material.dart';
import 'change_email_page.dart';
import 'change_name_page.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
        ),
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
              padding: const EdgeInsets.all(30),
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.alternate_email),
                  title: Text('Change Email Address'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeEmailPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.badge_outlined),
                  title: Text('Change Name'),
                  trailing: Icon(Icons.chevron_right),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
