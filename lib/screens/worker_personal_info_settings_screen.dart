import 'package:fix_now_app/Services/backend_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:fix_now_app/Services/worker_photo_service.dart';

class WorkerPersonalInfoSettingsScreen extends StatefulWidget {
  const WorkerPersonalInfoSettingsScreen({super.key});

  @override
  State<WorkerPersonalInfoSettingsScreen> createState() =>
      _WorkerPersonalInfoSettingsScreenState();
}

class _WorkerPersonalInfoSettingsScreenState
    extends State<WorkerPersonalInfoSettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _professionController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _uploadingPhoto = false;
  String _photoUrl = '';
  bool _isEditing = false;
  String _workerName = '';
  String _userInitial = 'W';

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await BackendAuthService().getWorkerProfile();

      final fullName = (profile['fullName'] ?? user.displayName ?? 'Worker')
          .toString();
      final email = (profile['email'] ?? user.email ?? '').toString();
      final phone9 = (profile['phoneNumber'] ?? '').toString(); // 9 digits
      final locationText = (profile['locationText'] ?? '').toString();
      final profession = (profile['profession'] ?? '').toString();
      final aboutMe = (profile['aboutMe'] ?? '').toString();
      final photoUrl = (profile['photoUrl'] ?? '').toString().trim();

      setState(() {
        _workerName = fullName;
        _userInitial = _workerName.isNotEmpty
            ? _workerName[0].toUpperCase()
            : 'W';

        _nameController.text = fullName;
        _emailController.text = email;
        _phoneController.text = phone9;
        _addressController.text = locationText;
        _professionController.text = profession;
        _aboutMeController.text = aboutMe;
        _photoUrl = photoUrl;
      });
    } catch (_) {
      setState(() {
        _workerName = user.displayName ?? 'Worker';
        _userInitial = _workerName.isNotEmpty
            ? _workerName[0].toUpperCase()
            : 'W';
        _nameController.text = _workerName;
        _emailController.text = user.email ?? '';
        _phoneController.text = '';
        _addressController.text = '';
        _professionController.text = '';
        _aboutMeController.text = '';
        _photoUrl = '';
      });
    }
  }

  Future<void> _saveChanges() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final locationText = _addressController.text.trim();
    final profession = _professionController.text.trim();
    final aboutMe = _aboutMeController.text.trim();

    // phone: keep only digits
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    try {
      final updatedProfile = await BackendAuthService().updateWorkerProfile(
        fullName: fullName,
        email: email.isEmpty ? null : email,
        phoneNumber9Digits: phoneDigits.isEmpty ? null : phoneDigits,
        locationText: locationText.isEmpty ? null : locationText,
        profession: profession.isEmpty ? null : profession,
        aboutMe: aboutMe.isEmpty ? null : aboutMe,
      );

      setState(() {
        _isEditing = false;
        _workerName = (updatedProfile['fullName'] ?? fullName).toString();
        _userInitial = _workerName.isNotEmpty
            ? _workerName[0].toUpperCase()
            : 'W';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _changePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final url = await WorkerPhotoService().uploadWorkerProfilePhoto(
        File(picked.path),
      );

      if (!mounted) return;
      setState(() => _photoUrl = url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

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
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Manage your details',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isEditing = !_isEditing);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditing ? Icons.close : Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Photo
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4A7FFF),
                                    Color(0xFF6B9FFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _photoUrl.isNotEmpty
                                  ? Image.network(
                                      _photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) {
                                        return Center(
                                          child: Text(
                                            _userInitial,
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Text(
                                        _userInitial,
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _workerName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Worker Account',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _uploadingPhoto ? null : _changePhoto,
                          child: const Text(
                            'Change Photo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A7FFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Full Name
                        _buildInfoField(
                          label: 'Full Name',
                          controller: _nameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),

                        // Email Address
                        _buildInfoField(
                          label: 'Email Address',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 20),

                        // Phone Number
                        _buildInfoField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 20),

                        // Work Location
                        _buildInfoField(
                          label: 'Work Location',
                          controller: _addressController,
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 20),

                        // Profession
                        _buildInfoField(
                          label: 'Profession',
                          controller: _professionController,
                          icon: Icons.work_outline,
                        ),
                        const SizedBox(height: 20),

                        // About Me
                        _buildInfoField(
                          label: 'About Me',
                          controller: _aboutMeController,
                          icon: Icons.info_outline,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 32),

                        // Privacy Notice
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Your personal information is kept secure and private. We only share necessary details with customers.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1F2937),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button (only visible when editing)
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A7FFF),
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
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

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditing
                  ? const Color(0xFF4A7FFF)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: _isEditing,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _professionController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }
}
