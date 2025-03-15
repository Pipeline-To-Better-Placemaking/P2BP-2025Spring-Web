import 'package:flutter/material.dart';
import 'theme.dart';
import 'Login.dart';
import 'homepage.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: defaultGrad,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: <Widget>[
            // Logo Illustration
            Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Image.asset('assets/landscape_weather.png', height: 301),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Google Sign Up Button
            ElevatedButton(
              onPressed: () {
                // TODO: Handle Google login logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/google_icon.png',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sign Up with Google',
                    style: TextStyle(
                      color: Color(0xFF5F6368),
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // OR Divider
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Divider(color: Colors.white)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            // Full Name Input
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 10, right: 30),
                  child: ImageIcon(
                    AssetImage('assets/User_box.png'),
                    color: Colors.white,
                  ),
                ),
                labelText: 'Full Name',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: false,
              ),
            ),
            const SizedBox(height: 10),
            // Email Address Input
            const TextField(
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 10, right: 30),
                  child: Opacity(
                    opacity: 0.75,
                    child: ImageIcon(
                      AssetImage('assets/mail_icon.png'),
                      color: Colors.white,
                    ),
                  ),
                ),
                labelText: 'Email Address',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: false,
              ),
            ),
            const SizedBox(height: 10),
            // Password Input
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 30,
                  ),
                  child: ImageIcon(
                    AssetImage('assets/Unlock.png'),
                    color: Colors.white,
                  ),
                ),
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: false,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // Toggle password visibility
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Confirm Password Input
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 30,
                  ),
                  child: ImageIcon(
                    AssetImage('assets/Lock.png'),
                    color: Colors.white,
                  ),
                ),
                labelText: 'Confirm Password',
                labelStyle: const TextStyle(color: Colors.white),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                filled: false,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.grey),
                  onPressed: () {
                    // Toggle password visibility
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Sign Up Button
            ElevatedButton(
              onPressed: () {
                // Handle sign up logic
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFCC00),
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            // Already have an account redirect
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                                            Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(), // Redirect to Login Page
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}