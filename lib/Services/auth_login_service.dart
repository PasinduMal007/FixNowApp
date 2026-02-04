import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/Services/backend_auth_service.dart';

class LoginResult {
  final String uid;
  final String role; // 'customer' or 'worker'
  final Map<String, dynamic> profile;

  LoginResult({required this.uid, required this.role, required this.profile});
}

class AuthLoginService {
  final FirebaseAuth _auth;

  AuthLoginService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  Future<LoginResult> loginWithEmail({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw Exception('Login failed. Please try again.');
    }

    try {
      final data = await BackendAuthService().loginInfo(
        expectedRole: expectedRole,
      );

      final role = (data['role'] as String?) ?? 'customer';
      final profile =
          (data['profile'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      return LoginResult(uid: user.uid, role: role, profile: profile);
    } catch (e) {
      // ⚠️ FALLBACK: If login failed, it often means Role Mismatch (e.g. Admin logs in as Customer).
      // We try fetching info *without* asserting a role. If that returns 'admin', we allow it.
      try {
        final fallbackData = await BackendAuthService().loginInfo(
          expectedRole: null,
        );
        final actualRole = fallbackData['role'] as String?;
        if (actualRole == 'admin') {
          return LoginResult(
            uid: user.uid,
            role: 'admin',
            profile:
                (fallbackData['profile'] as Map?)?.cast<String, dynamic>() ??
                {},
          );
        }
      } catch (_) {
        // Fallback also failed, ignore it
      }

      await _auth.signOut();
      rethrow;
    }
  }
}
