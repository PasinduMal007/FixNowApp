import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fix_now_app/services/worker_onboarding_service.dart';

class WorkerProfileScreen extends StatefulWidget {
  final Function(Map<String, String> profileData)? onNext;

  const WorkerProfileScreen({super.key, this.onNext});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedDistrict;

  static const List<String> _districts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // Format mobile number as XX XXX XXXX
  String _formatMobileNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length <= 2) return digits;
    if (digits.length <= 5)
      return '${digits.substring(0, 2)} ${digits.substring(2)}';
    if (digits.length <= 9) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 9)}';
  }

  // Check if user is at least 18 years old
  bool _isValidAge() {
    if (_selectedDate == null) return false;
    final today = DateTime.now();
    final age = today.year - _selectedDate!.year;
    final monthDiff = today.month - _selectedDate!.month;
    if (monthDiff < 0 || (monthDiff == 0 && today.day < _selectedDate!.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  bool _canProceed() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _mobileController.text.replaceAll(RegExp(r'\D'), '').length == 9 &&
        _isValidAge();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5B8CFF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C2334),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleNext() async {
    if (!_canProceed()) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone9 = _mobileController.text.replaceAll(RegExp(r'\D'), '');
    final dobIso = _selectedDate!.toIso8601String();

    try {
      final service = WorkerOnboardingService();
      await service.saveProfileDetails(
        firstName: firstName,
        lastName: lastName,
        mobileNumber9Digits: phone9,
        dateOfBirthIso: dobIso,
        district: _selectedDistrict,
      );

      if (!mounted) return;
      Navigator.pushNamed(context, '/worker-verification');

      if (widget.onNext != null) {
        widget.onNext!({
          'firstName': firstName,
          'lastName': lastName,
          'mobileNumber': phone9,
          'dateOfBirth': dobIso,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save profile: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar (66%)
            Container(
              height: 4,
              color: const Color(0xFFE5E7EB),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.66,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B8CFF), Color(0xFF4A7FFF)],
                    ),
                  ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Tell us about yourself',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2334),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Help us verify your identity and contact you',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9CA3AF),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // First Name
                      const Text(
                        'First Name *',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _firstNameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Enter your first name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            size: 20,
                            color: Color(0xFF9CA3AF),
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
                      const SizedBox(height: 20),

                      // Last Name
                      const Text(
                        'Last Name *',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _lastNameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Enter your last name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            size: 20,
                            color: Color(0xFF9CA3AF),
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
                      const SizedBox(height: 20),

                      // Mobile Number
                      const Text(
                        'Mobile Number *',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Country code
                          Container(
                            width: 70,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '+94',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Phone number
                          Expanded(
                            child: TextField(
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(9),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _mobileController.value = TextEditingValue(
                                    text: _formatMobileNumber(value),
                                    selection: TextSelection.collapsed(
                                      offset: _formatMobileNumber(value).length,
                                    ),
                                  );
                                });
                              },
                              decoration: InputDecoration(
                                hintText: '77 123 4567',
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                  color: Color(0xFF9CA3AF),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your mobile number',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date of Birth
                      const Text(
                        'Date of Birth *',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate == null
                                    ? 'Select date of birth'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDate == null
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF1C2334),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // District
                      const Text(
                        'District',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        items: _districts
                            .map(
                              (d) => DropdownMenuItem<String>(
                                value: d,
                                child: Text(d),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedDistrict = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Select your district',
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),

            // Next button - Fixed at bottom
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
                    'Next',
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
