import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class WorkerOnboardingService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  WorkerOnboardingService({FirebaseAuth? auth, FirebaseDatabase? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? DB.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    return user.uid;
  }

  DatabaseReference get _workerRef => _db.ref().child("users/workers/$_uid");

  // ✅ Public profile node for customer browsing
  DatabaseReference get _workerPublicRef =>
      _db.ref().child("workersPublic/$_uid");

  Future<void> ensureBaseProfile() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

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

    // Optional: create public node skeleton (safe fields only)
    await _workerPublicRef.update({
      "uid": _uid,
      "updatedAt": ServerValue.timestamp,
    });
  }

  // ✅ Keeps workersPublic in sync with what the customer app needs
  Future<void> _syncPublicProfile({
    String? fullName,
    String? profession,
    int? hourlyRate,
    bool? isAvailable,
    String? locationText,
    String? experience,
    String? description,
    String? district,
  }) async {
    final updates = <String, Object?>{
      "uid": _uid,
      "updatedAt": ServerValue.timestamp,
    };

    if (fullName != null) updates["fullName"] = fullName;
    if (profession != null) updates["profession"] = profession;
    if (hourlyRate != null) updates["hourlyRate"] = hourlyRate;
    if (isAvailable != null) updates["isAvailable"] = isAvailable;
    if (locationText != null) updates["locationText"] = locationText;
    if (experience != null) updates["experience"] = experience;
    if (description != null) updates["description"] = description;
    if (district != null) updates["district"] = district;

    // Optional defaults for the UI if you want
    updates.putIfAbsent("rating", () => 0);
    updates.putIfAbsent("reviews", () => 0);

    await _workerPublicRef.update(updates);
  }

  Future<void> saveProfession(String profession) async {
    await ensureBaseProfile();

    final p = profession.trim();

    await _workerRef.update({
      "profession": p,
      "onboarding/step": 1,
      "onboarding/updatedAt": ServerValue.timestamp,
    });

    await _syncPublicProfile(profession: p);
  }

  Future<void> saveExperience(String experienceValue) async {
    await ensureBaseProfile();

    await _workerRef.update({
      "experience": experienceValue,
      "onboarding/step": 2,
      "onboarding/updatedAt": ServerValue.timestamp,
    });

    await _syncPublicProfile(experience: experienceValue);

    // No public change needed here unless you want to expose experience publicly
  }

  Future<void> saveProfileDetails({
    required String firstName,
    required String lastName,
    required String mobileNumber9Digits,
    required String dateOfBirthIso,
    String? district,
  }) async {
    await ensureBaseProfile();

    final f = firstName.trim();
    final l = lastName.trim();
    final fullName = "$f $l".trim();

    await _workerRef.update({
      "firstName": f,
      "lastName": l,
      "fullName": fullName, // ✅ helpful for dashboards + queries
      "phoneNumber": mobileNumber9Digits,
      "dateOfBirth": dateOfBirthIso,
      if (district != null) "district": district,
      "onboarding/step": 3,
      "onboarding/updatedAt": ServerValue.timestamp,
    });

    await _syncPublicProfile(fullName: fullName, district: district);
  }

  Future<void> saveLocationText(String locationText) async {
    await ensureBaseProfile();

    final loc = locationText.trim();

    await _workerRef.update({
      "locationText": loc,
      "onboarding/updatedAt": ServerValue.timestamp,
    });

    await _syncPublicProfile(locationText: loc);
  }

  Future<void> saveDescription(String description) async {
    await ensureBaseProfile();

    final desc = description.trim();

    await _workerRef.update({
      "description": desc,
      "onboarding/updatedAt": ServerValue.timestamp,
    });

    await _syncPublicProfile(description: desc);
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
      "status": "pending_verification", // Reset status so admin sees it again
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

    // Your UI uses hourlyRate, so publish a good value here.
    // If rateType is not per-hour, you can still show baseRate as a displayed price.
    final hourlyRate = baseRate;

    await _workerRef.update({
      "rates/rateType": rateType,
      "rates/baseRate": baseRate,
      "rates/callOutCharge": callOutCharge,
      "rates/negotiable": negotiable,
      "onboarding/step": 5,
      "onboarding/completed": true,
      "onboarding/updatedAt": ServerValue.timestamp,
    });

    // ✅ Publish to workersPublic so customers can see pricing
    await _syncPublicProfile(
      hourlyRate: hourlyRate,
      isAvailable: true, // change based on your logic
    );
  }
}
