import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      body: StreamBuilder(
        stream: _chat.connectedRef().onValue,
        builder: (context, connSnap) {
          final isConnected = connSnap.data?.snapshot.value == true;
          final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'None';

          return Container(
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
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                      child: StreamBuilder<List<InboxThread>>(
                        stream: _chat.inboxStream(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snap.hasError) {
                            return Center(
                              child: Text('Inbox error: ${snap.error}'),
                            );
                          }

                          final list = snap.data ?? const <InboxThread>[];
                          if (list.isEmpty) return _emptyState();

                          final threads = list
                              .map(
                                (t) => {
                                  'threadId': t.threadId,
                                  'otherUid': t.otherUid,
                                  'otherName': t.otherName,
                                  'otherPhotoUrl': t.otherPhotoUrl,
                                  'lastMessageText': t.lastMessageText,
                                  'unreadCount': t.unreadCount,
                                  'lastMessageAt': t.lastMessageAt,
                                  // extra fields expected by existing UI
                                  'service': '',
                                  'rating': 0.0,
                                  'isOnline': false,
                                },
                              )
                              .toList();

                          threads.sort((a, b) {
                            final aa = (a['lastMessageAt'] as int?) ?? 0;
                            final bb = (b['lastMessageAt'] as int?) ?? 0;
                            return bb.compareTo(aa);
                          });

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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'When customers message you, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final unread = (conversation['unreadCount'] as int?) ?? 0;
    final hasUnread = unread > 0;

    return Container(
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
                : const Icon(Icons.person, color: Color(0xFF4A7FFF), size: 28),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasUnread
                            ? const Color(0xFFFFE4E6)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        hasUnread ? 'Unread' : 'Read',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasUnread
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF9CA3AF),
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
    );
  }
}
