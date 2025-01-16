import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'package:p2b/ForgotPassword.dart';
import 'register.dart';
import 'homepage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscureText = true; // Toggle for password visibility

  String _fullName = '';  // Variable to store full name
  Color _signUpButtonColor = Colors.white;
  TextStyle _forgotPasswordTextStyle = TextStyle(color: Colors.white);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _loginUser() async {
    try {
      // Sign in using Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check if the email is verified
      User? user = userCredential.user;
      if (user != null && !user.emailVerified) {
        // Log the user out immediately
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please verify your email before logging in.',
            ),
          ),
        );

        return;
      }

      // Add/Update last login time in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'lastLogin': FieldValue.serverTimestamp(), // Add last login timestamp
      }, SetOptions(merge: true)); // Merge data to avoid overwriting


      // Fetch the user's full name from Firestore
      String userId = userCredential.user!.uid;
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // Retrieve full name from Firestore if available
        String fullName = userDoc['fullName'] ?? 'User';
        setState(() {
          _fullName = fullName;
        });

        // Successfully logged in, navigate to the home screen
        ScaffoldMessenger.of(context).clearSnackBars(); // Clear any existing snackbars
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $_fullName!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // Replace with your home page
        );
      } else {
        // Handle case where user data does not exist in Firestore (shouldn't happen if user data is properly saved)
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found in Firestore')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      // Provide user-friendly error messages
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }

      // Clear any existing snackbars and show new one
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // General error handling
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C48A6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Image.asset(
                'assets/icons/PTBP.png',
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Please login',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 300,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2.0),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2.0),
                          ),
                          prefixIcon: ColorFiltered(
                            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            child: SizedBox(
                              width: 12,  // Adjust width
                              height: 12, // Adjust height
                              child: Image.asset('assets/icons/email.png'),
                            ),
                          ),
                          errorStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 18),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 300,
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 2.0),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2.0),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2.0),
                          ),
                          prefixIcon: ColorFiltered(
                            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            child: SizedBox(
                              width: 8,  // Adjust width
                              height: 8, // Adjust height
                              child: Image.asset('assets/icons/padlock.png'),
                            ),
                          ),
                          errorStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 18),
                          suffixIcon: IconButton(
                            icon: ColorFiltered(
                              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn), // Apply white color to the image
                              child: Image.asset(
                                _obscureText ? 'assets/icons/eye.png' : 'assets/icons/hidden.png',
                                width: 24, // Set width as per your requirement
                                height: 24, // Set height as per your requirement
                              ),
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                        ),
                        obscureText: _obscureText,
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _loginUser();
                          }
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFB300),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _forgotPasswordTextStyle = TextStyle(
                          color: Color(0xFFFFB300),
                          shadows: [
                            Shadow(
                              color: Colors.blueAccent,
                              blurRadius: 8.0,
                              offset: Offset(0, 0),
                            ),
                          ],
                        );
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _forgotPasswordTextStyle = TextStyle(color: Colors.white);
                      });
                    },
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ForgotPassword()),
                        );
                      },
                      child: Text(
                        'Forgot your password?',
                        style: _forgotPasswordTextStyle,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Column(
                    children: [
                      Text(
                        'Don’t have an account?',
                        style: TextStyle(color: Colors.white),
                      ),
                      MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            _signUpButtonColor = Color(0xFFFFB300); // Change color when hovering
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            _signUpButtonColor = Colors.white; // Revert back when not hovering
                          });
                        },
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPage()),
                            );
                          },
                          child: Text(
                            'Click here to Sign Up',
                            style: TextStyle(color: _signUpButtonColor),
                          ),
                        ),
                      ),
                    ],
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
