import 'package:flutter/material.dart';
import 'customer_personal_info_settings_screen.dart';
import 'customer_payment_methods_screen.dart';
import 'customer_saved_addresses_screen.dart';
import 'customer_favorite_workers_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fix_now_app/Services/backend_auth_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  final ValueChanged<String>? onNameChanged;

  const CustomerProfileScreen({super.key, this.onNameChanged});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _notificationsEnabled = true;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userLocation = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // This returns profile from RTDB via backend
      final data = await BackendAuthService().loginInfo(
        expectedRole: 'customer',
      );
      final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};

      final fullName = profile['fullName']?.toString().trim();
      final email = profile['email']?.toString().trim();
      final phone9 = profile['phoneNumber']
          ?.toString()
          .trim(); // expected 9 digits
      final locationText = profile['locationText']?.toString().trim();

      // display-friendly phone
      final displayPhone =
          (phone9 != null && RegExp(r'^\d{9}$').hasMatch(phone9))
          ? '+94 $phone9'
          : '+94 77 123 4567';

      setState(() {
        _userName = (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (user.displayName ?? 'Customer');

        _userEmail = (email != null && email.isNotEmpty)
            ? email
            : (user.email ?? 'email@example.com');

        _userPhone = displayPhone;

        _userLocation = (locationText != null && locationText.isNotEmpty)
            ? locationText
            : 'Colombo, Sri Lanka';
      });
      widget.onNameChanged?.call(_userName);
    } catch (_) {
      setState(() {
        _userName = user.displayName ?? 'Customer';
        _userEmail = user.email ?? 'email@example.com';
        _userPhone = '+94 77 123 4567';
        _userLocation = 'Colombo, Sri Lanka';
      });
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
                    const Expanded(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        // User Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Avatar with online indicator
                                  Stack(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFE8F0FF),
                                              Color(0xFFD0E2FF),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF4A7FFF),
                                          size: 36,
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
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Color(0xFFFBBF24),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              '4.8',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              '(135 reviews)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Joined January 2024',
                                              style: TextStyle(
                                                fontSize: 13,
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
                              const SizedBox(height: 16),
                              // Contact Info
                              _buildContactRow(
                                Icons.email_outlined,
                                _userEmail,
                              ),
                              const SizedBox(height: 12),
                              _buildContactRow(
                                Icons.phone_outlined,
                                _userPhone,
                              ),
                              const SizedBox(height: 12),
                              _buildContactRow(
                                Icons.location_on_outlined,
                                _userLocation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Account Settings
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
                              _buildSettingItem(
                                Icons.person_outline,
                                'Personal Information',
                                onTap: () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CustomerPersonalInfoSettingsScreen(),
                                    ),
                                  );

                                  if (changed == true) {
                                    await _loadUserData(); // reload updated details
                                    widget.onNameChanged?.call(
                                      _userName,
                                    ); // notify dashboard (next change)
                                  }
                                },
                              ),

                              const Divider(height: 1),
                              _buildSettingItem(
                                Icons.notifications_outlined,
                                'Notifications',
                                trailing: Switch(
                                  value: _notificationsEnabled,
                                  onChanged: (value) {
                                    setState(
                                      () => _notificationsEnabled = value,
                                    );
                                  },
                                  activeColor: const Color(0xFF4A7FFF),
                                ),
                              ),
                              const Divider(height: 1),
                              _buildSettingItem(
                                Icons.payment_outlined,
                                'Payment Methods',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CustomerPaymentMethodsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Preferences
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
                              _buildSettingItem(
                                Icons.location_on_outlined,
                                'Saved Addresses',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CustomerSavedAddressesScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              _buildSettingItem(
                                Icons.favorite_outline,
                                'Favorite Workers',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CustomerFavoriteWorkersScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

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

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
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

  Widget _buildSettingItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6B7280), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
      ),
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              final role = prefs.getString('selectedRole') ?? 'customer';

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
