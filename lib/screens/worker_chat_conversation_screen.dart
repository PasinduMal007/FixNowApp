import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fix_now_app/Services/chat_service.dart';

class WorkerChatConversationScreen extends StatefulWidget {
  final String customerName; // keep for UI fallback
  final String service;

  final String threadId;
  final String otherUid;
  final String otherName;

  const WorkerChatConversationScreen({
    super.key,
    required this.customerName,
    required this.service,
    required this.threadId,
    required this.otherUid,
    required this.otherName,
  });

  @override
  State<WorkerChatConversationScreen> createState() =>
      _WorkerChatConversationScreenState();
}

class _WorkerChatConversationScreenState
    extends State<WorkerChatConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final _chat = ChatService();
  late final String threadId;
  late final String otherUid;

  bool useMock = false;
  final List<Map<String, dynamic>> _mockMessages = [];

  @override
  void initState() {
    super.initState();

    threadId = widget.threadId;
    otherUid = widget.otherUid;
    useMock = threadId.startsWith('mock_');

    if (useMock) {
      _mockMessages.addAll([
        {
          'id': 'm1',
          'senderId': otherUid,
          'text': 'Hello! Are you available for an electrical repair?',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 10))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'm2',
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'text': 'Yes, I am. Where is the location?',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 8))
              .millisecondsSinceEpoch,
        },
        {
          'id': 'm3',
          'senderId': otherUid,
          'text': 'It\'s in Colombo 03. Can you come at 10 AM?',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .millisecondsSinceEpoch,
        },
      ]);
    }

    // Mark as read when opening
    if (!useMock) {
      _chat.markThreadRead(threadId: threadId).catchError((e) {
        debugPrint('DEBUG: markThreadRead error: $e');
      });
    }

    // Small delay so build finishes, then scroll if needed later
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    if (useMock) {
      setState(() {
        _mockMessages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'senderId': FirebaseAuth.instance.currentUser?.uid,
          'text': text,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      });
    } else {
      await _chat.sendTextMessage(
        threadId: threadId,
        text: text,
        otherUid: otherUid,
      );
    }

    if (!mounted) return;
    if (_isNearBottom()) _scrollToBottom(animated: true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending ${type}...'),
          duration: const Duration(seconds: 1),
        ),
      );

      final url = await _chat.uploadAttachment(file, threadId);

      if (useMock) {
        setState(() {
          _mockMessages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'senderId': FirebaseAuth.instance.currentUser?.uid,
            'text': (type == 'image') ? "Photo" : "Document",
            'type': type,
            'fileUrl': url,
            'fileName': fileName,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        });
      } else {
        await _chat.sendAttachmentMessage(
          threadId: threadId,
          otherUid: otherUid,
          fileUrl: url,
          type: type,
          fileName: fileName,
        );
      }

      if (_isNearBottom()) _scrollToBottom(animated: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending attachment: $e')));
      }
    }
  }

  void _scrollToBottom({required bool animated}) {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    return (max - current) < 120;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final titleName = widget.otherName.isNotEmpty
        ? widget.otherName
        : widget.customerName;

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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF4A7FFF),
                            size: 24,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleName + (useMock ? ' (MOCK)' : ''),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: useMock
                      ? _buildMockListView()
                      : StreamBuilder<DatabaseEvent>(
                          stream: _chat.messagesQuery(threadId).onValue,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final val = snapshot.data!.snapshot.value;
                            if (val == null) {
                              return const Center(
                                child: Text('No messages yet'),
                              );
                            }
                            if (val is! Map) {
                              return const Center(
                                child: Text('No messages yet'),
                              );
                            }

                            final raw = Map<dynamic, dynamic>.from(val as Map);
                            final list = raw.entries.map((e) {
                              final m = Map<String, dynamic>.from(
                                e.value as Map,
                              );
                              return {'id': e.key.toString(), ...m};
                            }).toList();

                            list.sort((a, b) {
                              final aa = _toInt(a['createdAt']);
                              final bb = _toInt(b['createdAt']);
                              return aa.compareTo(bb);
                            });

                            // After rebuild, scroll to bottom if user is already near bottom
                            if (_isNearBottom()) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _scrollToBottom(animated: false);
                              });
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final message = list[index];
                                final isMine =
                                    message['senderId'] ==
                                    FirebaseAuth.instance.currentUser?.uid;

                                return _buildMessageBubble(
                                  text: (message['text'] ?? '').toString(),
                                  isSent: isMine,
                                  type: (message['type'] ?? 'text').toString(),
                                  fileUrl: message['fileUrl']?.toString(),
                                  fileName: message['fileName']?.toString(),
                                  timestamp: '',
                                );
                              },
                            );
                          },
                        ),
                ),
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickDocument,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.attach_file,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A7FFF), Color(0xFF6B9FFF)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
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

  Widget _buildMockListView() {
    // After rebuild, scroll to bottom if user is already near bottom
    if (_isNearBottom()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _mockMessages.length,
      itemBuilder: (context, index) {
        final message = _mockMessages[index];
        final isMine =
            message['senderId'] == FirebaseAuth.instance.currentUser?.uid;

        return _buildMessageBubble(
          text: (message['text'] ?? '').toString(),
          isSent: isMine,
          type: (message['type'] ?? 'text').toString(),
          fileUrl: message['fileUrl']?.toString(),
          fileName: message['fileName']?.toString(),
          timestamp: 'Mock Time',
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isSent,
    required String timestamp,
    String type = 'text',
    String? fileUrl,
    String? fileName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F0FF), Color(0xFFD0E2FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF4A7FFF),
                size: 18,
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSent ? const Color(0xFF4A7FFF) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isSent ? 16 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 16),
                    ),
                  ),
                  child: _buildMessageContent(
                    text: text,
                    isSent: isSent,
                    type: type,
                    fileUrl: fileUrl,
                    fileName: fileName,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent({
    required String text,
    required bool isSent,
    required String type,
    String? fileUrl,
    String? fileName,
  }) {
    if (type == 'image' && fileUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fileUrl,
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
          if (text.isNotEmpty && text != 'Photo')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isSent ? Colors.white : const Color(0xFF1F2937),
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
            color: isSent ? Colors.white70 : const Color(0xFF4A7FFF),
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName ?? 'Document',
              style: TextStyle(
                fontSize: 14,
                color: isSent ? Colors.white : const Color(0xFF1F2937),
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: isSent ? Colors.white : const Color(0xFF1F2937),
      ),
    );
  }
}
