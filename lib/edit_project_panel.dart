import 'package:flutter/material.dart';
import 'themes.dart';
import 'widgets.dart';

class EditProjectPanel extends StatefulWidget {
  const EditProjectPanel({super.key});

  @override
  State<EditProjectPanel> createState() => _EditProjectPanel();
}

class _EditProjectPanel extends State<EditProjectPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            showEditProjectDialog(context);
          },
          child: const Text('Edit Project'),
        ),
      ),
    );
  }
}

void showEditProjectDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Color(0xFF1C48A6), // Ensure background matches the content
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: EdgeInsets.zero, // Removes extra margin around the dialog
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: buildEditSheet(context),
        ),
      );
    },
  );
}


Padding buildEditSheet(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      decoration: BoxDecoration(
        color: Color(0xFF1C48A6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Edit Project",
                style: TextStyle(
                    color: Colors.yellow[700],
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const EditProjectTextBox(
              maxLength: 60,
              maxLines: 2,
              minLines: 1,
              labelText: 'Project Name',
            ),
            const SizedBox(height: 10),
            const EditProjectTextBox(
              maxLength: 240,
              maxLines: 4,
              minLines: 3,
              labelText: 'Project Description',
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                EditButton(
                  text: 'Update Map',
                  foregroundColor: Colors.black,
                  backgroundColor: const Color(0xFFFFCC00),
                  icon: const Icon(Icons.gps_fixed),
                  onPressed: () {},
                ),
                EditButton(
                  text: 'Delete Project',
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  icon: const Icon(Icons.delete),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Color(0xFFFFD700)),
                  ),
                ),
                const SizedBox(width: 10),
                EditButton(
                  text: 'Save Changes',
                  foregroundColor: Colors.black,
                  backgroundColor: const Color(0xFFFFCC00),
                  icon: const Icon(Icons.save),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}