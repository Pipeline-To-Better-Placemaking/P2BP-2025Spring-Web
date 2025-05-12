import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:p2b/extensions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'db_schema_classes/member_class.dart';
import 'db_schema_classes/project_class.dart';
import 'db_schema_classes/specific_test_classes/absence_of_order_test_class.dart';
import 'db_schema_classes/specific_test_classes/access_profile_test_class.dart';
import 'db_schema_classes/specific_test_classes/acoustic_profile_test_class.dart';
import 'db_schema_classes/specific_test_classes/lighting_profile_test_class.dart';
import 'db_schema_classes/specific_test_classes/nature_prevalence_test_class.dart';
import 'db_schema_classes/specific_test_classes/people_in_motion_test_class.dart';
import 'db_schema_classes/specific_test_classes/people_in_place_test_class.dart';
import 'db_schema_classes/specific_test_classes/section_cutter_test_class.dart';
import 'db_schema_classes/specific_test_classes/spatial_boundaries_test_class.dart';
import 'db_schema_classes/test_class.dart';

// Allows user to see the pdf in browser so they know what they are getting
class PdfReportPage extends StatelessWidget {
  final Project activeProject;

  const PdfReportPage({super.key, required this.activeProject});

  // generate the PDF
  Future<Uint8List> _generatePdf() async {
    return generateReport(PdfPageFormat.letter, activeProject);
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

Future<PDFData?> retrievePDFInfo(Test test, Polygon projectPolygon) async {
  PDFData? pdfPage;
  switch (test.collectionID) {
    case LightingProfileTest.collectionIDStatic:
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
    case AbsenceOfOrderTest.collectionIDStatic:
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
    case NaturePrevalenceTest.collectionIDStatic:
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
                yAxisLabel: 'Area (sq. ft)',
                customLabels: ['vegetation', 'body of water'],
              ),
            ],
            pieGraphData: [],
            displayName: NaturePrevalenceTest.displayName,
            date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
            time: DateFormat.jmv().format(test.scheduledTime.toDate()));
        pdfPage = (npData);
      }
    case AccessProfileTest.collectionIDStatic:
      {
        PDFData iaData;
        AccessProfileData data = (test as AccessProfileTest).data;
        Map<String, double> polylineLengths = {
          AccessType.taxiAndRideShare.name: 0,
          AccessType.parking.name: 0,
          AccessType.transportStation.name: 0,
          AccessType.bikeRack.name: 0,
        };
        Map<String, double> spotsMap = {
          AccessType.bikeRack.name: 0,
          AccessType.parking.name: 0,
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
                customLabels: [
                  'rideshare/taxi',
                  'car',
                  'bus/train',
                  'bike/scooter'
                ],
                yAxisLabel: 'Length (ft.)'),
            BarGraphData(
              color: PdfColors.black,
              dataMap: spotsMap,
              graphTitle: 'Number of Parking Spots by Vehicle',
              customLabels: ['bike/scooter', 'car'],
            ),
          ],
          pieGraphData: [],
          displayName: AccessProfileTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
        );
        pdfPage = (iaData);
      }
    case PeopleInPlaceTest.collectionIDStatic:
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
              customLabels: ['laying down', 'sitting', 'squatting', 'standing'],
            )
          ],
          pieGraphData: [],
          displayName: PeopleInPlaceTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
        );
        pdfPage = (ppData);
      }
    case PeopleInMotionTest.collectionIDStatic:
      {
        PDFData pmData;
        PeopleInMotionData data = (test as PeopleInMotionTest).data;
        Map<String, double> dataMap = {
          ActivityTypeInMotion.activityOnWheels.name: 0,
          ActivityTypeInMotion.walking.name: 0,
          ActivityTypeInMotion.swimming.name: 0,
          ActivityTypeInMotion.running.name: 0,
          ActivityTypeInMotion.handicapAssistedWheels.name: 0,
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
              customLabels: [
                'on wheels',
                'walking',
                'swimming',
                'running',
                'handicap assisted'
              ],
            )
          ],
          pieGraphData: [],
          displayName: PeopleInMotionTest.displayName,
          date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
          time: DateFormat.jmv().format(test.scheduledTime.toDate()),
        );
        pdfPage = (pmData);
      }
    case AcousticProfileTest.collectionIDStatic:
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
    case SpatialBoundariesTest.collectionIDStatic:
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
                  customLabels: [
                    'building wall',
                    'curb',
                    'fence',
                    'partial wall',
                    'planter'
                  ]),
            ],
            pieGraphData: [],
            displayName: SpatialBoundariesTest.displayName,
            date: DateFormat.yMMMd().format(test.scheduledTime.toDate()),
            time: DateFormat.jmv().format(test.scheduledTime.toDate()));
        pdfPage = (sbData);
      }
    case SectionCutterTest.collectionIDStatic:
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
  PDFData? pdfData;
  List<Member> contributors;
  List<String> contributorsNames = [];
  const baseColor = PdfColors.black;
  String currentCollectionID = '';
  List<Test> sortedTests = [];

  // Actually launches the pdf builder
  final document = pw.Document();
  final Polygon projectPolygon;

  // Theme settings
  final theme = pw.ThemeData.withFont(
    base: await PdfGoogleFonts.openSansRegular(),
    bold: await PdfGoogleFonts.openSansBold(),
  );

  final roleMap = await activeProject.team?.loadMembersInfo();
  contributors = roleMap!.toSingleList();
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
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              activeProject.title,
              style: const pw.TextStyle(
                color: baseColor,
                fontSize: 40,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.Divider(thickness: 4),
            pw.Flexible(
              child: pw.Text(
                activeProject.description,
                style: const pw.TextStyle(fontSize: 16),
                textAlign: pw.TextAlign.center,
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
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(activeProject.address),
            pw.SizedBox(height: 10),
            pw.Text(
              "Total Project Area (sq. ft):",
              style: pw.TextStyle(
                  decoration: pw.TextDecoration.underline, fontSize: 16),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text("${activeProject.polygonArea.toStringAsFixed(3)} sq. ft."),
            pw.SizedBox(height: 10),
            pw.Text(
              'Contributors: ',
              style: pw.TextStyle(
                  decoration: pw.TextDecoration.underline, fontSize: 16),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(contributorsNames.join(', ')),
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

  if (activeProject.tests == null || activeProject.tests!.isEmpty) {
    return document.save();
  }

  projectPolygon = activeProject.polygon.clone();
  sortedTests = activeProject.tests!.toList();
  sortedTests.sort((a, b) => a.collectionID.compareTo(b.collectionID));

  for (Test currentTest in sortedTests) {
    // If a test isn't complete, skip it
    if (!currentTest.isComplete) continue;

    pdfData = await retrievePDFInfo(currentTest, projectPolygon);

    if (pdfData == null) continue;
    if (pdfData.sectionImageLink != null) await pdfData.loadImage();

    widgets.addAll(
      [
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Text(pdfData.displayName,
              style: pw.TextStyle(
                color: baseColor,
                fontSize: 12,
              ),
              textAlign: pw.TextAlign.center),
        ),
        pw.Center(
          child: pw.Text(pdfData.testTitle,
              style: pw.TextStyle(
                color: baseColor,
                fontSize: 20,
              ),
              textAlign: pw.TextAlign.center),
        ),
        pw.Center(
          child: pw.Text('${pdfData.date} at ${pdfData.time}',
              style: pw.TextStyle(
                color: baseColor,
                fontSize: 20,
              ),
              textAlign: pw.TextAlign.center),
        ),
        pw.Center(
          child: pw.Divider(thickness: 3),
        ),
      ],
    );

    // Add blank space for potential images to be added in post.
    widgets.add(
      pw.Padding(
        padding: pw.EdgeInsets.all(20),
        child: pw.Center(
          child: pw.SizedBox(
            height: 200,
            width: 350,
            child: pw.Container(
              color: PdfColors.grey100,
              child: pw.Center(
                child: pw.Text("<Placeholder Space>"),
              ),
            ),
          ),
        ),
      ),
    );

    if (pdfData.sectionImageLink != null && pdfData.sectionImage != null) {
      widgets.addAll(
        [
          pw.Center(
            child: pw.Text("Section Image:",
                style: pw.TextStyle(fontSize: 18),
                textAlign: pw.TextAlign.center),
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

    // Add one page for an explainer for each test type.
    if (currentTest.collectionID != currentCollectionID) {
      currentCollectionID = currentTest.collectionID;
      document.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          theme: theme,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          build: (context) {
            return <pw.Widget>[
              pw.Center(
                child: pw.Text(
                  pdfData!.displayName,
                  style: const pw.TextStyle(
                    color: baseColor,
                    fontSize: 28,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Divider(thickness: 2),
              collectionIDToDescription[currentCollectionID]!,
              pw.Divider(
                thickness: 0.5,
              ),
            ];
          },
        ),
      );
    }

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
    // Create a storage reference from app
    final storageRef = FirebaseStorage.instance.ref();
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

Map<String, pw.Column> collectionIDToDescription = {
  AbsenceOfOrderTest.collectionIDStatic: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "1. "),
            pw.TextSpan(text: AbsenceOfOrderTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text:
                      "Surveyors will identify where and what elements from the "
                      "built environment show signs of disorder during the "
                      "survey time slots."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Behavior"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "Maintenance"),
            ],
          ),
        ),
      ),
    ],
  ),
  AccessProfileTest.collectionIDStatic: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "2. "),
            pw.TextSpan(text: AccessProfileTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text:
                      "This part of the research locates the arrival points for "
                      "the public and how far to the project site that is. "),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Mode of arrival (Bike/Bus/Car)"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(
                  text:
                      "Capacity of the arrival points (# of parking spaces, racks)"),
            ],
          ),
        ),
      ),
    ],
  ),
  AcousticProfileTest.collectionIDStatic: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "3. "),
            pw.TextSpan(text: AcousticProfileTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text:
                      "This part of the research, the loudness of decibels will "
                      "be analyzed, and the role that noise and acoustics play "
                      "in our security."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Loudness"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "Sources"),
            ],
          ),
        ),
      ),
    ],
  ),
  LightingProfileTest.collectionIDStatic: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "4. "),
            pw.TextSpan(text: LightingProfileTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text: "Surveyors will identify what elements from the built "
                      "environment make up the lighting profile of the place."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(
                  text: "Existence of light within the built environment."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "How it is being used within the space."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "iii. "),
              pw.TextSpan(text: "the consistency of it."),
            ],
          ),
        ),
      ),
    ],
  ),
  NaturePrevalenceTest.collectionIDStatic: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "5. "),
            pw.TextSpan(text: NaturePrevalenceTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text: "Surveyors will identify where and what elements from "
                      "the built environment embrace the natural tools of place."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Natural"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "Designed"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "iii. "),
              pw.TextSpan(text: "Open Field"),
            ],
          ),
        ),
      ),
    ],
  ),
  PeopleInMotionTest.collectionIDStatic: pw.Column(
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "6. "),
            pw.TextSpan(text: PeopleInMotionTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text:
                      "The app will present research team members with a map to note "),
              pw.TextSpan(
                text: "where ",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: "and "),
              pw.TextSpan(
                text: "how ",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: "in the area of interest people are: "),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Located"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "Their Path"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "iii. "),
              pw.TextSpan(text: "Mode of Transportation"),
            ],
          ),
        ),
      ),
    ],
  ),
  PeopleInPlaceTest.collectionIDStatic: pw.Column(
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "7. "),
            pw.TextSpan(text: PeopleInPlaceTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text:
                      "The app will present research team members with a map to "
                      "note "),
              pw.TextSpan(
                text: "where ",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: "and "),
              pw.TextSpan(
                text: "what ",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: "in the area of interest people are: "),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Located"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "General Profile"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "iii. "),
              pw.TextSpan(text: "Activity"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "iv. "),
              pw.TextSpan(text: "Posture"),
            ],
          ),
        ),
      ),
    ],
  ),
  SectionCutterTest.collectionIDStatic: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "8. "),
            pw.TextSpan(text: SectionCutterTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text: "The part of the research has the surveyor create "
                      "architecture cross section through the site to gather."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Human scale"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "Vertical dimensions"),
            ],
          ),
        ),
      ),
    ],
  ),
  SpatialBoundariesTest.collectionIDStatic: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(text: "9. "),
            pw.TextSpan(text: SpatialBoundariesTest.displayName),
          ],
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 20),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "a. "),
              pw.TextSpan(
                  text: "Surveyors will identify what elements from the built "
                      "environment allow activity to take place or separate that "
                      "activity from the overall place."),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "i. "),
              pw.TextSpan(text: "Constructed (buildings, planters, fences)"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "ii. "),
              pw.TextSpan(text: "Material (brick, paver, concrete, natural)"),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 40),
        child: pw.RichText(
          text: pw.TextSpan(
            children: <pw.TextSpan>[
              pw.TextSpan(text: "iii. "),
              pw.TextSpan(text: "Shelter (canopies built & natural)"),
            ],
          ),
        ),
      ),
    ],
  ),
};
