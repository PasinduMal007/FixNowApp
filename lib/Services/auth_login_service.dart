import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/services/db.dart';

class LoginResult {
  final String uid;
  final String role; // 'customer' or 'worker'
  final Map<dynamic, dynamic> profile;

  LoginResult({
    required this.uid,
    required this.role,
    required this.profile,
  });
}

class AuthLoginService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  AuthLoginService({FirebaseAuth? auth, FirebaseDatabase? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? DB.instance;

  Future<LoginResult> loginWithEmail({
    required String email,
    required String password,
    String? expectedRole, // optional: 'customer' or 'worker'
  }) async {
    // 1) Auth sign in
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = cred.user!.uid;

    // 2) Read profile from RTDB
    final customerSnap = await _db.ref("users/customers/$uid").get();
    if (customerSnap.exists) {
      final profile = (customerSnap.value as Map?) ?? {};
      final role = (profile["role"] as String?) ?? "customer";

      if (expectedRole != null && expectedRole != role) {
        await _auth.signOut();
        throw Exception("This account is not a $expectedRole account.");
      }

      return LoginResult(uid: uid, role: role, profile: profile);
    }

    final workerSnap = await _db.ref("users/workers/$uid").get();
    if (workerSnap.exists) {
      final profile = (workerSnap.value as Map?) ?? {};
      final role = (profile["role"] as String?) ?? "worker";

      if (expectedRole != null && expectedRole != role) {
        await _auth.signOut();
        throw Exception("This account is not a $expectedRole account.");
      }

      return LoginResult(uid: uid, role: role, profile: profile);
    }

    // If user authenticated but no profile exists in DB
    // Decide how you want to handle this:
    // - sign out and show error
    // - or create profile here (not recommended silently)
    await _auth.signOut();
    throw Exception("No user profile found. Please sign up again.");
  }
}
