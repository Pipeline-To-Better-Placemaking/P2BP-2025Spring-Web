import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Change Password')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            child: const ChangePasswordForm(),
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _currentPassErrorText, _newPassErrorText, _confirmPassErrorText;
  bool _isLoading = false;

  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() {
      _currentPassErrorText = null;
      _newPassErrorText = null;
      _confirmPassErrorText = null;
      _isLoading = true;
    });

    String currentPass = _currentPasswordController.text.trim();
    String newPass = _newPasswordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    // Validate fields
    if (currentPass.isEmpty) {
      setState(() => _currentPassErrorText = 'Please enter your current password.');
      _isLoading = false;
      return;
    }
    if (newPass.isEmpty) {
      setState(() => _newPassErrorText = 'Please enter a new password.');
      _isLoading = false;
      return;
    }
    if (confirmPass.isEmpty) {
      setState(() => _confirmPassErrorText = 'Please confirm your new password.');
      _isLoading = false;
      return;
    }
    if (newPass != confirmPass) {
      setState(() {
        _newPassErrorText = 'Passwords do not match.';
        _confirmPassErrorText = 'Passwords do not match.';
      });
      _isLoading = false;
      return;
    }

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user signed in.')));
        return;
      }

      // Reauthenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPass,
      );

      await user.reauthenticateWithCredential(credential);

      // If reauthentication is successful, update the password
      await user.updatePassword(newPass);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));

      // Clear input fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        setState(() => _currentPassErrorText = 'Incorrect current password.');
      } else if (e.code == 'weak-password') {
        setState(() => _newPassErrorText = 'New password is too weak.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Toggle visibility functions
  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _currentPasswordVisible = !_currentPasswordVisible;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _newPasswordVisible = !_newPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _confirmPasswordVisible = !_confirmPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const Text('Current Password'),
          PasswordTextFormField(
            controller: _currentPasswordController,
            obscureText: !_currentPasswordVisible,
            forceErrorText: _currentPassErrorText,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Image.asset(
                  _currentPasswordVisible ? 'assets/eye.png' : 'assets/hidden.png',
                  height: 24,
                  width: 24,
                ),
                onPressed: _toggleCurrentPasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('New Password'),
          PasswordTextFormField(
            controller: _newPasswordController,
            obscureText: !_newPasswordVisible,
            forceErrorText: _newPassErrorText,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Image.asset(
                  _newPasswordVisible ? 'assets/eye.png' : 'assets/hidden.png',
                  height: 24,
                  width: 24,
                ),
                onPressed: _toggleNewPasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Confirm New Password'),
          PasswordTextFormField(
            controller: _confirmPasswordController,
            obscureText: !_confirmPasswordVisible,
            forceErrorText: _confirmPassErrorText,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Image.asset(
                  _confirmPasswordVisible ? 'assets/eye.png' : 'assets/hidden.png',
                  height: 24,
                  width: 24,
                ),
                onPressed: _toggleConfirmPasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isLoading ? null : _changePassword,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
