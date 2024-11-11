import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'register.dart' as register;
import 'login.dart' as login;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login & Register',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Disable the debug banner
      initialRoute: '/',
      routes: {
        '/': (context) => login.LoginPage(),
        '/register': (context) => register.RegisterPage(),
      },
    );
  }
}
