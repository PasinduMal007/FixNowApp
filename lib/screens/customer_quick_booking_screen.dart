import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class CustomerQuickBookingScreen extends StatefulWidget {
  final Map<String, dynamic> worker;
  final String categoryName;

  const CustomerQuickBookingScreen({
    super.key,
    required this.worker,
    required this.categoryName,
  });

  @override
  State<CustomerQuickBookingScreen> createState() =>
      _CustomerQuickBookingScreenState();
}

class _CustomerQuickBookingScreenState
    extends State<CustomerQuickBookingScreen> {
  int _currentStep = 0;
  bool _emergencyBooking = false;
  String _selectedDate = 'Today';
  String _selectedTime = '06:00 AM';
  String _paymentMethod = 'cash';
  final _locationController = TextEditingController();
  final _instructionsController = TextEditingController();

  final List<String> _timeSlots = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  int get _completionProgress => _calculateProgress();

  int _calculateProgress() {
    int progress = 0;
    if (_selectedTime.isNotEmpty) progress++;
    if (_selectedDate.isNotEmpty) progress++;
    if (_locationController.text.isNotEmpty) progress++;
    if (_paymentMethod.isNotEmpty) progress++;
    return progress;
  }

  // ✅ worker data getters
  String get _workerName => (widget.worker['name'] ?? 'Worker').toString();
  String get _workerType =>
      (widget.worker['type'] ?? widget.categoryName).toString();

  String get _workerId =>
      (widget.worker['uid'] ?? widget.worker['workerId'] ?? '').toString();

  String get _serviceId =>
      (widget.worker['serviceId'] ?? widget.categoryName).toString();

  String get _serviceName => widget.categoryName;

  double get _workerRating {
    final v = widget.worker['rating'];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int get _workerReviews {
    final v = widget.worker['reviews'];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int get _workerHourlyRate {
    final v = widget.worker['hourlyRate'];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 2500;
    return 2500;
  }

  // ✅ price getters
  double get _platformFee => 500.0;
  double get _baseHourly => _workerHourlyRate.toDouble();
  double get _serviceCharge =>
      _emergencyBooking ? (_baseHourly + 1000.0) : _baseHourly;
  double get _totalAmount => _serviceCharge + _platformFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Service',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Complete your booking details',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft saved!')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.bookmark_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Save Draft',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Worker Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE8F0FF),
                                      Color(0xFFD0E2FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF4A7FFF),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _workerName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: Color(0xFF10B981),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _workerType,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 12,
                                                color: Color(0xFFFBBF24),
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                _workerRating.toStringAsFixed(
                                                  1,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Active 2 mins ago',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Response Time
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Color(0xFF4A7FFF),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Response time ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                '~15 mins',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Spacer(),
                              Text(
                                '450 jobs',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Emergency Booking Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _emergencyBooking
                                ? const Color(0xFFFEE2E2)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _emergencyBooking
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _emergencyBooking
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.flash_on,
                                  color: _emergencyBooking
                                      ? Colors.white
                                      : const Color(0xFF9CA3AF),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Emergency Booking',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Get faster response with priority service +LKR 1,000',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _emergencyBooking
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _emergencyBooking,
                                onChanged: (value) {
                                  setState(() => _emergencyBooking = value);
                                },
                                activeColor: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Select Date
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF4A7FFF),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Date',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildDateChip('Today'),
                            const SizedBox(width: 12),
                            _buildDateChip('Tomorrow'),
                            const SizedBox(width: 12),
                            _buildDateChip(
                              'Pick Date',
                              icon: Icons.calendar_month,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Select Time
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: Color(0xFF4A7FFF),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Time',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _timeSlots
                              .map((time) => _buildTimeChip(time))
                              .toList(),
                        ),
                        const SizedBox(height: 24),

                        // Service Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Color(0xFF4A7FFF),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Service Location',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.gps_fixed, size: 16),
                              label: const Text('Saved'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4A7FFF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _locationController,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Enter complete address with landmarks...',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.send,
                                  color: Color(0xFF4A7FFF),
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Add / Special Instructions
                        OutlinedButton.icon(
                          onPressed: () {
                            _showInstructionsDialog();
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A7FFF),
                            side: const BorderSide(color: Color(0xFF4A7FFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_instructionsController.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.note_outlined,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Special Instructions (Optional)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _instructionsController.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Payment Method
                        Row(
                          children: [
                            const Icon(
                              Icons.payment,
                              size: 18,
                              color: Color(0xFF4A7FFF),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const Text(
                              ' *',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.help_outline,
                              size: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          'cash',
                          'Cash on Completion',
                          'Pay after service',
                          Icons.money,
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentOption(
                          'card',
                          'Credit/Debit Card',
                          '•••• 4532',
                          Icons.credit_card,
                          const Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 24),

                        // Price Summary
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 18,
                              color: Color(0xFF4A7FFF),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Price Summary',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              _buildPriceRow(
                                'Service (2hrs × LKR 2500)',
                                'LKR ${_serviceCharge.toStringAsFixed(0)}',
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _buildPriceRow(
                                'Platform Fee',
                                'LKR ${_platformFee.toStringAsFixed(0)}',
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, thickness: 2),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    'LKR ${_totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4A7FFF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Guarantee
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_user,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '100% Satisfaction Guarantee',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF065F46),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Free cancellation up to 2 hours before service. Full refund if service quality doesn\'t meet expectations.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'I agree to the ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Terms & Conditions',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4A7FFF),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(
                              ' and ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: const Text(
                                'Cancellation Policy',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4A7FFF),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Confirm Button
                        ElevatedButton(
                          onPressed: () async {
                            if (_completionProgress != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please complete all required fields',
                                  ),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
                              return;
                            }

                            try {
                              await _createBooking();

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking requested!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Booking failed: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7FFF),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Confirm Booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createBooking() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');

  final customerId = user.uid;

  if (_workerId.trim().isEmpty) {
    throw Exception('Worker ID is missing (uid not found in worker map).');
  }

  final location = _locationController.text.trim();
  if (location.isEmpty) throw Exception('Location is required');

  final rootRef = DB.ref();

  final bookingRef = rootRef.child('bookings').push();
  final bookingId = bookingRef.key;
  if (bookingId == null) throw Exception('Failed to generate bookingId');

  final scheduledAt = '${_selectedDate.trim()} ${_selectedTime.trim()}';
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  final bookingData = <String, dynamic>{
    'bookingId': bookingId,
    'customerId': customerId,
    'workerId': _workerId.trim(),
    'serviceId': _serviceId.toString(),
    'serviceName': _serviceName.toString(),
    'locationText': location,
    'scheduledAt': scheduledAt,
    'status': 'requested',
    'createdAt': nowMs,
    'updatedAt': nowMs,
  };

  final updates = <String, dynamic>{
    'bookings/$bookingId': bookingData,
    'userBookings/customers/$customerId/$bookingId': true,
    'userBookings/workers/${_workerId.trim()}/$bookingId': true,
  };

  await rootRef.update(updates);
}

  Widget _buildDateChip(String label, {IconData? icon}) {
    final isSelected = _selectedDate == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDate = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A7FFF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4A7FFF)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time) {
    final isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A7FFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A7FFF)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A7FFF)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4A7FFF)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF4A7FFF)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Special Instructions'),
        content: TextField(
          controller: _instructionsController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'E.g., Please bring ladder, call before arrival...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7FFF),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}
