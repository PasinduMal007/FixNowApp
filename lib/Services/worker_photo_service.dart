import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fix_now_app/Services/db.dart';

class WorkerPhotoService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;
  final FirebaseStorage _storage;

  WorkerPhotoService({
    FirebaseAuth? auth,
    FirebaseDatabase? db,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? DB.instance,
        _storage = storage ?? FirebaseStorage.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    return user.uid;
  }

  DatabaseReference get _workerRef =>
      _db.ref().child('users').child('workers').child(_uid);

  Future<String> uploadWorkerProfilePhoto(File file) async {
    final uid = _uid;

    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users/workers/$uid/profile/$fileName');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    await _workerRef.update({
      'photoUrl': url,
      'photoUpdatedAt': ServerValue.timestamp,
    });

    return url;
  }

  Future<String> uploadWorkerIdImage({
    required File file,
    required String side, // "front" or "back"
  }) async {
    final uid = _uid;
    final ts = DateTime.now().millisecondsSinceEpoch;

    final fileName = 'id_${side}_$ts.jpg';
    final ref = _storage.ref().child('users/workers/$uid/verification/$fileName');

    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<void> saveVerificationUrls({
    required String idType,
    String? idFrontUrl,
    String? idBackUrl,
  }) async {
    final updates = <String, Object?>{
      'verification/idType': idType,
      'verification/updatedAt': ServerValue.timestamp,
    };
    if (idFrontUrl != null) updates['verification/idFrontUrl'] = idFrontUrl;
    if (idBackUrl != null) updates['verification/idBackUrl'] = idBackUrl;

    await _workerRef.update(updates);
  }
}
