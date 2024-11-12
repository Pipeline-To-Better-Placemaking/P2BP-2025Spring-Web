import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isEmailValid = true;
  bool _isRequestSent = false;

  // The URL to send the POST request
  final String resetURL = '/password_reset';

  // TODO: Will need amending
  Future<void> sendForgotEmail() async {
    final email = _emailController.text;

    try {
      final response = await http.post(
        Uri.parse(resetURL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isRequestSent = true;
        });
      } else {
        setState(() {
          _message = 'Failed to send email. Please try again.';
        });
      }
    } catch (error) {
      setState(() {
        _message = 'Error sending email: $error';
      });
    }
  }

  void handleSubmit() {
    final email = _emailController.text;

    if (email.length < 7) {
      setState(() {
        _isEmailValid = false;
        _message = 'Please provide a valid email (minimum length 7)';
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
            color: Color(0xFF1A237E),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,                
                children: [
                  // TODO: Placeholder image needs changing when we get to it
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'It happens! Just enter the email associated with your account, and we will send you a link to help.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        if (!_isEmailValid)
                          Text(
                            _message,
                            style: TextStyle(color: Colors.red),
                          ),

                        SizedBox(height: 10),
                        Container( 
                          alignment: Alignment.center,
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Enter your Email Address',
                              labelStyle: TextStyle(color: Colors.white),
                              errorText: _isEmailValid ? null : 'Please provide a valid email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                            
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: handleSubmit,
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFFB300)),
                          child: Text('Send Reset Email', style: TextStyle(color: Colors.black),), 
                          ),
                      ],
                    ),

                  // TODO: Update emailController
                  if (_isRequestSent)
                    Container(
                      color: Color(0xFFB6D7A8),
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'An email containing a link to reset your password has been sent to ${_emailController.text}, it may take a few minutes to appear. In case you do not see an email in your inbox, check your Spam or Junk Folders.',
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
