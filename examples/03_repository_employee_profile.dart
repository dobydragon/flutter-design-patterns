// Repository (+ Data Source) — Employee Profile
// Run: dart run 03_repository_employee_profile.dart
//
// A feature repository that combines data sources, placed behind an
// abstract interface so Cubits can be tested with fakes.

// Pretend this is FirebaseFirestore.
class FakeDb {
  final Map<String, Map<String, dynamic>> employees = {
    'e1': {'full_name': 'Sara Ali', 'dept': 'HR', 'salary': 9000},
  };
}

// ---------------------------------------------------------------------------
// BEFORE: the "cubit" talks to the DB, parses maps and applies rules itself.
// ---------------------------------------------------------------------------
class BeforeProfileCubit {
  BeforeProfileCubit(this._db);

  final FakeDb _db;

  String load(String id) {
    final raw = _db.employees[id]; // knows the collection
    if (raw == null) return 'not found';
    final name = raw['full_name'] as String; // knows the field names
    return 'Hello $name';
  }
}

// ---------------------------------------------------------------------------
// AFTER: Model ← DataSource (raw I/O) ← Repository (app-facing API).
// ---------------------------------------------------------------------------
class Employee {
  const Employee({required this.id, required this.name, required this.department});

  final String id;
  final String name;
  final String department;
}

/// Data source: only knows how to talk to one backend. Returns raw data.
class EmployeeRemoteDataSource {
  EmployeeRemoteDataSource(this._db);

  final FakeDb _db;

  Future<Map<String, dynamic>?> fetch(String id) async => _db.employees[id];
}

/// What the rest of the app depends on.
abstract interface class EmployeeRepository {
  Future<Employee?> getEmployee(String id);
}

class FirestoreEmployeeRepository implements EmployeeRepository {
  FirestoreEmployeeRepository(this._remote);

  final EmployeeRemoteDataSource _remote;
  final Map<String, Employee> _cache = {};

  @override
  Future<Employee?> getEmployee(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final raw = await _remote.fetch(id);
    if (raw == null) return null;
    final employee = Employee(
      id: id,
      name: raw['full_name'] as String,
      department: raw['dept'] as String,
    );
    return _cache[id] = employee;
  }
}

/// In tests (or a demo build) swap the whole repository.
class InMemoryEmployeeRepository implements EmployeeRepository {
  @override
  Future<Employee?> getEmployee(String id) async =>
      const Employee(id: 'x', name: 'Test User', department: 'QA');
}

class ProfileCubit {
  ProfileCubit(this._repo);

  final EmployeeRepository _repo;

  Future<String> load(String id) async {
    final e = await _repo.getEmployee(id);
    return e == null ? 'not found' : 'Hello ${e.name} (${e.department})';
  }
}

Future<void> main() async {
  final db = FakeDb();
  print('Before → ${BeforeProfileCubit(db).load('e1')}');

  final repo = FirestoreEmployeeRepository(EmployeeRemoteDataSource(db));
  print('After  → ${await ProfileCubit(repo).load('e1')}');
  print('Test   → ${await ProfileCubit(InMemoryEmployeeRepository()).load('e1')}');
}
