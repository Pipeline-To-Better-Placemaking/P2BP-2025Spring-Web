import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_maps_page.dart'; // Import the GoogleMapsPage
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _sessionTimer;
  String? displayName;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _fetchUserData();
  }

  void _startSessionTimer() {
    const sessionTimeout = Duration(minutes: 30);
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, _signOutUser);
  }

  void _resetTimer() {
    _startSessionTimer();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            displayName = userDoc['fullName'];
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
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Home and Google Maps
      child: GestureDetector(
        onTap: _resetTimer,
        onPanUpdate: (_) => _resetTimer(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.home), text: 'Home'),
                Tab(icon: Icon(Icons.map), text: 'Google Maps'),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.exit_to_app),
                onPressed: _signOutUser,
              ),
            ],
          ),
          body: TabBarView(
            children: [
              _buildHomeContent(),
              GoogleMapsPage(), // Using the GoogleMapsPage widget
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Center(
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
                  'Hello, $displayName',
                  style: TextStyle(fontSize: 18),
                )
              : CircularProgressIndicator(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
