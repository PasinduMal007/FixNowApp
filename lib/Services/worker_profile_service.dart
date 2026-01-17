import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/services/db.dart';

class WorkerProfileService {
  final FirebaseAuth _auth;

  WorkerProfileService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception("Not logged in");
    return u.uid;
  }

  DatabaseReference get _workerRef => DB.ref().child("users/workers/$_uid");

  Future<String> getWorkerName() async {
    final snap = await _workerRef.get();
    if (!snap.exists) return "Worker";

    final data = snap.value;
    if (data is! Map) return "Worker";

    String readKey(String key) => (data[key] ?? "").toString().trim();

    // Try common keys
    final fullName = readKey("fullName");
    if (fullName.isNotEmpty) return fullName;

    final name = readKey("name");
    if (name.isNotEmpty) return name;

    final firstName = readKey("firstName");
    final lastName = readKey("lastName");
    final combined = ("$firstName $lastName").trim();
    if (combined.isNotEmpty) return combined;

    return "Worker";
  }
}
