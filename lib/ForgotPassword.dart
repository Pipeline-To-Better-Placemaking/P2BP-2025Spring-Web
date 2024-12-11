import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isEmailValid = true;
  bool _isRequestSent = false;

  Future<void> sendForgotEmail() async {
    final email = _emailController.text.trim(); // Trim to avoid trailing spaces

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isRequestSent = true;
        _message = 'A reset email has been sent to $email.';
      });
    } catch (error) {
      setState(() {
        _isRequestSent = false;
        _message = error.toString(); // Provide error details
      });
    }
  }

  void handleSubmit() {
    final email = _emailController.text.trim();

    if (!RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(email)) {
      setState(() {
        _isEmailValid = false;
        _message = 'Please provide a valid email address.';
      });
    } else {
      setState(() {
        _isEmailValid = true;
        _message = '';
      });
      sendForgotEmail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xFFFFB300),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Card(
            color: Color(0xFF1C48A6),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/icons/PTBP.png',
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Forgot Password?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  if (!_isRequestSent)
                    Column(
                      children: [
                        Text(
                          'Enter the email associated with your account, and we will send you a reset link.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        if (_message.isNotEmpty)
                          Text(
                            _message,
                            style: TextStyle(
                                color: !_isEmailValid ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: Colors.black),
                            errorText: _isEmailValid ? null : 'Invalid email format',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFFFFB300), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: Colors.black), // Set text color to black
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: handleSubmit,
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFB300)),
                          child: Text(
                            'Send Reset Email',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  if (_isRequestSent)
                    Container(
                      color: Color(0xFFB6D7A8),
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'An email has been sent to ${_emailController.text}. Please check your inbox or spam folder.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
