import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatting
import 'package:http/http.dart' as http; // For HTTP requests
import 'dart:convert';

class ResetPassword extends StatefulWidget {
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  String message = '';

  // Handles password complexity requirements
  void handleSubmit() {
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // These are the RegEx requirements for the password.
    if (password.isEmpty ||
        password.length < 8 ||
        password.contains(' ') || // No Empty Space allowed!
        !RegExp(r'\d').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() {
        message =
            '*Please provide a valid password, matching the requirements above';
      });
      return;
    } else if (confirmPassword != password) {
      setState(() {
        message = '*Passwords do not match';
      });
      return;
    } else {
      updatePassword(password);
    }
  }

  // TODO: API Call goes here for backend
  Future<void> updatePassword(String password) async {
    final String path = 'INSERT_PATHWAY_HERE'; // Needs to be the redirect we want to use
    final url = Uri.parse('https://INSERT_URL_FOR_WEBSITE_HERE.com/password_reset/$path');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'password': password}),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() {
          message = 'Error: ${response.body}';
        });
      }
    } catch (error) {
      setState(() {
        message = 'Error: $error';
      });
    }
  }

// TODO: This is initial pass at frontend. It's ugly and untested, but still.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Color(0xFFFFB300),
      ),
      body: Center(
        child: Card(
          color: Color(0xFF1A237E),
          margin: EdgeInsets.all(50),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Enter your new password',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center
                ),
                SizedBox(height: 8),
                Text(
                  '*Minimum password length of 8 characters, including a number, a symbol, and an uppercase letter',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                
                SizedBox(height: 16, width: 1000,), // Width here forces the blue box to stay wide.
                if (message.isNotEmpty)
                  Text(
                    message,
                    style: TextStyle(color: Colors.red),
                  ),
                  
                  Container(
                    width: 500,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                      labelText: 'New Password *',
                      labelStyle: TextStyle(color: Colors.white),
                      
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                     ),
                     keyboardType: TextInputType.visiblePassword,
                     style: TextStyle(color: Colors.white)
                    )
                  ),

                SizedBox(height: 16),

                Container(
                  width:500,
                  alignment: Alignment.center,
                  child: TextField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password *',
                      labelStyle: TextStyle(color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          color: Colors.white,
                          showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            showConfirmPassword = !showConfirmPassword;
                          });
                        },
                      ),
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    style: TextStyle(color: Colors.white)
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
          ),
        ),
      ),
    );
  }
}
