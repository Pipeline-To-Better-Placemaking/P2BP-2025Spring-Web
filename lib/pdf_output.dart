import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2b/db_schema_classes.dart';
import 'package:p2b/firestore_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:math';

// Allows user to see the pdf in browser so they know what they are getting
class PdfReportPage extends StatelessWidget {
  final Project projectData;

  const PdfReportPage({super.key, required this.projectData});

  // generate the PDF
  Future<Uint8List> _generatePdf() async {
    return generateReport(PdfPageFormat.a4, projectData);
  }

  // Create a GoogleMap widget in a SizedBox of certain size. Takes in data.
  // Then in a for loop: data is put into map. Map is rendered. Screenshot map.
  // Save screenshot to an array. Or do this in switch statement.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Results'),
      ),
      body: FutureBuilder<Uint8List>(
        future: _generatePdf(),
        builder: (context, snapshot) {
          try {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              throw Exception(snapshot.error);
            } else if (snapshot.hasData) {
              // Use the Printing package to display the PDF
              return PdfPreview(
                maxPageWidth: 800,
                build: (format) =>
                    snapshot.data!, // Generate PDF in the specified format
                onPrinted: (context) {},
              );
            } else {
              return Center(child: Text('No data available'));
            }
          } catch (e, stacktrace) {
            print('Exception: $e');
            print('Stacktrace: $stacktrace');
            return Center(child: Text('Error generating PDF'));
          }
        },
      ),
    );
  }
}

// PDF Generation Logic
Future<Uint8List> generateReport(
    PdfPageFormat pageFormat, Project projectData) async {
  // Variables used to sort all the tests, so similar tests are shown together
  List rawTests = [];
  List secCut = [],
      absOfOrder = [],
      identAccess = [],
      peopInMot = [],
      peopInPlace = [],
      lightProf = [],
      natPrev = [],
      spatBound = [],
      acouProf = [];
  List sortedTests = [];
  // Load images data before building the PDF, but was not implemented
  // final imageData = await _loadImage(data.mapImagePath);
  const baseColor = PdfColors.black;

  // Actually launches the pdf builder
  final document = pw.Document();

  // Theme settings
  final theme = pw.ThemeData.withFont(
    base: await PdfGoogleFonts.openSansRegular(),
    bold: await PdfGoogleFonts.openSansBold(),
  );

  // First Page
  document.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: theme,
      build: (context) {
        return pw.Column(
          children: [
            pw.Text(projectData.title,
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
                        projectData.description,
                        style: const pw.TextStyle(fontSize: 16),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                // TODO: Figure out how to populate the image for each test
                // This handles the cover page
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
                  // Contributor Loop should either be a manual entry by the user on 'who to thank'
                  // https://davbfr.github.io/dart_pdf/ -> certificate for an example
                  // Or Pull data from Team, to list all the people on the team who contributed.
                  child: pw.Text(
                      'Contributors:\n INSERT CONTRIBUTORS LOOP HERE\n\nSponsor: UCF Professor Herbert Tommy James',
                      textAlign: pw.TextAlign.center),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  // ** Bucket Sorting of tests **

  // Get all the test information sorted into the correct representation.
  if (projectData.tests == null) {
    await projectData.loadAllTestData();
  }
  rawTests = projectData.tests ?? [];
  for (Test currentTest in rawTests) {
    // If a test isn't complete, skip it
    if (!currentTest.isComplete) continue;

    // Add one page for an explainer for each test type.
    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: theme,
        build: (context) {
          return TestPdfPage(test: currentTest);
        },
      ),
    );

    // Logic to combine all the tests into an organized, singular list we can work with
    // Useful so all test types are clustered together
    // TODO: in each case, extract the data for graphs. dont need to add to their own lists, instead use sorting function based on test type?
    switch (currentTest.collectionID) {
      case 'lighting_profile_tests':
        {
          LightingProfileData currentLPData =
              (currentTest as LightingProfileTest).data;
          currentLPData.toString();
        }
      case 'absence_of_order_tests':
        {
          AbsenceOfOrderData currentLPData =
              (currentTest as AbsenceOfOrderTest).data;
        }
      case 'spatial_boundaries_tests':
        {
          SpatialBoundariesData currentLPData =
              (currentTest as SpatialBoundariesTest).data;
        }
      case 'section_cutter_tests':
        {
          Section currentLPData = (currentTest as SectionCutterTest).data;
        }
      case 'identifying_access_tests':
        {
          AccessData currentLPData =
              (currentTest as IdentifyingAccessTest).data;
        }
      case 'nature_prevalence_tests':
        {
          NatureData currentLPData = (currentTest as NaturePrevalenceTest).data;
        }
      case 'people_in_place_tests':
        {
          PeopleInPlaceData currentLPData =
              (currentTest as PeopleInPlaceTest).data;
        }
      case 'people_in_motion_tests':
        {
          PeopleInMotionData currentLPData =
              (currentTest as PeopleInMotionTest).data;
        }
      case 'acoustic_profile_tests':
        {
          throw UnimplementedError();
        }
    }
  }
  sortedTests.addAll(peopInMot +
      peopInPlace +
      spatBound +
      lightProf +
      natPrev +
      absOfOrder +
      acouProf +
      identAccess +
      secCut);
  // ** End Bucket Sorting, now allocated into a singular large 'bucket'

//   // ** Gathers the data from each test
//   for (int i = 0; i < rawTests.length; i++) {
//     List data = [], labels = [];
//     List<List<dynamic>> combined = [];
//
//     if (sortedTests[i]['projType'] ==
//         'Section Cutter') // ** SECTION CUTTER DATA
//     {
//       continue; // TODO: People In Place
//     } else if (sortedTests[i]['projType'] ==
//         'Lighting Profile') // ** LIGHTING PROFILE DATA
//     {
//       //continue; // Done for testing purposes
//       labels.add('Task');
//       if (sortedTests[i]['data']['task'] != null ||
//           sortedTests[i]['data']['task'].length != 0) {
//         data.add(sortedTests[i]['data']['task'].length);
//       } else {
//         data.add(0);
//       }
//
//       labels.add('Rythmic');
//       if (sortedTests[i]['data']['rhythmic'] != null ||
//           sortedTests[i]['data']['rhythmic'].length != 0) {
//         data.add(sortedTests[i]['data']['rhythmic'].length);
//       } else {
//         data.add(0);
//       }
//
//       labels.add('Building');
//       if (sortedTests[i]['data']['building'] != null ||
//           sortedTests[i]['data']['building'].length != 0) {
//         data.add(sortedTests[i]['data']['building'].length);
//       } else {
//         data.add(0);
//       }
//
//       for (int i = 0; i < labels.length; i++) {
//         combined.add([labels[i], data[i]]);
//       }
//     } else if (sortedTests[i]['projType'] ==
//         'Nature Prevalence') // ** NATURE PREVALENCE DATA
//     {
//       continue; // TODO: Nature Prevalence
//     } else if (sortedTests[i]['projType'] ==
//         'Spatial Boundaries') // ** SPATIAL BOUNDARIES DATA
//     {
//       // TODO: I did not get any data for the test I was working with
//       continue; //Temporary for my testing purposes
//     } else if (sortedTests[i]['projType'] ==
//         'Acoustic Profile') // ** ACOUSTIC PROFILE DATA
//     {
//       // This can honestly get refined a lot further but its work in progress
//       //continue;
//       labels.add('Traffic');
//       labels.add('Wind');
//       labels.add('people');
//       labels.add('animals');
//       labels.add('water');
//       labels.add('music');
//       labels.add('other');
//
//       num trafDec = 0;
//       num windDec = 0;
//       num peopDec = 0;
//       num othDec = 0;
//       num decibal_val = 0;
//       num animDec = 0;
//       num waterNum = 0;
//       num musicNum = 0;
//
//       for (int subtests = 0;
//           subtests = sortedTests[i]["data"]["dataPoints"].length;
//           subtests++) {
//         String soundType = sortedTests[i]["data"]["dataPoints"][subtests]
//             ["measurements"][0]["soundTypes"][1]; // Get Sound Type
//
//         decibal_val += sortedTests[i]["data"]["dataPoints"][subtests]
//             ["measurements"][1]["decibels"]; // Gets Decibel
//         if (soundType == 'traffic') {
//           trafDec += decibal_val;
//         } else if (soundType == 'wind') {
//           windDec += decibal_val;
//         } else if (soundType == 'people') {
//           peopDec += decibal_val;
//         } else if (soundType == 'animals') {
//           animDec += decibal_val;
//         } else if (soundType == 'people') {
//           peopDec += decibal_val;
//         } else if (soundType == 'water') {
//           waterNum += decibal_val;
//         } else if (soundType == 'music') {
//           musicNum += decibal_val;
//         } else if (soundType == 'other') {
//           othDec += decibal_val;
//         }
//       }
//
//       for (int i = 0; i < labels.length; i++) {
//         combined.add([labels[i], data[i]]);
//       }
//     }
//
// // Loop through sorted tests and add a page for each test
//     for (int i = 0; i < sortedTests.length; i++) {
//       document.addPage(
//         pw.Page(
//           pageFormat: pageFormat,
//           theme: theme,
//           build: (context) {
//             return TestPdfPage(test: sortedTests[i]);
//           },
//         ),
//       );
//     }
//   }
  return document.save();
} // End of generateReport()

// Function to generate all the charts
pw.Widget _generateBarChart(LightingProfileData data) {
  // Process data
  Map<LightType, int> dataMap = {
    LightType.rhythmic: 0,
    LightType.building: 0,
    LightType.task: 0,
  };
  int count = 0;
  for (Light light in data.lights) {
    count = dataMap[light.lightType] ?? 0;
    dataMap[light.lightType] = count + 1;
    print(dataMap[light.lightType]);
  }
  List dataSet = List.of(dataMap.values);
  // Top bar chart
  return pw.Chart(
    left: pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(right: 5),
      child: pw.Transform.rotateBox(
        angle: pi / 2,
        child: pw.Text('Amount'),
      ),
    ),
    grid: pw.CartesianGrid(
      xAxis: pw.FixedAxis.fromStrings(
        ["rhythmic", "task", "building"],
        marginStart: 30,
        marginEnd: 30,
        ticks: true,
      ),
      yAxis: pw.FixedAxis(
        [0, 5, 10, 15, 20, 25, 30],
        divisions: true,
      ),
    ),
    datasets: [
      pw.BarDataSet(
        color: PdfColors.blue100,
        width: 15,
        borderColor: PdfColors.cyan,
        data: List<pw.PointChartValue>.generate(
          dataSet.length,
          (i) {
            print(dataSet[i]);
            final v = dataSet[i] as num;
            return pw.PointChartValue(i.toDouble(), v.toDouble());
          },
        ),
      ),
    ],
  );
}

class TestPdfPage extends pw.StatelessWidget {
  TestPdfPage({required this.test, this.baseColor})
      : scheduledTime = DateFormat.yMMMd().format(test.scheduledTime.toDate());

  final Test test;
  final PdfColor? baseColor;
  // Fixes the Datetime for the header
  final String scheduledTime;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        pw.Text(
          '${test.collectionID} - $scheduledTime',
          style: pw.TextStyle(
            color: baseColor ?? PdfColors.black,
            fontSize: 20,
          ),
        ),
        pw.Divider(thickness: 4),
        // Add chart or other content dynamically
        pw.Column(
          children: [
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.SizedBox(
                    child: _generateBarChart(test.data
                        as LightingProfileData), // Generate the chart dynamically
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
