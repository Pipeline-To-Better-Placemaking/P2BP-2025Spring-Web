import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'strings.dart';

class SubmitBugReportPage extends StatelessWidget {
  const SubmitBugReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Submit a bug report'),
        ),
        body: DefaultTextStyle(
          style: TextStyle(
            color: Colors.blue[800],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          child: ListView(
            padding: EdgeInsets.all(30),
            children: <Widget>[
              SubmitBugReportForm(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class SubmitBugReportForm extends StatefulWidget {
  const SubmitBugReportForm({super.key});

  @override
  State<SubmitBugReportForm> createState() => _SubmitBugReportFormState();
}

class _SubmitBugReportFormState extends State<SubmitBugReportForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController(),
      _descController = TextEditingController();
  String? _titleErrorText, _descErrorText;

  // Stores bug report in Firestore DB after validating
  Future<void> _submitBugReport() async {
    String titleText = _titleController.text;
    String descText = _descController.text;
    // Resets all error states to null before validating
    setState(() {
      _titleErrorText = null;
      _descErrorText = null;
    });

    // Checks for no text in fields
    if (titleText.isEmpty) {
      setState(() {
        _titleErrorText = 'Please enter some text.';
      });
    }
    if (descText.isEmpty) {
      setState(() {
        _descErrorText = 'Please enter some text.';
      });
    }

    // Only succeeds if none of the fields had an error
    if (_titleErrorText == null && _descErrorText == null) {
      try {
        String? uid = FirebaseAuth.instance.currentUser?.uid;
        await FirebaseFirestore.instance.collection('bug_reports').doc().set({
          'uid': uid,
          'title': titleText,
          'description': descText,
          'creationTime': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted successfully! Thank you!'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error occurred while submitting bug report: $e'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            Strings.submitBugReportText,
            style: TextStyle(
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Title/Short summary',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _titleController,
            forceErrorText: _titleErrorText,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _descController,
            forceErrorText: _descErrorText,
            decoration: InputDecoration(border: OutlineInputBorder()),
            maxLines: null,
            minLines: 4,
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
            onPressed: _submitBugReport,
            child: const Text(
              'Submit report',
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