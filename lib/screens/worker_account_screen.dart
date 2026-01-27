import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkerAccountScreen extends StatefulWidget {
  final String workerName;
  final String email;
  final String phone;
  final String location;
  final double rating;
  final int reviewCount;

  const WorkerAccountScreen({
    super.key,
    this.workerName = 'Michael Rodriguez',
    this.email = 'sarah.johnson@email.com',
    this.phone = '+94 77 123 4567',
    this.location = 'Colombo, Sri Lanka',
    this.rating = 4.8,
    this.reviewCount = 156,
  });

  @override
  State<WorkerAccountScreen> createState() => _WorkerAccountScreenState();
}

class _WorkerAccountScreenState extends State<WorkerAccountScreen> {
  bool _notificationsEnabled = true;

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
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFE8F0FF),
                                              Color(0xFFD0E2FF),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF4A7FFF),
                                          size: 32,
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
                                          widget.workerName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
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
                                              '${widget.rating}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${widget.reviewCount} reviews)',
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
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F0FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF4A7FFF),
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              // Contact info
                              _buildInfoRow(Icons.email_outlined, widget.email),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.phone_outlined, widget.phone),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.location_on_outlined,
                                widget.location,
                              ),
                            ],
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
                                onTap: () {},
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
                                Icons.lock_outline,
                                'Privacy & Security',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                Icons.payment_outlined,
                                'Payment Methods',
                                onTap: () {},
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
                                Icons.favorite_outline,
                                'Favorite Workers',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                Icons.history,
                                'Booking History',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Support Section
                        const Text(
                          'Support',
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
                                Icons.help_outline,
                                'Help Center',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                Icons.description_outlined,
                                'Terms & Conditions',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                Icons.privacy_tip_outlined,
                                'Privacy Policy',
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
