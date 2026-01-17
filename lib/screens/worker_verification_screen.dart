import 'dart:io';
import 'package:fix_now_app/Services/worker_onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WorkerVerificationScreen extends StatefulWidget {
  final Function(Map<String, dynamic> verificationData)? onNext;

  const WorkerVerificationScreen({super.key, this.onNext});

  @override
  State<WorkerVerificationScreen> createState() =>
      _WorkerVerificationScreenState();
}

class _WorkerVerificationScreenState extends State<WorkerVerificationScreen> {
  File? _profilePhoto;
  File? _idFrontPhoto;
  File? _idBackPhoto;
  String _idType = 'nic';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfilePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profilePhoto = File(image.path);
      });
    }
  }

  Future<void> _pickIdFrontPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _idFrontPhoto = File(image.path);
      });
    }
  }

  Future<void> _pickIdBackPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _idBackPhoto = File(image.path);
      });
    }
  }

  bool _canProceed() {
    // TEMPORARY: Allow skipping for testing (remove in production)
    return true;
    // Production code: return _profilePhoto != null && _idFrontPhoto != null && _idBackPhoto != null;
  }

  Future<void> _handleNext() async {
    if (!_canProceed()) return;

    try {
      final service = WorkerOnboardingService();

      // Backend only stores flags + idType
      await service.saveVerification(
        idType: _idType,
        hasProfilePhoto: _profilePhoto != null,
        hasIdFront: _idFrontPhoto != null,
        hasIdBack: _idBackPhoto != null,
      );

      if (!mounted) return;
      Navigator.pushNamed(context, '/worker-rates');

      if (widget.onNext != null) {
        widget.onNext!({
          'profilePhoto': _profilePhoto,
          'idFrontPhoto': _idFrontPhoto,
          'idBackPhoto': _idBackPhoto,
          'idType': _idType,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save verification: $e")),
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
            // Progress bar (83%)
            Container(
              height: 4,
              color: const Color(0xFFE5E7EB),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.83,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with shield icon
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
                            Icons.shield_outlined,
                            size: 16,
                            color: Color(0xFF5B8CFF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Verify your identity',
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
                      'This helps us keep FixNow safe and trusted for everyone',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your documents are encrypted and only used for verification. We never share your personal information.',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF1E40AF).withOpacity(0.9),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Profile Photo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile Photo *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C2334),
                          ),
                        ),
                        if (_profilePhoto != null)
                          Row(
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Uploaded',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: _profilePhoto != null
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: _profilePhoto != null
                                ? const Color(0xFF10B981)
                                : const Color(0xFFD1D5DB),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _profilePhoto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _profilePhoto!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.person_outline,
                                    size: 48,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Upload your photo',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1C2334),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Clear selfie, face visible, good lighting',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: Color(0xFF5B8CFF),
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Take a clear selfie with your face fully visible',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ID Type selection
                    const Text(
                      'ID Type *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C2334),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _IdTypeButton(
                            label: 'NIC',
                            isSelected: _idType == 'nic',
                            onTap: () => setState(() => _idType = 'nic'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _IdTypeButton(
                            label: 'Passport',
                            isSelected: _idType == 'passport',
                            onTap: () => setState(() => _idType = 'passport'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _IdTypeButton(
                            label: 'License',
                            isSelected: _idType == 'driving-license',
                            onTap: () =>
                                setState(() => _idType = 'driving-license'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ID Front
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ID Front Side *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C2334),
                          ),
                        ),
                        if (_idFrontPhoto != null)
                          Row(
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Uploaded',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _IdUploadBox(
                      photo: _idFrontPhoto,
                      onTap: _pickIdFrontPhoto,
                      label: 'Upload front side',
                      subtitle: 'All corners visible, no glare',
                    ),
                    const SizedBox(height: 24),

                    // ID Back
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ID Back Side *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C2334),
                          ),
                        ),
                        if (_idBackPhoto != null)
                          Row(
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Uploaded',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _IdUploadBox(
                      photo: _idBackPhoto,
                      onTap: _pickIdBackPhoto,
                      label: 'Upload back side',
                      subtitle: 'All corners visible, no glare',
                    ),
                    const SizedBox(height: 24),

                    // Guidelines
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📸 Photo Guidelines:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _GuidelineItem(
                            icon: '✓',
                            text: 'Ensure all text is readable and clear',
                            isPositive: true,
                          ),
                          _GuidelineItem(
                            icon: '✓',
                            text:
                                'Take photos in good lighting (avoid shadows)',
                            isPositive: true,
                          ),
                          _GuidelineItem(
                            icon: '✓',
                            text: 'Make sure all four corners are visible',
                            isPositive: true,
                          ),
                          _GuidelineItem(
                            icon: '✗',
                            text: 'No glare, blur, or obstructions',
                            isPositive: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
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

// ID Type Button Widget
class _IdTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _IdTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B8CFF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5B8CFF)
                : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ID Upload Box Widget
class _IdUploadBox extends StatelessWidget {
  final File? photo;
  final VoidCallback onTap;
  final String label;
  final String subtitle;

  const _IdUploadBox({
    required this.photo,
    required this.onTap,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: photo != null
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFF9FAFB),
          border: Border.all(
            color: photo != null
                ? const Color(0xFF10B981)
                : const Color(0xFFD1D5DB),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(photo!, fit: BoxFit.contain),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.credit_card,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1C2334),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Guideline Item Widget
class _GuidelineItem extends StatelessWidget {
  final String icon;
  final String text;
  final bool isPositive;

  const _GuidelineItem({
    required this.icon,
    required this.text,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(
              color: isPositive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}
