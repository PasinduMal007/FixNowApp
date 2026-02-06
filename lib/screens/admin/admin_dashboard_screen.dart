import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/screens/login_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:intl/intl.dart';

import 'admin_verification_screen.dart';
import 'admin_earnings_screen.dart';
import '../../Services/mock_data_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  double _commissionForJob(Map<String, dynamic> job) {
    final summary = job['paymentSummary'];
    if (summary is Map && summary['commissionAmount'] is num) {
      return (summary['commissionAmount'] as num).toDouble();
    }

    final advanceAmount = job['advanceAmount'];
    if (advanceAmount is num) {
      return (advanceAmount as num).toDouble() * 0.10;
    }

    final invoice = job['invoice'];
    final subtotal = (invoice is Map && invoice['subtotal'] is num)
        ? (invoice['subtotal'] as num).toDouble()
        : 0.0;

    final total = subtotal > 0
        ? subtotal
        : (double.tryParse(job['total'].toString()) ?? 0.0);

    return total * 0.30 * 0.10;
  }

  @override
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'LKR ',
      decimalDigits: 0,
    );
    final db = DB.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.grey),
            tooltip: 'Seed Mock Data',
            onPressed: () async {
              try {
                // Lazy load mock service
                final mockService = MockDataService();
                await mockService.seedPendingWorkers();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock workers added!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: db
                        .ref('users/workers')
                        .orderByChild('status')
                        .equalTo('pending_verification')
                        .onValue,
                    builder: (context, snapshot) {
                      String count = '0';
                      // ⚠️ TEST MODE: On error, show mock count
                      if (snapshot.hasError) {
                        count = '2 (Mock)';
                      } else if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        final data = snapshot.data!.snapshot.value as Map;
                        count = data.length.toString();
                      }
                      return _buildStatCard(
                        context,
                        title: 'Pending Verifications',
                        value: count,
                        icon: Icons.verified_user,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminVerificationScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: db
                        .ref('bookings')
                        .orderByChild('status')
                        .equalTo('completed')
                        .onValue,
                    builder: (context, snapshot) {
                      double earning = 0.0;
                      if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        try {
                          final data = Map<dynamic, dynamic>.from(
                            snapshot.data!.snapshot.value as Map,
                          );
                          for (var jobVal in data.values) {
                            final job = Map<String, dynamic>.from(
                              jobVal as Map,
                            );
                            earning += _commissionForJob(job);
                          }
                        } catch (_) {}
                      }
                      return _buildStatCard(
                        context,
                        title: 'Total Earnings',
                        value: currencyFormat.format(earning),
                        icon: Icons.attach_money,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminEarningsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Add more admin modules here as needed
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
