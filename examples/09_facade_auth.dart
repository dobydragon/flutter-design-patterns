// Facade — Authentication
// Run: dart run 09_facade_auth.dart
//
// Typical Flutter AuthService rule:
// "UI must never import firebase_auth directly".

// Pretend these are three separate SDKs.
class FakeFirebaseAuth {
  Future<String> signInWithEmailAndPassword(String email, String password) async {
    if (password.length < 6) throw Exception('[firebase_auth/wrong-password]');
    return 'uid-123';
  }
}

class FakeFcm {
  Future<String> getToken() async => 'fcm-token-xyz';
}

class FakeFirestore {
  final Map<String, Map<String, Object>> docs = {};

  Future<void> set(String path, Map<String, Object> data) async => docs[path] = data;
}

// ---------------------------------------------------------------------------
// BEFORE: the login screen orchestrates 3 SDKs + error codes itself.
// ---------------------------------------------------------------------------
Future<String> beforeLoginScreen(String email, String password) async {
  final auth = FakeFirebaseAuth();
  final fcm = FakeFcm();
  final db = FakeFirestore();
  try {
    final uid = await auth.signInWithEmailAndPassword(email.trim(), password);
    final token = await fcm.getToken();
    await db.set('users/$uid/fcmTokens/$token', {'createdAt': 'now'});
    return 'Before → signed in $uid';
  } catch (e) {
    return e.toString().contains('wrong-password') ? 'Wrong password' : 'Error';
  }
}

// ---------------------------------------------------------------------------
// AFTER: one simple entry point; the UI knows nothing about the SDKs.
// ---------------------------------------------------------------------------
sealed class SignInResult {}

class SignedIn extends SignInResult {
  SignedIn(this.uid);

  final String uid;
}

class SignInFailed extends SignInResult {
  SignInFailed(this.message);

  final String message;
}

class AuthFacade {
  AuthFacade({FakeFirebaseAuth? auth, FakeFcm? fcm, FakeFirestore? db})
      : _auth = auth ?? FakeFirebaseAuth(),
        _fcm = fcm ?? FakeFcm(),
        _db = db ?? FakeFirestore();

  final FakeFirebaseAuth _auth;
  final FakeFcm _fcm;
  final FakeFirestore _db;

  Future<SignInResult> signIn(String email, String password) async {
    try {
      final uid = await _auth.signInWithEmailAndPassword(email.trim(), password);
      await _registerPushToken(uid);
      return SignedIn(uid);
    } catch (e) {
      return SignInFailed(_mapError(e));
    }
  }

  Future<void> _registerPushToken(String uid) async {
    final token = await _fcm.getToken();
    await _db.set('users/$uid/fcmTokens/$token', {'createdAt': 'now'});
  }

  String _mapError(Object e) =>
      e.toString().contains('wrong-password') ? 'Wrong password' : 'Something went wrong';
}

Future<void> main() async {
  print(await beforeLoginScreen('a@acme.com', 'secret1'));

  final auth = AuthFacade();
  for (final pass in ['secret1', '123']) {
    final result = await auth.signIn('a@acme.com', pass);
    print(switch (result) {
      SignedIn(:final uid) => 'After  → signed in $uid',
      SignInFailed(:final message) => 'After  → $message',
    });
  }
}
