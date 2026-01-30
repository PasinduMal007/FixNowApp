import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/services/db.dart';
import 'package:fix_now_app/services/backend_auth_service.dart';

class CustomerProfileService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  CustomerProfileService({FirebaseAuth? auth, FirebaseDatabase? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? DB.instance;

  Future<String> getCustomerName() async {
    final profile = await BackendAuthService().getCustomerProfile();
    return (profile['fullName'] ?? 'Customer').toString();
  }

  Future<Map<String, dynamic>?> getCustomerProfile({
    required String uid,
  }) async {
    final snap = await _db.ref().child('users/customers/$uid').get();
    if (!snap.exists) return null;

    final val = snap.value;
    if (val is Map) {
      return Map<String, dynamic>.from(val);
    }
    return null;
  }
}
