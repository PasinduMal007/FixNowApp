import 'package:flutter/material.dart';
import 'customer_payment_screen.dart';

class CustomerViewQuotationScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const CustomerViewQuotationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final invoice = booking['invoice'] as Map<String, dynamic>?;
    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF5B8CFF),
          title: const Text('Quotation', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: Text('No quotation found')),
      );
    }

    final workerName = invoice['workerName'] ?? 'Worker';
    final inspectionFee = invoice['inspectionFee'] ?? 0;
    final laborHours = invoice['laborHours'] ?? 0;
    final laborPrice = invoice['laborPrice'] ?? 0;
    final materials = invoice['materials'] ?? 0;
    final subtotal = invoice['subtotal'] ?? 0;
    final notes = invoice['notes'] ?? '';

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
                    // Title
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

                    // Service Info
                    _buildReadOnlyField(
                      'Service:',
                      booking['service'] ?? booking['whatNeeded'] ?? '',
                    ),
                    const SizedBox(height: 12),

                    // Price Breakdown
                    const Text(
                      'Price Breakdown:',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Inspection Fee
                    _buildPriceRow('Inspection fee:', 'LKR $inspectionFee'),
                    const SizedBox(height: 12),

                    // Labor
                    _buildPriceRow(
                      'Labor (est. $laborHours hours):',
                      'LKR $laborPrice',
                    ),
                    const SizedBox(height: 12),

                    // Materials
                    _buildPriceRow('Materials (est.):', 'LKR $materials'),
                    const SizedBox(height: 16),

                    // Divider
                    const Divider(color: Color(0xFF10B981), thickness: 2),
                    const SizedBox(height: 8),

                    // Subtotal
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

                    // Valid Until
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
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xFFF9FAFB),
                          ),
                          child: const Text(
                            '3 days from now',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Notes
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

          // Action Buttons
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
                  // Message Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to chat with worker
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening chat with $workerName...'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
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
                          onPressed: () {
                            // TODO: Decline quote
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quote declined'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                          onPressed: () {
                            // Navigate to payment screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerPaymentScreen(
                                  booking: booking,
                                  totalAmount: subtotal.toDouble(),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
