import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:math';

// ********* TODO: DUMMY DATA, TO BE TIED INTO db_schema_classes.dart ************************
TestProject generateSampleData() {
  return TestProject(
    projectName: 'Project Testing',
    projectDescription: 'This is the description of the project',
    // mapImagePath: 'assets/PinkHouse.png', // TODO: Figure out image workings
    contributors: ['John Doe', 'Jane Smith'],
    sponsor: 'UCF Professor Herbert ''Tommy'' James',
    tests: [
      Test('Test 1', [
        ['Phone',  80, 95],
        ['Internet', 250, 230],
        ['Electricity', 300, 375],
        ['Movies', 85, 80],
        ['Food', 300, 350],
      ]),
      Test('Test 2', [
        ['Fuel', 650, 550],
        ['Insurance', 250, 310],
        ['Rent', 1200, 1250],
      ]),
    ],
  );
}


// Actual Project / Test classes go here
class Test {
  final String name;
  final List<List<dynamic>> dataTable;
  Test(this.name, this.dataTable);
}

class TestProject {
  final String projectName;
  final String projectDescription;
  // final String mapImagePath;
  final List<String> contributors;
  final String sponsor;
  final List<Test> tests;

  TestProject({
    required this.projectName,
    required this.projectDescription,
    // required this.mapImagePath,
    required this.contributors,
    required this.sponsor,
    required this.tests,
  });
}
// ************************** END DUMMY DATA

// Allows user to see the pdf in browser, sort of testing purposes
class PdfReportPage extends StatelessWidget {
  final TestProject data;

  PdfReportPage({required this.data});

  // Function to generate the PDF
  Future<Uint8List> _generatePdf() async {
    return generateReport(PdfPageFormat.a4, data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Results'),
      ),
      body: FutureBuilder<Uint8List>(
        future: _generatePdf(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
           } else if (snapshot.hasError) {
             return Center(child: Text('Error generating PDF'));
          } else if (snapshot.hasData) {
            // Use the Printing package to display the PDF
            return PdfPreview(
              build: (format) => snapshot.data!, // Generate PDF in the specified format
              onPrinted: (context) {
                // Optional: Perform actions after the PDF is printed
              },
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}



// PDF Generation Logic
Future<Uint8List> generateReport(PdfPageFormat pageFormat, TestProject data) async {

  // Load image data before building the PDF
  // final imageData = await _loadImage(data.mapImagePath);
  const baseColor = PdfColors.cyan;

  final document = pw.Document();

  // Theme settings
  final theme = pw.ThemeData.withFont(
    base: await PdfGoogleFonts.openSansRegular(),
    bold: await PdfGoogleFonts.openSansBold(),
  );

  // Front Page
  document.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: theme,
      build: (context) {
        return pw.Column(
          children: [
            pw.Text(data.projectName,
                style: const pw.TextStyle(
                  color: baseColor,
                  fontSize: 40,
                )),
            pw.Divider(thickness: 4),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        data.projectDescription,
                        style: const pw.TextStyle(fontSize: 16),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                // TODO: Figure out how to populate the image for each test
                // pw.Expanded(
                  // child: pw.Image(
                  //   pw.MemoryImage(imageData),
                  //   fit: pw.BoxFit.contain,
                  // ),
                // ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text('Contributors:\n ${data.contributors.join(', ')}\n\nSponsor: ${data.sponsor}', textAlign: pw.TextAlign.center), 
                ),
              ],
            ),
          ],
        );
      },
    ),
  );


// ** Handles all chart generation for all the tests within the project.
for (var test in data.tests) { // For Each Test
  for (int i = 0; i < test.dataTable.length; i += 4) { // Handles the charts
    final end = (i + 4 <= test.dataTable.length) ? i + 4 : test.dataTable.length;
    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: theme,
        build: (context) {
          return pw.Column(
            children: [
              pw.Text(test.name,
                  style: const pw.TextStyle(
                    color: baseColor,
                    fontSize: 30,
                  )),
              pw.Divider(thickness: 4),
              pw.Column(
                children: List.generate(2, (rowIndex) { 
                  final startIndex = i + rowIndex * 2;
                  if (startIndex < end) {
                    return pw.Row(
                      children: List.generate(2, (colIndex) {
                        final chartIndex = startIndex + colIndex;
                        if (chartIndex < end) {
                          return pw.Expanded(
                            child: _generateChart(test.dataTable[chartIndex]),
                          );
                        } else {
                          return pw.Expanded(child: pw.SizedBox()); // Empty space if no chart
                        }
                      }),
                    );
                  } else {
                    return pw.SizedBox(); // Empty row if there's nothing to show
                  }
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
  return document.save();
}

// Function to generate all the charts
pw.Widget _generateChart(List<dynamic> data) {
  final chartData = [
    pw.PointChartValue(0, data[1].toDouble()),
    pw.PointChartValue(1, data[2].toDouble()),
  ];

  return pw.Chart(
    grid: pw.CartesianGrid(
    xAxis: pw.FixedAxis.fromStrings(
        List<String>.generate(
            data.length, (index) => data[0] as String),
      marginStart: 30,
      marginEnd: 30,
      ticks: true,
    ), 
      yAxis: pw.FixedAxis([0, 100, 200, 300, 400]),
    ),
    datasets: [
      pw.BarDataSet(
        color: PdfColors.blue,
        legend: 'Expense',
        width: 15,
        data: chartData,
      ),
      pw.BarDataSet(
        color: PdfColors.green,
        legend: 'Budget',
        width: 15,
        data: chartData,
      ),
    ],
  );
}

