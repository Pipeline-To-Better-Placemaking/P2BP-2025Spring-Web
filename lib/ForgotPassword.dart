import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';

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
    final email = _emailController.text.trim();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _isRequestSent = true;
        _message = 'A reset email has been sent to $email.';
      });
    } catch (error) {
      setState(() {
        _isRequestSent = false;
        _message = error.toString();
      });
    }
  }

  void handleSubmit() {
    final email = _emailController.text.trim();

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
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
      backgroundColor: Color(0xFF1C48A6),
      appBar: AppBar(
        title: Text("Forgot Password", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1C48A6),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/PTBP.png', height: 100),
              SizedBox(height: 20),
              Text(
                'Reset Your Password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                'Enter your email, and we will send a password reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                  errorText: _isEmailValid ? null : 'Invalid email format',
                  filled: true,
                  fillColor: Color(0xFF1C48A6),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 15),
              if (_message.isNotEmpty)
                Text(
                  _message,
                  style: TextStyle(
                    color: _isRequestSent ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: Text(
                  'Send Reset Email',
                  style: TextStyle(color: Color(0xFF1C48A6), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
