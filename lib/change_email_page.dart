import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'strings.dart';

class ChangeEmailPage extends StatelessWidget {
  const ChangeEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Email Address'),
        ),
        body: DefaultTextStyle(
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Text(Strings.changeEmailText1),
              const SizedBox(height: 16),
              ChangeEmailForm(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeEmailForm extends StatefulWidget {
  const ChangeEmailForm({super.key});

  @override
  State<ChangeEmailForm> createState() => _ChangeEmailFormState();
}

class _ChangeEmailFormState extends State<ChangeEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _currentEmail;
  StreamSubscription? _userChangesListener;

  bool _isEmailSent = false;

  @override
  void initState() {
    super.initState();
    _currentEmail = _currentUser?.email;

    // Meant to listen for auth update after changing email to update displayed
    // current email address. But it doesn't work, the email never updates
    // except sometimes to null.
    _userChangesListener = FirebaseAuth.instance.userChanges().listen((user) {
      setState(() {
        _currentUser = user;
        _currentEmail = _currentUser?.email;
      });
    });
  }

  Future<void> _submitEmailChange() async {
    if (_formKey.currentState!.validate()) {
      try {
        String newEmail = _emailController.text.trim();
        await _currentUser?.verifyBeforeUpdateEmail(newEmail);

        setState(() {
          _isEmailSent = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification email sent successfully!')),
          );
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing email: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userChangesListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            style: TextStyle(
              fontSize: 20,
              color: Colors.black87,
            ),
            'Your current email address is:\n$_currentEmail',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Email Address',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your new email address';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              if (value == _currentEmail) {
                return 'This is your current email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _submitEmailChange,
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isEmailSent)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 16),
                Text(
                  'The verification email sent successfully.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  Strings.changeEmailText2,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}