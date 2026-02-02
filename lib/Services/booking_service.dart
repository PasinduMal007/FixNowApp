import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'db.dart';

class BookingService {
  final DatabaseReference _root = DB.ref();

  String _requireUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    return user.uid;
  }

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  /// Customer creates a quotation request (creates booking with status: pending)
  Future<String> createQuotationRequest({
    required String workerId,
    required String workerName,
    required String serviceName,
    required String categoryName,
    required String locationText,
    required String scheduledAt,
    required String problemTitle,
    required String problemDescription,
    required List<String> requestedWorks,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');

    if (workerId.trim().isEmpty) throw Exception('Worker not found');

    final bookingsRef = DB.ref().child('bookings');
    final newRef = bookingsRef.push();
    final bookingId = newRef.key;
    if (bookingId == null) throw Exception('Failed to create booking id');

    // Use client timestamp as number so it passes rules (createdAt/updatedAt areNumber)
    final now = DateTime.now().millisecondsSinceEpoch;

    final booking = <String, dynamic>{
      'bookingId': bookingId,
      'customerId': user.uid,
      'workerId': workerId.trim(),

      // Required fields for rules
      'serviceName': serviceName.trim(),
      'locationText': locationText.trim(),
      'problemDescription': problemDescription.trim(),
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,

      // Extra fields your UI already collects (allowed because rules do not forbid extras)
      'workerName': workerName.trim(),
      'categoryName': categoryName.trim(),
      'scheduledAt': scheduledAt.trim(),
      'problemTitle': problemTitle.trim(),
      'requestedWorks': requestedWorks,

      // Keep a quotationRequest block (optional in rules)
      'quotationRequest': {
        'requestedAt': now,
        'requestNote': problemTitle.trim(),
      },
    };

    // 1) Create booking
    await newRef.set(booking);

    // 2) Index booking under userBookings
    // Customer index: allowed (customer writes to their own node)
    await DB
        .ref()
        .child('userBookings/customers/${user.uid}/$bookingId')
        .set(true);

    // Worker index: DO NOT write from client (will violate rules)
    // Cloud Function will create: userBookings/workers/{workerId}/{bookingId} = true

    // 3) Create a notification for worker (if your app uses notifications)
    // This is optional. If your notifications rules are strict, you may remove this.
    final notifId = DB.ref().child('notifications/$workerId').push().key;
    if (notifId != null) {
      await DB.ref().child('notifications/$workerId/$notifId').set({
        'id': notifId,
        'timestamp': now,
        'isRead': false,
        'type': 'quote_request',
        'title': 'New quotation request',
        'message': 'New request for $serviceName',
        'bookingId': bookingId,
      });
    }

    return bookingId;
  }

  /// Worker confirms request (status -> confirmed)
  Future<void> workerConfirmRequest({required String bookingId}) async {
    final now = _nowMs();
    await _root.child('bookings/$bookingId').update({
      'status': 'confirmed',
      'updatedAt': now,
    });
  }

  Future<void> workerDeclineRequest({required String bookingId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _root.child('bookings/$bookingId').update({
      'status': 'quote_declined', // must match your RTDB rules
      'updatedAt': now,
    });
  }

  /// Worker sends invoice (status -> invoice_sent) and notifies customer
  Future<void> workerSendInvoice({
    required String bookingId,
    required String customerId,
    required String workerId,
    required String workerName,
    required num inspectionFee,
    required num laborHours,
    required num laborPrice,
    required num materials,
    required num subtotal,
    required String notes,
    required int validUntilMs,
  }) async {
    final now = _nowMs();

    final invoiceData = <String, dynamic>{
      'inspectionFee': inspectionFee,
      'laborHours': laborHours,
      'laborPrice': laborPrice,
      'materials': materials,
      'subtotal': subtotal,
      'notes': notes,
      'validUntil': validUntilMs,
      'sentAt': now,
      'workerName': workerName,
      'workerId': workerId,
    };

    await _root.child('bookings/$bookingId').update({
      'invoice': invoiceData,
      'status': 'invoice_sent',
      'updatedAt': now,
    });

    // Notify customer: invoice sent (as required in report) :contentReference[oaicite:1]{index=1}
    await _pushCustomerNotification(
      customerId: customerId,
      data: {
        'type': 'invoice_sent',
        'title': 'New Quotation Received',
        'message': '$workerName sent you a quotation for LKR $subtotal',
        'bookingId': bookingId,
        'timestamp': now,
        'isRead': false,
      },
    );
  }

  /// Customer accepts quote (status -> quote_accepted) and notifies worker :contentReference[oaicite:2]{index=2}
  Future<void> customerAcceptQuote({
    required String bookingId,
    required String workerId,
    required String customerName,
  }) async {
    final now = _nowMs();
    await _root.child('bookings/$bookingId').update({
      'status': 'quote_accepted',
      'updatedAt': now,
    });

    await _pushWorkerNotification(
      workerId: workerId,
      data: {
        'type': 'quote_accepted',
        'title': 'Quote Accepted!',
        'message': '$customerName accepted your quotation',
        'bookingId': bookingId,
        'timestamp': now,
        'isRead': false,
      },
    );
  }

  /// Customer declines quote (status -> quote_declined) and notifies worker :contentReference[oaicite:3]{index=3}
  Future<void> customerDeclineQuote({
    required String bookingId,
    required String workerId,
    required String customerName,
    String? reason,
  }) async {
    final now = _nowMs();

    await _root.child('bookings/$bookingId').update({
      'status': 'quote_declined',
      'updatedAt': now,
      if (reason != null && reason.trim().isNotEmpty)
        'quoteDeclineReason': reason.trim(),
    });

    await _pushWorkerNotification(
      workerId: workerId,
      data: {
        'type': 'quote_declined',
        'title': 'Quote Declined',
        'message': '$customerName declined your quotation',
        'bookingId': bookingId,
        'timestamp': now,
        'isRead': false,
      },
    );
  }

  Future<void> _pushCustomerNotification({
    required String customerId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _root.child('notifications/$customerId').push();
    final id = ref.key;
    await ref.set({'id': id, ...data});
  }

  Future<void> _pushWorkerNotification({
    required String workerId,
    required Map<String, dynamic> data,
  }) async {
    final ref = _root.child('notifications/$workerId').push();
    final id = ref.key;
    await ref.set({'id': id, ...data});
  }
}
