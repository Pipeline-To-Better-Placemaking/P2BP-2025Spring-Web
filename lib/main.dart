import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart' as register;
import 'login.dart' as login;
import 'ForgotPassword.dart' as forgotpassword;
//import 'homepage.dart'; // Import the HomePage
import 'firebase_options.dart'; // Import the firebase_options.dart file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Ensure Firebase is initialized correctly
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set Firebase persistence to SESSION to log out on tab/browser close
    await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
  } catch (e) {
    print("Firebase initialization failed: $e");
    // Handle the error here, maybe show an error screen or fallback UI
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipeline to Better Placemaking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Disable the debug banner
      initialRoute: '/',
      routes: {
        '/': (context) => _determineInitialRoute(),
        '/register': (context) => register.RegisterPage(),
        '/home': (context) => HomePage(), // Add HomePage route
        '/password_reset': (context) => forgotpassword.ForgotPassword(),
      },
    );
  }

  // This method will check if the user is logged in and navigate accordingly
  Widget _determineInitialRoute() {
    return FutureBuilder<User?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While Firebase is loading, show a loading spinner
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Handle any errors that occur during the fetch
          return Center(child: Text('Something went wrong'));
        }

        if (snapshot.data != null) {
          // If the user is logged in, go directly to HomePage
          return HomePage();
        } else {
          // If not logged in, show the login page
          return login.LoginPage();
        }
      },
    );
  }

  // This method retrieves the current user from Firebase
  Future<User?> _getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
  }

  void _startSessionTimer() {
    const sessionTimeout = Duration(minutes: 30); // Set inactivity timeout
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, _signOutUser);
  }

  void _signOutUser() async {
    await FirebaseAuth.instance.signOut();
    // Redirect to login page after sign-out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login.LoginPage()),
    );
  }

  void _resetTimer() {
    _startSessionTimer(); // Reset the session timer
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetTimer, // Reset timer on user interaction
      onPanUpdate: (_) => _resetTimer(), // Track gestures
      child: Scaffold(
        appBar: AppBar(title: Text("Home Page")),
        body: Center(child: Text("Welcome to the Home Page!")),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}

// Functions for Firestore interaction
Future<void> addUserToFirestore(String uid, String name) async {
  try {
    // Reference to the 'users' collection
    var usersCollection = FirebaseFirestore.instance.collection('users');

    // Add a new document with a user ID
    await usersCollection.doc(uid).set({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('User added successfully');
  } catch (e) {
    print('Error adding user: $e');
  }
}

Future<void> getUserFromFirestore(String uid) async {
  try {
    var usersCollection = FirebaseFirestore.instance.collection('users');
    var userDoc = await usersCollection.doc(uid).get();

    if (userDoc.exists) {
      print('User Data: ${userDoc.data()}');
    } else {
      print('User not found');
    }
  } catch (e) {
    print('Error fetching user data: $e');
  }
}
