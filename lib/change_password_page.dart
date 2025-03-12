import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Password'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            child: ChangePasswordForm(),
          ),
        ),
      ),
    );
  }
}

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController // this comment is for fixing formatting
      _currentPasswordController = TextEditingController(),
      _newPasswordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  
  String? _currentPassErrorText, _newPassErrorText, _confirmPassErrorText;
  bool _currentPassObscureText = true;
  bool _newPassObscureText = true;
  bool _confirmPassObscureText = true;
  bool _isTypingPassword = false;

  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigits = false;
  bool _hasSpecialCharacter = false;
  bool _isLengthValid = false;

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword(String password) {
    setState(() {
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacter = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _isLengthValid = password.length >= 12;
    });
  }

  // Returns true if current password matches, otherwise false and/or throws error.
  Future<bool> _validateCurrentPassword(String password) async {
    try {
      UserCredential userCredential =
          await _currentUser!.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: _currentUser!.email!,
          password: password,
        ),
      );
      return true; // If no exception is thrown, password is correct
    } on FirebaseAuthException catch (e) {
      setState(() {
        _currentPassErrorText = 'Incorrect password. Please try again.';
      });
      return false; // Password is incorrect
    }
  }

  // Validates data and then updates the password if everything validates.
  Future<void> _submitForm() async {
    String currentPass = _currentPasswordController.text,
        newPass = _newPasswordController.text,
        confirmPass = _confirmPasswordController.text;

    // Reset error messages before validation
    setState(() {
      _currentPassErrorText = null;
      _newPassErrorText = null;
      _confirmPassErrorText = null;
    });

    bool isCurrentPassValid = await _validateCurrentPassword(currentPass);

    // If the current password is incorrect, show error and stop further execution
    if (!isCurrentPassValid) {
      setState(() {}); // Ensure UI updates with the error message
      return;
    }

    // Validate new password fields
    if (newPass.isEmpty) {
      _newPassErrorText = 'Please enter a new password.';
    }
    if (confirmPass.isEmpty) {
      _confirmPassErrorText = 'Please confirm your new password.';
    }
    if (newPass.isNotEmpty && confirmPass.isNotEmpty && newPass != confirmPass) {
      _newPassErrorText = 'Passwords do not match.';
      _confirmPassErrorText = 'Passwords do not match.';
    }

    // If there are any errors, update UI and stop execution
    if (_newPassErrorText != null || _confirmPassErrorText != null) {
      setState(() {}); // Update UI with errors
      return;
    }

    // Proceed with password update if all checks pass
    try {
      await _currentUser?.updatePassword(newPass);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _newPassErrorText = 'An error occurred: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: <Widget>[
          const Text('Current Password'),
          PasswordTextFormField(
            controller: _currentPasswordController,
            obscureText: _currentPassObscureText,
            forceErrorText: _currentPassErrorText,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _currentPassObscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() => _currentPassObscureText = !_currentPassObscureText);
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          const Text('New Password'),
          PasswordTextFormField(
            controller: _newPasswordController,
            obscureText: _newPassObscureText,
            forceErrorText: _newPassErrorText,
            onChanged: (password) {
              setState(() {
                _isTypingPassword = true;
                _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
                _hasLowerCase = password.contains(RegExp(r'[a-z]'));
                _hasDigits = password.contains(RegExp(r'[0-9]'));
                _hasSpecialCharacter = password.contains(RegExp(r'[^A-Za-z0-9]'));
                _isLengthValid = password.length >= 12;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _newPassObscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() => _newPassObscureText = !_newPassObscureText);
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          if (_isTypingPassword)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!_hasUpperCase)
                  Text('✘ Uppercase letter', style: TextStyle(color: Colors.blue[800])),
                if (!_hasLowerCase)
                  Text('✘ Lowercase letter', style: TextStyle(color: Colors.blue[800])),
                if (!_hasDigits)
                  Text('✘ Number', style: TextStyle(color: Colors.blue[800])),
                if (!_hasSpecialCharacter)
                  Text('✘ Special character', style: TextStyle(color: Colors.blue[800])),
                if (!_isLengthValid)
                  Text('✘ Minimum length of 12 characters', style: TextStyle(color: Colors.blue[800])),
              ],
            ),
          SizedBox(height: 12),
          const Text('Confirm New Password'),
          PasswordTextFormField(
            controller: _confirmPasswordController,
            obscureText: _confirmPassObscureText,
            forceErrorText: _confirmPassErrorText,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPassObscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() => _confirmPassObscureText = !_confirmPassObscureText);
                },
              ),
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 200, // You can adjust the width as needed
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _submitForm,
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}