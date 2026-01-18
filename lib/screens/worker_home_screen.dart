import 'package:flutter/material.dart';
import 'worker_notifications_screen.dart';
import 'worker_job_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class WorkerHomeScreen extends StatefulWidget {
  final String workerName;
  final int unreadMessages;

  const WorkerHomeScreen({
    super.key,
    this.workerName = 'Customer',
    this.unreadMessages = 3,
  });

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  bool _isAvailable = true;

  String get _workerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<DatabaseEvent> get _workerBookingIdsStream {
    final uid = _workerId;
    if (uid.isEmpty) {
      // no stream when logged out
      return const Stream.empty();
    }
    return DB.ref().child('userBookings/workers/$uid').onValue;
  }

  Future<Map<String, dynamic>?> _fetchBooking(String bookingId) async {
    final snap = await DB.ref().child('bookings/$bookingId').get();
    if (!snap.exists || snap.value == null) return null;

    final data = Map<String, dynamic>.from(snap.value as Map);
    data['bookingId'] = data['bookingId'] ?? bookingId;

    // Extra safety: only accept bookings assigned to this worker
    if ((data['workerId'] ?? '').toString() != _workerId) return null;

    return data;
  }

  Future<List<Map<String, dynamic>>> _fetchBookingsForIds(
    List<String> ids,
  ) async {
    final futures = ids.map(_fetchBooking).toList();
    final results = await Future.wait(futures);

    final list = results.whereType<Map<String, dynamic>>().toList();

    // show newest first
    list.sort((a, b) {
      final aTs = (a['createdAt'] is num) ? (a['createdAt'] as num).toInt() : 0;
      final bTs = (b['createdAt'] is num) ? (b['createdAt'] as num).toInt() : 0;
      return bTs.compareTo(aTs);
    });

    return list;
  }

  Future<void> _handleAcceptJob(String bookingId) async {
    await DB.ref().child('bookings/$bookingId').update({
      'status': 'confirmed',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job accepted!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleDeclineJob(String bookingId) async {
    await DB.ref().child('bookings/$bookingId').update({
      'status': 'declined_by_worker',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job declined'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Mock data
  final Map<String, dynamic> _todayStats = {
    'earnings': 'Rs8,500',
    'jobs': 3,
    'rating': 4.9,
    'newRequests': 5,
  };

  Widget _buildBookingRequestCard(Map<String, dynamic> job) {
    // booking status
    final status = (job['status'] ?? 'requested').toString();
    final isPending = status == 'requested';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.build_outlined,
                size: 18,
                color: Color(0xFF4A7FFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (job['service'] ?? 'Service').toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPending
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (job['location'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (job['scheduledDate'] ?? '').toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isPending
                      ? () => _handleDeclineJob(job['id'])
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFF3F4F6),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPending
                      ? () => _handleAcceptJob(job['id'])
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF4A7FFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Accept Job',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.workerName.split(' ').first;

    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              // Header with gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome and Notification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$firstName!',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notification button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WorkerNotificationsScreen(),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  if (_todayStats['newRequests'] > 0)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF6B6B),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${_todayStats['newRequests']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Availability Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _isAvailable
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isAvailable
                                          ? 'Available for Work'
                                          : 'Unavailable',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF1F2937),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isAvailable
                                          ? 'Accepting new job requests'
                                          : 'Not accepting requests',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(
                                  () => _isAvailable = !_isAvailable,
                                ),
                                child: Container(
                                  width: 56,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _isAvailable
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFD1D5DB),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: AnimatedAlign(
                                    alignment: _isAvailable
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Today's Stats
                        Row(
                          children: [
                            _buildStatCard(
                              Icons.attach_money,
                              _todayStats['earnings'],
                              'Today',
                              const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              Icons.check_circle_outline,
                              '${_todayStats['jobs']}',
                              'Jobs',
                              const Color(0xFF4A7FFF),
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              Icons.star_outline,
                              '${_todayStats['rating']}',
                              'Rating',
                              const Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              Icons.notifications_outlined,
                              '${_todayStats['newRequests']}',
                              'New',
                              const Color(0xFFFF6B6B),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content scroll area
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // New Job Requests (from RTDB)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New Job Requests',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            StreamBuilder<DatabaseEvent>(
                              stream: _workerBookingIdsStream,
                              builder: (context, snap) {
                                final v = snap.data?.snapshot.value;
                                final count = (v is Map) ? v.length : 0;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count pending',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        StreamBuilder<DatabaseEvent>(
                          stream: _workerBookingIdsStream,
                          builder: (context, snapshot) {
                            if (_workerId.isEmpty) {
                              return const Center(child: Text('Please log in'));
                            }

                            if (snapshot.hasError) {
                              return Text(
                                'Failed to load requests: ${snapshot.error}',
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final raw = snapshot.data!.snapshot.value;

                            if (raw == null) {
                              return const Text('No job requests yet.');
                            }

                            if (raw is! Map) {
                              return const Text('No job requests yet.');
                            }

                            // bookingIds are the keys under userBookings/workers/{uid}
                            final bookingIds = raw.keys
                                .map((k) => k.toString())
                                .toList();

                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchBookingsForIds(bookingIds),
                              builder: (context, bookingsSnap) {
                                if (bookingsSnap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                if (bookingsSnap.hasError) {
                                  return Text(
                                    'Failed to load booking details: ${bookingsSnap.error}',
                                  );
                                }

                                final bookings = bookingsSnap.data ?? [];
                                if (bookings.isEmpty) {
                                  return const Text('No job requests yet.');
                                }

                                // Convert booking -> card model your UI expects
                                final jobRequests = bookings.map((b) {
                                  return <String, dynamic>{
                                    'id': b['bookingId'] ?? '',
                                    'customerId': b['customerId'] ?? '',
                                    'workerId': b['workerId'] ?? '',
                                    'service': (b['serviceName'] ?? '')
                                        .toString(),
                                    'issue':
                                        (b['serviceName'] ?? 'Service request')
                                            .toString(),
                                    'location': (b['locationText'] ?? '')
                                        .toString(),
                                    'scheduledDate': (b['scheduledAt'] ?? '')
                                        .toString(),
                                    'scheduledTime': '',
                                    'budget':
                                        'Rs${(b['serviceCharge'] ?? b['amount'] ?? b['price'] ?? '')}',
                                    'urgency': 'normal',
                                    'status': (b['status'] ?? 'requested')
                                        .toString(),
                                  };
                                }).toList();

                                return Column(
                                  children: jobRequests
                                      .map(
                                        (job) => _buildBookingRequestCard(job),
                                      )
                                      .toList(),
                                );
                              },
                            );
                          },
                        ),

                        // Quick Actions
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionCard(
                                Icons.trending_up,
                                'My Earnings',
                                const Color(0xFFE8F0FF),
                                const Color(0xFF4A7FFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionCard(
                                Icons.emoji_events_outlined,
                                'My Reviews',
                                const Color(0xFFFEF3C7),
                                const Color(0xFFFFB800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF4A7FFF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job['customerName'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      job['time'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A7FFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  job['service'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job['location'],
                      style: const TextStyle(
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.navigation,
              size: 16,
              color: Color(0xFF4A7FFF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRequestCard(Map<String, dynamic> job) {
    final isUrgent = job['urgency'] == 'urgent';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WorkerJobDetailsScreen(job: {...job, 'status': 'pending'}),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUrgent ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUrgent ? const Color(0xFFFF6B6B) : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgency badge
            if (isUrgent) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Urgent Request',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Customer info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF4A7FFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            job['customerName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Color(0xFFFFB800),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${job['rating']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${job['completedJobs']} jobs completed',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Job details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.build_outlined,
                        size: 16,
                        color: Color(0xFF4A7FFF),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        job['service'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      job['issue'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${job['scheduledDate']}, ${job['scheduledTime']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          Text(
                            job['budget'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Location
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Color(0xFFFF6B6B),
                ),
                const SizedBox(width: 6),
                Text(
                  job['location'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDeclineJob(job['id']),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFF3F4F6),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAcceptJob(job['id']),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF4A7FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Accept Job',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
