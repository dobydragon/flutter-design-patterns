// Observer — Live attendance board (Stream + a Cubit-like class)
// Run: dart run 06_observer_attendance_stream.dart
//
// Typical Flutter shape: NetworkManager.statusStream (broadcast StreamController)
// → NetworkCubit.listen → BlocBuilder.

import 'dart:async';

// ---------------------------------------------------------------------------
// BEFORE: polling — the screen keeps asking "anything new?".
// ---------------------------------------------------------------------------
class BeforeAttendanceSource {
  final List<String> checkedIn = [];
}

Future<void> beforeDemo() async {
  final source = BeforeAttendanceSource();
  var polls = 0;
  final timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
    polls++; // wasted work even when nothing changed
  });
  source.checkedIn.add('Sara');
  await Future<void>.delayed(const Duration(milliseconds: 55));
  timer.cancel();
  print('Before → polled $polls times to notice 1 change');
}

// ---------------------------------------------------------------------------
// AFTER: the subject pushes changes; observers subscribe/unsubscribe.
// ---------------------------------------------------------------------------
class AttendanceFeed {
  final _controller = StreamController<String>.broadcast(); // many listeners

  Stream<String> get checkIns => _controller.stream;

  void checkIn(String name) => _controller.add(name);

  Future<void> dispose() => _controller.close();
}

/// Minimal Cubit: holds state, notifies listeners on every emit.
class CountCubit {
  CountCubit(AttendanceFeed feed) {
    _sub = feed.checkIns.listen((name) => _emit(_state + 1));
  }

  final _states = StreamController<int>.broadcast();
  late final StreamSubscription<String> _sub;
  int _state = 0;

  Stream<int> get stream => _states.stream;

  void _emit(int next) {
    _state = next;
    _states.add(next);
  }

  Future<void> close() async {
    await _sub.cancel(); // always unsubscribe — do it in close()
    await _states.close();
  }
}

Future<void> main() async {
  await beforeDemo();

  final feed = AttendanceFeed();
  final cubit = CountCubit(feed);

  // Two independent observers (think: BlocBuilder + a BlocListener).
  final ui = cubit.stream.listen((n) => print('UI: $n employees in office'));
  final log = feed.checkIns.listen((name) => print('Log: $name checked in'));

  feed
    ..checkIn('Sara')
    ..checkIn('Omar');
  await Future<void>.delayed(Duration.zero);

  await ui.cancel();
  await log.cancel();
  await cubit.close();
  await feed.dispose();
}
