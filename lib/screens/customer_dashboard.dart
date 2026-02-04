import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/customer_profile_service.dart';
import 'package:flutter/material.dart';
import 'customer_home_screen.dart';

import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_bookings_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _currentIndex = 0;
  int _unreadMessages = 0; // Changed from final to variable

  String _customerName = "Customer";
  bool _loadingName = true;

  late List<Widget> _screens;

  StreamSubscription<DatabaseEvent>? _unreadSub;

  @override
  void initState() {
    super.initState();
    _screens = [
      CustomerHomeScreen(customerName: _customerName),
      const CustomerBookingsScreen(),
      const CustomerMessagesScreen(),
      CustomerProfileScreen(
        onNameChanged: (name) {
          if (!mounted) return;
          setState(() {
            _customerName = name;
            // Update the Home screen in the list if name changes
            _screens[0] = CustomerHomeScreen(customerName: _customerName);
          });
        },
      ),
    ];
    _loadName();
    _listenUnreadBadge();
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  Future<void> _loadName() async {
    try {
      final service = CustomerProfileService();
      final name = await service.getCustomerName();

      if (!mounted) return;
      setState(() {
        _customerName = name.isNotEmpty ? name : 'Customer';
        _screens[0] = CustomerHomeScreen(customerName: _customerName);
        _loadingName = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _customerName = _customerName.isNotEmpty ? _customerName : 'Customer';
        _screens[0] = CustomerHomeScreen(customerName: _customerName);
        _loadingName = false;
      });
    }
  }

  void _listenUnreadBadge() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseDatabase.instance.ref('threadUnread/$uid');

    _unreadSub = ref.onValue.listen(
      (event) {
        final v = event.snapshot.value;

        int total = 0;

        if (v is Map) {
          final m = Map<dynamic, dynamic>.from(v as Map);
          for (final entry in m.entries) {
            final val = entry.value;
            if (val is int) {
              total += val;
            } else if (val is num) {
              total += val.toInt();
            } else if (val is String) {
              total += int.tryParse(val) ?? 0;
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _unreadMessages = total;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _unreadMessages = 0;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingName) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 70,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.calendar_today, 'Bookings', 1),
                    _buildNavItem(
                      Icons.chat_bubble_outline,
                      'Messages',
                      2,
                      badge: _unreadMessages,
                    ),
                    _buildNavItem(Icons.person_outline, 'Profile', 3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {int? badge}) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? const Color(0xFF4A7FFF)
                    : const Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? const Color(0xFF4A7FFF)
                      : const Color(0xFF9CA3AF),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
