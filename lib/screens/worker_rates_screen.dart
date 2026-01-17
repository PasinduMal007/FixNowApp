import 'package:fix_now_app/Services/worker_onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkerRatesScreen extends StatefulWidget {
  final String? profession;
  final Function(Map<String, dynamic> ratesData)? onNext;

  const WorkerRatesScreen({super.key, this.profession, this.onNext});

  @override
  State<WorkerRatesScreen> createState() => _WorkerRatesScreenState();
}

class _WorkerRatesScreenState extends State<WorkerRatesScreen> {
  String _rateType = 'per-hour';
  final _baseRateController = TextEditingController();
  final _callOutChargeController = TextEditingController();
  bool _negotiable = true;

  final List<Map<String, dynamic>> _rateTypes = [
    {
      'value': 'per-hour',
      'label': 'Per Hour',
      'icon': Icons.access_time,
      'description': 'Charge by the hour',
    },
    {
      'value': 'per-visit',
      'label': 'Per Visit',
      'icon': Icons.work_outline,
      'description': 'Fixed visit fee',
    },
    {
      'value': 'per-job',
      'label': 'Per Job',
      'icon': Icons.check_circle_outline,
      'description': 'Job-based pricing',
    },
  ];

  @override
  void dispose() {
    _baseRateController.dispose();
    _callOutChargeController.dispose();
    super.dispose();
  }

  // Format number with commas (LKR format)
  String _formatCurrency(String value) {
    final numbers = value.replaceAll(RegExp(r'\D'), '');
    if (numbers.isEmpty) return '';

    final number = int.parse(numbers);
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _handleBaseRateChange(String value) {
    final formatted = _formatCurrency(value);
    _baseRateController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  void _handleCallOutChargeChange(String value) {
    final formatted = _formatCurrency(value);
    _callOutChargeController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  bool _canProceed() {
    final numericBaseRate = _baseRateController.text.isEmpty
        ? 0
        : int.parse(_baseRateController.text.replaceAll(',', ''));
    return numericBaseRate >= 500;
  }

  Future<void> _handleNext() async {
    if (!_canProceed()) return;

    final baseRate = int.parse(_baseRateController.text.replaceAll(',', ''));
    final callOut = _callOutChargeController.text.isEmpty
        ? 0
        : int.parse(_callOutChargeController.text.replaceAll(',', ''));

    try {
      final service = WorkerOnboardingService();
      await service.saveRatesAndComplete(
        rateType: _rateType,
        baseRate: baseRate,
        callOutCharge: callOut,
        negotiable: _negotiable,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/worker-dashboard',
        (route) => false,
      );

      if (widget.onNext != null) {
        widget.onNext!({
          'rateType': _rateType,
          'baseRate': baseRate,
          'negotiable': _negotiable,
          'callOutCharge': callOut,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save rates: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar (100%)
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B8CFF), Color(0xFF4A7FFF)],
                ),
              ),
            ),

            // Back button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF1C2334),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with dollar icon
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F0FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Color(0xFF5B8CFF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Set your rates',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2334),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How much do you charge for your services?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rate Type Selection
                    const Text(
                      'Rate Type *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _rateTypes.map((type) {
                        final isSelected = _rateType == type['value'];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: type == _rateTypes.last ? 0 : 12,
                            ),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _rateType = type['value']),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF5B8CFF)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF5B8CFF)
                                        : const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      type['icon'],
                                      size: 24,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      type['label'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type['description'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.8)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Base Rate Input
                    const Text(
                      'Base Rate *',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _baseRateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _handleBaseRateChange,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF1C2334),
                      ),
                      decoration: InputDecoration(
                        hintText: '2,500',
                        prefixIcon: Container(
                          width: 80,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Text(
                            'LKR',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 22,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF5B8CFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _rateType == 'per-hour'
                          ? 'Amount you charge per hour of work'
                          : _rateType == 'per-visit'
                          ? 'Fixed fee for each service visit'
                          : 'Base price per completed job',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Call-out Charge
                    Row(
                      children: const [
                        Text(
                          'Call-out Charge ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '(Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _callOutChargeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _handleCallOutChargeChange,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF1C2334),
                      ),
                      decoration: InputDecoration(
                        hintText: '500',
                        prefixIcon: Container(
                          width: 80,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16),
                          child: const Text(
                            'LKR',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF5B8CFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Additional fee for traveling to customer location',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 24),

                    // Negotiable Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flash_on,
                            size: 20,
                            color: Color(0xFF5B8CFF),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Open to negotiation',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1C2334),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Rates can be discussed with customers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _negotiable = !_negotiable),
                            child: Container(
                              width: 56,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _negotiable
                                    ? const Color(0xFF5B8CFF)
                                    : const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: AnimatedAlign(
                                alignment: _negotiable
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '💡 Tip: You can adjust your rates anytime from your profile settings. Set competitive rates to attract more customers!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Complete Setup button - Fixed at bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed() ? () => _handleNext() : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8CFF),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Complete Setup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _canProceed()
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
