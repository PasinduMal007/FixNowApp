import 'package:flutter/material.dart';
import 'worker_notifications_screen.dart';
import 'worker_job_details_screen.dart';
import 'worker_earnings_screen.dart';
import 'worker_reviews_screen.dart';
import 'worker_chat_conversation_screen.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:fix_now_app/Services/chat_service.dart';

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
  bool _availabilitySaving = false;

  static const Set<String> _newRequestStatuses = {'pending', 'quote_requested'};
  static const Set<String> _activeStatuses = {
    'confirmed',
    'payment_paid',
  };

  // Dashboard State
  double _dashboardEarnings = 0.0;
  int _dashboardJobsCompleted = 0;
  double _dashboardRating = 0.0;
  int _dashboardNewRequests = 0;

  StreamSubscription? _bookingsSubscription;
  StreamSubscription? _reviewsSubscription;
  StreamSubscription? _availabilitySubscription;

  String get _workerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<DatabaseEvent> get _workerBookingIdsStream {
    final uid = _workerId;
    if (uid.isEmpty) {
      // no stream when logged out
      return const Stream.empty();
    }
    return DB.ref().child('userBookings/workers/$uid').onValue;
  }

  Stream<DatabaseEvent> get _notifStream {
    final uid = _workerId;
    if (uid.isEmpty) return const Stream.empty();
    return DB.instance.ref('notifications').child(uid).onValue;
  }

  @override
  void initState() {
    super.initState();
    _setupDashboardListeners();
    _startAvailabilityListener();
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _reviewsSubscription?.cancel();
    _availabilitySubscription?.cancel();
    super.dispose();
  }

  void _startAvailabilityListener() {
    final uid = _workerId;
    if (uid.isEmpty) return;

    _availabilitySubscription = DB.instance
        .ref('users/workers/$uid/isAvailable')
        .onValue
        .listen((event) {
          final raw = event.snapshot.value;
          final isAvailable = raw is bool
              ? raw
              : (raw is String ? raw.toLowerCase() == 'true' : false);

          if (mounted) {
            setState(() => _isAvailable = isAvailable);
          }
        });
  }

  Future<void> _updateAvailability(bool value) async {
    final uid = _workerId;
    if (uid.isEmpty) return;
    if (_availabilitySaving) return;

    setState(() => _availabilitySaving = true);

    try {
      final updates = <String, Object?>{
        'users/workers/$uid/isAvailable': value,
        'users/workers/$uid/updatedAt': ServerValue.timestamp,
        'workersPublic/$uid/isAvailable': value,
        'workersPublic/$uid/updatedAt': ServerValue.timestamp,
      };

      await DB.instance.ref().update(updates);

      if (mounted) {
        setState(() => _isAvailable = value);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update availability: $e')),
      );
    } finally {
      if (mounted) setState(() => _availabilitySaving = false);
    }
  }

  void _setupDashboardListeners() {
    final uid = _workerId;
    if (uid.isEmpty) return;

    // 1. Listen to Bookings for Earnings, Jobs, New Requests
    _bookingsSubscription = DB.ref().child('userBookings/workers/$uid').onValue.listen((
      event,
    ) async {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        if (mounted) {
          setState(() {
            _dashboardEarnings = 0.0;
            _dashboardJobsCompleted = 0;
            _dashboardNewRequests = 0;
          });
        }
        return;
      }

      final ids = data.keys.map((k) => k.toString()).toList();
      final bookings = await _fetchBookingsForIds(ids);

      if (!mounted) return;

      double earnings = 0.0;
      int jobsToday = 0;
      int newRequests = 0;

      final now = DateTime.now();
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).millisecondsSinceEpoch;
      final todayEnd = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      ).millisecondsSinceEpoch;

      for (var b in bookings) {
        final status = (b['status'] ?? '').toString();

        // Count New Requests
        if (_newRequestStatuses.contains(status)) {
          newRequests++;
        }

        // Calculate Today's Earnings & Jobs logic
        if (['completed', 'payment_paid', 'paid'].contains(status)) {
          // check if 'completedAt' or 'updatedAt' is today.
          // Falling back to 'createdAt' if others missing, but ideally we want completion time.
          // For now, let's use 'createdAt' or the timestamp field if we have one.
          // Using createdAt for simplicity as per previous existing logic patterns or updated logic.
          // Let's ensure we check if the transaction happened "Today".

          // If we don't have completedAt, we can check updatedAt.
          int timestamp = 0;
          if (b['completedAt'] is num) {
            timestamp = (b['completedAt'] as num).toInt();
          } else if (b['updatedAt'] is num) {
            timestamp = (b['updatedAt'] as num).toInt();
          } else if (b['createdAt'] is num) {
            timestamp = (b['createdAt'] as num).toInt();
          }

          if (timestamp >= todayStart && timestamp <= todayEnd) {
            jobsToday++;

            double advanceAmount = 0.0;
            double commissionAmount = 0.0;

            if (b['paymentSummary'] is Map) {
              final summary = b['paymentSummary'] as Map;
              if (summary['advanceAmount'] is num) {
                advanceAmount = (summary['advanceAmount'] as num).toDouble();
              }
              if (summary['commissionAmount'] is num) {
                commissionAmount =
                    (summary['commissionAmount'] as num).toDouble();
              }
            }

            if (advanceAmount == 0.0) {
              if (b['advanceAmount'] is num) {
                advanceAmount = (b['advanceAmount'] as num).toDouble();
              } else if (b['invoice'] is Map) {
                final inv = b['invoice'] as Map;
                final subtotal = (inv['subtotal'] is num)
                    ? (inv['subtotal'] as num).toDouble()
                    : 0.0;
                advanceAmount = subtotal * 0.30;
              }
            }

            if (commissionAmount == 0.0) {
              commissionAmount = advanceAmount * 0.10;
            }

            earnings += (advanceAmount - commissionAmount);
          }
        }
      }

      setState(() {
        _dashboardEarnings = earnings;
        _dashboardJobsCompleted = jobsToday;
        _dashboardNewRequests = newRequests;
      });
    });

    // 2. Listen to Reviews for Rating
    _reviewsSubscription = DB.ref().child('reviews/$uid').onValue.listen((
      event,
    ) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        if (mounted) setState(() => _dashboardRating = 0.0);
        return;
      }

      double totalRating = 0.0;
      int count = 0;

      data.forEach((key, value) {
        if (value is Map && value['rating'] is num) {
          totalRating += (value['rating'] as num).toDouble();
          count++;
        }
      });

      if (mounted) {
        setState(() {
          _dashboardRating = count == 0 ? 0.0 : totalRating / count;
        });
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchBooking(String bookingId) async {
    try {
      final snap = await DB.ref().child('bookings/$bookingId').get();
      if (!snap.exists || snap.value == null) return null;

      final raw = snap.value;

      // If booking node is not an object, ignore it safely
      if (raw is! Map) return null;

      // Convert keys to String safely (prevents weird key-type crashes)
      final map = Map<String, dynamic>.fromEntries(
        (raw as Map).entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );

      map['bookingKey'] = bookingId;
      map['bookingId'] = (map['bookingId'] ?? bookingId).toString();

      // Only accept bookings assigned to this worker
      if ((map['workerId'] ?? '').toString() != _workerId) return null;

      return map;
    } catch (_) {
      // ✅ Never let one bad record break the whole list
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBookingsForIds(
    List<String> ids,
  ) async {
    final futures = ids.map(_fetchBooking).toList();
    final results = await Future.wait(futures);

    final list = results
        .whereType<Map<String, dynamic>>()
        .where((b) => (b['status'] ?? '').toString() != 'declined_by_worker')
        .toList();

    // show newest first
    list.sort((a, b) {
      final aTs = (a['createdAt'] is num) ? (a['createdAt'] as num).toInt() : 0;
      final bTs = (b['createdAt'] is num) ? (b['createdAt'] as num).toInt() : 0;
      return bTs.compareTo(aTs);
    });

    return list;
  }

  Future<void> _handleDeclineJob(dynamic bookingId) async {
    final uid = _workerId;
    final id = (bookingId ?? '').toString().trim();

    if (uid.isEmpty) return;

    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Decline failed: missing booking key'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    final updates = <String, dynamic>{
      'bookings/$id/status': 'quote_declined',
      'bookings/$id/updatedAt': now,

      // remove from worker index so it disappears
      'userBookings/workers/$uid/$id': null,
    };

    await DB.ref().update(updates);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job declined'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildBookingRequestCard(Map<String, dynamic> job) {
    final status = (job['status'] ?? '').toString();
    final isPending = status == 'pending';

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    switch (status) {
      case 'pending':
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        badgeLabel = 'PENDING';
        break;
      case 'confirmed':
        badgeBg = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF059669);
        badgeLabel = 'CONFIRMED';
        break;
      case 'invoice_sent':
        badgeBg = const Color(0xFFE0E7FF);
        badgeText = const Color(0xFF4338CA);
        badgeLabel = 'INVOICE SENT';
        break;
      case 'quote_declined':
      case 'declined_by_worker':
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFDC2626);
        badgeLabel = 'DECLINED';
        break;
      default:
        badgeBg = const Color(0xFFE5E7EB);
        badgeText = const Color(0xFF374151);
        badgeLabel = status.isEmpty ? 'UNKNOWN' : status.toUpperCase();
    }

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
          // Customer name and status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF4A7FFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  job['customerName'] ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 16,
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
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Service type
          Row(
            children: [
              const Icon(
                Icons.build_outlined,
                size: 18,
                color: Color(0xFF4A7FFF),
              ),
              const SizedBox(width: 8),
              Text(
                (job['service'] ?? 'Service').toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location
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

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (isPending) ...[
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
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerJobDetailsScreen(
                          bookingKey: job['id'].toString(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF4A7FFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'View Request',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    final customerId = job['customerId'];
                    final customerName = job['customerName'];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerChatConversationScreen(
                          threadId: 'mock_$customerId',
                          otherUid: customerId.toString(),
                          otherName: customerName.toString(),
                          customerName: customerName.toString(),
                          service: job['service'].toString(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF4A7FFF),
                    size: 20,
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
                            StreamBuilder<DatabaseEvent>(
                              stream: _notifStream,
                              builder: (context, snapshot) {
                                bool hasUnread = false;

                                final raw = snapshot.data?.snapshot.value;
                                if (raw != null && raw is Map) {
                                  final map = Map<dynamic, dynamic>.from(raw);

                                  for (final n in map.values) {
                                    if (n is Map) {
                                      final isRead = n['isRead'];
                                      if (isRead != true &&
                                          isRead.toString() != 'true') {
                                        hasUnread = true;
                                        break;
                                      }
                                    }
                                  }
                                }

                                return GestureDetector(
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
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),

                                      if (hasUnread)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
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
                                onTap: _availabilitySaving
                                    ? null
                                    : () => _updateAvailability(!_isAvailable),
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
                            // Earnings Card (Custom styling)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      size: 20,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Rs${_dashboardEarnings.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F2937),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Today',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF6B7280),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              Icons.check_circle_outline,
                              '$_dashboardJobsCompleted',
                              'Jobs',
                              const Color(0xFF4A7FFF),
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              Icons.star_outline,
                              _dashboardRating.toStringAsFixed(1),
                              'Rating',
                              const Color(0xFFFFB800),
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              Icons.notifications_outlined,
                              '$_dashboardNewRequests',
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
                        const SizedBox(height: 8),

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

                                if (_workerId.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '0 pending',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }

                                if (v == null || v is! Map) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '0 pending',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }

                                final rawMap = v as Map;

                                final bookingIds = rawMap.entries
                                    .where((e) => e.value == true)
                                    .map((e) => e.key.toString())
                                    .toList();

                                return FutureBuilder<
                                  List<Map<String, dynamic>>
                                >(
                                  future: _fetchBookingsForIds(bookingIds),
                                  builder: (context, bookingsSnap) {
                                    final bookings =
                                        bookingsSnap.data ?? const [];

                                    final activeCount = bookings.where((b) {
                                      final s = (b['status'] ?? '').toString();
                                      return _activeStatuses.contains(s);
                                    }).length;

                                    final pendingCount = bookings.where((b) {
                                      final s = (b['status'] ?? '').toString();
                                      return _newRequestStatuses.contains(s);
                                    }).length;

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Pending (red)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '$pendingCount pending',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFEF4444),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Active (green)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '$activeCount active',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
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

                            final rawMap = raw as Map;

                            final bookingIds = rawMap.entries
                                .where(
                                  (e) => e.value == true,
                                ) // ✅ only real index items
                                .map((e) => e.key.toString())
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

                                final bookings = (bookingsSnap.data ?? [])
                                    .where((b) {
                                      final s = (b['status'] ?? '').toString();
                                      return _newRequestStatuses.contains(
                                        s,
                                      ); // only pending / quote_requested
                                    })
                                    .toList();

                                if (bookings.isEmpty) {
                                  return const Text('No job requests yet.');
                                }

                                // Convert booking -> card model your UI expects
                                final jobRequests = bookings.map((b) {
                                  final bookingId =
                                      (b['bookingId'] ?? b['bookingKey'] ?? '')
                                          .toString();

                                  // Support both shapes: quotationRequest (new) and quoteRequest (old)
                                  final qr = (b['quotationRequest'] is Map)
                                      ? Map<String, dynamic>.from(
                                          b['quotationRequest'] as Map,
                                        )
                                      : <String, dynamic>{};

                                  final oldQr = (b['quoteRequest'] is Map)
                                      ? Map<String, dynamic>.from(
                                          b['quoteRequest'] as Map,
                                        )
                                      : <String, dynamic>{};

                                  final requestNote = (qr['requestNote'] ?? '')
                                      .toString()
                                      .trim();
                                  final oldTitle = (oldQr['title'] ?? '')
                                      .toString()
                                      .trim();
                                  final oldDesc = (oldQr['description'] ?? '')
                                      .toString()
                                      .trim();

                                  final serviceName =
                                      (b['serviceName'] ??
                                              b['serviceType'] ??
                                              'Service')
                                          .toString()
                                          .trim();

                                  final locationText =
                                      (b['locationText'] ?? b['location'] ?? '')
                                          .toString()
                                          .trim();

                                  final problemDescription =
                                      (b['problemDescription'] ?? '')
                                          .toString()
                                          .trim();

                                  final issueText =
                                      [
                                        if (oldTitle.isNotEmpty) oldTitle,
                                        if (requestNote.isNotEmpty) requestNote,
                                        if (problemDescription.isNotEmpty)
                                          problemDescription,
                                        if (oldDesc.isNotEmpty) oldDesc,
                                      ].firstWhere(
                                        (s) => s.isNotEmpty,
                                        orElse: () => 'Service request',
                                      );

                                  final bookingKey = (b['bookingKey'] ?? '')
                                      .toString();

                                  return <String, dynamic>{
                                    'id': bookingKey,
                                    'customerId': (b['customerId'] ?? '')
                                        .toString(),
                                    'customerName':
                                        (b['customerName'] ?? 'Customer')
                                            .toString(),
                                    'workerId': (b['workerId'] ?? '')
                                        .toString(),
                                    'service': serviceName,
                                    'issue': issueText,
                                    'location': locationText,
                                    'status': (b['status'] ?? '').toString(),
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
                        const SizedBox(height: 32),

                        // Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
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
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WorkerEarningsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionCard(
                                Icons.emoji_events_outlined,
                                'My Reviews',
                                const Color(0xFFFEF3C7),
                                const Color(0xFFFFB800),
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WorkerReviewsScreen(),
                                    ),
                                  );
                                },
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
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
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
