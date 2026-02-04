import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';
import 'package:flutter/material.dart';

class WorkerNotificationsScreen extends StatefulWidget {
  const WorkerNotificationsScreen({super.key});

  @override
  State<WorkerNotificationsScreen> createState() =>
      _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState extends State<WorkerNotificationsScreen> {
  String _selectedTab = 'all';

  final _auth = FirebaseAuth.instance;
  final _db = DB.instance;

  DatabaseReference get _root => _db.ref();

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  DatabaseReference get _notifRef => _root.child('notifications').child(_uid);

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
      case 'confirmed':
      case 'quote_request':
      case 'quote_accepted':
      case 'invoice_sent':
      case 'completed':
        return Icons.calendar_today;

      case 'message':
        return Icons.chat_bubble_outline;

      case 'payment':
      case 'paid':
      case 'invoice_paid':
      case 'payment_success':
        return Icons.attach_money;

      case 'review':
        return Icons.star_outline;

      case 'appointment':
        return Icons.access_time;

      case 'offer':
      case 'promo':
        return Icons.card_giftcard_outlined;

      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking':
      case 'confirmed':
      case 'quote_request':
      case 'quote_accepted':
      case 'invoice_sent':
      case 'completed':
        return const Color(0xFF3B82F6);

      case 'message':
        return const Color(0xFF10B981);

      case 'payment':
      case 'paid':
      case 'invoice_paid':
      case 'payment_success':
        return const Color(0xFF10B981);

      case 'review':
        return const Color(0xFFFBBF24);

      case 'appointment':
        return const Color(0xFFEF4444);

      case 'offer':
      case 'promo':
        return const Color(0xFF8B5CF6);

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

  List<Map<String, dynamic>> _parseNotifications(DataSnapshot snap) {
    final v = snap.value;
    if (v == null) return [];

    final list = <Map<String, dynamic>>[];

    void addOne(String nid, dynamic val) {
      if (val is! Map) return;

      final data = Map<String, dynamic>.from(val as Map);

      final type = (data['type'] ?? '').toString().trim();

      final ts = (data['timestamp'] is int)
          ? data['timestamp'] as int
          : int.tryParse('${data['timestamp']}') ?? 0;

      final rawIsRead = data['isRead'];
      final isRead = rawIsRead == true || rawIsRead.toString() == 'true';

      final title = (data['title'] ?? '').toString();
      final desc = (data['message'] ?? data['description'] ?? '').toString();

      final c = _colorForType(type);

      list.add({
        // keep nid so we can mark read on tap
        'nid': nid,
        'id': (data['id'] ?? nid).toString(),

        'type': type,
        'title': title,
        'description': desc,

        'timestamp': ts,
        'time': _timeAgo(ts),

        'isRead': isRead,

        // UI expects these
        'icon': _iconForType(type),
        'iconColor': c,
        'iconBg': c.withOpacity(0.15),
      });
    }

    if (v is Map) {
      final m = Map<dynamic, dynamic>.from(v as Map);
      for (final e in m.entries) {
        addOne(e.key.toString(), e.value);
      }
    } else if (v is List) {
      for (int i = 0; i < v.length; i++) {
        addOne(i.toString(), v[i]);
      }
    }

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

    // safest: write back the whole object (works even if your rules validate full payload)
    await ref.set(data);
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> all) async {
    for (final n in all) {
      if (n['isRead'] == true) continue;
      final nid = (n['nid'] ?? '').toString();
      if (nid.isEmpty) continue;
      await _markOneRead(nid);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredNotifications(
    List<Map<String, dynamic>> all,
  ) {
    if (_selectedTab == 'unread') {
      return all.where((n) => n['isRead'] != true).toList();
    }
    return all;
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
                return Center(child: Text('Firebase error: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final all = _parseNotifications(snap.data!.snapshot);
              final filtered = _filteredNotifications(all);

              return Column(
                children: [
                  // Header (UI unchanged)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                              await _markAllAsRead(all);
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
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs (UI unchanged, just counts from RTDB)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 'all'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTab == 'all'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'All (${all.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTab == 'all'
                                      ? const Color(0xFF4A7FFF)
                                      : Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTab = 'unread'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTab == 'unread'
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Unread',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTab == 'unread'
                                      ? const Color(0xFF4A7FFF)
                                      : Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notifications List (UI unchanged)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You\'re all caught up!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final notification = filtered[index];
                                return _buildNotificationCard(notification);
                              },
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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return GestureDetector(
      onTap: () async {
        final nid = (notification['nid'] ?? '').toString();
        if (nid.isEmpty) return;

        try {
          await _markOneRead(nid);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification['isRead']
                ? const Color(0xFFE5E7EB)
                : const Color(0xFF4A7FFF).withOpacity(0.2),
            width: notification['isRead'] ? 1 : 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification['iconBg'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification['icon'],
                color: notification['iconColor'],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (notification['isRead'] != true)
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
                  const SizedBox(height: 4),
                  Text(
                    notification['description'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notification['time'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
