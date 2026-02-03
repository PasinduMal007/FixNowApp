import 'package:flutter/material.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  bool _loading = true;
  bool _savingDraft = false;
  bool _sending = false;

  // Booking UI fields
  String _customerName = 'Customer';
  String _request = '';
  String _description = '';

  String get _bookingId {
    final v = widget.job['id'] ?? widget.job['bookingId'] ?? '';
    return v.toString().trim();
  }

  DatabaseReference get _bookingRef => DB.ref().child('bookings/$_bookingId');

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return <String, dynamic>{};
  }

  String _pickFirstNonEmpty(List<String> values, {required String fallback}) {
    for (final s in values) {
      final t = s.trim();
      if (t.isNotEmpty) return t;
    }
    return fallback;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  double get subtotal {
    final inspection = double.tryParse(_inspectionController.text) ?? 0;
    final hours = double.tryParse(_laborHoursController.text) ?? 0;
    final pricePerHour = double.tryParse(_laborPriceController.text) ?? 0;
    final materials = double.tryParse(_materialsController.text) ?? 0;
    return inspection + (hours * pricePerHour) + materials;
  }

  @override
  void initState() {
    super.initState();
    _loadBookingAndInvoice();
  }

  Future<void> _loadBookingAndInvoice() async {
    final bookingId = _bookingId;
    if (bookingId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snap = await _bookingRef.get();
      if (!snap.exists || snap.value == null) {
        setState(() => _loading = false);
        return;
      }

      final booking = _asMap(snap.value);

      // Support old + new shapes (same idea as job details screen)
      final quotationRequest = _asMap(booking['quotationRequest']);
      final quoteRequest = _asMap(booking['quoteRequest']);

      _customerName =
          (booking['customerName'] ?? booking['customer'] ?? 'Customer')
              .toString();

      _request = _pickFirstNonEmpty([
        (booking['serviceName'] ?? '').toString(),
        (booking['serviceType'] ?? '').toString(),
        (booking['service'] ?? '').toString(),
        (quotationRequest['serviceName'] ?? '').toString(),
        (quoteRequest['title'] ?? '').toString(),
      ], fallback: '');

      _description = _pickFirstNonEmpty([
        (booking['problemDescription'] ?? '').toString(),
        (quotationRequest['requestNote'] ?? '').toString(),
        (quoteRequest['description'] ?? '').toString(),
        (booking['issue'] ?? '').toString(),
        (booking['description'] ?? '').toString(),
      ], fallback: '');

      // Prefer final invoice if exists; otherwise draft
      final invoice = (booking['invoice'] is Map)
          ? Map<String, dynamic>.from(booking['invoice'] as Map)
          : null;

      final invoiceDraft = (booking['invoiceDraft'] is Map)
          ? Map<String, dynamic>.from(booking['invoiceDraft'] as Map)
          : null;

      final used = invoice ?? invoiceDraft;

      if (used != null) {
        _inspectionController.text = _toDouble(
          used['inspectionFee'],
        ).toStringAsFixed(0);
        _laborHoursController.text = _toDouble(
          used['laborHours'],
        ).toStringAsFixed(0);
        _laborPriceController.text = _toDouble(
          used['laborPrice'],
        ).toStringAsFixed(0);
        _materialsController.text = _toDouble(
          used['materials'],
        ).toStringAsFixed(0);

        final notes = (used['notes'] ?? '').toString();
        if (notes.trim().isNotEmpty) _notesController.text = notes;
      }
    } catch (_) {
      // ignore and show UI
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _invoicePayload() {
    final inspection = double.tryParse(_inspectionController.text) ?? 0;
    final laborHours = double.tryParse(_laborHoursController.text) ?? 0;
    final laborPrice = double.tryParse(_laborPriceController.text) ?? 0;
    final materials = double.tryParse(_materialsController.text) ?? 0;

    return {
      'inspectionFee': inspection,
      'laborHours': laborHours,
      'laborPrice': laborPrice,
      'materials': materials,
      'subtotal': inspection + (laborHours * laborPrice) + materials,
      'notes': _notesController.text.trim(),
      'validDays': 3,
    };
  }

  Future<void> _saveDraft() async {
    if (_savingDraft) return;

    final bookingId = _bookingId;
    if (bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Booking ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _savingDraft = true);

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      );
      final callable = functions.httpsCallable('saveInvoiceDraft');

      await callable.call({'bookingId': bookingId, ..._invoicePayload()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to save draft'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _sendQuotation() async {
    if (_sending) return;

    final bookingId = _bookingId;
    if (bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Booking ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      );
      final callable = functions.httpsCallable('sendInvoice');

      final res = await callable.call({
        'bookingId': bookingId,
        ..._invoicePayload(),
      });

      final subtotalReturned = (res.data is Map)
          ? (res.data['subtotal'])
          : null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subtotalReturned != null
                ? 'Quotation sent. Total: LKR $subtotalReturned'
                : 'Quotation sent to customer',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to send quotation'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending quotation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
    if (_loading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
              Center(
                child: Text(
                  'Invoice for $_customerName',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildReadOnlyField('Customer:', _customerName),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                'Request:',
                _request.isEmpty ? '-' : _request,
              ),
              const SizedBox(height: 12),

              const Text(
                'Service Description:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _description.trim().isEmpty ? '"-"' : '"$_description"',
                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
              ),
              const SizedBox(height: 24),

              const Text(
                'Price Breakdown:',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              _buildEditableField(
                'Inspection fee:',
                _inspectionController,
                prefix: 'LKR',
              ),
              const SizedBox(height: 12),

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

              _buildEditableField(
                'Materials (est.):',
                _materialsController,
                prefix: 'LKR',
              ),
              const SizedBox(height: 16),

              const Divider(color: Color(0xFF10B981), thickness: 2),
              const SizedBox(height: 8),

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

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _savingDraft ? null : _saveDraft,
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
                      child: Text(
                        _savingDraft ? 'Saving...' : 'Save Draft',
                        style: const TextStyle(
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
                      onPressed: _sending ? null : _sendQuotation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _sending ? 'Sending...' : 'Send Quotation',
                        style: const TextStyle(
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
