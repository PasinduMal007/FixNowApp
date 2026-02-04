import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/worker_profile_service.dart';
import 'package:flutter/material.dart';
import 'worker_home_screen.dart';
import 'worker_bookings_screen.dart';
import 'worker_chat_screen.dart';
import 'worker_account_screen.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _currentIndex = 0;
  int _unreadMessages = 0;

  String _workerName = "Worker";
  bool _loadingName = true;

  StreamSubscription<DatabaseEvent>? _unreadSub;
  StreamSubscription<User?>? _authSub;

  List<Widget> get _screens => [
    WorkerHomeScreen(workerName: _workerName, unreadMessages: _unreadMessages),
    const WorkerBookingsScreen(),
    const WorkerChatScreen(showBackButton: false),
    WorkerAccountScreen(
      onNameChanged: (name) {
        if (!mounted) return;
        setState(() => _workerName = name);
      },
      showBackButton: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadName();
    _listenUnreadBadge();
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadName() async {
    try {
      final service = WorkerProfileService();
      final name = await service.getWorkerName();

      if (!mounted) return;
      setState(() {
        _workerName = name.isNotEmpty ? name : 'Worker';
        _loadingName = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingName = false);
    }
  }

  void _listenUnreadBadge() {
    _authSub?.cancel();
    _unreadSub?.cancel();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _unreadSub?.cancel();

      final uid = user?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() => _unreadMessages = 0);
        return;
      }

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
    });
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
              top: 0,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
