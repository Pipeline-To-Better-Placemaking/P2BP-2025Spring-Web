import 'package:flutter/material.dart';
import 'project_details_page.dart';

class ProjectListWidget extends StatelessWidget {
  final bool isMultiSelectMode;
  final Set<int> selectedProjects;
  final Function(int) onToggleSelection;
  final Function(int) onProjectTap;

  const ProjectListWidget({
    Key? key,
    required this.isMultiSelectMode,
    required this.selectedProjects,
    required this.onToggleSelection,
    required this.onProjectTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6, // Replace with the actual project count
      itemBuilder: (context, index) {
        bool isSelected = selectedProjects.contains(index);
        return Column(
          children: [
            ListTile(
              // If in multi-select mode, show a checkmark bubble on the left.
              leading: isMultiSelectMode
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => onToggleSelection(index),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Color(0xFF62B6FF)
                                  : Colors.grey.withValues(alpha: 0.3),
                            ),
                            child: isSelected
                                ? Icon(Icons.check,
                                    color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                        SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/RedHouse.png', // Replace with project image
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/RedHouse.png', // Replace with project image
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
              title: Text(
                'Project Title $index',
                style: TextStyle(color: Colors.white),
              ),
              // Hide trailing chevron when in multi-select mode
              trailing: isMultiSelectMode
                  ? null
                  : Icon(Icons.chevron_right, color: Colors.white),
              onTap: () {
                if (isMultiSelectMode) {
                  onToggleSelection(index);
                } else {
                  onProjectTap(index);
                }
              },
            ),
            isMultiSelectMode
                ? Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    thickness: 1,
                    indent: 50,
                    endIndent: 16,
                  )
                : Divider(
                    color: Colors.white.withValues(alpha: 0.3),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
          ],
        );
      },
    );
  }
}