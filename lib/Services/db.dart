import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class DB {
  static const String _dbUrl =
      'https://fixnow-app-75722-default-rtdb.asia-southeast1.firebasedatabase.app';

  static FirebaseDatabase? _instance;

  static FirebaseDatabase get instance {
    _instance ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _dbUrl,
    );
    return _instance!;
  }

  static DatabaseReference ref() => instance.ref();
}
