import 'package:flutter/material.dart';
import 'package:fix_now_app/services/db.dart';

import 'customer_review_screen.dart';

class CustomerJobCompletionScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> invoice;
  final double total;

  const CustomerJobCompletionScreen({
    super.key,
    required this.booking,
    required this.invoice,
    required this.total,
  });

  @override
  State<CustomerJobCompletionScreen> createState() =>
      _CustomerJobCompletionScreenState();
}

class _CustomerJobCompletionScreenState
    extends State<CustomerJobCompletionScreen> {
  bool _isLoading = false;

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    try {
      final bookingId = widget.booking['id'] ?? widget.booking['bookingId'];
      if (bookingId != null && bookingId != 'demo_booking_123') {
        // Update booking status to 'completed' or 'paid'
        await DB.instance.ref('bookings/$bookingId').update({
          'status': 'paid',
          'paymentStatus': 'completed',
          'paidAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (mounted) {
        // Navigate to Review Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerReviewScreen(
              booking: widget.booking,
              workerName: widget.invoice['workerName'] ?? 'Worker',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const workerImage = 'https://i.pravatar.cc/150?img=33'; // Placeholder
    final workerName = widget.invoice['workerName'] ?? 'Worker';
    final serviceName = widget.booking['serviceName'] ?? 'Service';

    // Payment breakdown
    final totalAmount = widget.total;
    // Assuming partial payment isn't implemented yet, so paid is 0
    final paidAmount =
        (widget.booking['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = totalAmount - paidAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Job Completion',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified,
                    size: 64,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Service Completed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please complete the payment to finish the job.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Worker Info
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(workerImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            serviceName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildRow('Total Amount', totalAmount),
                  const SizedBox(height: 12),
                  if (paidAmount > 0) ...[
                    _buildRow('Already Paid', -paidAmount, isNegative: true),
                    const SizedBox(height: 12),
                  ],
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildRow(
                    'Remaining to Pay',
                    remainingAmount,
                    isBold: true,
                    isLarge: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7FFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Pay LKR ${remainingAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isBold = false,
    bool isLarge = false,
  }) {
    final amountStr = 'LKR ${amount.abs().toStringAsFixed(0)}';
    final displayAmount = isNegative ? '- $amountStr' : amountStr;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isLarge ? const Color(0xFF1F2937) : Colors.grey[600],
          ),
        ),
        Text(
          displayAmount,
          style: TextStyle(
            fontSize: isLarge ? 20 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isNegative
                ? Colors.red
                : (isLarge ? const Color(0xFF4A7FFF) : const Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }
}
