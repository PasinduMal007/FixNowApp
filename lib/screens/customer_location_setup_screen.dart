import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/backend_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/Services/db.dart';

class CustomerLocationSetupScreen extends StatefulWidget {
  final Function(String location)? onNext;

  const CustomerLocationSetupScreen({super.key, this.onNext});

  @override
  State<CustomerLocationSetupScreen> createState() =>
      _CustomerLocationSetupScreenState();
}

class _CustomerLocationSetupScreenState
    extends State<CustomerLocationSetupScreen> {
  final _locationController = TextEditingController();
  bool _hasLocation = false;
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
    _locationController.dispose();
    super.dispose();
  }

  void _useGPS() {
    // TODO: Implement GPS location fetching
    // For now, just set a placeholder
    setState(() {
      _locationController.text = 'Current Location (Via GPS)';
      _hasLocation = true;
    });
  }

  bool _canProceed() {
    return _locationController.text.trim().isNotEmpty &&
        (_selectedDistrict != null && _selectedDistrict!.trim().isNotEmpty);
  }

  Future<void> _handleComplete() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not signed in');
      }

      final authSvc = BackendAuthService();
      await authSvc.ensureCustomerProfile();

      // Always write to RTDB directly (like worker profile screen flow)
      final customerRef = DB.instance.ref('users/customers/${user.uid}');
      final snap = await customerRef.get();

      final current = snap.value is Map ? (snap.value as Map) : {};
      final currentUid = (current['uid'] ?? '').toString();
      final currentRole = (current['role'] ?? '').toString();
      final currentCreatedAt = current['createdAt'];

      final baseUpdates = <String, dynamic>{
        'locationText': location,
        // Ensure required fields exist for validation
        'uid': currentUid.isNotEmpty ? currentUid : user.uid,
        'role': currentRole.isNotEmpty ? currentRole : 'customer',
        'createdAt':
            currentCreatedAt is num ? currentCreatedAt : ServerValue.timestamp,
      };

      // Save location first so it doesn't get blocked by district rule issues
      await customerRef.update(baseUpdates);

      // Save district separately (only if selected)
      if (_selectedDistrict != null) {
        await customerRef.update({'district': _selectedDistrict});
      }

      // Best-effort backend sync (non-blocking)
      try {
        await authSvc.updateCustomerLocation(
          locationText: location,
          district: _selectedDistrict,
        );
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to FixNow! Let\'s find you a professional.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),

        ),
      );

      widget.onNext?.call(location);

      Navigator.pushReplacementNamed(context, '/customer-dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
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

            // Back button and step indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Text(
                    'Step 3 of 3 • Final step!',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
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
                    // Title
                    const Text(
                      'Where are you located?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2334),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We\'ll connect you with the best professionals in your area',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Background check reassurance
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.verified_user,
                            size: 18,
                            color: Color(0xFF5B8CFF),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'All workers are background-checked and verified ✓',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1C2334),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Location Input
                    const Text(
                      'Your Location',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Enter your address',
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
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
                        const SizedBox(width: 8),
                        // GPS button
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B8CFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _useGPS,
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Use GPS',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'We\'ll show you nearby workers when you search for services',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 16),

                    // District dropdown
                    const Text(
                      'District',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
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
                    const SizedBox(height: 32),

                    // What happens next
                    const Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1C2334),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _NextStepItem(
                      number: '1',
                      icon: Icons.search,
                      color: Color(0xFF10B981),
                      title: 'Browse Services',
                      description:
                          'Search for plumbers, electricians, cleaners, and more',
                    ),
                    const SizedBox(height: 12),
                    _NextStepItem(
                      number: '2',
                      icon: Icons.people_outline,
                      color: Color(0xFF5B8CFF),
                      title: 'Find Workers',
                      description:
                          'View profiles, ratings, and reviews from your area',
                    ),
                    const SizedBox(height: 12),
                    _NextStepItem(
                      number: '3',
                      icon: Icons.event_available,
                      color: Color(0xFFF59E0B),
                      title: 'Book & Pay',
                      description:
                          'Schedule services and pay securely through the app',
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
                  onPressed: _canProceed() ? () => _handleComplete() : null,
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

// Next Step Item Widget
class _NextStepItem extends StatelessWidget {
  final String number;
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _NextStepItem({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C2334),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
