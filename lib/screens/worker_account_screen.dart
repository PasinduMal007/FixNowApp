import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/Services/backend_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'worker_personal_info_settings_screen.dart';
import 'worker_bank_details_screen.dart';

import 'worker_verification_screen.dart';

class WorkerAccountScreen extends StatefulWidget {
  final ValueChanged<String>? onNameChanged;
  final bool showBackButton;

  const WorkerAccountScreen({
    super.key,
    this.onNameChanged,
    this.showBackButton = true,
  });

  @override
  State<WorkerAccountScreen> createState() => _WorkerAccountScreenState();
}

class _WorkerAccountScreenState extends State<WorkerAccountScreen> {
  bool _notificationsEnabled = true;

  String _workerName = '';
  String _workerEmail = '';
  String _workerPhone = '';
  String _workerLocation = '';
  String _photoUrl = '';
  String _verificationStatus = 'pending_verification';
  double _rating = 4.8;
  int _reviewCount = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final data = await BackendAuthService().loginInfo(expectedRole: 'worker');
      final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};

      final fullName = (profile['fullName'] ?? user.displayName ?? 'Worker')
          .toString();
      final email = (profile['email'] ?? user.email ?? 'email@example.com')
          .toString();

      // If your rules store 9 digits only, format for display
      final phone9 = (profile['phoneNumber'] ?? '').toString().trim();
      final displayPhone = RegExp(r'^\d{9}$').hasMatch(phone9)
          ? '+94 $phone9'
          : '+94 77 123 4567';

      final locationText = (profile['locationText'] ?? 'Colombo, Sri Lanka')
          .toString();

      final photoUrl = (profile['photoUrl'] ?? '').toString().trim();
      final status = (profile['status'] ?? 'pending_verification').toString();

      // Optional: if you later store these:
      final rating = (profile['rating'] is num)
          ? (profile['rating'] as num).toDouble()
          : 4.8;
      final reviewCount = (profile['reviewCount'] is int)
          ? profile['reviewCount'] as int
          : 0;

      if (!mounted) return;
      setState(() {
        _workerName = fullName;
        _workerEmail = email;
        _workerPhone = displayPhone;
        _workerLocation = locationText;
        _photoUrl = photoUrl;
        _verificationStatus = status;
        _rating = rating;
        _reviewCount = reviewCount;
        _loading = false;
      });
      final name = _workerName.trim();
      if (name.isNotEmpty) {
        widget.onNameChanged?.call(name);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _workerName = user.displayName ?? 'Worker';
        _workerEmail = user.email ?? 'email@example.com';
        _workerPhone = '+94 77 123 4567';
        _workerLocation = 'Colombo, Sri Lanka';
        _photoUrl = '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    if (widget.showBackButton)
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (widget.showBackButton)
                      const SizedBox(width: 40, height: 40),
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
                        // Profile Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Avatar and basic info
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFE8F0FF),
                                              Color(0xFFD0E2FF),
                                            ],
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: (_photoUrl.isNotEmpty)
                                            ? Image.network(
                                                _photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) {
                                                  return Center(
                                                    child: Text(
                                                      _workerName.isNotEmpty
                                                          ? _workerName[0]
                                                                .toUpperCase()
                                                          : 'W',
                                                      style: const TextStyle(
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF4A7FFF,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Text(
                                                  _workerName.isNotEmpty
                                                      ? _workerName[0]
                                                            .toUpperCase()
                                                      : 'W',
                                                  style: const TextStyle(
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4A7FFF),
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _workerName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        if (_verificationStatus == 'approved' ||
                                            _verificationStatus ==
                                                'verified') ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            size: 18,
                                            color: Color(0xFF4A7FFF),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Color(0xFFFBBF24),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${_rating}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${_reviewCount} reviews)',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Joined January 2024',
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
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              // Contact info
                              _buildInfoRow(Icons.email_outlined, _workerEmail),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.phone_outlined, _workerPhone),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.location_on_outlined,
                                _workerLocation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Verification Status Section
                        const Text(
                          'Verification Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            // Only allow navigation if rejected
                            if (_verificationStatus == 'rejected') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const WorkerVerificationScreen(),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _verificationStatus == 'rejected'
                                    ? const Color(0xFFEF4444)
                                    : _verificationStatus == 'approved' ||
                                          _verificationStatus == 'verified'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFFBBF24),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _verificationStatus == 'rejected'
                                        ? const Color(0xFFFEE2E2)
                                        : _verificationStatus == 'approved' ||
                                              _verificationStatus == 'verified'
                                        ? const Color(0xFFD1FAE5)
                                        : const Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _verificationStatus == 'rejected'
                                        ? Icons.close
                                        : _verificationStatus == 'approved' ||
                                              _verificationStatus == 'verified'
                                        ? Icons.check
                                        : Icons.access_time_filled,
                                    size: 20,
                                    color: _verificationStatus == 'rejected'
                                        ? const Color(0xFFEF4444)
                                        : _verificationStatus == 'approved' ||
                                              _verificationStatus == 'verified'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFD97706),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _verificationStatus == 'rejected'
                                            ? 'Verification Rejected'
                                            : _verificationStatus ==
                                                      'approved' ||
                                                  _verificationStatus ==
                                                      'verified'
                                            ? 'Account Verified'
                                            : 'Verification Pending',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _verificationStatus == 'rejected'
                                              ? const Color(0xFFEF4444)
                                              : _verificationStatus ==
                                                        'approved' ||
                                                    _verificationStatus ==
                                                        'verified'
                                              ? const Color(0xFF059669)
                                              : const Color(0xFFD97706),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (_verificationStatus == 'rejected')
                                        const Text(
                                          'Tap to re-upload documents',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFEF4444),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else if (_verificationStatus ==
                                              'approved' ||
                                          _verificationStatus == 'verified')
                                        const Text(
                                          'You can now accept bookings',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF059669),
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Admin is reviewing your details',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_verificationStatus == 'rejected')
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF9CA3AF),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Account Settings Section
                        const Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                Icons.person_outline,
                                'Personal Information',
                                onTap: () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const WorkerPersonalInfoSettingsScreen(),
                                    ),
                                  );

                                  if (changed == true) {
                                    await _loadWorkerData(); // reload worker data from backend/RTDB
                                    widget.onNameChanged?.call(
                                      _workerName.trim(),
                                    );
                                  }
                                },
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                Icons.notifications_outlined,
                                'Notifications',
                                trailing: Switch(
                                  value: _notificationsEnabled,
                                  onChanged: (value) => setState(
                                    () => _notificationsEnabled = value,
                                  ),
                                  activeColor: const Color(0xFF4A7FFF),
                                ),
                                onTap: null,
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                Icons.account_balance,
                                'Bank Details',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const WorkerBankDetailsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Preferences Section
                        const Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                Icons.history,
                                'Booking History',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Logout Button
                        ElevatedButton(
                          onPressed: () {
                            _showLogoutDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2),
                            foregroundColor: const Color(0xFFEF4444),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF6B7280)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Close dialog
              Navigator.pop(context);

              // 2. Read saved role (do NOT delete it)
              final prefs = await SharedPreferences.getInstance();
              final role = prefs.getString('selectedRole') ?? 'worker';

              // 3. Firebase sign out
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
                arguments: role,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
