import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p2b/db_schema_classes.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
    print(projectData.tests);
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
          IdentifyingAccessData currentLPData =
              (currentTest as IdentifyingAccessTest).data;
        }
      case 'nature_prevalence_tests':
        {
          NaturePrevalenceData currentLPData =
              (currentTest as NaturePrevalenceTest).data;
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
          AcousticProfileData currentLPData =
              (currentTest as AcousticProfileTest).data;
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

  return document.save();
} // End of generateReport()

// Function to generate the chart for Points (bar charts)
pw.Widget _generateBarChart(Map<String, int> dataMap) {
  List<int> sortedValues = (dataMap.values).toList();
  sortedValues.sort((a, b) => a.compareTo(b));
  int increment = (sortedValues.lastOrNull ?? 0) ~/ 5;
  if (increment < 3) increment = 1;
  if (dataMap.isEmpty || increment <= 0) return pw.Container();
  // Process data
  List<int> dataSet = (dataMap.values).toList();
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
        List.of(dataMap.keys),
        marginStart: 30,
        marginEnd: 30,
        ticks: true,
      ),
      yAxis: pw.FixedAxis(
        [
          0,
          increment,
          increment * 2,
          increment * 3,
          increment * 4,
          increment * 5,
          increment * 6,
          increment * 7,
        ],
        divisions: true,
      ),
    ),
    datasets: [
      pw.BarDataSet(
        color: PdfColors.blue100,
        width: (1 / dataMap.keys.length) * 110,
        borderColor: PdfColors.cyan,
        data: List<pw.PointChartValue>.generate(
          dataSet.length,
          (i) {
            return pw.PointChartValue(i.toDouble(), dataSet[i].toDouble());
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
  String? displayName;

  Map<String, int> processTestPointsForGraph(Test test) {
    Map<String, int> processedData = {};
    switch (test.collectionID) {
      case 'lighting_profile_tests':
        {
          LightingProfileData data = (test as LightingProfileTest).data;
          displayName = LightingProfileTest.displayName;
          Map<String, int> dataMap = {
            LightType.rhythmic.name: 0,
            LightType.building.name: 0,
            LightType.task.name: 0,
          };
          int count = 0;
          for (Light light in data.lights) {
            count = dataMap[light.lightType.name] ?? 0;
            dataMap[light.lightType.name] = count + 1;
          }
          processedData = dataMap;
        }
      case 'absence_of_order_tests':
        {
          AbsenceOfOrderData data = (test as AbsenceOfOrderTest).data;
          displayName = AbsenceOfOrderTest.displayName;
          Map<String, int> dataMap = {
            "maintenanceType": data.maintenanceList.length,
            "behaviorType": data.behaviorList.length,
          };
          processedData = dataMap;
        }
      case 'nature_prevalence_tests':
        {
          NaturePrevalenceData data = (test as NaturePrevalenceTest).data;
          displayName = NaturePrevalenceTest.displayName;
          Map<String, int> dataMap = {
            AnimalType.cat.name: 0,
            AnimalType.dog.name: 0,
            AnimalType.squirrel.name: 0,
            AnimalType.bird.name: 0,
            AnimalType.rabbit.name: 0,
            AnimalType.turtle.name: 0,
            AnimalType.duck.name: 0,
            AnimalType.other.name: 0,
          };
          for (Animal animal in data.animals) {
            dataMap[animal.animalType.name] =
                dataMap[animal.animalType.name]! + 1;
          }
          processedData = dataMap;
        }
      case 'people_in_place_tests':
        {
          PeopleInPlaceData data = (test as PeopleInPlaceTest).data;
          displayName = PeopleInMotionTest.displayName;
          Map<String, int> dataMap = {
            PostureType.layingDown.name: 0,
            PostureType.sitting.name: 0,
            PostureType.squatting.name: 0,
            PostureType.standing.name: 0,
          };
          for (final PersonInPlace person in data.persons) {
            dataMap[person.posture.name] = dataMap[person.posture.name]! + 1;
          }
          processedData = dataMap;
        }
      case 'acoustic_profile_tests':
        {
          AcousticProfileData data = (test as AcousticProfileTest).data;
          displayName = AcousticProfileTest.displayName;
          List<String> standingPointNames = [];
          List<double> standingPointAvg = [];
          Map<String, int> dataMap = {};
          double sum = 0;

          for (final dataPoint in test.data.dataPoints) {
            standingPointNames.add(dataPoint.standingPoint.title);
            for (final measurement in dataPoint.measurements) {
              sum += measurement.decibels;
            }
            standingPointAvg.add(sum / test.intervalCount);
            sum = 0;
          }

          print(standingPointNames);
          print(standingPointAvg);
          processedData = dataMap;
        }
    }
    return processedData;
  }

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        pw.Text(
          // TODO: add switch case function for retrieving test displayName
          '${displayName ?? ''} - $scheduledTime',
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
                    height: 200,
                    width: 200,
                    child: _generateBarChart(processTestPointsForGraph(
                        test)), // Generate the chart dynamically
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
