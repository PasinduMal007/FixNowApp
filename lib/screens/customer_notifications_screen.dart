import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:flutter/material.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _auth = FirebaseAuth.instance;
  final _db = DB.instance;

  DatabaseReference get _root => _db.ref();

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  DatabaseReference get _notifRef => _root.child('notifications').child(_uid);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
      case 'confirmed':
      case 'quote_declined':
      case 'quote_accepted':
      case 'invoice_sent':
      case 'declined_by_worker':
        return Icons.check_circle;

      case 'message':
        return Icons.message;

      case 'payment':
      case 'invoice_paid':
      case 'paid':
      case 'payment_success':
        return Icons.payment;

      case 'promo':
        return Icons.local_offer;

      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking':
      case 'confirmed':
      case 'quote_accepted':
      case 'invoice_sent':
        return const Color(0xFF10B981);

      case 'quote_declined':
      case 'declined_by_worker':
        return const Color(0xFFFF6B6B);

      case 'message':
        return const Color(0xFF4A7FFF);

      case 'payment':
      case 'invoice_paid':
      case 'paid':
      case 'payment_success':
        return const Color(0xFF10B981);

      case 'promo':
        return const Color(0xFFFBBF24);

      default:
        return const Color(0xFF6B7280);
    }
  }

  String _timeAgo(int tsMs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - tsMs;
    if (diff < 0) return 'Just now';

    final secs = (diff / 1000).floor();
    if (secs < 60) return 'Just now';

    final mins = (secs / 60).floor();
    if (mins < 60) return '$mins min ago';

    final hrs = (mins / 60).floor();
    if (hrs < 24) return '$hrs hours ago';

    final days = (hrs / 24).floor();
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  bool _matchesTab(String type, int tabIndex) {
    if (tabIndex == 0) return true; // All

    final bookingTypes = <String>{
      'booking',
      'confirmed',
      'declined_by_worker',
      'quote_declined',
      'quote_accepted',
      'invoice_sent',
    };

    if (tabIndex == 1) return bookingTypes.contains(type); // Bookings
    if (tabIndex == 2) return type == 'message'; // Messages
    if (tabIndex == 3) return type == 'promo'; // Promos

    return true;
  }

  List<Map<String, dynamic>> _parseNotifications(DataSnapshot snap) {
    final v = snap.value;
    if (v == null) return [];

    final list = <Map<String, dynamic>>[];

    void addOne(String nid, dynamic val) {
      if (val is! Map) return;

      final data = Map<String, dynamic>.from(val as Map);

      final type = (data['type'] ?? '').toString();

      final ts = (data['timestamp'] is int)
          ? data['timestamp'] as int
          : int.tryParse('${data['timestamp']}') ?? 0;

      final rawIsRead = data['isRead'];
      final isRead = rawIsRead == true || rawIsRead.toString() == 'true';

      list.add({
        'nid': nid,
        'id': (data['id'] ?? nid).toString(),
        'type': type,
        'title': (data['title'] ?? '').toString(),
        'message': (data['message'] ?? '').toString(),
        'timestamp': ts,
        'time': _timeAgo(ts),
        'isRead': isRead,
        'bookingId': (data['bookingId'] ?? '').toString(),
        'icon': _iconForType(type),
        'color': _colorForType(type),
      });
    }

    // Notifications stored under push IDs -> Map
    if (v is Map) {
      final m = Map<dynamic, dynamic>.from(v as Map);
      for (final e in m.entries) {
        addOne(e.key.toString(), e.value);
      }
    } else if (v is List) {
      // Just in case numeric keys ever happen
      for (int i = 0; i < v.length; i++) {
        addOne(i.toString(), v[i]);
      }
    }

    // Newest first
    list.sort((a, b) {
      final aa = (a['timestamp'] as int?) ?? 0;
      final bb = (b['timestamp'] as int?) ?? 0;
      return bb.compareTo(aa);
    });

    return list;
  }

  Future<void> _markOneRead(String nid) async {
    final ref = _notifRef.child(nid);
    final snap = await ref.get();
    if (!snap.exists) return;

    if (snap.value is! Map) return;
    final data = Map<String, dynamic>.from(snap.value as Map);

    if (data['isRead'] == true) return;

    data['isRead'] = true;

    // Must write full object (your rules validate full payload)
    await ref.set(data);
  }

  Future<void> _markAllRead(List<Map<String, dynamic>> notifications) async {
    for (final n in notifications) {
      final nid = (n['nid'] ?? '').toString();
      if (nid.isEmpty) continue;
      if (n['isRead'] == true) continue;

      await _markOneRead(nid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

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
          child: StreamBuilder<DatabaseEvent>(
            stream: _notifRef.onValue,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text('Firebase error: ${snap.error}'),
                );
              }

              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final snapshot = snap.data!.snapshot;
              final all = _parseNotifications(snapshot);

              final unreadCount =
                  all.where((n) => n['isRead'] != true).length;

              List<Map<String, dynamic>> filterForTab(int tabIndex) {
                return all
                    .where((n) => _matchesTab((n['type'] ?? '').toString(), tabIndex))
                    .toList();
              }

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                try {
                                  await _markAllRead(all);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              },
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$unreadCount unread notifications',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelPadding: EdgeInsets.zero,
                            tabs: const [
                              Tab(height: 40, child: Center(child: Text('All'))),
                              Tab(height: 40, child: Center(child: Text('Bookings'))),
                              Tab(height: 40, child: Center(child: Text('Messages'))),
                              Tab(height: 40, child: Center(child: Text('Promos'))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotificationsList(filterForTab(0)),
                          _buildNotificationsList(filterForTab(1)),
                          _buildNotificationsList(filterForTab(2)),
                          _buildNotificationsList(filterForTab(3)),
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

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 16,
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
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        return _buildNotificationCard(n);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = notification['isRead'] != true;

    return GestureDetector(
      onTap: () async {
        final nid = (notification['nid'] ?? '').toString();
        if (nid.isEmpty) return;

        try {
          await _markOneRead(nid);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFE8F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? const Color(0xFF4A7FFF).withOpacity(0.3)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (notification['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification['icon'] as IconData,
                color: notification['color'] as Color,
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
                      Expanded(
                        child: Text(
                          (notification['title'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A7FFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (notification['message'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (notification['time'] ?? '').toString(),
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
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}