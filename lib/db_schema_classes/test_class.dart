import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:p2b/db_schema_classes/project_class.dart';

import 'misc_class_stuff.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

// *--------------------------------------------------------------------------*
// | Important: When adding a test, make sure to implement the requisite      |
// | fields and functions. When done, make sure to implement it in the        |
// | dropdown on create_test_form.dart, register it on main.dart, and add it  |
// | to the initials list on project_details.dart. If it it implements        |
// | standing points and a timer, add it to the following lists.              |
// *--------------------------------------------------------------------------*

/// Parent class extended by every specific test class.
///
/// Each specific test will most likely have a different format for data
/// which needs to be specified around the implementation and used in place
/// of generic type [T] in each subclass.
///
/// Additionally, each subclass is expected to statically define constants
/// for the associated collection ID in Firestore and the basic structure
/// used for that test's [data] for initialization.
abstract class Test<T> with JsonToString implements FirestoreDocument {
  /// The time this [Test] was initially created at.
  final Timestamp creationTime;

  final String id;

  String title = '';

  /// The time scheduled for this test to be completed.
  ///
  /// For most tests this is the time that the test should be completed at
  /// but for some like 'Section cutter' and 'Identify programs' it is more
  /// like a deadline for the latest it should be completed by.
  Timestamp scheduledTime;

  /// The [DocumentReference] pointing to the project in which this [Test]
  /// resides.
  DocumentReference projectRef;

  /// Maximum researchers that can complete this test.
  ///
  /// Currently always 1.
  int maxResearchers = 1;

  /// Instance member using custom data type for each specific test
  /// implementation for storing test data.
  ///
  /// Initial framework for storing data for each test should be defined in
  /// each implementation as the value returned from
  /// `getInitialDataStructure()`, as this is used for initializing `data`
  /// when it is not defined in the constructor.
  T data;

  /// Whether this test has been completed by a surveyor yet.
  bool isComplete = false;

  /// Creates a new [Test] instance from the given arguments.
  ///
  /// Used for all creation of [Test] subclasses through super-constructor
  /// calls through factory constructors, so all logic for when certain
  /// values are not provided should be here.
  ///
  /// This is private because the only intended usage is through various
  /// public methods acting as factory constructors.
  Test({
    required this.title,
    required this.id,
    required this.scheduledTime,
    required this.projectRef,
    required this.data,
    Timestamp? creationTime,
    int? maxResearchers,
    bool? isComplete,
  })  : creationTime = creationTime ?? Timestamp.now(),
        maxResearchers = maxResearchers ?? 1,
        isComplete = isComplete ?? false;

  // The below Maps must have values registered for each subclass of Test.
  // Thus each subclass should have a method `static void register()`
  // which adds the appropriate values to each Map.

  /// Maps from the collection ID of each [Test] subclass to a function
  /// which should use a constructor of that [Test] type to make a new instance
  /// of said [Test].
  static final Map<
      String,
      Test Function({
        required String title,
        required String id,
        required Timestamp scheduledTime,
        required DocumentReference projectRef,
        List? standingPoints,
        int? testDuration,
        int? intervalDuration,
        int? intervalCount,
      })> newTestConstructors = {};

  /// Maps from collection ID to a function which should use a constructor
  /// to make and return a [Test] object from the existing information
  /// given in [testDoc].
  static final Map<String,
          Test Function(DocumentSnapshot<Map<String, dynamic>>)>
      recreateTestConstructors = {};

  /// Maps from a [Type] assumed to be a subclass of [Test] to the page
  /// for completing that [Test].
  static final Map<Type, Widget Function(Project, Test)> pageBuilders = {};

  static final Map<Type, String> testInitialsMap = {};

  /// Set used internally to determine whether a [Test] subclass uses
  /// standing points. Subclasses that do are expected to register themselves
  /// into this set.
  static final Set<String> standingPointTestCollectionIDs = {};

  /// Set containing all tests that make use of timers.
  ///
  /// Used to check for test creation and saving.
  static final Set<String> timerTestCollectionIDs = {};

  /// Set containing all tests that use a timer with intervals.
  ///
  /// Used to check for test creation and saving.
  static final Set<String> intervalTimerTestCollectionIDs = {};

  /// Returns a new instance of the [Test] subclass associated with
  /// [collectionID].
  ///
  /// This acts as a factory constructor and is intended to be used for
  /// any newly created tests.
  ///
  /// Utilizes values registered to [Test.newTestConstructors].
  static Test createNew(
      {required String title,
      required Timestamp scheduledTime,
      required Project project,
      required String collectionID,
      List? standingPoints,
      int? testDuration,
      int? intervalDuration,
      int? intervalCount}) {
    // Generate new ID;
    final id = _firestore.collection(collectionID).doc().id;

    // Get constructor for appropriate test type.
    final constructor = newTestConstructors[collectionID];
    if (constructor != null) {
      final test = constructor(
        title: title,
        id: id,
        scheduledTime: scheduledTime,
        projectRef: project.ref,
        standingPoints: standingPoints,
        testDuration: testDuration,
        intervalDuration: intervalDuration,
        intervalCount: intervalCount,
      );

      // Add test to project.
      project.testRefs.add(test.ref);
      project.tests?.add(test);

      _firestore.runTransaction((transaction) async {
        transaction.set(
          _firestore.collection(test.collectionID).doc(test.id),
          test.toJson(),
        );
        transaction.update(project.ref, project.toJson());
      });

      return test;
    }
    throw Exception('Unregistered Test type for collection: $collectionID');
  }

  /// Returns a new instance of the [Test] subclass appropriate for the
  /// given [testDoc] based on the collection it is from.
  ///
  /// This acts as a factory constructor for tests which already exist in
  /// Firestore.
  ///
  /// Utilizes values registered to [Test.recreateTestConstructors].
  static Test recreateFromDoc(DocumentSnapshot<Map<String, dynamic>> testDoc) {
    final constructor = recreateTestConstructors[testDoc.reference.parent.id];
    if (constructor != null) {
      return constructor(testDoc);
    }
    throw Exception(
        'Unregistered Test type for collection: ${testDoc.reference.parent.id}');
  }

  /// Returns the [Widget] of the page used to complete this type of [Test]
  /// with the given [Test] and [Project] parameters already given.
  ///
  /// Basically when you want to navigate to [Test] completion page just use
  /// `test.getPage(project)` as the page given to a Navigator function.
  Widget getPage(Project project) {
    final pageBuilder = pageBuilders[runtimeType];
    if (pageBuilder != null) {
      return pageBuilder(project, this);
    }
    throw Exception('No registered page for test type: $runtimeType');
  }

  /// Returns 2-letter initials for given test type if they are registered.
  String getInitials() {
    return testInitialsMap[runtimeType] ?? '';
  }

  /// Returns whether [Test] subclass with given [collectionID] is
  /// registered as a standing points test.
  static bool isStandingPointTest(String? collectionID) {
    return standingPointTestCollectionIDs.contains(collectionID);
  }

  /// Returns whether [Test] subclass with given [collectionID] is
  /// registered as a timer test.
  static bool isTimerTest(String? collectionID) {
    return timerTestCollectionIDs.contains(collectionID);
  }

  /// Returns whether [Test] subclass with given collection ID is
  /// registered as an interval timer test.
  static bool isIntervalTimerTest(String? collectionID) {
    return intervalTimerTestCollectionIDs.contains(collectionID);
  }

  Future<Test?> get(DocumentReference ref) async {
    try {
      final doc = await ref.get();
      if (doc.exists && doc.data()! is Map<String, Object?>) {
        return recreateFromDoc(doc as DocumentSnapshot<Map<String, Object?>>);
      } else {
        return null;
      }
    } catch (e, s) {
      print('Exception: $e');
      print('Stacktrace: $s');
      throw Exception('Failed to get test because of exception: $e');
    }
  }

  /// Uploads the data from a completed test to Firestore.
  ///
  /// Used on completion of a test and should be passed all data
  /// collected throughout the duration of the test.
  ///
  /// Updates this test instance in Firestore with
  /// this new data and marks the test as complete; `isComplete = true`.
  /// This will need to change if more than 1 researcher is allowed per test.
  void submitData(T data);
}
