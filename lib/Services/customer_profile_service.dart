import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/services/db.dart';

class CustomerProfileService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  CustomerProfileService({FirebaseAuth? auth, FirebaseDatabase? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? DB.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    return user.uid;
  }

  DatabaseReference get _customerRef => DB.ref().child("users/customers/$_uid");

  Future<String> getCustomerName() async {
    final snap = await _customerRef.get();
    if (!snap.exists) return "Customer";

    final data = snap.value;
    if (data is! Map) return "Customer";

    String readKey(String key) => (data[key] ?? "").toString().trim();

    // Try common possibilities
    final fullName = readKey("fullName");
    if (fullName.isNotEmpty) return fullName;

    final name = readKey("name");
    if (name.isNotEmpty) return name;

    final firstName = readKey("firstName");
    final lastName = readKey("lastName");
    final combined = ("$firstName $lastName").trim();
    if (combined.isNotEmpty) return combined;

    return "Customer";
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
