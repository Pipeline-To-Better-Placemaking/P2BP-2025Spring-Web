import 'dart:convert';
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
import 'package:web/web.dart' as web;

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
  switch (test.collectionID) {
    case 'lighting_profile_tests':
      {
        PDFData lpData;
        Set<Marker> lpMarkers = {};
        LightingProfileData data = (test as LightingProfileTest).data;
        Map<String, double> dataMap = {
          LightType.rhythmic.name: 0,
          LightType.building.name: 0,
          LightType.task.name: 0,
        };
        double count = 0;
        for (Light light in data.lights) {
          lpMarkers.add(light.marker);
          count = dataMap[light.lightType.name] ?? 0;
          dataMap[light.lightType.name] = count + 1;
        }
        lpData = PDFData(
            testTitle: test.title,
            barGraphData: [
              BarGraphData(
                color: PdfColors.amber,
                dataMap: dataMap,
                graphTitle: 'Light Types',
              )
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
        Map<String, double> dataMap = {
          MisconductType.maintenance.name:
              data.maintenanceList.length.toDouble(),
          MisconductType.behavior.name: data.behaviorList.length.toDouble(),
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
        Map<String, double> polygonAreas = {
          NatureType.vegetation.name: 0,
          NatureType.waterBody.name: 0,
        };
        Map<String, double> dataMap = {
          AnimalType.cat.name: 0,
          AnimalType.dog.name: 0,
          AnimalType.squirrel.name: 0,
          AnimalType.bird.name: 0,
          AnimalType.rabbit.name: 0,
          AnimalType.turtle.name: 0,
          AnimalType.duck.name: 0,
          AnimalType.other.name: 0,
        };

        Map<String, double> domesticWild = {
          AnimalDesignation.domesticated.name: 0,
          AnimalDesignation.wild.name: 0,
          AnimalDesignation.other.name: 0,
        };

        for (final Animal animal in data.animals) {
          dataMap[animal.animalType.name] =
              dataMap[animal.animalType.name]! + 1;
          domesticWild[animal.animalType.designation.name] =
              domesticWild[animal.animalType.designation.name]! + 1;
        }
        for (final Vegetation vegetation in data.vegetation) {
          polygonAreas[NatureType.vegetation.name] =
              polygonAreas[NatureType.vegetation.name]! +
                  vegetation.polygonArea;
        }
        for (final WaterBody waterBody in data.waterBodies) {
          polygonAreas[NatureType.waterBody.name] =
              polygonAreas[NatureType.waterBody.name]! + waterBody.polygonArea;
        }
        npData = PDFData(
            testTitle: test.title,
            barGraphData: [
              BarGraphData(
                color: PdfColors.brown,
                dataMap: dataMap,
                graphTitle: 'Animal Types',
              ),
              BarGraphData(
                color: PdfColors.purple,
                dataMap: domesticWild,
                graphTitle: 'Domestic vs. Wild',
              ),
              BarGraphData(
                  color: PdfColors.green,
                  dataMap: polygonAreas,
                  graphTitle: 'Vegetation vs. Water',
                  yAxisLabel: 'Area (sq. ft)'),
            ],
            pieGraphData: [],
            displayName: NaturePrevalenceTest.displayName,
            date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
            time: DateFormat.jmv().format(test.scheduledTime.toDate()));
        pdfPage = (npData);
      }
    case 'identifying_access_tests':
      {
        PDFData iaData;
        IdentifyingAccessData data = (test as IdentifyingAccessTest).data;
        Map<String, double> polylineLengths = {
          AccessType.taxiAndRideShare.name: 0,
          AccessType.parking.name: 0,
          AccessType.transportStation.name: 0,
          AccessType.bikeRack.name: 0,
        };
        Map<String, double> spotsMap = {
          AccessType.parking.name: 0,
          AccessType.bikeRack.name: 0,
        };
        for (final TaxiAndRideShare taxiShare in data.taxisAndRideShares) {
          polylineLengths[AccessType.taxiAndRideShare.name] =
              polylineLengths[AccessType.taxiAndRideShare.name]! +
                  taxiShare.polylineLength;
        }
        for (final Parking parking in data.parkingStructures) {
          polylineLengths[AccessType.parking.name] =
              polylineLengths[AccessType.parking.name]! +
                  parking.polylineLength;
          spotsMap[AccessType.parking.name] =
              spotsMap[AccessType.parking.name]! + parking.spots;
        }
        for (final TransportStation transportStation
            in data.transportStations) {
          polylineLengths[AccessType.transportStation.name] =
              polylineLengths[AccessType.transportStation.name]! +
                  transportStation.polylineLength;
        }
        for (final BikeRack bikeRack in data.bikeRacks) {
          polylineLengths[AccessType.bikeRack.name] =
              polylineLengths[AccessType.bikeRack.name]! +
                  bikeRack.polylineLength;
          spotsMap[AccessType.bikeRack.name] =
              spotsMap[AccessType.bikeRack.name]! + bikeRack.spots;
        }
        iaData = PDFData(
          testTitle: test.title,
          barGraphData: [
            BarGraphData(
                color: PdfColors.grey,
                dataMap: polylineLengths,
                graphTitle: 'Path Lengths for Each Transportation Type',
                customLabels: ['Rideshare/Taxi', 'Car', 'Bus/Train', 'Bike'],
                yAxisLabel: 'Length (ft.)'),
            BarGraphData(
              color: PdfColors.black,
              dataMap: spotsMap,
              graphTitle: 'Number of Parking Spots by Vehicle',
              customLabels: ['Bike', 'Car'],
            ),
          ],
          pieGraphData: [],
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
        Map<String, double> dataMap = {
          PostureType.layingDown.name: 0,
          PostureType.sitting.name: 0,
          PostureType.squatting.name: 0,
          PostureType.standing.name: 0,
        };
        for (final PersonInPlace person in data.persons) {
          dataMap[person.posture.name] = dataMap[person.posture.name]! + 1;
        }
        ppData = PDFData(
          testTitle: test.title,
          barGraphData: [
            BarGraphData(
              color: PdfColors.green,
              dataMap: dataMap,
              graphTitle: 'Posture Types',
            )
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
        Map<String, double> dataMap = {
          ActivityTypeInMotion.activityOnWheels.name: 0,
          ActivityTypeInMotion.handicapAssistedWheels.name: 0,
          ActivityTypeInMotion.walking.name: 0,
          ActivityTypeInMotion.swimming.name: 0,
          ActivityTypeInMotion.running.name: 0,
        };

        for (final PersonInMotion person in data.persons) {
          dataMap[person.activity.name] = dataMap[person.activity.name]! + 1;
        }

        pmData = PDFData(
          testTitle: test.title,
          barGraphData: [
            BarGraphData(
              color: PdfColors.orange,
              dataMap: dataMap,
              graphTitle: 'Activity Types',
            )
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
        AcousticProfileData data = (test as AcousticProfileTest).data;
        PDFData apData;
        String standingPointTitle = '';
        Map<String, double> dataMap = {};
        double sum = 0;

        for (final dataPoint in data.dataPoints) {
          standingPointTitle = dataPoint.standingPoint.title;
          for (final measurement in dataPoint.measurements) {
            sum += measurement.decibels;
          }
          dataMap.putIfAbsent(standingPointTitle,
              () => (sum / (test.intervalCount).toDouble()));
          sum = 0;
        }

        if (dataMap.values.length < 2) {
          dataMap.putIfAbsent('', () => 0);
        }

        apData = PDFData(
          barGraphData: [
            BarGraphData(
              color: PdfColors.cyan,
              dataMap: dataMap,
              graphTitle: 'Decibels by Standing Point',
              yAxisLabel: 'Decibels',
            ),
          ],
          pieGraphData: [],
          displayName: AcousticProfileTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
          testTitle: test.title,
        );
        pdfPage = (apData);
      }
    case 'spatial_boundaries_tests':
      {
        PDFData sbData;
        SpatialBoundariesData data = (test as SpatialBoundariesTest).data;
        Map<String, double> shelterArea = {
          ShelterBoundaryType.canopy.name: 0,
          ShelterBoundaryType.constructed.name: 0,
          ShelterBoundaryType.furniture.name: 0,
          ShelterBoundaryType.temporary.name: 0,
          ShelterBoundaryType.tree.name: 0,
        };
        Map<String, double> materialArea = {
          MaterialBoundaryType.concrete.name: 0,
          MaterialBoundaryType.decking.name: 0,
          MaterialBoundaryType.natural.name: 0,
          MaterialBoundaryType.pavers.name: 0,
          MaterialBoundaryType.tile.name: 0,
        };
        Map<String, double> constructedLength = {
          ConstructedBoundaryType.buildingWall.name: 0,
          ConstructedBoundaryType.curb.name: 0,
          ConstructedBoundaryType.fence.name: 0,
          ConstructedBoundaryType.partialWall.name: 0,
          ConstructedBoundaryType.planter.name: 0,
        };
        Map<String, double> materialShelter = {
          BoundaryType.material.name: 0,
          BoundaryType.shelter.name: 0,
        };

        for (final MaterialBoundary material in data.material) {
          materialArea[material.materialType.name] =
              materialArea[material.materialType.name]! + material.polygonArea;
          materialShelter[BoundaryType.material.name] =
              materialShelter[BoundaryType.material.name]! + 1;
        }

        for (final ShelterBoundary shelter in data.shelter) {
          shelterArea[shelter.shelterType.name] =
              shelterArea[shelter.shelterType.name]! + shelter.polygonArea;
          materialShelter[BoundaryType.shelter.name] =
              materialShelter[BoundaryType.shelter.name]! + 1;
        }

        for (final ConstructedBoundary constructed in data.constructed) {
          constructedLength[constructed.constructedType.name] =
              constructedLength[constructed.constructedType.name]! +
                  constructed.polylineLength;
        }

        sbData = PDFData(
            testTitle: test.title,
            barGraphData: [
              BarGraphData(
                color: PdfColors.brown,
                dataMap: materialShelter,
                graphTitle: 'Material vs. Shelter',
              ),
              BarGraphData(
                color: PdfColors.deepOrange,
                dataMap: materialArea,
                graphTitle: 'Area of Material Types',
                yAxisLabel: 'Area (sq. ft)',
              ),
              BarGraphData(
                color: PdfColors.pink,
                dataMap: shelterArea,
                graphTitle: 'Area of Shelter Types',
                yAxisLabel: 'Area (sq. ft)',
              ),
              BarGraphData(
                color: PdfColors.yellow,
                dataMap: constructedLength,
                graphTitle: 'Length of Constructed Types',
                yAxisLabel: 'Length (ft)',
              ),
            ],
            pieGraphData: [],
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

List<pw.Padding> getPDFDataGraphs(PDFData testData) {
  List<pw.Padding> graphs = [];
  List<pw.Widget> pieGraphs = [];
  for (final BarGraphData barData in testData.barGraphData) {
    graphs.add(
      pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.5),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3.0)),
            ),
            child: pw.Padding(
              padding: pw.EdgeInsets.all(5.0),
              child: pw.Center(
                child: pw.SizedBox(
                  height: 200,
                  child: pw.Expanded(child: _generateBarGraph(barData)),
                ),
              ),
            )),
      ),
    );
  }

  for (final PieGraphData pieData in testData.pieGraphData) {
    pieGraphs.add(pw.Flexible(child: _generatePieGraph(pieData)));
    if (pieGraphs.length % 2 == 0) {
      graphs.add(
        pw.Padding(
          padding: pw.EdgeInsets.all(5.0),
          child: pw.Center(
            child: pw.SizedBox(
              height: 200,
              child: pw.Row(
                children: pieGraphs,
              ),
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
        child: pw.Center(
          child: pw.SizedBox(
            height: 200,
            child: pw.Row(
              children: pieGraphs,
            ),
          ),
        ),
      ),
    );
  }

  return graphs;
}

// PDF Generation Logic
Future<Uint8List> generateReport(
    PdfPageFormat pageFormat, Project activeProject) async {
  List<pw.Widget> widgets = [];
  List<Test> rawTests = [];
  PDFData? pdfData;
  List<Member> contributors;
  List<String> contributorsNames = [];
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

  contributors = await getTeamMembers(activeProject.teamRef!.id);
  for (Member contributor in contributors) {
    contributorsNames.add(contributor.fullName);
  }
  // First Page
  document.addPage(
    pw.Page(
      pageFormat: pageFormat,
      theme: theme,
      build: (context) {
        return pw.Column(
          children: [
            pw.Text(activeProject.title,
                style: const pw.TextStyle(
                  color: baseColor,
                  fontSize: 40,
                )),
            pw.Divider(thickness: 4),
            pw.Flexible(
              child: pw.Text(
                activeProject.description,
                style: const pw.TextStyle(fontSize: 16),
                textAlign: pw.TextAlign.justify,
              ),
            ),
            pw.Divider(
              thickness: 0.5,
            ),
            pw.SizedBox(
              height: 20,
            ),
            pw.Text(
              "Project Address: ",
              style: pw.TextStyle(
                  decoration: pw.TextDecoration.underline, fontSize: 16),
            ),
            pw.Text(activeProject.address),
            pw.SizedBox(height: 10),
            pw.Text(
              "Total Project Area (sq. ft):",
              style: pw.TextStyle(
                  decoration: pw.TextDecoration.underline, fontSize: 16),
            ),
            pw.Text("${activeProject.polygonArea.toStringAsFixed(3)} sq. ft."),
            pw.SizedBox(height: 10),
            pw.Text(
              'Contributors: ',
              style: pw.TextStyle(
                  decoration: pw.TextDecoration.underline, fontSize: 16),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text('${contributorsNames.join(', ')}'),
            pw.SizedBox(height: 10),
            pw.Text(
              'Sponsor: ',
              style: pw.TextStyle(
                  decoration: pw.TextDecoration.underline, fontSize: 16),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text('UCF Professor Herbert Tommy James'),
          ],
        );
      },
    ),
  );

  projectPolygon = getProjectPolygon(activeProject.polygonPoints);
  rawTests = activeProject.tests ?? [];
  for (Test currentTest in rawTests) {
    // If a test isn't complete, skip it
    if (!currentTest.isComplete) continue;
    pdfData = await retrievePDFInfo(currentTest, projectPolygon);

    if (pdfData == null) continue;
    if (pdfData.sectionImageLink != null) await pdfData.loadImage();
    // TODO: Add one page for an explainer for each test type.

    widgets.addAll(
      [
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Text(
            pdfData.displayName,
            style: pw.TextStyle(
              color: baseColor,
              fontSize: 12,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            pdfData.testTitle,
            style: pw.TextStyle(
              color: baseColor,
              fontSize: 20,
            ),
          ),
        ),
        pw.Center(
          child: pw.Text(
            '${pdfData.date} at ${pdfData.time}',
            style: pw.TextStyle(
              color: baseColor,
              fontSize: 20,
            ),
          ),
        ),
        pw.Center(
          child: pw.Divider(thickness: 3),
        ),
      ],
    );

    if (pdfData.sectionImageLink != null && pdfData.sectionImage != null) {
      widgets.addAll(
        [
          pw.Center(
            child: pw.Text("Section Image:", style: pw.TextStyle(fontSize: 18)),
          ),
          pw.Center(
            child: pw.SizedBox(height: 5),
          ),
          pw.Center(
            child: pw.SizedBox(
              height: 200,
              width: 200,
              child: pw.Image(
                pw.MemoryImage(pdfData.sectionImage!),
              ),
            ),
          )
        ],
      );
    }

    if (pdfData.mapImage != null) {
      widgets.add(
        pw.Image(pw.MemoryImage(pdfData.mapImage!)),
      );
    }

    widgets.addAll(
      getPDFDataGraphs(pdfData),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        theme: theme,
        build: (context) {
          return widgets;
        },
      ),
    );
    widgets = [];
  }
  final documentImage = await (document.save());
  web.HTMLAnchorElement()
    ..href =
        'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(documentImage.toList())}'
    ..setAttribute('download', 'results_pdf.pdf')
    ..click();
  return document.save();
} // End of generateReport()

// Function to generate the chart for Points (bar charts)
pw.Widget _generateBarGraph(BarGraphData barGraphData) {
  int increment = ((barGraphData.values.toList().maxOrNull ?? 0) ~/ 5) + 1;
  if (increment < 3) increment = 2;
  if (barGraphData.values.isEmpty || increment <= 0) return pw.Container();
  // Process data
  List<double> dataSet = barGraphData.values;
  // Top bar chart
  print("${barGraphData.values} ${barGraphData.labels}");
  return pw.Chart(
    left: pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(right: 5),
      child: pw.Transform.rotateBox(
        angle: pi / 2,
        child: pw.Text(barGraphData.yAxisLabel),
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
            return pw.PointChartValue(i.toDouble(), dataSet[i]);
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

class PieGraphData {
  final List<PdfColor> colorList;
  final Map<String, double> dataMap;
  List<String> labels = [];
  late final List<double> values;
  final String graphTitle;

  PieGraphData(
      {List<String>? customLabels,
      this.colorList = defaultChartColors,
      required this.dataMap,
      required this.graphTitle}) {
    if (customLabels == null || customLabels.length != dataMap.values.length) {
      customLabels = dataMap.keys.toList();
    }
    labels = customLabels;
    values = dataMap.values.toList();
  }
}

class BarGraphData {
  final PdfColor color;
  final Map<String, double> dataMap;
  List<String> labels = [];
  late final List<double> values;
  final String graphTitle;
  final String yAxisLabel;

  BarGraphData(
      {List<String>? customLabels,
      this.yAxisLabel = 'Amount',
      required this.color,
      required this.dataMap,
      required this.graphTitle}) {
    if (customLabels == null || customLabels.length != dataMap.values.length) {
      customLabels = dataMap.keys.toList();
    }
    labels = customLabels.toList();
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
