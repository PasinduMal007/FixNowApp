import 'package:flutter/material.dart';

class CustomerStaticViewQuotationScreen extends StatelessWidget {
  final String workerName;
  final String serviceName;
  final double inspectionFee;
  final double laborPrice;
  final double laborHours;
  final double materials;
  final double total;
  final String validUntil;

  const CustomerStaticViewQuotationScreen({
    super.key,
    required this.workerName,
    required this.serviceName,
    required this.inspectionFee,
    required this.laborPrice,
    required this.laborHours,
    required this.materials,
    required this.total,
    this.validUntil = '2026-02-06 19:32:13.635',
  });

  @override
  Widget build(BuildContext context) {
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
                  'Quotation from $workerName',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildReadOnlyField('Service:', serviceName),
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
                    'LKR ${total.toStringAsFixed(0)}',
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
                    child: Text(
                      validUntil,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Notes from worker:',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF0FDF4),
                ),
                child: const Text(
                  'Price may vary based on actual materials needed',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 14),
                ),
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
