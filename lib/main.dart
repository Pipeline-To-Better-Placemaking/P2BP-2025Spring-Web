import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart' as register;
import 'login.dart' as login;
import 'ForgotPassword.dart' as forgotpassword;
import 'firebase_options.dart'; // Import the firebase_options.dart file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:provider/provider.dart'; // Add Provider package
import 'homepage_state.dart'; // Import the state management class
import 'homepage.dart';
import 'db_schema_classes.dart';

  /// All [Test] subclass's register methods should be called here.
  void registerTestTypes() {
    AbsenceOfOrderTest.register();
    //AcousticProfileTest.register();
    IdentifyingAccessTest.register();
    LightingProfileTest.register();
    NaturePrevalenceTest.register();
    PeopleInMotionTest.register();
    PeopleInPlaceTest.register();
    SectionCutterTest.register();
    SpatialBoundariesTest.register();
  }

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
    registerTestTypes(); // Test class setup
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
    Timer? _idleTimer;
    final Duration idleDuration = Duration(minutes: 30);

    @override
    void initState() {
      super.initState();
      _resetTimer(); // Start tracking activity
    }

    void _resetTimer() {
      _idleTimer?.cancel(); // Cancel any existing timer
      _idleTimer = Timer(idleDuration, _handleUserIdle); // Start new timer
    }

    void _handleUserIdle() {
      FirebaseAuth.instance.signOut(); // Log out the user
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/'); // Redirect to login
      }
    }

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: _resetTimer, // Reset on user interaction
        onPanDown: (_) => _resetTimer(),
        child: MaterialApp(
          title: 'Pipeline to Better Placemaking',
          debugShowCheckedModeBanner: false,
          home: FutureBuilder<User?>(
            future: FirebaseAuth.instance.authStateChanges().first,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                return HomePage(); // User is logged in
              } else {
                return login.LoginPage(); // User is not logged in
              }
            },
          ),
          routes: {
            '/register': (context) => register.RegisterPage(),
            '/password_reset': (context) => forgotpassword.ForgotPassword(),
            '/login': (context) => login.LoginPage(),
          },
        ),
      );
    }

    @override
    void dispose() {
      _idleTimer?.cancel(); // Cancel timer on dispose
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
