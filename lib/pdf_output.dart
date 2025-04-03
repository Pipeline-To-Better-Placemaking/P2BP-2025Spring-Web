import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:p2b/db_schema_classes.dart';
import 'package:p2b/firestore_functions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'google_maps_functions.dart';
import 'maps_image_generation.dart';

// Create a storage reference from app
final storageRef = FirebaseStorage.instance.ref();

// Allows user to see the pdf in browser so they know what they are getting
class PdfReportPage extends StatelessWidget {
  final Project activeProject;

  const PdfReportPage({super.key, required this.activeProject});

  // generate the PDF
  Future<Uint8List> _generatePdf() async {
    return generateReport(PdfPageFormat.a4, activeProject);
  }

  // TODO: Create a GoogleMap widget in a SizedBox of certain size. Takes in data.
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
            print('$e');
            print('Stacktrace: $stacktrace');
            return Center(child: Text('Error generating PDF'));
          }
        },
      ),
    );
  }
}

Future<List<PDFData>> retrieveAllPDFInfo(
    List<Test> tests, Polygon projectPolygon) async {
  List<PDFData> pdfDataList = [];
  PDFData? pdfData;
  for (final Test test in tests) {
    pdfData = await retrievePDFInfo(test, projectPolygon);
    if (pdfData != null) {
      pdfDataList.add(pdfData);
    }
  }
  return pdfDataList;
}

Future<PDFData?> retrievePDFInfo(Test test, Polygon projectPolygon) async {
  PDFData? pdfPage;
  Uint8List mapImage;
  print(test.collectionID);
  switch (test.collectionID) {
    case 'lighting_profile_tests':
      {
        PDFData lpData;
        Set<Marker> lpMarkers = {};
        LightingProfileData data = (test as LightingProfileTest).data;
        Map<Enum, int> dataMap = {
          LightType.rhythmic: 0,
          LightType.building: 0,
          LightType.task: 0,
        };
        int count = 0;
        for (Light light in data.lights) {
          lpMarkers.add(light.marker);
          count = dataMap[light.lightType] ?? 0;
          dataMap[light.lightType] = count + 1;
        }
        // mapImage = await generateMapImage(
        //   projectPolygon: projectPolygon,
        //   markers: lpMarkers,
        // );
        // print(mapImage);
        lpData = PDFData(
            testTitle: test.title,
            barGraphData: [
              BarGraphData(
                  color: PdfColors.amber,
                  dataMap: dataMap,
                  graphTitle: 'Light Types')
            ],
            pieGraphData: [],
            displayName: LightingProfileTest.displayName,
            date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
            time: DateFormat.jmv().format(test.scheduledTime.toDate()));
        pdfPage = (lpData);
      }
    case 'absence_of_order_tests':
      {
        PDFData aoData;
        AbsenceOfOrderData data = (test as AbsenceOfOrderTest).data;
        Map<Enum, int> dataMap = {
          MisconductType.maintenance: data.maintenanceList.length,
          MisconductType.behavior: data.behaviorList.length,
        };
        aoData = PDFData(
            testTitle: test.title,
            barGraphData: [
              BarGraphData(
                  color: PdfColors.orange,
                  dataMap: dataMap,
                  graphTitle: 'Misconduct Type')
            ],
            pieGraphData: [],
            displayName: AbsenceOfOrderTest.displayName,
            date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
            time: DateFormat.jmv().format(test.scheduledTime.toDate()));
        pdfPage = (aoData);
      }
    case 'nature_prevalence_tests':
      {
        PDFData npData;
        NaturePrevalenceData data = (test as NaturePrevalenceTest).data;
        Map<Enum, double> polygonAreas = {
          NatureType.vegetation: 0,
          NatureType.waterBody: 0,
        };
        Map<Enum, int> dataMap = {
          AnimalType.cat: 0,
          AnimalType.dog: 0,
          AnimalType.squirrel: 0,
          AnimalType.bird: 0,
          AnimalType.rabbit: 0,
          AnimalType.turtle: 0,
          AnimalType.duck: 0,
          AnimalType.other: 0,
        };

        Map<Enum, int> domesticWild = {
          AnimalDesignation.domesticated: 0,
          AnimalDesignation.wild: 0,
          AnimalDesignation.other: 0,
        };

        for (final Animal animal in data.animals) {
          dataMap[animal.animalType] = dataMap[animal.animalType]! + 1;
          domesticWild[animal.animalType.designation] =
              domesticWild[animal.animalType.designation]! + 1;
        }
        for (final Vegetation vegetation in data.vegetation) {
          polygonAreas[NatureType.vegetation] =
              polygonAreas[NatureType.vegetation]! + vegetation.polygonArea;
        }
        for (final WaterBody waterBody in data.waterBodies) {
          polygonAreas[NatureType.waterBody] =
              polygonAreas[NatureType.waterBody]! + waterBody.polygonArea;
        }
        npData = PDFData(
            testTitle: test.title,
            barGraphData: [
              BarGraphData(
                  color: PdfColors.brown,
                  dataMap: dataMap,
                  graphTitle: 'Animal Types'),
              BarGraphData(
                  color: PdfColors.purple,
                  dataMap: domesticWild,
                  graphTitle: 'Domestic vs. Wild')
            ],
            pieGraphData: [
              PieGraphData(
                  colorList: [PdfColors.green, PdfColors.blue],
                  dataMap: polygonAreas,
                  graphTitle: 'Vegetation vs. Water')
            ],
            displayName: NaturePrevalenceTest.displayName,
            date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
            time: DateFormat.jmv().format(test.scheduledTime.toDate()));
        pdfPage = (npData);
      }
    case 'identifying_access_tests':
      {
        PDFData iaData;
        IdentifyingAccessData data = (test as IdentifyingAccessTest).data;
        Map<Enum, double> polylineLengths = {
          AccessType.taxiAndRideShare: 0,
          AccessType.parking: 0,
          AccessType.transportStation: 0,
        };
        for (final TaxiAndRideShare taxiShare in data.taxisAndRideShares) {
          polylineLengths[AccessType.taxiAndRideShare] =
              polylineLengths[AccessType.taxiAndRideShare]! +
                  taxiShare.polylineLength;
        }
        for (final Parking parking in data.parkingStructures) {
          polylineLengths[AccessType.parking] =
              polylineLengths[AccessType.parking]! + parking.polylineLength;
        }
        for (final TransportStation transportStation
            in data.transportStations) {
          polylineLengths[AccessType.transportStation] =
              polylineLengths[AccessType.transportStation]! +
                  transportStation.polylineLength;
        }
        iaData = PDFData(
          testTitle: test.title,
          barGraphData: [],
          pieGraphData: [
            PieGraphData(
                colorList: [PdfColors.yellow, PdfColors.grey, PdfColors.green],
                dataMap: polylineLengths,
                graphTitle: 'Path Lengths for Each Transportation Type')
          ],
          displayName: IdentifyingAccessTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
        );
        pdfPage = (iaData);
      }
    case 'people_in_place_tests':
      {
        PDFData ppData;
        PeopleInPlaceData data = (test as PeopleInPlaceTest).data;
        Map<Enum, int> dataMap = {
          PostureType.layingDown: 0,
          PostureType.sitting: 0,
          PostureType.squatting: 0,
          PostureType.standing: 0,
        };
        for (final PersonInPlace person in data.persons) {
          dataMap[person.posture] = dataMap[person.posture]! + 1;
        }
        ppData = PDFData(
          testTitle: test.title,
          barGraphData: [
            BarGraphData(
                color: PdfColors.green,
                dataMap: dataMap,
                graphTitle: 'Posture Types')
          ],
          pieGraphData: [],
          displayName: PeopleInPlaceTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
        );
        pdfPage = (ppData);
      }
    case 'people_in_motion_tests':
      {
        PDFData pmData;
        PeopleInMotionData data = (test as PeopleInMotionTest).data;
        Map<Enum, int> dataMap = {
          ActivityTypeInMotion.activityOnWheels: 0,
          ActivityTypeInMotion.handicapAssistedWheels: 0,
          ActivityTypeInMotion.walking: 0,
          ActivityTypeInMotion.swimming: 0,
          ActivityTypeInMotion.running: 0,
        };

        for (final PersonInMotion person in data.persons) {
          dataMap[person.activity] = dataMap[person.activity]! + 1;
        }

        pmData = PDFData(
          testTitle: test.title,
          barGraphData: [
            BarGraphData(
                color: PdfColors.orange,
                dataMap: dataMap,
                graphTitle: 'Activity Types')
          ],
          pieGraphData: [],
          displayName: PeopleInMotionTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
        );
        pdfPage = (pmData);
      }
    case 'acoustic_profile_tests':
      {
        // AcousticProfileData data = (test as AcousticProfileTest).data;
        // PDFData apData;
        // String standingPointTitle = '';
        // Map<Enum, double> dataMap = {};
        // double sum = 0;
        //
        // for (final dataPoint in test.data.dataPoints) {
        //   standingPointTitle = dataPoint.standingPoint.title;
        //   for (final measurement in dataPoint.measurements) {
        //     sum += measurement.decibels;
        //   }
        //   dataMap.putIfAbsent(
        //       standingPointTitle, () => (sum / test.intervalCount));
        //   sum = 0;
        // }
        // // TODO: bar graph but is a double?
        // apData = PDFData(
        //   barGraphData: [],
        //   pieGraphData: [
        //     PieGraphData(
        //         colorList: [PdfColors.cyan, PdfColors.deepOrange],
        //         dataMap: dataMap)
        //   ],
        //   displayName: AcousticProfileTest.displayName,
        //   date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
        //   time: DateFormat.jmv().format(test.scheduledTime.toDate()),
        // );
        // pdfPage = (apData);
      }
    case 'spatial_boundaries_tests':
      {
        PDFData sbData;
        SpatialBoundariesData data = (test as SpatialBoundariesTest).data;
        Map<Enum, double> shelterArea = {
          ShelterBoundaryType.canopy: 0,
          ShelterBoundaryType.constructed: 0,
          ShelterBoundaryType.furniture: 0,
          ShelterBoundaryType.temporary: 0,
          ShelterBoundaryType.tree: 0,
        };
        Map<Enum, double> materialArea = {
          MaterialBoundaryType.concrete: 0,
          MaterialBoundaryType.decking: 0,
          MaterialBoundaryType.natural: 0,
          MaterialBoundaryType.pavers: 0,
          MaterialBoundaryType.tile: 0,
        };
        Map<Enum, double> constructedLength = {
          ConstructedBoundaryType.buildingWall: 0,
          ConstructedBoundaryType.curb: 0,
          ConstructedBoundaryType.fence: 0,
          ConstructedBoundaryType.partialWall: 0,
          ConstructedBoundaryType.planter: 0,
        };
        Map<Enum, int> materialShelter = {
          BoundaryType.material: 0,
          BoundaryType.shelter: 0,
        };

        for (final MaterialBoundary material in data.material) {
          materialArea[material.materialType] =
              materialArea[material.materialType]! + material.polygonArea;
          materialShelter[BoundaryType.material] =
              materialShelter[BoundaryType.material]! + 1;
        }

        for (final ShelterBoundary shelter in data.shelter) {
          shelterArea[shelter.shelterType] =
              shelterArea[shelter.shelterType]! + shelter.polygonArea;
          materialShelter[BoundaryType.shelter] =
              materialShelter[BoundaryType.shelter]! + 1;
        }

        for (final ConstructedBoundary constructed in data.constructed) {
          constructedLength[constructed.constructedType] =
              constructedLength[constructed.constructedType]! +
                  constructed.polylineLength;
        }

        sbData = PDFData(
            testTitle: test.title,
            barGraphData: [
              BarGraphData(
                  color: PdfColors.brown,
                  dataMap: materialShelter,
                  graphTitle: 'Material vs. Shelter')
            ],
            pieGraphData: [
              PieGraphData(
                  dataMap: materialArea, graphTitle: 'Area of Material Types'),
              PieGraphData(
                  dataMap: shelterArea, graphTitle: 'Area of Shelter Types'),
              PieGraphData(
                  dataMap: constructedLength,
                  graphTitle: 'Length of Constructed Types'),
            ],
            displayName: SpatialBoundariesTest.displayName,
            date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
            time: DateFormat.jmv().format(test.scheduledTime.toDate()));
        pdfPage = (sbData);
      }
    case 'section_cutter_tests':
      {
        PDFData scData;
        Section data = (test as SectionCutterTest).data;

        scData = PDFData(
          testTitle: test.title,
          barGraphData: [],
          pieGraphData: [],
          displayName: SectionCutterTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
          sectionImageLink: data.sectionLink,
        );
        pdfPage = (scData);
      }
  }
  return pdfPage;
}

// PDF Generation Logic
Future<Uint8List> generateReport(
    PdfPageFormat pageFormat, Project projectData) async {
  List<Test> rawTests = [];
  PDFData? pdfData;
  // Load images data before building the PDF, but was not implemented
  // final imageData = await _loadImage(data.mapImagePath);
  const baseColor = PdfColors.black;

  // Actually launches the pdf builder
  final document = pw.Document();
  final Polygon projectPolygon;

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
                      'Contributors:\n \n\nSponsor: UCF Professor Herbert Tommy James',
                      textAlign: pw.TextAlign.center),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  // Get all the test information sorted into the correct representation.
  if (projectData.tests == null) {
    await projectData.loadAllTestData();
  }
  projectPolygon = getProjectPolygon(projectData.polygonPoints);
  rawTests = projectData.tests ?? [];
  for (Test currentTest in rawTests) {
    // If a test isn't complete, skip it
    if (!currentTest.isComplete) continue;
    pdfData = await retrievePDFInfo(currentTest, projectPolygon);

    if (pdfData == null) continue;
    if (pdfData.sectionImageLink != null) await pdfData.loadImage();
    // TODO: Add one page for an explainer for each test type.
    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        theme: theme,
        build: (context) {
          return <pw.Widget>[TestPdfPage(testPDFData: pdfData!)];
        },
      ),
    );
  }

  return document.save();
} // End of generateReport()

// Function to generate the chart for Points (bar charts)
pw.Widget _generateBarGraph(BarGraphData barGraphData) {
  List<int> sortedValues = barGraphData.values;
  sortedValues.sort((a, b) => a.compareTo(b));
  int increment = (sortedValues.lastOrNull ?? 0) ~/ 5;
  if (increment < 3) increment = 1;
  if (sortedValues.isEmpty || increment <= 0) return pw.Container();
  // Process data
  List<int> dataSet = barGraphData.values;
  // Top bar chart
  return pw.Chart(
    left: pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(right: 5),
      child: pw.Transform.rotateBox(
        angle: pi / 2,
        // TODO: dynamic label?
        child: pw.Text('Amount'),
      ),
    ),
    grid: pw.CartesianGrid(
      xAxis: pw.FixedAxis.fromStrings(
        barGraphData.labels,
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
        color: barGraphData.color,
        width: (1 / barGraphData.labels.length) * 110,
        borderColor: barGraphData.color,
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

pw.Widget _generatePieGraph(PieGraphData pieGraphData) {
  return pw.Column(
    children: [
      pw.Flexible(
        child: pw.Chart(
          title: pw.Text(
            pieGraphData.graphTitle,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(
              color: PdfColors.black,
              fontSize: 20,
            ),
          ),
          grid: pw.PieGrid(),
          datasets:
              List<pw.Dataset>.generate(pieGraphData.values.length, (index) {
            final double total = pieGraphData.values.sum;
            final dataLabels = pieGraphData.labels;
            final data = dataLabels[index];
            final PdfColor color =
                pieGraphData.colorList[index % pieGraphData.colorList.length];
            final value = (pieGraphData.values[index]).toDouble();
            final pct = (value / total * 100).round();
            return pw.PieDataSet(
              legend: '$data\n$pct%',
              value: value,
              color: color,
              legendStyle: const pw.TextStyle(fontSize: 10),
            );
          }),
        ),
      ),
    ],
  );
}

class TestPdfPage extends pw.StatelessWidget {
  TestPdfPage({required this.testPDFData, this.baseColor});

  final PdfColor? baseColor;
  // Fixes the Datetime for the header
  final PDFData testPDFData;

  List<pw.Padding> getPDFDataGraphs(PDFData testData) {
    List<pw.Padding> graphs = [];
    List<pw.Widget> pieGraphs = [];
    for (final BarGraphData barData in testData.barGraphData) {
      graphs.add(
        pw.Padding(
          padding: pw.EdgeInsets.all(5.0),
          child: pw.SizedBox(
            height: 200,
            child: pw.Expanded(child: _generateBarGraph(barData)),
          ),
        ),
      );
    }

    for (final PieGraphData pieData in testData.pieGraphData) {
      pieGraphs.add(pw.Flexible(child: _generatePieGraph(pieData)));
      if (pieGraphs.length % 2 == 0) {
        graphs.add(
          pw.Padding(
            padding: pw.EdgeInsets.all(5.0),
            child: pw.SizedBox(
              height: 200,
              child: pw.Row(
                children: pieGraphs,
              ),
            ),
          ),
        );
        pieGraphs = [];
      }
    }
    if (pieGraphs.length % 2 != 0) {
      graphs.add(
        pw.Padding(
          padding: pw.EdgeInsets.all(5.0),
          child: pw.SizedBox(
            height: 200,
            child: pw.Row(
              children: pieGraphs,
            ),
          ),
        ),
      );
    }

    return graphs;
  }

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Text(
            testPDFData.displayName,
            style: pw.TextStyle(
              color: baseColor ?? PdfColors.black,
              fontSize: 12,
            ),
          ),
        ),
        pw.Text(
          testPDFData.testTitle,
          style: pw.TextStyle(
            color: baseColor ?? PdfColors.black,
            fontSize: 20,
          ),
        ),
        pw.Text(
          '${testPDFData.date} at ${testPDFData.time}',
          style: pw.TextStyle(
            color: baseColor ?? PdfColors.black,
            fontSize: 20,
          ),
        ),

        pw.Divider(thickness: 3),
        // Add chart or other content dynamically
        if (testPDFData.sectionImageLink != null &&
            testPDFData.sectionImage != null)
          pw.Column(
            children: <pw.Widget>[
              pw.Text("Section Image:", style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 5),
              pw.SizedBox(
                height: 200,
                width: 200,
                child: pw.Image(
                  pw.MemoryImage(testPDFData.sectionImage!),
                ),
              ),
            ],
          ),
        if (testPDFData.mapImage != null)
          pw.Image(pw.MemoryImage(testPDFData.mapImage!)),
        pw.Column(
          children: getPDFDataGraphs(testPDFData),
        ),
      ],
    );
  }
}

class PDFData {
  final List<BarGraphData> barGraphData;
  final List<PieGraphData> pieGraphData;
  final String displayName;
  final String date;
  final String time;
  final String testTitle;

  /// If specifying a section image, use loadImage() to load the image before
  /// using it.
  final String? sectionImageLink;
  late final Uint8List? sectionImage;
  final Uint8List? mapImage;

  PDFData({
    required this.barGraphData,
    required this.pieGraphData,
    required this.displayName,
    required this.date,
    required this.time,
    required this.testTitle,
    this.mapImage,
    this.sectionImageLink,
  });

  Future<void> loadImage() async {
    final Reference firebaseImageRef;
    const tenMegabytes = 10240 * 10240;
    try {
      if (sectionImageLink != null) {
        firebaseImageRef = storageRef.child(sectionImageLink!);
        sectionImage = (await firebaseImageRef.getData(tenMegabytes));
      }
    } catch (e, stacktrace) {
      print(e);
      print("Stacktrace: $stacktrace");
    }
  }
}

class BarGraphData {
  final PdfColor color;
  final Map<Enum, int> dataMap;
  List<String> labels = [];
  late final List<int> values;
  final String graphTitle;

  BarGraphData(
      {List<String>? customLabels,
      required this.color,
      required this.dataMap,
      required this.graphTitle}) {
    // If no supplied customLabels, or customLabels are not correct length, set
    // them according to the enum names.
    if (customLabels == null || customLabels.length != dataMap.values.length) {
      customLabels = [];
      for (Enum key in dataMap.keys) {
        customLabels.add(key.name);
      }
    }
    labels = customLabels;
    values = dataMap.values.toList();
  }
}

class PieGraphData {
  final List<PdfColor> colorList;
  final Map<Enum, double> dataMap;
  List<String> labels = [];
  late final List<double> values;
  final String graphTitle;

  PieGraphData(
      {List<String>? customLabels,
      this.colorList = defaultChartColors,
      required this.dataMap,
      required this.graphTitle}) {
    // If no supplied customLabels, or customLabels are not correct length, set
    // them according to the enum names.
    if (customLabels == null || customLabels.length != dataMap.values.length) {
      customLabels = [];
      for (Enum key in dataMap.keys) {
        customLabels.add(key.name);
      }
    }
    labels = customLabels;
    values = dataMap.values.toList();
  }
}

const defaultChartColors = [
  PdfColors.blue300,
  PdfColors.green300,
  PdfColors.amber300,
  PdfColors.pink300,
  PdfColors.cyan300,
  PdfColors.purple300,
  PdfColors.lime300,
];