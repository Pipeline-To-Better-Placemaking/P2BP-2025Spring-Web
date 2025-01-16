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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validation feedback variables
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigits = false;
  bool _hasSpecialCharacter = false;
  bool _isLengthValid = false;
  bool _isTypingPassword = false;

  bool _isHovering = false;

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
          'createdAt': FieldValue.serverTimestamp(),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User Registered Successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                'Create an Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 254, 254, 254)),
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
                            labelStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2.0),
                            ),
                            prefixIcon: Image.asset(
                              'assets/icons/user.png',
                              width: 24,
                              height: 24,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
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
                            labelStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white, width: 2.0),
                            ),
                            prefixIcon: Image.asset(
                              'assets/icons/email.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
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
                            labelStyle: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 2.0),
                            ),
                            prefixIcon: Image.asset(
                              'assets/icons/padlock.png',
                              width: 24,
                              height: 24,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                                size: 24,
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
                    if (_isTypingPassword)
                      Center(
                        child: Container(
                          width: 300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (!_hasUpperCase || !_hasLowerCase || !_hasDigits || !_hasSpecialCharacter || !_isLengthValid)
                                Text(
                                  'Password must contain:',
                                  style: TextStyle(color: Colors.white),
                                ),
                              if (!_hasUpperCase)
                                Text(
                                  '✘ Uppercase letter',
                                  style: TextStyle(color: Colors.white),
                                ),
                              if (!_hasLowerCase)
                                Text(
                                  '✘ Lowercase letter',
                                  style: TextStyle(color: Colors.white),
                                ),
                              if (!_hasDigits)
                                Text(
                                  '✘ Number',
                                  style: TextStyle(color: Colors.white),
                                ),
                              if (!_hasSpecialCharacter)
                                Text(
                                  '✘ Special character',
                                  style: TextStyle(color: Colors.white),
                                ),
                              if (!_isLengthValid)
                                Text(
                                  '✘ Minimum length of 12 characters',
                                  style: TextStyle(color: Colors.white),
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
                            prefixIcon: Image.asset(
                              'assets/icons/padlock.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: _toggleConfirmPasswordVisibility,
                            ),
                          ),
                          obscureText: _obscureConfirmText,
                          style: TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFB300),
                          minimumSize: Size(200, 50),
                        ),
                        child: Text('Create an Account', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    SizedBox(height: 16),
                    Column(
                      children: <Widget>[
                        Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _isHovering = true;  // When the mouse enters the area
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _isHovering = false;  // When the mouse exits the area
                            });
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);  // Navigate back to the login page
                            },
                            child: Text(
                              'Login here',
                              style: TextStyle(
                                color: _isHovering ? Color(0xFFFFB300) : Colors.white,  // Change color on hover
                                fontWeight: FontWeight.bold,
                                decoration: _isHovering ? TextDecoration.underline : null,  // Underline text on hover
                              ),
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
      ),
    );
  }
}
