import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class BookingService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  BookingService({FirebaseAuth? auth, FirebaseDatabase? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? DB.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");
    return user.uid;
  }

  Future<String> createBooking({
    required String workerId,
    required String serviceId,
    required String serviceName,
    required String locationText,
    required int scheduledAtMillis,
    String description = "",
    String rateType = "per-hour",
    int estimatedBudget = 0,
  }) async {
    final root = _db.ref();
    final bookingKey = root.child("bookings").push().key;
    if (bookingKey == null) throw Exception("Failed to generate booking id");

    final now = ServerValue.timestamp;

    final bookingData = {
      "bookingId": bookingKey,
      "customerId": _uid,
      "workerId": workerId,
      "serviceId": serviceId,
      "serviceName": serviceName,
      "description": description,
      "locationText": locationText,
      "scheduledAt": scheduledAtMillis,
      "rateType": rateType,
      "estimatedBudget": estimatedBudget,
      "status": "requested",
      "createdAt": now,
      "updatedAt": now,
    };

    // Atomic write to multiple locations
    final updates = <String, Object?>{
      "bookings/$bookingKey": bookingData,
      "userBookings/customers/$_uid/$bookingKey": true,
      "userBookings/workers/$workerId/$bookingKey": true,
    };

    await root.update(updates);

    return bookingKey;
  }

  Future<void> cancelBooking({required String bookingId}) async {
    final ref = _db.ref("bookings/$bookingId");

    // Customer cancellation should only be allowed while status == requested
    await ref.update({
      "status": "cancelled_by_customer",
      "updatedAt": ServerValue.timestamp,
    });
  }
}
