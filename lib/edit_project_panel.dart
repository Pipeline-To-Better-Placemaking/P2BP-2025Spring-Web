import 'dart:typed_data'; // For web image bytes
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'db_schema_classes/project_class.dart';
import 'theme.dart';
import 'widgets.dart';
import 'dart:io' show File;

class EditProjectForm extends StatefulWidget {
  final Project activeProject;
  const EditProjectForm({super.key, required this.activeProject});

  @override
  State<EditProjectForm> createState() => _EditProjectFormState();
}

class _EditProjectFormState extends State<EditProjectForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  // For mobile
  // File? _imageFile;

  // For web and mobile
  XFile? _pickedImageFile;
  Uint8List? _imageBytes; // web image bytes

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activeProject.title);
    _descriptionController =
        TextEditingController(text: widget.activeProject.description);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          // Padding for keyboard opening
          padding: MediaQuery.viewInsetsOf(context),
          child: Container(
            // Container decoration- rounded corners and gradient
            decoration: BoxDecoration(
              gradient: defaultGrad,
              borderRadius: BorderRadius.circular(24.0)
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                spacing: 12,
                children: [
                  // Creates little indicator on top of sheet
                  const BarIndicator(bottomPadding: 0),
                  Text(
                    "Edit Project",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p2bpYellow.shade600,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project name text field
                      Expanded(
                        flex: 2,
                        child: EditProjectTextBox(
                          maxLength: 60,
                          maxLines: 2,
                          minLines: 1,
                          labelText: 'Project Name',
                          controller: _nameController,
                          validator: (value) {
                            if (value == null || value.length < 3) {
                              return 'Name must have at least 3 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      // Add photo button
                      InkWell(
                        onTap: () async {
                          final XFile? pickedFile = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            if (kIsWeb) {
                              _pickedImageFile = pickedFile;
                              _imageBytes = await pickedFile.readAsBytes();
                            } else {
                              _pickedImageFile = pickedFile;
                            }
                            setState(() {});
                          }
                        },
                        child: Column(
                          spacing: 3,
                          children: [
                            CircleAvatar(
                              radius: 27.0,
                              backgroundColor: p2bpYellow,
                              child: Icon(
                                Icons.add_photo_alternate,
                                size: 36,
                              ),
                            ),
                            Text(
                              'Update Cover',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Project description text field
                  EditProjectTextBox(
                    maxLength: 240,
                    maxLines: 4,
                    minLines: 3,
                    labelText: 'Project Description',
                    controller: _descriptionController,
                    validator: (value) {
                      if (value == null || value.length < 3) {
                        return 'Description must have at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      // Save Changes button
                      EditButton(
                        text: 'Save Changes',
                        foregroundColor: Colors.black,
                        backgroundColor: p2bpYellow,
                        icon: const Icon(Icons.save),
                        iconColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              bool changed = false;
                              if (widget.activeProject.title
                                      .compareTo(_nameController.text) !=
                                  0) {
                                widget.activeProject.title =
                                    _nameController.text;
                                changed = true;
                              }

                              if (widget.activeProject.description
                                      .compareTo(_descriptionController.text) !=
                                  0) {
                                widget.activeProject.description =
                                    _descriptionController.text;
                                changed = true;
                              }

                              if (_pickedImageFile != null) {
                                final coverImageRef = FirebaseStorage.instance.ref(
                                    'project_covers/${widget.activeProject.id}');
                                if (kIsWeb && _imageBytes != null) {
                                  await coverImageRef.putData(_imageBytes!,
                                      SettableMetadata(contentType: 'image/jpeg'));
                                } else {
                                  final file = File(_pickedImageFile!.path);
                                  await coverImageRef.putFile(file);
                                }
                                widget.activeProject.coverImageUrl =
                                    await coverImageRef.getDownloadURL();
                                changed = true;
                              }

                              if (changed) await widget.activeProject.update();

                              if (!context.mounted) return;
                              Navigator.pop(
                                  context, changed ? 'altered' : null);
                            } catch (e, s) {
                              print('Error updating project: $e');
                              print('Stacktrace: $s');
                            }
                          }
                        },
                      ),
                      // Delete project button
                      EditButton(
                        text: 'Delete Project',
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFFD32F2F),
                        icon: Icon(FontAwesomeIcons.trashCan),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        onPressed: () async {
                          final didDelete = await showDeleteProjectDialog(
                            context: context,
                            project: widget.activeProject,
                          );

                          if (!context.mounted) return;
                          if (didDelete == true) {
                            Navigator.pop(context, 'deleted');
                          }
                        },
                      ),
                    ],
                  ),
                  // Cancel button to close bottom sheet
                  InkWell(
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Cancel',
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFFFFD700)),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
