import 'package:flutter/material.dart';

class WorkerNotificationsScreen extends StatefulWidget {
  const WorkerNotificationsScreen({super.key});

  @override
  State<WorkerNotificationsScreen> createState() => _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState extends State<WorkerNotificationsScreen> {
  String _selectedTab = 'all';
  
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'booking',
      'icon': Icons.calendar_today,
      'iconColor': Color(0xFF3B82F6),
      'iconBg': Color(0xFFDBEAFE),
      'title': 'New Booking Request',
      'description': 'John Smith requested plumbing service for tomorrow at 2:00 PM',
      'time': '5 min ago',
      'isRead': false,
    },
    {
      'id': 2,
      'type': 'message',
      'icon': Icons.chat_bubble_outline,
      'iconColor': Color(0xFF10B981),
      'iconBg': Color(0xFFD1FAE5),
      'title': 'New Message',
      'description': 'Sarah Johnson: "Thank you for the excellent service!"',
      'time': '15 min ago',
      'isRead': false,
    },
    {
      'id': 3,
      'type': 'payment',
      'icon': Icons.attach_money,
      'iconColor': Color(0xFF10B981),
      'iconBg': Color(0xFFD1FAE5),
      'title': 'Payment Received',
      'description': 'You received \$150 for Pipe Repair service',
      'time': '1 hour ago',
      'isRead': false,
    },
    {
      'id': 4,
      'type': 'review',
      'icon': Icons.star_outline,
      'iconColor': Color(0xFFFBBF24),
      'iconBg': Color(0xFFFEF3C7),
      'title': 'New Review',
      'description': 'Michael Chen left a 5-star review for your service',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'id': 5,
      'type': 'completed',
      'icon': Icons.check_circle_outline,
      'iconColor': Color(0xFF10B981),
      'iconBg': Color(0xFFD1FAE5),
      'title': 'Booking Completed',
      'description': 'Your booking with David Wilson has been completed',
      'time': '3 hours ago',
      'isRead': true,
    },
    {
      'id': 6,
      'type': 'appointment',
      'icon': Icons.access_time,
      'iconColor': Color(0xFFEF4444),
      'iconBg': Color(0xFFFEE2E2),
      'title': 'Upcoming Appointment',
      'description': 'You have a booking scheduled in 30 minutes',
      'time': '5 hours ago',
      'isRead': true,
    },
    {
      'id': 7,
      'type': 'offer',
      'icon': Icons.card_giftcard_outlined,
      'iconColor': Color(0xFF8B5CF6),
      'iconBg': Color(0xFFEDE9FE),
      'title': 'Special Offer',
      'description': 'Get 20% off on emergency service bookings this weekend!',
      'time': '1 day ago',
      'isRead': true,
    },
  ];

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedTab == 'unread') {
      return _notifications.where((n) => !n['isRead']).toList();
    }
    return _notifications;
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _markAsRead(int id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n['id'] == id);
      notification['isRead'] = true;
    });
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
          child: Column(
            children: [
              // Header
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
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                      onPressed: _markAllAsRead,
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

              // Tabs
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
                            'All (${_notifications.length})',
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
                        onTap: () => setState(() => _selectedTab = 'unread'),
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

              // Notifications List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _filteredNotifications.isEmpty
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
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return GestureDetector(
      onTap: () => _markAsRead(notification['id']),
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
                      if (!notification['isRead'])
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
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
