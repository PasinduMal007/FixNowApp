import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer_dashboard.dart';
import 'screens/worker_dashboard.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  late final Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _resolveRole();
  }

  Future<String?> _resolveRole() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selectedRole');

    // Normalize if you accidentally stored "work/hire"
    if (saved == 'work') return 'worker';
    if (saved == 'hire') return 'customer';

    return saved; // 'worker' | 'customer' | null
  }

  Future<String?> _loadRoleFromDatabaseAndSave(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    // If customer profile exists -> customer
    final customerSnap =
        await FirebaseDatabase.instance.ref('users/customers/$uid/role').get();
    if (customerSnap.exists && customerSnap.value == 'customer') {
      await prefs.setString('selectedRole', 'customer');
      return 'customer';
    }

    // If worker profile exists -> worker
    final workerSnap =
        await FirebaseDatabase.instance.ref('users/workers/$uid/role').get();
    if (workerSnap.exists && workerSnap.value == 'worker') {
      await prefs.setString('selectedRole', 'worker');
      return 'worker';
    }

    return null;
  }

  Future<void> _saveRoleAndGoLogin(BuildContext context, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedRole', role);

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, roleSnap) {
        if (!roleSnap.hasData && roleSnap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final savedRole = roleSnap.data; // 'worker' | 'customer' | null

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnap) {
            if (authSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final user = authSnap.data;

            // 1) Not logged in
            if (user == null) {
              // No role saved -> show role selection (first launch)
              if (savedRole == null) {
                return RoleSelectionScreen(
                  onSelectRole: (raw) {
                    // raw could be 'hire'/'work' or already 'customer'/'worker'
                    final role = (raw == 'work')
                        ? 'worker'
                        : (raw == 'hire')
                            ? 'customer'
                            : raw;

                    _saveRoleAndGoLogin(context, role);
                  },
                );
              }

              // Role saved -> show login for that role
              return LoginScreen(role: savedRole);
            }

            // 2) Logged in
            // If role already saved -> go dashboard
            if (savedRole == 'customer') return const CustomerDashboard();
            if (savedRole == 'worker') return const WorkerDashboard();

            // Role missing but user logged in -> derive role from DB and then show correct screen
            return FutureBuilder<String?>(
              future: _loadRoleFromDatabaseAndSave(user.uid),
              builder: (context, dbRoleSnap) {
                if (dbRoleSnap.connectionState != ConnectionState.done) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                final dbRole = dbRoleSnap.data;
                if (dbRole == 'customer') return const CustomerDashboard();
                if (dbRole == 'worker') return const WorkerDashboard();

                // Could not determine role -> fallback to role selection
                return RoleSelectionScreen(
                  onSelectRole: (raw) {
                    final role = (raw == 'work')
                        ? 'worker'
                        : (raw == 'hire')
                            ? 'customer'
                            : raw;

                    _saveRoleAndGoLogin(context, role);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
