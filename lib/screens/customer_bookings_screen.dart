import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_now_app/services/db.dart';
import 'package:fix_now_app/Services/chat_service.dart';
import 'customer_chat_conversation_screen.dart'; // Ensure this exists or adapt

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ChatService _chat;
  final Map<String, Future<Map<String, String>>> _workerPublicCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _chat = ChatService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getWorkerPublic(String workerId) {
    final id = workerId.trim();
    if (id.isEmpty) return Future.value(const {});
    return _workerPublicCache.putIfAbsent(id, () async {
      final snap = await DB.instance.ref('workersPublic/$id').get();
      if (!snap.exists || snap.value is! Map) return const {};
      final data = Map<String, dynamic>.from(snap.value as Map);
      final name = (data['fullName'] ?? '').toString().trim();
      final profession = (data['profession'] ?? '').toString().trim();
      return {
        if (name.isNotEmpty) 'fullName': name,
        if (profession.isNotEmpty) 'profession': profession,
      };
    });
  }

  // Fetch bookings for the current customer
  Stream<List<Map<String, dynamic>>> get _bookingsStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final q = DB.instance
        .ref('bookings')
        .orderByChild('customerId')
        .equalTo(user.uid);

    return q.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return [];

      final all = Map<dynamic, dynamic>.from(raw);
      final List<Map<String, dynamic>> list = [];

      all.forEach((key, value) {
        if (value is! Map) return;
        final data = Map<String, dynamic>.from(value);
        data['id'] = key;
        list.add(data);
      });

      // Sort by createdAt descending (newest first)
      list.sort((a, b) {
        final ta = a['createdAt'] as int? ?? 0;
        final tb = b['createdAt'] as int? ?? 0;
        return tb.compareTo(ta);
      });

      return list;
    });
  }

  // Helper to generate consistent thread ID
  String _getThreadId(String myUid, String otherUid) {
    return (myUid.compareTo(otherUid) < 0)
        ? '${myUid}_$otherUid'
        : '${otherUid}_$myUid';
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
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _bookingsStream,
            builder: (context, snapshot) {
              final allBookings = snapshot.data ?? [];

              // Filter into Upcoming vs Past
              // Upcoming: pending, invoice_sent, confirmed, started
              // Past: completed, canceled, rejected
              final upcoming = allBookings.where((b) {
                final s = (b['status'] ?? '').toString();
                return [
                  'pending',
                  'invoice_sent',
                  'quote_accepted',
                  'confirmed',
                  'started',
                  'payment_paid',
                ].contains(s);
              }).toList();

              final past = allBookings.where((b) {
                final s = (b['status'] ?? '').toString();
                return ['completed', 'canceled', 'rejected'].contains(s);
              }).toList();

              return Column(
                children: [
                  // H E A D E R
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Bookings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Track all your service bookings',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),

                        // Tabs
                        Container(
                          padding: const EdgeInsets.all(4),
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
                            labelColor: const Color(0xFF4A7FFF),
                            unselectedLabelColor: Colors.white,
                            labelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelPadding: EdgeInsets.zero,
                            tabs: [
                              Tab(
                                height: 44,
                                child: Center(
                                  child: Text('Upcoming (${upcoming.length})'),
                                ),
                              ),
                              Tab(
                                height: 44,
                                child: Center(
                                  child: Text('Past (${past.length})'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // C O N T E N T
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingsList(upcoming),
                          _buildBookingsList(past),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No bookings found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString();
    final workerId = (booking['workerId'] ?? '').toString();

    // Status Badge Logic
    Color badgeColor = Colors.grey;
    Color badgeText = Colors.white;
    String statusLabel = status;

    switch (status) {
      case 'confirmed':
      case 'started':
        badgeColor = const Color(0xFFD1FAE5);
        badgeText = const Color(0xFF059669);
        statusLabel = status == 'started' ? 'In Progress' : 'Confirmed';
        break;
      case 'payment_paid':
        badgeColor = const Color(0xFFE0F2FE);
        badgeText = const Color(0xFF0284C7);
        statusLabel = 'Advance Paid';
        break;
      case 'invoice_sent':
        badgeColor = const Color(0xFFE0F2FE);
        badgeText = const Color(0xFF0284C7);
        statusLabel = 'Quote Ready';
        break;
      case 'pending':
        badgeColor = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        statusLabel = 'Pending';
        break;
      case 'completed':
        badgeColor = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF166534);
        statusLabel = 'Completed';
        break;
      case 'canceled':
      case 'rejected':
        badgeColor = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFDC2626);
        statusLabel = status == 'rejected' ? 'Rejected' : 'Canceled';
        break;
    }

    final isActionable = [
      'pending',
      'confirmed',
      'invoice_sent',
      'quote_accepted',
      'started',
      'payment_paid',
    ].contains(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Title and Status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFFFBBF24),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (booking['serviceName'] ?? 'Service').toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${(booking['id'] ?? '').toString().substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Worker Info
          if (workerId.isNotEmpty) ...[
            FutureBuilder<Map<String, String>>(
              future: _getWorkerPublic(workerId),
              builder: (context, snap) {
                final cached = snap.data ?? const {};
                final name =
                    (booking['workerName'] ?? cached['fullName'] ?? 'Provider')
                        .toString()
                        .trim();
                final profession =
                    (booking['workerProfession'] ??
                            booking['profession'] ??
                            booking['workerType'] ??
                            cached['profession'] ??
                            'Professional')
                        .toString();

                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
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
                            name.isEmpty ? 'Provider' : name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profession,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Date & Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Text(
                (booking['scheduledDate'] ?? 'Date TBD').toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.schedule, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                (booking['scheduledTime'] ?? '').toString(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location
          if (booking['locationText'] != null)
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking['locationText'].toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),

          if (booking['total'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payments, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Text(
                  'LKR ${booking['total']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ],

          if (isActionable) ...[
            const SizedBox(height: 16),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final chat = ChatService();
                  final db = DB.instance;

                  try {
                    // bookingOrId is whatever you have in your card (Map or String)
                    final dynamic bookingOrId =
                        booking; // <-- keep YOUR variable name here

                    Map<String, dynamic> bookingData;

                    if (bookingOrId is Map) {
                      bookingData = Map<String, dynamic>.from(
                        bookingOrId as Map,
                      );
                    } else if (bookingOrId is String) {
                      final bookingId = bookingOrId.trim();
                      if (bookingId.isEmpty)
                        throw Exception('Missing bookingId');

                      final snap = await db.ref('bookings/$bookingId').get();
                      if (!snap.exists || snap.value is! Map) {
                        throw Exception('Booking not found or invalid');
                      }
                      bookingData = Map<String, dynamic>.from(
                        snap.value as Map,
                      );
                    } else {
                      throw Exception('Invalid booking object');
                    }

                    final workerId = (bookingData['workerId'] ?? '')
                        .toString()
                        .trim();
                    if (workerId.isEmpty)
                      throw Exception('Missing workerId in booking');

                    // Customer cannot read users/workers/$uid (your rules block that).
                    // Use workersPublic which is readable.
                    String workerName = 'Worker';
                    final wsnap = await db
                        .ref('workersPublic/$workerId/fullName')
                        .get();
                    if (wsnap.exists && wsnap.value is String) {
                      final name = (wsnap.value as String).trim();
                      if (name.isNotEmpty) workerName = name;
                    }

                    final customerName =
                        (bookingData['customerName'] ?? 'Customer')
                            .toString()
                            .trim()
                            .isNotEmpty
                        ? (bookingData['customerName'] ?? 'Customer')
                              .toString()
                              .trim()
                        : 'Customer';

                    final threadId = await chat.createOrGetThread(
                      otherUid: workerId,
                      myRole: 'customer',
                      otherRole: 'worker',
                      otherName: workerName,
                      myName: customerName,
                    );

                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerChatConversationScreen(
                          threadId: threadId,
                          otherUid: workerId,
                          otherName: workerName,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Message failed: $e')),
                    );
                  }
                },

                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
