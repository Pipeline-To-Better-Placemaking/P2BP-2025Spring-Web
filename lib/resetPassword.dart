import 'package:flutter/material.dart';
import 'widgets.dart';
import 'theme.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    AssetBundle bundle = DefaultAssetBundle.of(context);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reset Password'),
        ),
        body: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 20,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: defaultGrad,
              ),
              padding: const EdgeInsets.all(30),
              child: ListView(
                children: <Widget>[
                  Image(
                    image: AssetImage(
                      'assets/ResetPasswordBanner.png',
                      bundle: bundle,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                    ),
                  ),
                  SizedBox(height: 10),
                  ResetPasswordForm(),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: const ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(
                        Color(0xFFFFD700),
                      ),
                    ),
                    child: const Text(
                      'Return to Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController // this comment is for fixing formatting
      _newPasswordController = TextEditingController(),
      _confirmPasswordController = TextEditingController();
  String? _newPassErrorText, _confirmPassErrorText;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          PasswordTextFormField(
            controller: _newPasswordController,
            forceErrorText: _newPassErrorText,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xD8C3C3C3),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFF6F6F6),
                ),
              ),
              hintStyle: TextStyle(
                color: Color(0xD8C3C3C3),
              ),
              prefixIcon: Icon(
                Icons.lock_open,
                color: Color(0xD8C3C3C3),
              ),
              hintText: 'New Password',
            ),
          ),
          SizedBox(height: 10),
          PasswordTextFormField(
            controller: _confirmPasswordController,
            forceErrorText: _confirmPassErrorText,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xD8C3C3C3),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFF6F6F6),
                ),
              ),
              hintStyle: TextStyle(
                color: Color(0xD8C3C3C3),
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Color(0xD8C3C3C3),
              ),
              hintText: 'Confirm Password',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Color(0xFFFFCC00),
              ),
              foregroundColor: WidgetStatePropertyAll(
                Color(0xFF333333),
              ),
            ),
            onPressed: () {
              setState(() {
                // All validation logic is here
                String newPass = _newPasswordController.text,
                    confirmPass = _confirmPasswordController.text;
                // Resets all error states to null before checking
                _newPassErrorText = null;
                _confirmPassErrorText = null;
                if (newPass.isEmpty) {
                  _newPassErrorText = 'Please enter some text.';
                }
                if (confirmPass.isEmpty) {
                  _confirmPassErrorText = 'Please enter some text.';
                }
                if (newPass.isNotEmpty &&
                    confirmPass.isNotEmpty &&
                    newPass != confirmPass) {
                  _newPassErrorText = 'Passwords do not match.';
                  _confirmPassErrorText = 'Passwords do not match.';
                }
                // Only succeeds if none of the fields had an error
                if (_newPassErrorText == null &&
                    _confirmPassErrorText == null) {
                  // TODO: Change password on backend here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processing Data...')),
                  );
                }
              });
            },
            child: const Text(
              'Update Password',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
