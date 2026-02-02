import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'dart:async';

class WorkerBookingsScreen extends StatefulWidget {
  const WorkerBookingsScreen({super.key});

  @override
  State<WorkerBookingsScreen> createState() => _WorkerBookingsScreenState();
}

class _WorkerBookingsScreenState extends State<WorkerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  StreamSubscription? _subscription;
  bool _isLoading = true;

  // Dynamic data lists
  List<Map<String, dynamic>> _upcomingBookings = [];
  List<Map<String, dynamic>> _inProgressBookings = [];
  List<Map<String, dynamic>> _pastBookings = [];

  String get _workerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<DatabaseEvent> get _workerBookingIdsStream {
    final uid = _workerId;
    if (uid.isEmpty) return const Stream.empty();
    return DB.ref().child('userBookings/workers/$uid').onValue;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _setupStreamListener();
  }

  void _setupStreamListener() {
    _subscription = _workerBookingIdsStream.listen((event) {
      final data = event.snapshot.value;
      if (data == null) {
        if (mounted) {
          setState(() {
            _upcomingBookings = [];
            _inProgressBookings = [];
            _pastBookings = [];
            _isLoading = false;
          });
        }
        return;
      }

      if (data is Map) {
        final ids = data.keys.map((k) => k.toString()).toList();
        _loadBookings(ids);
      }
    });
  }

  Future<void> _loadBookings(List<String> ids) async {
    try {
      final futures = ids.map(_fetchBooking).toList();
      final results = await Future.wait(futures);
      final allBookings = results.whereType<Map<String, dynamic>>().toList();

      // Sort by newer first
      allBookings.sort((a, b) {
        final aTs = (a['createdAt'] is num)
            ? (a['createdAt'] as num).toInt()
            : 0;
        final bTs = (b['createdAt'] is num)
            ? (b['createdAt'] as num).toInt()
            : 0;
        return bTs.compareTo(aTs);
      });

      // Categorize
      final upcoming = <Map<String, dynamic>>[];
      final inProgress = <Map<String, dynamic>>[];
      final past = <Map<String, dynamic>>[];

      for (var b in allBookings) {
        final status = (b['status'] ?? 'pending').toString();
        // Categorization logic
        if ([
          'started',
          'arrived',
          'in_progress',
          'invoice_sent',
        ].contains(status)) {
          inProgress.add(b);
        } else if ([
          'completed',
          'cancelled',
          'quote_declined',
          'declined_by_worker',
          'refunded',
        ].contains(status)) {
          past.add(b);
        } else {
          // 'pending', 'quote_requested', 'quote_received', 'quote_accepted', 'confirmed', 'scheduled' and fallback
          upcoming.add(b);
        }
      }

      if (mounted) {
        setState(() {
          _upcomingBookings = upcoming;
          _inProgressBookings = inProgress;
          _pastBookings = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchBooking(String bookingId) async {
    try {
      final snap = await DB.ref().child('bookings/$bookingId').get();
      if (!snap.exists || snap.value == null) return null;
      final raw = snap.value;
      if (raw is! Map) return null;

      final map = Map<String, dynamic>.fromEntries(
        raw.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );

      // Add ID if missing
      map['bookingId'] = bookingId; // Ensure ID is consistent
      map['id'] = bookingId;

      // Extract timestamp (scheduledAt or createdAt)
      final tsVal = map['scheduledAt'] ?? map['createdAt'];
      int? timestamp;
      if (tsVal is int) {
        timestamp = tsVal;
      } else if (tsVal is String) {
        // If stored as string, try to parse or just leave it
        // If it's a number string:
        timestamp = int.tryParse(tsVal);
      }

      if (timestamp != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        // Only set if not already present
        map['date'] ??= '${months[dt.month - 1]} ${dt.day}, ${dt.year}';

        final hour = dt.hour > 12
            ? dt.hour - 12
            : (dt.hour == 0 ? 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');

        map['time'] ??= '$hour:$minute $ampm';
      }

      // Defaults to prevent null errors
      map['customerName'] ??= 'Unknown Customer';
      map['service'] ??= 'Service Request';
      map['description'] ??= 'No description provided';
      map['location'] ??= 'Unknown Location';
      map['payment'] ??= 'Pending';
      map['date'] ??= 'Date Pending';
      map['time'] ??= 'Time Pending';

      return map;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
            colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: const Color(0xFF4A7FFF),
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Upcoming'),
                            if (_upcomingBookings.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 0
                                      ? const Color(0xFF4A7FFF)
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_upcomingBookings.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedTabIndex == 0
                                        ? Colors.white
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('In Progress'),
                            if (_inProgressBookings.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTabIndex == 1
                                      ? const Color(0xFF4A7FFF)
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_inProgressBookings.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedTabIndex == 1
                                        ? Colors.white
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Past'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            // Upcoming
                            _buildBookingsList(_upcomingBookings, 'upcoming'),
                            // In Progress
                            _buildBookingsList(
                              _inProgressBookings,
                              'inProgress',
                            ),
                            // Past
                            _buildBookingsList(_pastBookings, 'past'),
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

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming'
                  ? Icons.event_available
                  : type == 'inProgress'
                  ? Icons.pending_actions
                  : Icons.history,
              size: 64,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming'
                  ? 'No upcoming bookings'
                  : type == 'inProgress'
                  ? 'No jobs in progress'
                  : 'No past bookings',
              style: const TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, type);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, String type) {
    final isInProgress = type == 'inProgress';
    final isPast = type == 'past';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInProgress
              ? const Color(0xFFFBBF24)
              : const Color(0xFFE5E7EB),
          width: isInProgress ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer info and status
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
                    Text(
                      booking['customerName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking['service'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (isInProgress)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'In Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isPast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            booking['description'],
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),

          // Date and Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                'Date',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.access_time, size: 14, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                'Time',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                booking['date'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 40),
              Text(
                booking['time'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
                'Location',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            booking['location'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (booking['address'] != null) ...[
            const SizedBox(height: 2),
            Text(
              booking['address'],
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
          const SizedBox(height: 12),

          // Payment
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                size: 14,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              const Text(
                'Payment',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
              const Spacer(),
              Text(
                booking['payment'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Past booking extras
          if (isPast && booking['earned'] != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Earned: ${booking['earned']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],

          // Rating for past bookings
          if (isPast && booking['rating'] > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < booking['rating'] ? Icons.star : Icons.star_border,
                  size: 18,
                  color: const Color(0xFFFBBF24),
                );
              }),
            ),
          ],

          // Review for past bookings
          if (isPast && booking['review'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking['review'],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          if (isPast)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4A7FFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF4A7FFF),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: const Color(0xFF4A7FFF),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (isInProgress) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Job marked as complete!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
