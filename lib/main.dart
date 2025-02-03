import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart' as register;
import 'login.dart' as login;
import 'ForgotPassword.dart' as forgotpassword;
import 'homepage.dart'; // Import the HomePage
import 'firebase_options.dart'; // Import the firebase_options.dart file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'settings_page.dart';
import 'package:provider/provider.dart'; // Add Provider package
import 'homepage_state.dart'; // Import the state management class
import 'package:shared_preferences/shared_preferences.dart';

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
  runApp(
    ChangeNotifierProvider(
      create: (_) => HomePageState(), // Provide the state management class
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipeline to Better Placemaking',
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