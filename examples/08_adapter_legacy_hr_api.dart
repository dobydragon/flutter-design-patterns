// Adapter — Legacy HR API → the app's own interface
// Run: dart run 08_adapter_legacy_hr_api.dart
//
// Other Flutter examples: a route bridge (named routes → go_router) and
// SearchResultItem.fromPost/fromQuestion/... (many types → 1 row type).

// The app's interface (what every screen already uses).
abstract interface class LeaveBalanceProvider {
  /// Remaining annual leave in days.
  Future<double> remainingDays(String employeeId);
}

// Our existing, clean implementation.
class FirestoreLeaveBalance implements LeaveBalanceProvider {
  @override
  Future<double> remainingDays(String employeeId) async => 12;
}

// A third-party / legacy client we cannot change. Different names, different
// units (hours), different id format.
class LegacyOdooHrClient {
  Future<Map<String, dynamic>> getAllocation({required int empNo}) async =>
      {'emp_no': empNo, 'remaining_hours': 64.0, 'hours_per_day': 8.0};
}

// ---------------------------------------------------------------------------
// BEFORE: the screen calls the legacy client directly and converts units.
// Every screen that needs the balance repeats this.
// ---------------------------------------------------------------------------
Future<String> beforeScreen(LegacyOdooHrClient client, String employeeId) async {
  final raw = await client.getAllocation(empNo: int.parse(employeeId.substring(1)));
  final days = (raw['remaining_hours'] as double) / (raw['hours_per_day'] as double);
  return 'Before → $days days';
}

// ---------------------------------------------------------------------------
// AFTER: an adapter that makes the legacy client look like our interface.
// ---------------------------------------------------------------------------
class OdooLeaveBalanceAdapter implements LeaveBalanceProvider {
  OdooLeaveBalanceAdapter(this._client);

  final LegacyOdooHrClient _client; // wraps (composition), delegates

  @override
  Future<double> remainingDays(String employeeId) async {
    final raw = await _client.getAllocation(empNo: _toEmpNo(employeeId));
    return (raw['remaining_hours'] as double) / (raw['hours_per_day'] as double);
  }

  int _toEmpNo(String id) => int.parse(id.replaceFirst('E', ''));
}

// The screen never knows which backend it talks to.
Future<String> leaveScreen(LeaveBalanceProvider provider) async =>
    'After  → ${await provider.remainingDays('E1001')} days';

Future<void> main() async {
  print(await beforeScreen(LegacyOdooHrClient(), 'E1001'));
  print(await leaveScreen(FirestoreLeaveBalance()));
  print(await leaveScreen(OdooLeaveBalanceAdapter(LegacyOdooHrClient())));
}
