import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'db_schema_classes/member_class.dart';
import 'strings.dart';

class ChangeNamePage extends StatelessWidget {
  final Member member;

  const ChangeNamePage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Change Name'),
        ),
        body: DefaultTextStyle(
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          child: ListView(
            padding: const EdgeInsets.all(30),
            children: <Widget>[
              const Text(Strings.changeNameText),
              const SizedBox(height: 16),
              ChangeNameForm(member: member,),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeNameForm extends StatefulWidget {
  final Member member;

  const ChangeNameForm({super.key, required this.member});

  @override
  State<ChangeNameForm> createState() => _ChangeNameFormState();
}

class _ChangeNameFormState extends State<ChangeNameForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentFullName = 'Loading...';

  bool _isNameChanged = false;

  Future<void> _submitNameChange() async {
    if (_formKey.currentState!.validate()) {
      try {
        String newName = _fullNameController.text.trim();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.member.id)
            .update({'fullName': newName});
        await _currentUser?.updateDisplayName(newName);
        setState(() {
          widget.member.fullName = newName;
          _isNameChanged = true;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing name: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
            'Your current name is:\n${widget.member.fullName}',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Full Name',
            ),
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your new name';
              }
              if (value.trim() == widget.member.fullName) {
                return 'This is already your name';
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
            onPressed: _submitNameChange,
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isNameChanged)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 16),
                Text(
                  'Your name has been changed successfully.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 17,
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