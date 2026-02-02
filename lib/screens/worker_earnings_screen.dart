import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:intl/intl.dart';
import 'worker_bank_details_screen.dart';
import 'dart:async';

class WorkerEarningsScreen extends StatefulWidget {
  const WorkerEarningsScreen({super.key});

  @override
  State<WorkerEarningsScreen> createState() => _WorkerEarningsScreenState();
}

class _WorkerEarningsScreenState extends State<WorkerEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _subscription;
  bool _isLoading = true;

  List<Map<String, dynamic>> _earnings = [];

  double _totalEarnings = 0.0;

  String get _workerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<DatabaseEvent> get _workerBookingIdsStream {
    final uid = _workerId;
    if (uid.isEmpty) return const Stream.empty();
    return DB.ref().child('userBookings/workers/$uid').onValue;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupStreamListener();
  }

  void _setupStreamListener() {
    _subscription = _workerBookingIdsStream.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        if (mounted) {
          setState(() {
            _earnings = [];
            _totalEarnings = 0.0;
            _isLoading = false;
          });
        }
        return;
      }

      if (data is Map) {
        final ids = data.keys.map((k) => k.toString()).toList();
        _loadEarnings(ids);
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadEarnings(List<String> ids) async {
    try {
      final futures = ids.map(_fetchBooking).toList();
      final results = await Future.wait(futures);
      final allBookings = results.whereType<Map<String, dynamic>>().toList();

      // Filter for completed/paid jobs
      final completedJobs = allBookings.where((b) {
        final status = (b['status'] ?? '').toString();
        // Check for completed or invoice_sent statuses that imply earning
        return ['completed', 'invoice_sent', 'paid'].contains(status);
      }).toList();

      // Sort by newer first
      completedJobs.sort((a, b) {
        final aTs = (a['createdAt'] is num)
            ? (a['createdAt'] as num).toInt()
            : 0;
        final bTs = (b['createdAt'] is num)
            ? (b['createdAt'] as num).toInt()
            : 0;
        return bTs.compareTo(aTs);
      });

      // Calculate totals and map to UI model
      double total = 0.0;
      final earningsList = <Map<String, dynamic>>[];

      for (var b in completedJobs) {
        // Extract amount from invoice if available
        double amount = 0.0;
        if (b['invoice'] is Map) {
          final inv = b['invoice'] as Map;
          amount = (inv['subtotal'] is num)
              ? (inv['subtotal'] as num).toDouble()
              : 0.0;
        }

        total += amount;

        final customerName = (b['customerName'] ?? 'Customer').toString();
        final service = (b['serviceName'] ?? b['serviceType'] ?? 'Service')
            .toString();

        final ts = (b['createdAt'] is num)
            ? (b['createdAt'] as num).toInt()
            : 0;
        final dateStr = _formatDate(ts);

        earningsList.add({
          'id': b['bookingId'].toString(),
          'type': 'earning',
          'customerName': customerName,
          'service': service,
          'amount': amount,
          'date': dateStr,
          'status': 'completed',
        });
      }

      if (mounted) {
        setState(() {
          _earnings = earningsList;
          _totalEarnings = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading earnings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'Unknown Date';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return DateFormat('MMM d, y').format(dt);
  }

  Future<Map<String, dynamic>?> _fetchBooking(String bookingId) async {
    try {
      final snap = await DB.ref().child('bookings/$bookingId').get();
      if (!snap.exists || snap.value == null) return null;
      final raw = snap.value;
      if (raw is! Map) return null;

      final map = Map<String, dynamic>.fromEntries(
        (raw as Map).entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
      map['bookingId'] = bookingId;
      return map;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
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
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Earnings Summary Card
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LKR ${_totalEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WorkerBankDetailsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A7FFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Withdraw Funds',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction History
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF4A7FFF),
                        unselectedLabelColor: const Color(0xFF6B7280),
                        indicatorColor: const Color(0xFF4A7FFF),
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Earnings'),
                          Tab(text: 'Payouts'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Earnings List
                            _earnings.isEmpty
                                ? _buildEmptyState('No earnings yet')
                                : ListView.separated(
                                    padding: const EdgeInsets.all(24),
                                    itemCount: _earnings.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      return _buildTransactionCard(
                                        _earnings[index],
                                      );
                                    },
                                  ),

                            // Payouts List (Empty for now)
                            _buildEmptyState('No payouts yet'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    // transaction 'type' is 'earning' or 'payout'
    // but for now we only really have earnings in the list
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: Color(0xFF4A7FFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['customerName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction['service'] ?? 'Service',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['date'] ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Text(
            '+ LKR ${(transaction['amount'] as num).toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
