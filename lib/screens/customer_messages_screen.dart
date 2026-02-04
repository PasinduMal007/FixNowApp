import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_chat_conversation_screen.dart';

class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  late final ChatService _chat;

  @override
  void initState() {
    super.initState();
    _chat = ChatService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _chat.connectedRef().onValue,
        builder: (context, connSnap) {
          final isConnected = connSnap.data?.snapshot.value == true;

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
                  if (!isConnected)
                    Container(
                      color: Colors.orange.withOpacity(0.8),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isConnected ? 'Checking inbox... ' : 'Connecting... ',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, authSnap) {
                      final uid = authSnap.data?.uid ?? 'None';
                      return Container(
                        padding: const EdgeInsets.all(4),
                      );
                    },
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: StreamBuilder<List<InboxThread>>(
                      stream: _chat.inboxStream(),
                      builder: (context, snapshot) {
                        int unreadTotal = 0;
                        final threads = snapshot.data ?? const <InboxThread>[];
                        for (final t in threads) {
                          unreadTotal += t.unreadCount;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

                  // Conversations List
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
                          if (list.isEmpty) {
                            return const Center(
                              child: Text('No conversations yet'),
                            );
                          }

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
                                },
                              )
                              .toList();

                          return ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: threads.length,
                            itemBuilder: (context, index) {
                              return _buildConversationCard(threads[index]);
                            },
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

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final unread = (conversation['unreadCount'] as int?) ?? 0;
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: () async {
        final threadId = conversation['threadId'] as String;
        final otherUid = conversation['otherUid'] as String;
        final otherName = conversation['otherName'] as String;

        if (!threadId.startsWith('mock_')) {
          try {
            await _chat
                .markThreadRead(threadId: threadId)
                .timeout(const Duration(seconds: 1));
          } catch (e) {
            debugPrint('DEBUG: markThreadRead error or timeout: $e');
          }
        }

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
