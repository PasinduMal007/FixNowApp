import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'db.dart';

class QuotationFlowService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  QuotationFlowService({FirebaseAuth? auth, FirebaseDatabase? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? DB.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    return user.uid;
  }

  DatabaseReference get _root => _db.ref();

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  /// CUSTOMER: Create a quotation request (creates booking + quotationRequest)
  Future<String> createQuotationRequest({
    required String workerId,
    required String serviceName,
    required String locationText,
    required String problemDescription,
    String requestNote = '',
  }) async {
    if (workerId.trim().isEmpty) throw Exception('Worker ID is missing');

    final bookingRef = _root.child('bookings').push();
    final bookingId = bookingRef.key;
    if (bookingId == null) throw Exception('Failed to generate booking id');

    final now = _nowMs();

    final bookingData = <String, dynamic>{
      'bookingId': bookingId,
      'customerId': _uid,
      'workerId': workerId.trim(),
      'serviceName': serviceName.trim(),
      'locationText': locationText.trim(),
      'problemDescription': problemDescription.trim(),
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
      'quotationRequest': {
        'requestNote': requestNote.trim(),
        'requestedAt': now,
      },
    };

    final updates = <String, Object?>{
      'bookings/$bookingId': bookingData,
      'userBookings/customers/$_uid/$bookingId': true,
      'userBookings/workers/${workerId.trim()}/$bookingId': true,
    };

    await _root.update(updates);

    await _createNotification(
      userId: workerId.trim(),
      data: {
        'type': 'quote_request',
        'title': 'New quotation request',
        'message': 'You received a new quotation request for $serviceName',
        'bookingId': bookingId,
      },
    );

    return bookingId;
  }

  /// WORKER: Accept request (status -> confirmed)
  Future<void> acceptQuotationRequest({required String bookingId}) async {
    final ref = _root.child('bookings/$bookingId');
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');

    final data = (snap.value as Map?)?.cast<String, dynamic>() ?? {};
    final workerId = (data['workerId'] ?? '').toString();
    if (workerId != _uid) throw Exception('Not authorized for this booking');

    final now = _nowMs();

    await ref.update({'status': 'confirmed', 'updatedAt': now});

    final customerId = (data['customerId'] ?? '').toString();
    if (customerId.isNotEmpty) {
      await _createNotification(
        userId: customerId,
        data: {
          'type': 'quote_request_accepted',
          'title': 'Request accepted',
          'message': 'Worker accepted your quotation request',
          'bookingId': bookingId,
        },
      );
    }
  }

  /// WORKER: Decline request (status -> quote_declined)
  Future<void> declineQuotationRequest({
    required String bookingId,
    String reason = '',
  }) async {
    final ref = _root.child('bookings/$bookingId');
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');

    final data = (snap.value as Map?)?.cast<String, dynamic>() ?? {};
    final workerId = (data['workerId'] ?? '').toString();
    if (workerId != _uid) throw Exception('Not authorized for this booking');

    final now = _nowMs();

    await ref.update({
      'status': 'quote_declined',
      'declineReason': reason.trim(),
      'updatedAt': now,
    });

    final customerId = (data['customerId'] ?? '').toString();
    if (customerId.isNotEmpty) {
      await _createNotification(
        userId: customerId,
        data: {
          'type': 'quote_declined',
          'title': 'Request declined',
          'message': reason.trim().isEmpty
              ? 'Worker declined your request'
              : 'Worker declined: ${reason.trim()}',
          'bookingId': bookingId,
        },
      );
    }
  }

  /// WORKER: Send invoice (invoice saved + status invoice_sent)
  Future<void> sendInvoice({
    required String bookingId,
    required int inspectionFee,
    required double laborHours,
    required int laborPrice,
    required int materials,
    required String notes,
    required int subtotal,
    required int validUntilMillis,
    required String workerName,
  }) async {
    final ref = _root.child('bookings/$bookingId');
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');

    final data = (snap.value as Map?)?.cast<String, dynamic>() ?? {};
    final workerId = (data['workerId'] ?? '').toString();
    if (workerId != _uid) throw Exception('Not authorized for this booking');

    final now = _nowMs();

    await ref.update({
      'invoice': {
        'inspectionFee': inspectionFee,
        'laborHours': laborHours,
        'laborPrice': laborPrice,
        'materials': materials,
        'notes': notes.trim(),
        'subtotal': subtotal,
        'validUntil': validUntilMillis,
        'sentAt': now,
        'workerName': workerName.trim(),
      },
      'status': 'invoice_sent',
      'updatedAt': now,
    });

    final customerId = (data['customerId'] ?? '').toString();
    if (customerId.isNotEmpty) {
      await _createNotification(
        userId: customerId,
        data: {
          'type': 'invoice_sent',
          'title': 'New quotation received',
          'message': '$workerName sent you a quotation for LKR $subtotal',
          'bookingId': bookingId,
        },
      );
    }
  }

  /// CUSTOMER: Accept quote (status -> quote_accepted)
  Future<void> acceptQuote({required String bookingId}) async {
    final ref = _root.child('bookings/$bookingId');
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');

    final data = (snap.value as Map?)?.cast<String, dynamic>() ?? {};
    final customerId = (data['customerId'] ?? '').toString();
    if (customerId != _uid) throw Exception('Not authorized for this booking');

    final now = _nowMs();

    await ref.update({'status': 'quote_accepted', 'updatedAt': now});

    final workerId = (data['workerId'] ?? '').toString();
    final customerName = (data['customerName'] ?? 'Customer').toString();

    if (workerId.isNotEmpty) {
      await _createNotification(
        userId: workerId,
        data: {
          'type': 'quote_accepted',
          'title': 'Quote accepted',
          'message': '$customerName accepted your quotation',
          'bookingId': bookingId,
        },
      );
    }
  }

  /// CUSTOMER: Decline quote (status -> quote_declined)
  Future<void> declineQuote({
    required String bookingId,
    String reason = '',
  }) async {
    final ref = _root.child('bookings/$bookingId');
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');

    final data = (snap.value as Map?)?.cast<String, dynamic>() ?? {};
    final customerId = (data['customerId'] ?? '').toString();
    if (customerId != _uid) throw Exception('Not authorized for this booking');

    final now = _nowMs();

    await ref.update({
      'status': 'quote_declined',
      'quoteDeclineReason': reason.trim(),
      'updatedAt': now,
    });

    final workerId = (data['workerId'] ?? '').toString();
    final customerName = (data['customerName'] ?? 'Customer').toString();

    if (workerId.isNotEmpty) {
      await _createNotification(
        userId: workerId,
        data: {
          'type': 'quote_declined',
          'title': 'Quote declined',
          'message': reason.trim().isEmpty
              ? '$customerName declined your quotation'
              : '$customerName declined: ${reason.trim()}',
          'bookingId': bookingId,
        },
      );
    }
  }

  Future<void> _createNotification({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _root.child('notifications/$userId').push();
    final id = ref.key;
    if (id == null) return;

    final now = _nowMs();

    await ref.set({'id': id, 'timestamp': now, 'isRead': false, ...data});
  }
}
