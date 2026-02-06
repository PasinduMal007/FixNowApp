import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:flutter/material.dart';
import 'payment_success_screen.dart';

class CustomerPaymentScreen extends StatefulWidget {
  final String bookingId;

  const CustomerPaymentScreen({super.key, required this.bookingId});

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  bool _agreedToTerms = false;
  bool _paying = false;

  Future<void> _startPayHereCheckout({
    required Map<String, dynamic> booking,
    required double advancePayment,
    required double total,
    required double remainingAmount,
  }) async {
    if (_paying) return;
    setState(() => _paying = true);

    try {
      // --- MOCK PAYMENT BYPASS ---
      // Directly mark as paid to unblock testing
      await DB.instance.ref('bookings/${widget.bookingId}').update({
        'status': 'payment_paid',
        'payment_method': 'payhere_mock',
        'payment_id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
        'paid_at': ServerValue.timestamp,
        'advanceAmount': advancePayment,
        'paymentSummary': {
          'totalAmount': total,
          'advanceRate': 0.30,
          'advanceAmount': advancePayment,
          'remainingAmount': remainingAmount,
        },
        'payment': {
          'status': 'paid',
          'method': 'payhere_mock',
          'paidAt': ServerValue.timestamp,
          'amountPaid': advancePayment,
          'advanceRate': 0.30,
          'advanceAmount': advancePayment,
          'totalAmount': total,
          'remainingAmount': remainingAmount,
        },
      });

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(amountPaid: advancePayment),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mock Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = DB.instance.ref('bookings/${widget.bookingId}');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF5B8CFF),
              title: const Text(
                'Payment',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: Center(child: Text('Failed: ${snap.error}')),
          );
        }

        if (!snap.hasData || snap.data!.snapshot.value == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final raw = snap.data!.snapshot.value;
        if (raw is! Map) {
          return const Scaffold(body: Center(child: Text('Invalid booking')));
        }

        final booking = Map<String, dynamic>.from(raw as Map);

        final invoiceRaw = booking['invoice'];
        final invoice = invoiceRaw is Map
            ? Map<String, dynamic>.from(invoiceRaw)
            : null;

        final total = (invoice?['subtotal'] is num)
            ? (invoice!['subtotal'] as num).toDouble()
            : 0.0;

        final advancePayment = (total * 0.30).roundToDouble();
        final completionPayment = total.roundToDouble() - advancePayment;

        return _buildPaymentScaffold(
          context: context,
          booking: booking,
          total: total,
          advancePayment: advancePayment,
          completionPayment: completionPayment,
        );
      },
    );
  }

  Widget _buildPaymentScaffold({
    required BuildContext context,
    required Map<String, dynamic> booking,
    required double total,
    required double advancePayment,
    required double completionPayment,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B8CFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Breakdown Card
                  Container(
                    width: double.infinity,
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
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Color(0xFFFBBF24),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Payment Breakdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildPriceRow(
                          'Service (quoted):',
                          'LKR ${total.toStringAsFixed(0)}',
                          isSubdued: true,
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                          'Total:',
                          'LKR ${total.toStringAsFixed(0)}',
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                          'Advance (30%):',
                          'LKR ${advancePayment.toStringAsFixed(0)}',
                          isSubdued: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Payment Split:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pay Now (30% Advance)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4A7FFF),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A7FFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pay Now (30% Advance)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LKR ${advancePayment.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A7FFF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Via: PayHere',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pay on Completion (Cash)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pay on Completion (Cash)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LKR ${completionPayment.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Give to worker after work',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Safe & Secure Payment
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) => setState(() {
                            _agreedToTerms = value ?? false;
                          }),
                          activeColor: const Color(0xFF10B981),
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safe & Secure Payment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your advance is held safely until worker completes the job',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Bottom Pay Button
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_agreedToTerms && !_paying && total > 0)
                      ? () => _startPayHereCheckout(
                          booking: booking,
                          advancePayment: advancePayment,
                          total: total,
                          remainingAmount: completionPayment,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4A7FFF),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _paying
                            ? 'Starting...'
                            : 'Pay LKR ${advancePayment.toStringAsFixed(0)} Now',
                        style: TextStyle(
                          color: _agreedToTerms
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: _agreedToTerms
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String price, {
    bool isBold = false,
    bool isSubdued = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isSubdued
                ? const Color(0xFF6B7280)
                : const Color(0xFF1F2937),
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
