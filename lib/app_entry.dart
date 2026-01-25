import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/login_screen.dart';
import 'screens/customer_dashboard.dart';
import 'screens/worker_dashboard.dart';

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  Future<String?> _loadRoleFromDatabase(String uid) async {
    try {
      // Check customer profile
      final customerSnap = await FirebaseDatabase.instance
          .ref('users/customers/$uid/role')
          .get();
      
      if (customerSnap.exists && customerSnap.value == 'customer') {
        // Save to SharedPreferences for faster future access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedRole', 'customer');
        return 'customer';
      }

      // Check worker profile
      final workerSnap = await FirebaseDatabase.instance
          .ref('users/workers/$uid/role')
          .get();
      
      if (workerSnap.exists && workerSnap.value == 'worker') {
        // Save to SharedPreferences for faster future access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedRole', 'worker');
        return 'worker';
      }

      return null; // No role found
    } catch (e) {
      debugPrint('Error loading role from database: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Show loading while checking authentication
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle authentication errors
        if (authSnap.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      authSnap.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = authSnap.data;

        // ✅ NOT LOGGED IN → Show Login Screen
        if (user == null) {
          return const LoginScreen();
        }

        // ✅ LOGGED IN → Check role from database
        return FutureBuilder<String?>(
          future: _loadRoleFromDatabase(user.uid),
          builder: (context, roleSnap) {
            // Show loading while fetching role
            if (roleSnap.connectionState != ConnectionState.done) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading profile...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Handle database errors
            if (roleSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Profile',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Could not load your profile. Please try again.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                        child: const Text('Sign Out & Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final role = roleSnap.data;

            // Route to appropriate dashboard based on role
            if (role == 'customer') {
              return const CustomerDashboard();
            } else if (role == 'worker') {
              return const WorkerDashboard();
            }

            // No role found - Account exists but incomplete profile
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Incomplete Profile',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Your account exists but profile setup is incomplete. Please sign out and complete registration.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
