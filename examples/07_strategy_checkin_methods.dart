// Strategy — Attendance check-in methods (GPS / QR / Wi-Fi)
// Run: dart run 07_strategy_checkin_methods.dart
//
// A lighter Dart variant is function-based, e.g. a static
// AppNavigator.webPushNamed hook that the web build replaces.

// ---------------------------------------------------------------------------
// BEFORE: one method with a growing if/else. Every new method = edit here.
// ---------------------------------------------------------------------------
bool beforeVerify(String method, Map<String, Object> input) {
  if (method == 'gps') {
    return (input['distanceMeters'] as int) <= 100;
  } else if (method == 'qr') {
    return input['qr'] == 'OFFICE-2026';
  } else if (method == 'wifi') {
    return input['ssid'] == 'Acme-Office';
  }
  throw ArgumentError('unknown method $method');
}

// ---------------------------------------------------------------------------
// AFTER (A): classic Strategy — an interface + one class per algorithm.
// ---------------------------------------------------------------------------
abstract interface class CheckInStrategy {
  String get name;
  bool verify(Map<String, Object> input);
}

class GpsCheckIn implements CheckInStrategy {
  GpsCheckIn({this.maxMeters = 100});

  final int maxMeters;

  @override
  String get name => 'GPS';

  @override
  bool verify(Map<String, Object> input) =>
      (input['distanceMeters'] as int) <= maxMeters;
}

class QrCheckIn implements CheckInStrategy {
  @override
  String get name => 'QR';

  @override
  bool verify(Map<String, Object> input) => input['qr'] == 'OFFICE-2026';
}

class WifiCheckIn implements CheckInStrategy {
  @override
  String get name => 'Wi-Fi';

  @override
  bool verify(Map<String, Object> input) => input['ssid'] == 'Acme-Office';
}

/// The context: does not know which algorithm it runs.
class CheckInService {
  CheckInService(this._strategy);

  CheckInStrategy _strategy;

  set strategy(CheckInStrategy s) => _strategy = s; // swap at runtime

  String checkIn(Map<String, Object> input) =>
      '${_strategy.name}: ${_strategy.verify(input) ? 'accepted' : 'rejected'}';
}

// ---------------------------------------------------------------------------
// AFTER (B): Dart-idiomatic Strategy — just pass a function.
// ---------------------------------------------------------------------------
typedef Verifier = bool Function(Map<String, Object> input);

String checkInWith(Verifier verify, Map<String, Object> input) =>
    verify(input) ? 'accepted' : 'rejected';

void main() {
  print('Before → ${beforeVerify('gps', {'distanceMeters': 40})}');

  final service = CheckInService(GpsCheckIn());
  print(service.checkIn({'distanceMeters': 40}));
  service.strategy = QrCheckIn(); // e.g. company setting changed
  print(service.checkIn({'qr': 'WRONG'}));
  service.strategy = WifiCheckIn();
  print(service.checkIn({'ssid': 'Acme-Office'}));

  print('Function strategy → ${checkInWith((i) => i['badge'] == 42, {'badge': 42})}');
}
