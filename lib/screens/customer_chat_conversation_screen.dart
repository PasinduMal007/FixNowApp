import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fix_now_app/Services/chat_service.dart';

class CustomerChatConversationScreen extends StatefulWidget {
  final String threadId;
  final String otherUid;
  final String otherName;

  const CustomerChatConversationScreen({
    super.key,
    required this.threadId,
    required this.otherUid,
    required this.otherName,
  });

  @override
  State<CustomerChatConversationScreen> createState() =>
      _CustomerChatConversationScreenState();
}

class _CustomerChatConversationScreenState
    extends State<CustomerChatConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chat = ChatService();

  final List<Map<String, dynamic>> _mockMessages = [
    {
      'senderId': 'other',
      'text': 'Hi there! How can I help you today?',
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    },
    {
      'senderId': 'me',
      'text': 'I need some help with my plumbing.',
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 8))
          .millisecondsSinceEpoch,
    },
    {
      'senderId': 'other',
      'text': 'Sure, what seems to be the problem?',
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch,
    },
    {
      'senderId': 'me',
      'text': 'The kitchen sink is leaking.',
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 2))
          .millisecondsSinceEpoch,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.threadId.startsWith('mock_')) {
      _chat.markThreadRead(threadId: widget.threadId);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (widget.threadId.startsWith('mock_')) {
      setState(() {
        _mockMessages.add({
          'senderId': 'me',
          'text': text,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      });
      _messageController.clear();
      _scrollToBottom();
      return;
    }

    _messageController.clear();
    await _chat.sendTextMessage(
      threadId: widget.threadId,
      text: text,
      otherUid: widget.otherUid,
    );
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    _sendAttachment(file, 'image');
  }

  Future<void> _pickDocument() async {
    const allowedExtensions = ['pdf', 'doc', 'docx', 'txt'];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result == null || result.files.single.path == null) return;

    File file = File(result.files.single.path!);
    _sendAttachment(file, 'file', fileName: result.files.single.name);
  }

  Future<void> _sendAttachment(
    File file,
    String type, {
    String? fileName,
  }) async {
    try {
      // Show "uploading..." state or a simple snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending ${type}...'),
          duration: const Duration(seconds: 1),
        ),
      );

      final url = await _chat.uploadAttachment(file, widget.threadId);

      await _chat.sendAttachmentMessage(
        threadId: widget.threadId,
        otherUid: widget.otherUid,
        fileUrl: url,
        type: type,
        fileName: fileName,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending attachment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                ),
                borderRadius: BorderRadius.circular(10),
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
                    widget.otherName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.threadId.startsWith('mock_')
                ? _buildMockListView(myUid)
                : _buildFirebaseListView(myUid),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMockListView(String? myUid) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _mockMessages.length,
      itemBuilder: (context, index) {
        final m = _mockMessages[index];
        final isMe = m['senderId'] == 'me';
        return _buildMessageBubble({
          'text': m['text'],
          'isMine': isMe,
          'type': 'text',
          'timestamp': '',
          'isRead': true,
        });
      },
    );
  }

  Widget _buildFirebaseListView(String? myUid) {
    return StreamBuilder<DatabaseEvent>(
      stream: _chat.messagesQuery(widget.threadId).onValue,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final val = snap.data?.snapshot.value;
        if (val == null) {
          return const Center(child: Text('Start a conversation'));
        }

        final map = Map<String, dynamic>.from(val as Map);
        final list = map.entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          return {'id': e.key, ...m};
        }).toList();

        list.sort((a, b) {
          final aa = (a['createdAt'] ?? 0) as int;
          final bb = (b['createdAt'] ?? 0) as int;
          return aa.compareTo(bb);
        });

        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final m = list[index];
            final isMine = (m['senderId']?.toString() == myUid);
            return _buildMessageBubble({
              'text': (m['text'] ?? '').toString(),
              'isMine': isMine,
              'type': (m['type'] ?? 'text').toString(),
              'fileUrl': m['fileUrl']?.toString(),
              'fileName': m['fileName']?.toString(),
              'timestamp': '',
              'isRead': true,
            });
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF6B7280),
                size: 22,
              ),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: const Icon(
                Icons.attach_file,
                color: Color(0xFF6B7280),
                size: 22,
              ),
              onPressed: _pickDocument,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF4A7FFF),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isMine = message['isMine'] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF4A7FFF) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message),
            ),
          ),
          if (isMine) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> message) {
    final bool isMine = message['isMine'] ?? false;
    final String type = message['type'] ?? 'text';

    if (type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message['fileUrl'],
              width: 200,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          ),
          if ((message['text'] ?? '').isNotEmpty &&
              message['text'] != '📷 Photo')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message['text'],
                style: TextStyle(
                  color: isMine ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      );
    }

    if (type == 'file') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            color: isMine ? Colors.white70 : const Color(0xFF4A7FFF),
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message['fileName'] ?? 'Document',
              style: TextStyle(
                color: isMine ? Colors.white : const Color(0xFF1F2937),
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      message['text'] ?? '',
      style: TextStyle(
        color: isMine ? Colors.white : const Color(0xFF1F2937),
        fontSize: 14,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
