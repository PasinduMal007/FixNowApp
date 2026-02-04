import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fix_now_app/Services/db.dart';
import 'customer_payment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/Services/chat_service.dart';
import 'customer_chat_conversation_screen.dart';

class CustomerViewQuotationScreen extends StatelessWidget {
  final String bookingId;

  const CustomerViewQuotationScreen({super.key, required this.bookingId});

  static final ChatService _chat = ChatService();

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return 0;
  }

  num _asNum(dynamic v) {
    if (v is num) return v;
    return 0;
  }

  Future<void> _updateStatus(String status) async {
    final ref = DB.instance.ref('bookings/$bookingId');

    await ref.update({'status': status, 'updatedAt': ServerValue.timestamp});
  }

  Future<void> _declineQuote(BuildContext context) async {
    try {
      await _updateStatus('quote_declined');
      if (context.mounted) Navigator.pop(context); // back to home
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to decline quote: $e')));
    }
  }

  Future<void> _acceptQuote(
    BuildContext context,
    Map<String, dynamic> booking,
    num subtotal,
  ) async {
    try {
      await _updateStatus('quote_accepted');

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerPaymentScreen(bookingId: bookingId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept quote: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookingId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF5B8CFF),
          title: const Text('Quotation', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text('Missing booking id')),
      );
    }

    final ref = DB.instance.ref('bookings/$bookingId');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF5B8CFF),
              title: const Text(
                'Quotation',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Center(
              child: Text(
                'Failed to load quotation: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF5B8CFF),
              title: const Text(
                'Quotation',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final raw = snap.data!.snapshot.value;
        if (raw is! Map) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF5B8CFF),
              title: const Text(
                'Quotation',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: const Center(child: Text('Invalid booking data')),
          );
        }

        final booking = Map<String, dynamic>.from(raw as Map);

        final invoiceRaw = booking['invoice'];
        final invoice = (invoiceRaw is Map)
            ? Map<String, dynamic>.from(invoiceRaw as Map)
            : null;

        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF5B8CFF),
              title: const Text(
                'Quotation',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: const Center(child: Text('No quotation found')),
          );
        }

        final workerName = (invoice['workerName'] ?? 'Worker').toString();

        final inspectionFee = _asNum(invoice['inspectionFee']);
        final laborHours = _asNum(invoice['laborHours']);
        final laborPrice = _asNum(invoice['laborPrice']);
        final materials = _asNum(invoice['materials']);
        final subtotal = _asNum(invoice['subtotal']);
        final notes = (invoice['notes'] ?? '').toString();

        final serviceTitle =
            (booking['serviceName'] ?? booking['service'] ?? '').toString();

        // Optional: compute "valid until" if you store it
        final validUntilMs = _asInt(invoice['validUntil']);
        final validUntilText = validUntilMs > 0
            ? DateTime.fromMillisecondsSinceEpoch(validUntilMs).toString()
            : '3 days from now';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF5B8CFF),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Quotation from $workerName',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Quotation from $workerName',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildReadOnlyField('Service:', serviceTitle),
                        const SizedBox(height: 12),

                        const Text(
                          'Price Breakdown:',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildPriceRow(
                          'Inspection fee:',
                          'LKR ${inspectionFee.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 12),

                        _buildPriceRow(
                          'Labor (est. ${laborHours.toStringAsFixed(0)} hours):',
                          'LKR ${laborPrice.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 12),

                        _buildPriceRow(
                          'Materials (est.):',
                          'LKR ${materials.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 16),

                        const Divider(color: Color(0xFF10B981), thickness: 2),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LKR ${subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            const Text(
                              'Valid until: ',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFFF9FAFB),
                              ),
                              child: Text(
                                validUntilText,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        if (notes.isNotEmpty) ...[
                          const Text(
                            'Notes from worker:',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFF0FDF4),
                            ),
                            child: Text(
                              notes,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final chat = ChatService();
                            final db = DB.instance;

                            try {
                              final workerId = (booking['workerId'] ?? '')
                                  .toString()
                                  .trim();
                              if (workerId.isEmpty) {
                                throw Exception('Missing workerId');
                              }

                              // Resolve worker name from workersPublic
                              String workerNameResolved = workerName;
                              final wsnap = await db
                                  .ref('workersPublic/$workerId/fullName')
                                  .get();
                              if (wsnap.exists && wsnap.value is String) {
                                final n = (wsnap.value as String).trim();
                                if (n.isNotEmpty) workerNameResolved = n;
                              }

                              final customerName =
                                  (booking['customerName'] ?? 'Customer')
                                      .toString()
                                      .trim();

                              final threadId = await chat.createOrGetThread(
                                otherUid: workerId,
                                myRole: 'customer',
                                otherRole: 'worker',
                                otherName: workerNameResolved,
                                myName: customerName.isNotEmpty
                                    ? customerName
                                    : 'Customer',
                              );

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerChatConversationScreen(
                                        threadId: threadId,
                                        otherUid: workerId,
                                        otherName: workerNameResolved,
                                      ),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Message failed: $e')),
                              );
                            }
                          },

                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Message Worker'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFF4A7FFF),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await _declineQuote(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _acceptQuote(context, booking, subtotal);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Accept and Book',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        Text(
          price,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
