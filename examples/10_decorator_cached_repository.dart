// Decorator — add caching + logging to a repository without editing it
// Run: dart run 10_decorator_cached_repository.dart
//
// Widget wrappers like
// PushNotificationListener(child: ...) are the Flutter-composition cousin.

abstract interface class DashboardStatsRepository {
  Future<int> activeEmployees(String companyId);
}

class RemoteDashboardStatsRepository implements DashboardStatsRepository {
  int calls = 0;

  @override
  Future<int> activeEmployees(String companyId) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 20)); // network
    return 42;
  }
}

// ---------------------------------------------------------------------------
// BEFORE: caching + logging pasted inside the remote class (or in each cubit).
// Every new concern makes the class bigger; you can't turn one off.
// ---------------------------------------------------------------------------
class BeforeStatsRepository {
  final Map<String, int> _cache = {};

  Future<int> activeEmployees(String companyId) async {
    print('[log] activeEmployees($companyId)');
    final hit = _cache[companyId];
    if (hit != null) return hit;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _cache[companyId] = 42;
  }
}

// ---------------------------------------------------------------------------
// AFTER: each concern is a wrapper with the SAME interface.
// ---------------------------------------------------------------------------
class CachedStatsRepository implements DashboardStatsRepository {
  CachedStatsRepository(this._inner);

  final DashboardStatsRepository _inner;
  final Map<String, int> _cache = {};

  @override
  Future<int> activeEmployees(String companyId) async =>
      _cache[companyId] ??= await _inner.activeEmployees(companyId);
}

class LoggingStatsRepository implements DashboardStatsRepository {
  LoggingStatsRepository(this._inner);

  final DashboardStatsRepository _inner;

  @override
  Future<int> activeEmployees(String companyId) async {
    final sw = Stopwatch()..start();
    final result = await _inner.activeEmployees(companyId);
    print('[log] activeEmployees($companyId) = $result in ${sw.elapsedMilliseconds}ms');
    return result;
  }
}

Future<void> main() async {
  await BeforeStatsRepository().activeEmployees('acme');

  final remote = RemoteDashboardStatsRepository();
  // Stack them in any order; the cubit only sees DashboardStatsRepository.
  final DashboardStatsRepository repo = LoggingStatsRepository(CachedStatsRepository(remote));
  await repo.activeEmployees('acme');
  await repo.activeEmployees('acme'); // served from cache, much faster
  print('Remote was called ${remote.calls} time(s)');
}
