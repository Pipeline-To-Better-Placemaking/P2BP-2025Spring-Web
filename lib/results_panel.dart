import 'package:flutter/material.dart';
import 'themes.dart';
import 'widgets.dart';

class ResultsPanel extends StatefulWidget {
  const ResultsPanel({super.key});

  @override
  State<ResultsPanel> createState() => _ResultsPanelState();
}

class _ResultsPanelState extends State<ResultsPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () {
            showResultsModalSheet(context);
          },
          child: const Text('Open bottom sheet'),
        ),
      ),
    );
  }
}

void showResultsModalSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: defaultGrad,
              // rounded corners of panel
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            child: Column(
              children: [
                const BarIndicator(),
                Text(
                  "Results",
                  style: TextStyle(
                    color: Colors.yellow[700],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}