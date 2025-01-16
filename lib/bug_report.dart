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
        body: Padding(
          padding: const EdgeInsets.all(100),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            child: SubmitBugReportForm(),
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
      child: ListView(
        children: <Widget>[
          Text(
            Strings.submitBugReportText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
          ),
          SizedBox(height: 12),
          const Text('Title/Short summary'),
          TextFormField(
            controller: _titleController,
            forceErrorText: _titleErrorText,
            decoration: InputDecoration(border: OutlineInputBorder()),
          ),
          SizedBox(height: 12),
          const Text('Description'),
          TextFormField(
            controller: _descController,
            forceErrorText: _descErrorText,
            decoration: InputDecoration(border: OutlineInputBorder()),
            maxLines: null,
            minLines: 4,
          ),
          SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                // Validation
                String titleText = _titleController.text,
                    descText = _descController.text;
                // Resets all error states to null before validating
                _titleErrorText = null;
                _descErrorText = null;
                if (titleText.isEmpty) {
                  _titleErrorText = 'Please enter some text.';
                }
                if (descText.isEmpty) {
                  _descErrorText = 'Please enter some text.';
                }
                // Only succeeds if none of the fields had an error
                if (_titleErrorText == null && _descErrorText == null) {
                  // TODO: Actually submit a report to backend
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processing Data...')),
                  );
                }
              });
            },
            child: const Text(
              'Submit report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }
}