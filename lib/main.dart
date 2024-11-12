import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart' as register;
import 'login.dart' as login;
import 'homepage.dart'; // Import the HomePage
import 'firebase_options.dart';  // Import the firebase_options.dart file

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
        '/': (context) => login.LoginPage(),
        '/register': (context) => register.RegisterPage(),
        '/home': (context) => HomePage(), // Add HomePage route
      },
    );
  }
}
