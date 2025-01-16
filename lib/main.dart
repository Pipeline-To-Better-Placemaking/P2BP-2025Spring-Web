import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart' as register;
import 'login.dart' as login;
import 'ForgotPassword.dart' as forgotpassword;
import 'google_maps_page.dart'; // Import your GoogleMapsPage
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
        '/home': (context) => HomePage(),
        '/password_reset': (context) => forgotpassword.ForgotPassword(),
        '/maps': (context) => GoogleMapsPage(), // Add GoogleMapsPage route
      },
    );
  }

  Widget _determineInitialRoute() {
    return FutureBuilder<User?>(
      future: _getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        return snapshot.data != null
            ? HomePage()
            : login.LoginPage();
      },
    );
  }

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
    const sessionTimeout = Duration(minutes: 30);
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, _signOutUser);
  }

  void _signOutUser() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => login.LoginPage()),
    );
  }

  void _resetTimer() {
    _startSessionTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetTimer,
      onPanUpdate: (_) => _resetTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home Page"),
          actions: [
            IconButton(
              icon: Icon(Icons.map),
              onPressed: () => Navigator.pushNamed(context, '/maps'),
            ),
          ],
        ),
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
