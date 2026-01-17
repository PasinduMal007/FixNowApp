import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class WorkerOnboardingService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  WorkerOnboardingService({FirebaseAuth? auth, FirebaseDatabase? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = DB.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    return user.uid;
  }

  DatabaseReference get _workerRef => _db.ref().child("users/workers/$_uid");

  Future<void> ensureBaseProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    // Do not overwrite if it already exists
    await _workerRef.runTransaction((current) {
      if (current != null) return Transaction.success(current);

      return Transaction.success({
        "uid": user.uid,
        "email": user.email,
        "role": "worker",
        "status": "pending_verification",
        "createdAt": ServerValue.timestamp,
        "onboarding": {
          "step": 0,
          "completed": false,
          "updatedAt": ServerValue.timestamp,
        },
      });
    });
  }

  Future<void> saveProfession(String profession) async {
    await ensureBaseProfile();
    await _workerRef.update({
      "profession": profession.trim(),
      "onboarding/step": 1,
      "onboarding/updatedAt": ServerValue.timestamp,
    });
  }

  Future<void> saveExperience(String experienceValue) async {
    await ensureBaseProfile();
    await _workerRef.update({
      "experience": experienceValue,
      "onboarding/step": 2,
      "onboarding/updatedAt": ServerValue.timestamp,
    });
  }

  Future<void> saveProfileDetails({
    required String firstName,
    required String lastName,
    required String mobileNumber9Digits,
    required String dateOfBirthIso,
  }) async {
    await ensureBaseProfile();

    await _workerRef.update({
      "firstName": firstName.trim(),
      "lastName": lastName.trim(),
      "phoneNumber": mobileNumber9Digits,
      "dateOfBirth": dateOfBirthIso,
      "onboarding/step": 3,
      "onboarding/updatedAt": ServerValue.timestamp,
    });
  }

  Future<void> saveVerification({
    required String idType,
    bool hasProfilePhoto = false,
    bool hasIdFront = false,
    bool hasIdBack = false,
  }) async {
    await ensureBaseProfile();

    await _workerRef.update({
      "idType": idType,

      // Flags only — no files
      "verification": {
        "profilePhotoPending": hasProfilePhoto,
        "idFrontPending": hasIdFront,
        "idBackPending": hasIdBack,
      },

      "onboarding/step": 4,
      "onboarding/updatedAt": ServerValue.timestamp,
    });
  }

  Future<void> saveRatesAndComplete({
    required String rateType,
    required int baseRate,
    required int callOutCharge,
    required bool negotiable,
  }) async {
    await ensureBaseProfile();

    await _workerRef.update({
      "rates/rateType": rateType,
      "rates/baseRate": baseRate,
      "rates/callOutCharge": callOutCharge,
      "rates/negotiable": negotiable,
      "onboarding/step": 5,
      "onboarding/completed": true,
      "onboarding/updatedAt": ServerValue.timestamp,
    });
  }
}
