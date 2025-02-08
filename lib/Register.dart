import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  double _scale = 1.0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

  // Validation feedback variables
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigits = false;
  bool _hasSpecialCharacter = false;
  bool _isLengthValid = false;
  bool _isTypingPassword = false;  // Flag to track if user has started typing

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmText = !_obscureConfirmText;
    });
  }

  // Register user with Firebase
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create user with email and password
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Update the user's displayName with the full name entered during registration
        await userCredential.user?.updateProfile(displayName: _fullNameController.text.trim());
 	
        // Add user data to Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'creationTime': FieldValue.serverTimestamp(),
        });

        // Send email verification
        if (userCredential.user != null) {
          await userCredential.user!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration successful! A verification email has been sent to ${_emailController.text.trim()}. Please verify your email before logging in.',
              ),
            ),
          );
        }

        // If registration is successful, show a message and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User Registered Successfully!')),
        );

        // Optionally, navigate to the login page (or another page)
        Navigator.pop(context); // This will return to the login page, for example.
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $e')),
        );
      }
    }
  }

  void _checkPasswordConditions(String value) {
    setState(() {
      _isTypingPassword = true;
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = value.contains(RegExp(r'[a-z]'));
      _hasDigits = value.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacter = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _isLengthValid = value.length >= 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C48A6),
      body: SingleChildScrollView(  // Wrap the entire body in a scroll view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,  // Ensure the column doesn't take too much vertical space
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/PTBP.png',
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Create an Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
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
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
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
                            prefixIcon: Icon(Icons.person, color: Colors.white),
                            errorStyle: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          style: TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
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
                            prefixIcon: Icon(Icons.email, color: Colors.white),
                            errorStyle: TextStyle(color: Colors.white, fontSize: 18),
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
                          onChanged: _checkPasswordConditions,
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
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            errorStyle: TextStyle(color: Colors.white, fontSize: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
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
                    SizedBox(height: 8),
                    // Show password condition feedback only when the user starts typing
                    if (_isTypingPassword)
                      Center(
                        child: Container(
                          width: 300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Only show the "Password must contain:" line if any condition is unmet
                              if (!_hasUpperCase || !_hasLowerCase || !_hasDigits || !_hasSpecialCharacter || !_isLengthValid)
                                Text(
                                  'Password must contain:',
                                  style: TextStyle(color: Colors.white),
                                ),
                              if (!_hasUpperCase)
                                Text(
                                  '✘ Uppercase letter',
                                  style: TextStyle(color: const Color(0xFFFFFFFF)),
                                ),
                              if (!_hasLowerCase)
                                Text(
                                  '✘ Lowercase letter',
                                  style: TextStyle(color: const Color(0xFFFFFFFF)),
                                ),
                              if (!_hasDigits)
                                Text(
                                  '✘ Number',
                                  style: TextStyle(color: const Color(0xFFFFFFFF)),
                                ),
                              if (!_hasSpecialCharacter)
                                Text(
                                  '✘ Special character',
                                  style: TextStyle(color: const Color(0xFFFFFFFF)),
                                ),
                              if (!_isLengthValid)
                                Text(
                                  '✘ Minimum length of 12 characters',
                                  style: TextStyle(color: const Color(0xFFFFFFFF)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 300,
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
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
                            prefixIcon: Icon(Icons.lock, color: Colors.white),
                            errorStyle: TextStyle(color: Colors.white, fontSize: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: _toggleConfirmPasswordVisibility,
                            ),
                          ),
                          obscureText: _obscureConfirmText,
                          style: TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
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
                        onPressed: _registerUser,
                        child: Text(
                          'Register',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFB300),
                        ),
                      ),
                    ),
                  ),
                    SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Navigate back to the login page
                            },
                            child: Text(
                              'Login here',
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255), // Yellow color text
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}