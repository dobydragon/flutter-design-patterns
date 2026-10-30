// Singleton — Local Storage
// Run: dart run 01_singleton_local_storage.dart
//
// Typical Flutter shapes: a SharedPreferences wrapper (CacheHelper) and a
// NetworkManager.instance that is still injectable in tests.

// ---------------------------------------------------------------------------
// BEFORE: every screen creates its own storage object.
// ---------------------------------------------------------------------------
class BeforeLocalStorage {
  BeforeLocalStorage() {
    print('BeforeLocalStorage created (loading prefs from disk...)');
  }

  final Map<String, String> _data = {};

  void save(String key, String value) => _data[key] = value;
  String? read(String key) => _data[key];
}

void beforeDemo() {
  BeforeLocalStorage().save('token', 'abc'); // login screen
  final token = BeforeLocalStorage().read('token'); // home screen
  print('Before → token on home screen: $token'); // null! different object
}

// ---------------------------------------------------------------------------
// AFTER (A): strict Singleton — private constructor, one static instance.
// ---------------------------------------------------------------------------
class LocalStorage {
  LocalStorage._() {
    print('LocalStorage created once');
  }

  static final LocalStorage instance = LocalStorage._();

  final Map<String, String> _data = {};

  void save(String key, String value) => _data[key] = value;
  String? read(String key) => _data[key];
}

// ---------------------------------------------------------------------------
// AFTER (B): "soft singleton" — public constructor (tests can make a fresh
// one) + a shared default instance that is handed out through DI.
// This is a common shape for a NetworkManager.
// ---------------------------------------------------------------------------
abstract interface class KeyValueStore {
  void save(String key, String value);
  String? read(String key);
}

class PrefsStore implements KeyValueStore {
  PrefsStore();

  static final PrefsStore instance = PrefsStore();

  final Map<String, String> _data = {};

  @override
  void save(String key, String value) => _data[key] = value;

  @override
  String? read(String key) => _data[key];
}

class SessionCubitLike {
  SessionCubitLike(this._store); // depends on the interface, not on .instance

  final KeyValueStore _store;

  bool get isLoggedIn => _store.read('token') != null;
}

void main() {
  beforeDemo();

  LocalStorage.instance.save('token', 'abc');
  print('After  → token on home screen: ${LocalStorage.instance.read('token')}');
  print('Same object? ${identical(LocalStorage.instance, LocalStorage.instance)}');

  // Production: pass the shared instance.
  final prod = SessionCubitLike(PrefsStore.instance);
  // Test: pass a fresh, isolated store — no shared global state between tests.
  final test = SessionCubitLike(PrefsStore());
  PrefsStore.instance.save('token', 'abc');
  print('prod logged in: ${prod.isLoggedIn}, test logged in: ${test.isLoggedIn}');
}
