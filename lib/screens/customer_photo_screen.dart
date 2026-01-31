import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/customer_photo_service.dart';
import 'package:fix_now_app/Services/db.dart';

class CustomerPhotoScreen extends StatefulWidget {
  final Function(File? photo)? onNext;

  const CustomerPhotoScreen({super.key, this.onNext});

  @override
  State<CustomerPhotoScreen> createState() => _CustomerPhotoScreenState();
}

class _CustomerPhotoScreenState extends State<CustomerPhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _photo; // local preview
  String? _photoUrl; // uploaded download url
  bool _uploading = false;

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _photo = File(image.path);
    });
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() {
      _photo = File(image.path);
    });
  }

  Future<void> _uploadSelectedPhoto() async {
    if (_photo == null) return;

    setState(() => _uploading = true);

    try {
      final url = await CustomerPhotoService().uploadCustomerProfilePhoto(_photo!);

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
      rethrow;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _setOnboardingStep2AndGoNext({required String nextRoute}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not signed in')),
      );
      return;
    }

    await DB.ref().child('users/customers/$uid').update({
      'onboarding/step': 2,
      'onboarding/updatedAt': ServerValue.timestamp,
    });

    if (!mounted) return;
    Navigator.pushNamed(context, nextRoute);
  }

  Future<void> _handleNext() async {
    try {
      // If a photo is selected, upload it first
      if (_photo != null) {
        await _uploadSelectedPhoto();
      }

      // Then continue onboarding
      await _setOnboardingStep2AndGoNext(nextRoute: '/customer-location-setup');

      if (widget.onNext != null) {
        widget.onNext!(_photo);
      }
    } catch (_) {
      // errors already shown as snackbars
    }
  }

  Future<void> _handleSkip() async {
    try {
      await _setOnboardingStep2AndGoNext(nextRoute: '/customer-service-selection');

      if (widget.onNext != null) {
        widget.onNext!(null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildPhotoCircle() {
    // Priority: local file -> uploaded url -> placeholder
    if (_photo != null) {
      return ClipOval(child: Image.file(_photo!, fit: BoxFit.cover));
    }

    if ((_photoUrl ?? '').isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.person_add_outlined,
              size: 64,
              color: Color(0xFF5B8CFF),
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.person_add_outlined,
      size: 64,
      color: Color(0xFF5B8CFF),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = !_uploading;

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
                    'Step 2 of 3 • Almost done!',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a Profile Photo',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2334),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help workers recognize you when they arrive (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: (_photo != null || (_photoUrl ?? '').isNotEmpty)
                                ? [Colors.transparent, Colors.transparent]
                                : const [Color(0xFFE8F0FF), Color(0xFFF0F6FF)],
                          ),
                          border: Border.all(
                            color: const Color(0xFF5B8CFF),
                            width: 3,
                          ),
                        ),
                        child: _uploading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildPhotoCircle(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploading ? null : _takePhoto,
                            icon: const Icon(Icons.camera_alt, size: 20),
                            label: const Text('Take Photo'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5B8CFF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: Color(0xFF5B8CFF),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _uploading ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library, size: 20),
                            label: const Text('Gallery'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5B8CFF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: Color(0xFF5B8CFF),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: canContinue ? (_photo != null ? _handleNext : _handleSkip) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B8CFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _photo != null ? 'Continue' : 'Skip for now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You can always add a photo later in settings',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
