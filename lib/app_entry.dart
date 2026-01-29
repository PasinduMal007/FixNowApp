import 'package:fix_now_app/Services/db.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer_dashboard.dart';
import 'screens/worker_dashboard.dart';
import 'dart:async';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  late final Future<String?> _roleFuture;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _roleFuture = _resolveRole();
  }

  Future<String?> _resolveRole() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedRole');

    if (saved == 'work') return 'worker';
    if (saved == 'hire') return 'customer';

    if (saved == 'customer' || saved == 'worker') return saved;
    return null;
  }

  Future<String?> _getRoleFromDatabase(String uid) async {
    final db = DB.instance;

    final customerRole = await db.ref('users/customers/$uid/role').get();
    if (customerRole.exists && customerRole.value == 'customer')
      return 'customer';

    final workerRole = await db.ref('users/workers/$uid/role').get();
    if (workerRole.exists && workerRole.value == 'worker') return 'worker';

    return null;
  }

  Future<void> _setAuthError(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authError', message);
  }

  Future<void> _clearAuthError() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authError');
  }

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedRole', role);
  }

  void _redirectToLogin({required String role, required String message}) {
    if (_redirecting) return;
    _redirecting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _setAuthError(message);

      // Sign out AFTER saving error (so login screen can read it)
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Clear stack and go login with the role we want the UI to show
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/login', (r) => false, arguments: role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, roleSnap) {
        if (roleSnap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final savedRole = roleSnap.data; // 'customer' | 'worker' | null

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            if (authSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = authSnap.data;

            // NOT LOGGED IN
            if (user == null) {
              if (savedRole == null) {
                return RoleSelectionScreen(
                  onSelectRole: (raw) async {
                    final role = (raw == 'work')
                        ? 'worker'
                        : (raw == 'hire')
                        ? 'customer'
                        : raw;

                    if (role != 'customer' && role != 'worker') return;

                    await _saveRole(role);
                    if (!context.mounted) return;

                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                      arguments: role,
                    );
                  },
                );
              }

              // Role is known -> show login for that role
              return LoginScreen(role: savedRole);
            }

            // LOGGED IN -> verify role from DB safely
            return FutureBuilder<String?>(
              future: _getRoleFromDatabase(
                user.uid,
              ).timeout(const Duration(seconds: 12)),
              builder: (context, dbRoleSnap) {
                if (dbRoleSnap.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (dbRoleSnap.hasError) {
                  final err = dbRoleSnap.error;
                  if (err is TimeoutException &&
                      (savedRole == 'customer' || savedRole == 'worker')) {
                    return savedRole == 'customer'
                        ? const CustomerDashboard()
                        : const WorkerDashboard();
                  }
                  _redirectToLogin(
                    role: savedRole ?? 'customer',
                    message: 'Could not verify account role. Please try again.',
                  );
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final dbRole = dbRoleSnap.data;

                if (dbRole != 'customer' && dbRole != 'worker') {
                  _redirectToLogin(
                    role: savedRole ?? 'customer',
                    message: 'Account profile not found. Please log in again.',
                  );
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // If savedRole exists but differs, force user to the correct role login
                final resolvedRole = dbRole!;

                if (savedRole != null && savedRole != dbRole) {
                  _redirectToLogin(
                    role: resolvedRole,
                    message:
                        'This account is registered as a $dbRole. Please log in as $dbRole.',
                  );
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // Success -> keep prefs clean and save role
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await _clearAuthError();
                  await _saveRole(resolvedRole);
                });

                return dbRole == 'customer'
                    ? const CustomerDashboard()
                    : const WorkerDashboard();
              },
            );
          },
        );
      },
    );
  }
}
