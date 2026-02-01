import 'package:flutter/material.dart';
import 'package:fix_now_app/Services/db.dart';

class WorkerCreateInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic> job;

  const WorkerCreateInvoiceScreen({super.key, required this.job});

  @override
  State<WorkerCreateInvoiceScreen> createState() =>
      _WorkerCreateInvoiceScreenState();
}

class _WorkerCreateInvoiceScreenState extends State<WorkerCreateInvoiceScreen> {
  final _inspectionController = TextEditingController(text: '500');
  final _laborHoursController = TextEditingController(text: '2');
  final _laborPriceController = TextEditingController(text: '2000');
  final _materialsController = TextEditingController(text: '1000');
  final _notesController = TextEditingController(
    text: 'Price may vary based on actual materials needed',
  );

  double get subtotal {
    final inspection = double.tryParse(_inspectionController.text) ?? 0;
    final labor = double.tryParse(_laborPriceController.text) ?? 0;
    final materials = double.tryParse(_materialsController.text) ?? 0;
    return inspection + labor + materials;
  }

  @override
  void dispose() {
    _inspectionController.dispose();
    _laborHoursController.dispose();
    _laborPriceController.dispose();
    _materialsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.job['customerName'] ?? 'Customer';
    final request = widget.job['whatNeeded'] ?? widget.job['service'] ?? '';
    final description = widget.job['description'] ?? widget.job['issue'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B8CFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Invoice',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
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
                  'Invoice for $customerName',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Customer Info
              _buildReadOnlyField('Customer:', customerName),
              const SizedBox(height: 12),
              _buildReadOnlyField('Request:', request),
              const SizedBox(height: 12),

              // Service Description
              const Text(
                'Service Description:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '"$description"',
                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
              ),
              const SizedBox(height: 24),

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
              _buildEditableField(
                'Inspection fee:',
                _inspectionController,
                prefix: 'LKR',
              ),
              const SizedBox(height: 12),

              // Labor
              Row(
                children: [
                  const Text(
                    'Labor (est. ',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  SizedBox(
                    width: 30,
                    child: TextField(
                      controller: _laborHoursController,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const Text(
                    ' hours):',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  const Spacer(),
                  const Text(
                    'LKR ',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _laborPriceController,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF10B981),
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Materials
              _buildEditableField(
                'Materials (est.):',
                _materialsController,
                prefix: 'LKR',
              ),
              const SizedBox(height: 16),

              // Divider
              const Divider(color: Color(0xFF10B981), thickness: 2),
              const SizedBox(height: 8),

              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal:',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'LKR ${subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
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
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes for customer:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF0FDF4),
                ),
                child: TextField(
                  controller: _notesController,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Save draft
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Draft saved'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: Color(0xFF6B7280),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Draft',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
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
                        // Save invoice to Firebase
                        final bookingId = widget.job['id'];
                        if (bookingId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error: Booking ID not found'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          // Save invoice data
                          await DB
                              .ref()
                              .child('bookings/$bookingId/invoice')
                              .set({
                                'inspectionFee':
                                    double.tryParse(
                                      _inspectionController.text,
                                    ) ??
                                    0,
                                'laborHours':
                                    double.tryParse(
                                      _laborHoursController.text,
                                    ) ??
                                    0,
                                'laborPrice':
                                    double.tryParse(
                                      _laborPriceController.text,
                                    ) ??
                                    0,
                                'materials':
                                    double.tryParse(
                                      _materialsController.text,
                                    ) ??
                                    0,
                                'subtotal': subtotal,
                                'notes': _notesController.text,
                                'validUntil': DateTime.now()
                                    .add(const Duration(days: 3))
                                    .millisecondsSinceEpoch,
                                'sentAt': DateTime.now().millisecondsSinceEpoch,
                                'workerName':
                                    widget.job['workerName'] ?? 'Worker',
                              });

                          // Update booking status
                          await DB.ref().child('bookings/$bookingId').update({
                            'status': 'invoice_sent',
                            'updatedAt': DateTime.now().millisecondsSinceEpoch,
                          });

                          // TODO: Add notification for customer

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invoice sent to customer'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error sending invoice: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
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
                        'Send Invoice',
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

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    String prefix = '',
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const Spacer(),
        if (prefix.isNotEmpty)
          Text(
            '$prefix ',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 14,
              decoration: TextDecoration.underline,
              decorationColor: Color(0xFF10B981),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }
}
