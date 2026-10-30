// Dependency Injection — Attendance check-in
// Run: dart run 04_dependency_injection_attendance.dart
//
// Typical Flutter constructor injection, e.g.
// PostsService({FirebaseFirestore? firestore})
// and a composition root at the top of the widget tree.

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

// ---------------------------------------------------------------------------
// BEFORE: the class creates what it needs. Untestable "is late?" logic.
// ---------------------------------------------------------------------------
class BeforeAttendanceService {
  final SystemClock _clock = SystemClock(); // hard-wired

  bool isLate() => _clock.now().hour >= 9; // result depends on when you run it
}

// ---------------------------------------------------------------------------
// AFTER: dependencies come from outside (constructor injection).
// ---------------------------------------------------------------------------
class AttendanceService {
  AttendanceService({required Clock clock, int startHour = 9})
      : _clock = clock,
        _startHour = startHour;

  final Clock _clock;
  final int _startHour;

  bool isLate() => _clock.now().hour >= _startHour;
}

// Composition root: the ONE place that knows the concrete classes
// (in Flutter this is MultiRepositoryProvider in the root widget).
AttendanceService buildProductionAttendance() =>
    AttendanceService(clock: SystemClock());

void main() {
  print('Before → isLate = ${BeforeAttendanceService().isLate()} (depends on real time)');

  final at0830 = AttendanceService(clock: FixedClock(DateTime(2026, 1, 1, 8, 30)));
  final at0915 = AttendanceService(clock: FixedClock(DateTime(2026, 1, 1, 9, 15)));
  print('Test 08:30 → late? ${at0830.isLate()}'); // false, always
  print('Test 09:15 → late? ${at0915.isLate()}'); // true, always
  print('Prod       → late? ${buildProductionAttendance().isLate()}');
}
