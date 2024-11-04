import 'package:flutter/material.dart';
import 'Register.dart' as register; // Alias for RegisterPage
import 'Login.dart' as login; // Alias for LoginPage

void main() {
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
        '/': (context) => login.LoginPage(), // Use alias for LoginPage
        '/register': (context) => register.RegisterPage(), // Use alias for RegisterPage
      },
    );
  }
}