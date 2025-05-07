import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:p2b/db_schema_classes/standing_point_class.dart';
import 'package:p2b/db_schema_classes/test_class.dart';

abstract interface class FirestoreDocument {
  String get collectionID;
  DocumentReference get ref;
}

/// Class to be implemented by all Test subclasses which use standing points.
///
/// Using this also requires that the class run
/// [Test._standingPointTestCollectionIDs.add(collectionIDStatic)]
/// in its register method to be recognized as using standing points.
abstract interface class StandingPointTest {
  final List<StandingPoint> standingPoints = [];
}

/// Class to be implemented by all Test subclasses which use a timer.
///
/// Using this also requires that the class run
/// [Test._timerTestCollectionIDs.add(collectionIDStatic)]
/// in its register method to be recognized as using a timer.
abstract interface class TimerTest {
  final int testDuration;

  TimerTest(this.testDuration);
}

abstract interface class IntervalTimerTest {
  final int intervalDuration;
  final int intervalCount;

  IntervalTimerTest(this.intervalDuration, this.intervalCount);
}

abstract interface class DisplayNameEnum {
  final String displayName;

  DisplayNameEnum({required this.displayName});

  /// Returns the enumerated type with the matching displayName.
  factory DisplayNameEnum.byDisplayName(String displayName) {
    throw UnimplementedError();
  }
}

/// Mixin to add toString functionality to any class with a toJson() method.
mixin JsonToString {
  @override
  String toString() {
    return toJson().toString();
  }

  Map<String, Object?> toJson();
}

enum GroupRole {
  member(rank: 0),
  owner(rank: 10);

  const GroupRole({required this.rank});

  final int rank;
}

final Set<GroupRole> elevatedRoles =
    GroupRole.values.where((role) => role.rank > 4).toSet();

typedef RoleMap<T> = Map<GroupRole, List<T>>;

/// Comparison function for tests. Used in [.sort].
///
/// Sorts based on scheduled time.
/// The tests are split further into two categories completed and not completed.
/// For completed tests, simply sort by scheduled time.
/// For non-completed tests, sort first by whether the date has passed. This gives two more groups.
/// Sort both by their scheduled time.
int testTimeComparison(Test a, Test b) {
  Timestamp currentTime = Timestamp.now();
  if (a.isComplete) {
    // If a and b are both complete
    if (b.isComplete) {
      return a.scheduledTime.compareTo(b.scheduledTime);
    }
    // If a is complete and b is not
    else {
      return 2;
    }
  }
  // If a is not complete and b is
  else if (b.isComplete) {
    return -2;
  }
  // If both a and b are not complete
  else {
    // If a's time has passed
    if (a.scheduledTime.compareTo(currentTime) > 0) {
      // If b's time has also passed
      if (b.scheduledTime.compareTo(currentTime) > 0) {
        return a.scheduledTime.compareTo(b.scheduledTime);
      }
      // Else if a's time has not passed, but b's has
      else {
        return -3;
      }
    }
    // Else if a's time has passed
    else {
      return 3;
    }
  }
}
