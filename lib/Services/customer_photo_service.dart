import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class CustomerPhotoService {
  final FirebaseStorage _storage;
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  CustomerPhotoService({
    FirebaseStorage? storage,
    FirebaseDatabase? db,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _db = db ?? DB.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    return user.uid;
  }

  Future<String> uploadCustomerProfilePhoto(File file) async {
    final uid = _uid;

    // Make filename unique to avoid stale cached image
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = _storage.ref().child('users/customers/$uid/$fileName');

    await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await storageRef.getDownloadURL();

    // IMPORTANT: user node must already contain uid/role/createdAt (rules require)
    final customerRef = _db.ref().child('users').child('customers').child(uid);

    await customerRef.update({
      'photoUrl': url,
      // optional but useful for debugging and refreshing
      'photoUpdatedAt': ServerValue.timestamp,
    });

    return url;
  }
}
