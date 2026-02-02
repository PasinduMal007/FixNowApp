import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/chat_service.dart';
import 'worker_chat_conversation_screen.dart';

class WorkerChatScreen extends StatefulWidget {
  final bool showBackButton;

  const WorkerChatScreen({super.key, this.showBackButton = true});

  @override
  State<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends State<WorkerChatScreen> {
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
              // Header + Search (static UI)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    if (widget.showBackButton)
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
                    if (widget.showBackButton) const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Messages',
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search conversations...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (_) {
                            // Optional: implement filtering later
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Conversations list (dynamic)
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
                      if (firstSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (firstSnap.hasError) {
                        return Center(
                          child: Text('Inbox error: ${firstSnap.error}'),
                        );
                      }

                      final firstData = firstSnap.data?.value;

                      // If no conversations node exists yet
                      if (firstData == null) {
                        return _emptyState();
                      }

                      // After first load, keep it live
                      return StreamBuilder<DatabaseEvent>(
                        stream: _chat.inboxQuery().onValue,
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Center(
                              child: Text('Live error: ${snap.error}'),
                            );
                          }

                          final data = snap.data?.snapshot.value;

                          // IMPORTANT: no spinner here
                          if (data == null) return _emptyState();

                          final map = Map<String, dynamic>.from(data as Map);

                          final threads = map.entries.map((e) {
                            final t = Map<String, dynamic>.from(e.value as Map);

                            final unread = (t['unreadCount'] is int)
                                ? t['unreadCount'] as int
                                : int.tryParse('${t['unreadCount'] ?? 0}') ?? 0;

                            final lastAt = (t['lastMessageAt'] is int)
                                ? t['lastMessageAt'] as int
                                : int.tryParse('${t['lastMessageAt'] ?? 0}') ??
                                      0;

                            return {
                              'threadId': e.key,
                              'otherUid': (t['otherUid'] ?? '').toString(),
                              'otherName': (t['otherName'] ?? 'Customer')
                                  .toString(),
                              'otherPhotoUrl': (t['otherPhotoUrl'] ?? '')
                                  .toString(),
                              'lastMessageText': (t['lastMessageText'] ?? '')
                                  .toString(),
                              'unreadCount': unread,
                              'lastMessageAt': lastAt,
                              'service': (t['service'] ?? '').toString(),
                              'rating': (t['rating'] is num)
                                  ? (t['rating'] as num).toDouble()
                                  : double.tryParse('${t['rating'] ?? ''}') ??
                                        0.0,
                              'isOnline': (t['isOnline'] == true),
                            };
                          }).toList();

                          threads.sort((a, b) {
                            final aa = (a['lastMessageAt'] as int?) ?? 0;
                            final bb = (b['lastMessageAt'] as int?) ?? 0;
                            return bb.compareTo(aa);
                          });

                          if (threads.isEmpty) return _emptyState();

                          final unreadThreads = threads
                              .where(
                                (t) => ((t['unreadCount'] as int?) ?? 0) > 0,
                              )
                              .length;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  10,
                                  24,
                                  6,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$unreadThreads unread messages',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    10,
                                    24,
                                    100,
                                  ),
                                  itemCount: threads.length,
                                  itemBuilder: (context, index) {
                                    final conv = threads[index];
                                    return GestureDetector(
                                      onTap: () async {
                                        final tid = conv['threadId'] as String;
                                        await _chat.markThreadRead(
                                          threadId: tid,
                                        );

                                        if (!context.mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                WorkerChatConversationScreen(
                                                  threadId: tid,
                                                  otherUid:
                                                      conv['otherUid']
                                                          as String,
                                                  otherName:
                                                      conv['otherName']
                                                          as String,
                                                  customerName:
                                                      conv['otherName']
                                                          as String,
                                                  service:
                                                      (conv['service']
                                                          as String?) ??
                                                      '',
                                                  isOnline:
                                                      (conv['isOnline']
                                                          as bool?) ??
                                                      false,
                                                ),
                                          ),
                                        );
                                      },
                                      child: _buildConversationCard(conv),
                                    );
                                  },
                                ),
                              ),
                            ],
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final unread = (conversation['unreadCount'] as int?) ?? 0;
    final hasUnread = unread > 0;

    final name = (conversation['otherName'] ?? 'Customer').toString();
    final lastMsg = (conversation['lastMessageText'] ?? '').toString();
    final service = (conversation['service'] ?? '').toString();
    final rating = (conversation['rating'] as double?) ?? 0.0;
    final isOnline = (conversation['isOnline'] == true);

    // Optional: show simple relative time later if you want.
    // For now, keep it blank or use a placeholder.
    final timestampText = '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread ? const Color(0xFF4A7FFF) : const Color(0xFFE5E7EB),
          width: hasUnread ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar with online indicator + unread badge
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF4A7FFF),
                  size: 28,
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              if (hasUnread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: hasUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Text(
                      timestampText,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUnread
                            ? const Color(0xFF4A7FFF)
                            : const Color(0xFF9CA3AF),
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (service.isNotEmpty || rating > 0)
                  Row(
                    children: [
                      if (service.isNotEmpty)
                        Text(
                          service,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      if (service.isNotEmpty && rating > 0) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '•',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (rating > 0) ...[
                        const Icon(
                          Icons.star,
                          size: 12,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  lastMsg.isNotEmpty ? lastMsg : ' ',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasUnread
                        ? const Color(0xFF1F2937)
                        : const Color(0xFF9CA3AF),
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
