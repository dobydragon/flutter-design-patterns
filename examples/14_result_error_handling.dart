// Result type — errors as values (Flutter docs "Result" pattern)
// Run: dart run 14_result_error_handling.dart
//
// Common today: services throw → Cubit catches → ErrorHandler.handle(e)
// → Failure.
// The Failure classes exist; a Result wrapper is the next step.

class Failure {
  const Failure(this.message);

  final String message;
}

class FakeApi {
  Future<double> fetchSalary(String id) async {
    if (id == 'bad') throw Exception('permission-denied');
    return 9000;
  }
}

// ---------------------------------------------------------------------------
// BEFORE: the signature says "returns double" but it can also throw.
// Forget the try/catch once → crash.
// ---------------------------------------------------------------------------
Future<String> beforeCubit(FakeApi api, String id) async {
  final salary = await api.fetchSalary(id); // nothing forces you to catch
  return 'Before → $salary';
}

// ---------------------------------------------------------------------------
// AFTER: the signature says success OR failure. The compiler makes you
// handle both (sealed + exhaustive switch).
// ---------------------------------------------------------------------------
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

class SalaryRepository {
  SalaryRepository(this._api);

  final FakeApi _api;

  Future<Result<double>> salary(String id) async {
    try {
      return Ok(await _api.fetchSalary(id));
    } catch (e) {
      final denied = e.toString().contains('permission-denied');
      return Err(Failure(denied ? 'You are not allowed to see this salary' : 'Try again'));
    }
  }
}

Future<void> main() async {
  try {
    print(await beforeCubit(FakeApi(), 'bad'));
  } catch (e) {
    print('Before → uncaught: $e');
  }

  final repo = SalaryRepository(FakeApi());
  for (final id in ['e1', 'bad']) {
    final text = switch (await repo.salary(id)) {
      Ok(:final value) => 'After  → salary $value',
      Err(:final failure) => 'After  → ${failure.message}',
    };
    print(text);
  }
}
