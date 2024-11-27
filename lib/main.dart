import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart' as register;
import 'login.dart' as login;
import 'ForgotPassword.dart' as forgotpassword;
import 'homepage.dart'; // Import the HomePage
import 'firebase_options.dart';  // Import the firebase_options.dart file
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Ensure Firebase is initialized correctly
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
