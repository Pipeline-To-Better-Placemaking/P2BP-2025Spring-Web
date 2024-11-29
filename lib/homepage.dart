import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _sessionTimer;
  String? displayName; // To store the user's full name

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _fetchUserData(); // Fetch user data on page load
  }

  void _startSessionTimer() {
    const sessionTimeout = Duration(minutes: 30); // Set inactivity timeout
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, _signOutUser);
  }

  void _resetTimer() {
    _startSessionTimer(); // Reset the session timer
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Fetch user data from Firestore
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            displayName = userDoc['fullName']; // Fetch user's full name
          });
        } else {
          print('User data not found in Firestore.');
        }
      } else {
        print('No authenticated user found.');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _signOutUser() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/'); // Redirect to login page
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetTimer, // Reset timer on user interaction
      onPanUpdate: (_) => _resetTimer(), // Track gestures
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          actions: [
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: _signOutUser, // Log out the user
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome to the Home Page!',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              displayName != null
                  ? Text(
                      'Hello, $displayName', // Display user's full name
                      style: TextStyle(fontSize: 18),
                    )
                  : CircularProgressIndicator(), // Show loading spinner until data is fetched
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }
}
