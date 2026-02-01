import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/chat_service.dart';
import 'customer_chat_conversation_screen.dart';

class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  final _chat = ChatService();

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
              // Header + unread (dynamic)
              Padding(
                padding: const EdgeInsets.all(20),
                child: StreamBuilder(
                  stream: _chat.inboxQuery().onValue,
                  builder: (context, snapshot) {
                    int unreadTotal = 0;

                    if (snapshot.hasData) {
                      final event = snapshot.data as DatabaseEvent;
                      final data = event.snapshot.value;

                      if (data != null) {
                        final map = Map<String, dynamic>.from(data as Map);
                        for (final e in map.entries) {
                          final t = Map<String, dynamic>.from(e.value as Map);
                          final u = t['unreadCount'];
                          if (u is int) unreadTotal += u;
                        }
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$unreadTotal unread',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Search Bar (still UI only for now)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Color(0xFF9CA3AF),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search conversations...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Conversations List (THIS is where your StreamBuilder goes)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: FutureBuilder<DataSnapshot>(
                    future: _chat.inboxOnce(),
                    builder: (context, firstSnap) {
                      // 1) First load: always ends (success or error)
                      if (firstSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (firstSnap.hasError) {
                        return Center(child: Text('Inbox error: ${firstSnap.error}'));
                      }

                      final firstData = firstSnap.data?.value;

                      // Empty inbox
                      if (firstData == null) {
                        return const Center(child: Text('No conversations yet'));
                      }

                      // 2) After first load, keep it live
                      return StreamBuilder<DatabaseEvent>(
                        stream: _chat.inboxQuery().onValue,
                        builder: (context, snap) {
                          final data = snap.data?.snapshot.value;

                          if (snap.hasError) {
                            return Center(child: Text('Live error: ${snap.error}'));
                          }

                          if (data == null) {
                            return const Center(child: Text('No conversations yet'));
                          }

                          final map = Map<String, dynamic>.from(data as Map);

                          final threads = map.entries.map((e) {
                            final t = Map<String, dynamic>.from(e.value as Map);

                            final unread = (t['unreadCount'] is int)
                                ? t['unreadCount'] as int
                                : int.tryParse('${t['unreadCount'] ?? 0}') ?? 0;

                            final lastAt = (t['lastMessageAt'] is int)
                                ? t['lastMessageAt'] as int
                                : int.tryParse('${t['lastMessageAt'] ?? 0}') ?? 0;

                            return {
                              'threadId': e.key,
                              'otherUid': (t['otherUid'] ?? '').toString(),
                              'otherName': (t['otherName'] ?? 'User').toString(),
                              'otherPhotoUrl': (t['otherPhotoUrl'] ?? '').toString(),
                              'lastMessageText': (t['lastMessageText'] ?? '').toString(),
                              'unreadCount': unread,
                              'lastMessageAt': lastAt,
                            };
                          }).toList();

                          threads.sort((a, b) {
                            final aa = (a['lastMessageAt'] as int?) ?? 0;
                            final bb = (b['lastMessageAt'] as int?) ?? 0;
                            return bb.compareTo(aa);
                          });

                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: threads.length,
                            itemBuilder: (context, index) {
                              return _buildConversationCard(threads[index]);
                            },
                          );
                        },
                      );
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

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final unread = (conversation['unreadCount'] as int?) ?? 0;
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: () async {
        final threadId = conversation['threadId'] as String;
        final otherUid = conversation['otherUid'] as String;
        final otherName = conversation['otherName'] as String;

        await _chat.markThreadRead(threadId: threadId);

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerChatConversationScreen(
              threadId: threadId,
              otherUid: otherUid,
              otherName: otherName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? const Color(0xFF4A7FFF).withOpacity(0.3)
                : const Color(0xFFE5E7EB),
            width: hasUnread ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (conversation['otherPhotoUrl'] as String).isNotEmpty
                      ? Image.network(
                          conversation['otherPhotoUrl'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Color(0xFF4A7FFF),
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xFF4A7FFF),
                          size: 28,
                        ),
                ),
              ],
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
                          conversation['otherName'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      // You can format lastMessageAt later
                      const SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (conversation['lastMessageText'] as String).isNotEmpty
                              ? conversation['lastMessageText'] as String
                              : 'Tap to start chatting',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF9CA3AF),
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
