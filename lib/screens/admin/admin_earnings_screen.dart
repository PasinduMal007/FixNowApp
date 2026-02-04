import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:intl/intl.dart';

class AdminEarningsScreen extends StatefulWidget {
  const AdminEarningsScreen({super.key});

  @override
  State<AdminEarningsScreen> createState() => _AdminEarningsScreenState();
}

class _AdminEarningsScreenState extends State<AdminEarningsScreen> {
  final _db = DB.instance;
  final _currencyFormat = NumberFormat.currency(
    symbol: 'LKR ',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Platform Earnings',
          style: TextStyle(color: Color(0xFF1F2937)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: StreamBuilder<DatabaseEvent>(
        // Query COMPLETED jobs to calculate commission
        stream: _db
            .ref('bookings')
            .orderByChild('status')
            .equalTo('completed')
            .onValue,
        builder: (context, snapshot) {
          // ⚠️ TEST MODE: On error, show mock data
          if (snapshot.hasError) {
            final jobs = [
              {
                'id': 'job1',
                'total': 5000,
                'service': 'Plumbing Repair',
                'scheduledDate': '2024-02-04',
              },
              {
                'id': 'job2',
                'total': 3500,
                'service': 'AC Service',
                'scheduledDate': '2024-02-03',
              },
            ];
            double totalCommission = 850.0; // Mock total

            return Column(
              children: [
                // Summary Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Text(
                        'Total Commission Earned (Mock)',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currencyFormat.format(totalCommission),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Transaction List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final total = double.parse(job['total'].toString());
                      final commission = total * 0.10;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE8F0FF),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color(0xFF4A7FFF),
                            ),
                          ),
                          title: Text(
                            job['service'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Job Total: ${_currencyFormat.format(total)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Commission',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                _currencyFormat.format(commission),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('No completed jobs yet'));
          }

          final data = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final jobs = data.entries.map((e) {
            final m = Map<String, dynamic>.from(e.value as Map);
            return {'id': e.key, ...m};
          }).toList();

          // Sort by date (newest first)
          jobs.sort((a, b) {
            final da = DateTime.parse(a['scheduledDate'] ?? '2000-01-01');
            final db = DateTime.parse(b['scheduledDate'] ?? '2000-01-01');
            return db.compareTo(da);
          });

          // Calculate Total Commission (e.g., 10%)
          double totalCommission = 0;
          for (var job in jobs) {
            final total = double.tryParse(job['total'].toString()) ?? 0;
            totalCommission += (total * 0.10); // 10% commission
          }

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  children: [
                    const Text(
                      'Total Commission Earned',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFormat.format(totalCommission),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Transaction List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final total = double.tryParse(job['total'].toString()) ?? 0;
                    final commission = total * 0.10;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F0FF),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF4A7FFF),
                          ),
                        ),
                        title: Text(
                          job['service'] ?? 'Service',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Job Total: ${_currencyFormat.format(total)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Commission',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              _currencyFormat.format(commission),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
