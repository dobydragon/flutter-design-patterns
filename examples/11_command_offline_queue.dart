// Command — Offline attendance queue (+ undo)
// Run: dart run 11_command_offline_queue.dart
//
// Typical Flutter shape: a NetworkRequestQueue that stores closures and
// replays them on reconnect.

// ---------------------------------------------------------------------------
// BEFORE: the action runs immediately. If offline, it's just lost.
// ---------------------------------------------------------------------------
Future<void> beforeCheckIn(bool online, String employee) async {
  if (!online) {
    print('Before → offline, check-in for $employee LOST');
    return;
  }
  print('Before → sent check-in for $employee');
}

// ---------------------------------------------------------------------------
// AFTER: each action is an object → can be queued, retried, logged, undone.
// ---------------------------------------------------------------------------
abstract interface class AttendanceCommand {
  String get label;
  Future<void> execute();
  Future<void> undo();
}

class FakeAttendanceApi {
  final List<String> records = [];
}

class CheckInCommand implements AttendanceCommand {
  CheckInCommand(this._api, this.employee, this.at);

  final FakeAttendanceApi _api;
  final String employee;
  final DateTime at;

  @override
  String get label => 'check-in $employee @ ${at.hour}:${at.minute.toString().padLeft(2, '0')}';

  @override
  Future<void> execute() async => _api.records.add(label);

  @override
  Future<void> undo() async => _api.records.remove(label);
}

class CommandQueue {
  final List<AttendanceCommand> _pending = [];
  final List<AttendanceCommand> _history = [];

  Future<void> run(AttendanceCommand c, {required bool online}) async {
    if (!online) {
      _pending.add(c);
      print('After  → queued "${c.label}" (${_pending.length} pending)');
      return;
    }
    await c.execute();
    _history.add(c);
  }

  Future<void> flush() async {
    final copy = List.of(_pending);
    _pending.clear();
    for (final c in copy) {
      await c.execute();
      _history.add(c);
      print('After  → replayed "${c.label}"');
    }
  }

  Future<void> undoLast() async {
    if (_history.isEmpty) return;
    final c = _history.removeLast();
    await c.undo();
    print('After  → undid "${c.label}"');
  }
}

Future<void> main() async {
  await beforeCheckIn(false, 'Sara');

  final api = FakeAttendanceApi();
  final queue = CommandQueue();
  await queue.run(CheckInCommand(api, 'Sara', DateTime(2026, 1, 1, 8, 55)), online: false);
  await queue.run(CheckInCommand(api, 'Omar', DateTime(2026, 1, 1, 9, 2)), online: false);
  await queue.flush(); // connection is back
  await queue.undoLast(); // HR fixes a mistake
  print('Saved records: ${api.records}');
}
