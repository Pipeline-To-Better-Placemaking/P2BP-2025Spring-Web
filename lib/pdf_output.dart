import 'dart:typed_data';
import 'package:flutter/material.dart';
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
Future<Uint8List> generateReport(PdfPageFormat pageFormat, Project projectData) async 
{

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
                  child: pw.Text('Contributors:\n INSERT CONTRIBUTORS LOOP HERE\n\nSponsor: UCF Professor Herbert Tommy James', textAlign: pw.TextAlign.center), 
                ),
              ],
            ),
          ],
        );
      },
    ),
  );



  // ** Bucket Sorting of tests **
  // Variables used to sort all the tests, so similar tests are shown together
  List secCut = [], absOfOrder =[], identAccess = [], peopInMot = [] ,peopInPlace = [], lightProf = [], natPrev = [], spatBound = [], acouProf = [];
  List sortedTests = [];

  for (var testIterator in projectData.testRefs) 
  {
    // Pulls data for this individual test
    DocumentSnapshot testDoc = await testIterator.get(); 
    Map<String, dynamic> test = testDoc.data() as Map<String, dynamic>;

    // Fixes the Datetime for the header
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(test["scheduledTime"].millisecondsSinceEpoch);
    DateTime estDateTime = dateTime.toLocal();
    test['scheduledTime'] = estDateTime;

    // If a test isn't complete, skip it
    if (!test['isComplete']) continue;

    // Logic to combine all the tests into an organized, singular list we can work with
    // Useful so all test types are clustered together
    if (testIterator.path.contains('section_cutter'))
    {
      test['projType'] = 'Section Cutter'; 
      secCut.add(test);

    } else 
    if (testIterator.path.contains('absence_of_order'))
    {
      test['projType'] = 'Absence Of Order'; 
      absOfOrder.add(test);

    } else
    if (testIterator.path.contains('identifying_access'))
    {
      test['projType'] = 'Identifying Access'; 
      identAccess.add(test);

    } else
    if (testIterator.path.contains('people_in_motion'))
    {
      test['projType'] = 'People In Motion'; 
      peopInMot.add(test);

    } else 
    if (testIterator.path.contains('people_in_place'))
    {
      test['projType'] = 'People In Place'; 
      peopInPlace.add(test);

    } else 
    if (testIterator.path.contains('lighting_profile'))
    {
      test['projType'] = 'Lighting Profile';
      lightProf.add(test);
    } else 
    if (testIterator.path.contains('nature_prevalence'))
    {
      test['projType'] = 'Nature Prevalence';
      natPrev.add(test);
    }
      if (testIterator.path.contains('spatial_boundaries'))
    {
      test['projType'] = 'Spatial Boundaries';
      spatBound.add(test);
    }
    if (testIterator.path.contains('acoustic_profile'))                                                         
    {
      test['projType'] = 'Acoustic Profile';
      acouProf.add(test);
    }
  }
  sortedTests.addAll(peopInMot + peopInPlace + spatBound + lightProf + natPrev + absOfOrder + acouProf + identAccess + secCut);
  // ** End Bucket Sorting, now allocated into a singular large 'bucket'

    
  // ** Gathers the data from each test
  for (int testNum = 0; testNum < sortedTests.length; testNum++)
  {
    List data = [], labels = [];
    List<List<dynamic>> combined = [];

   
    if (sortedTests[testNum]['projType'] == 'Section Cutter') 
    {
      continue; // TODO: Section Cutter
      // note: Might need Dom's help with this one... Picture rendering
    } else
    if (sortedTests[testNum]['projType'] == 'Absence Of Order') 
    {
      continue; // TODO: Absence of Order
    } else 
    if (sortedTests[testNum]['projType'] == 'People In Motion') 
    {
      continue; // TODO: People In Motion
    } else 
    if (sortedTests[testNum]['projType'] == 'People In Place') 
    {
      continue; // TODO: People In Place
    } else 
    if (sortedTests[testNum]['projType'] == 'Lighting Profile')                         // ** LIGHTING PROFILE DATA
    {
      continue; // Done for testing purposes
      labels.add('Task');
      if (sortedTests[testNum]['data']['task'] != null || sortedTests[testNum]['data']['task'].length != 0)
      {
        data.add(sortedTests[testNum]['data']['task'].length);
      } 
      else {data.add(0);}

      labels.add('Rythmic');
      if (sortedTests[testNum]['data']['rhythmic'] != null|| sortedTests[testNum]['data']['rhythmic'].length != 0) 
      {
        data.add(sortedTests[testNum]['data']['rhythmic'].length);
      } else {data.add(0);}

      labels.add('Building');
      if (sortedTests[testNum]['data']['building'] != null|| sortedTests[testNum]['data']['building'].length != 0) 
      {
        data.add(sortedTests[testNum]['data']['building'].length);
      } else {data.add(0);}

      for (int i = 0; i < labels.length; i++) {
        combined.add([labels[i], data[i]]);
      }                                                                               // ** END LIGHTING PROFILE DATA

    } else 
    if (sortedTests[testNum]['projType'] == 'Nature Prevalence') 
    {
      continue; // TODO: Nature Prevalence
    } else 
    if (sortedTests[testNum]['projType'] == 'Spatial Boundaries') // TODO: I did not get any data for the test I was working with
    {
      continue; //Temporary for my testing purposes
    } else 
    if (sortedTests[testNum]['projType'] == 'Acoustic Profile') 
    {
      continue;// TODO: Acoustic Profile
    }



// Loop through sorted tests and add a page for each test
for (int i = 0; i < sortedTests.length; i++) {
  document.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: theme,
      build: (context) {
        return pw.Column(
          children: [
            pw.Text(
              '${sortedTests[i]['projType']} - ${sortedTests[i]['scheduledTime']}',
              style: const pw.TextStyle(
                color: baseColor,
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
                        // child: _generateChart(sortedTests[i]), // Generate the chart dynamically
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

  }
  return document.save();
} // End of generateReport()

// Function to generate all the charts
pw.Widget _generateChart(List<dynamic> data) {

          List<pw.PointChartValue> chartValues = List.generate(data.length, (index) {
            return pw.PointChartValue(index.toDouble(), data[index].toDouble());
          });

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
        width: 15,
        data: chartValues,
      ),
    ],
  );
}

