import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fix_now_app/Services/db.dart';

class InboxThread {
  final String threadId;
  final String otherUid;
  final String otherName;
  final String
  otherPhotoUrl; // not used by your rules, kept for UI compatibility
  final String lastMessageText;
  final int lastMessageAt;
  final int unreadCount;

  const InboxThread({
    required this.threadId,
    required this.otherUid,
    required this.otherName,
    required this.otherPhotoUrl,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.unreadCount,
  });
}

class ChatService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _db;

  ChatService({FirebaseAuth? auth, FirebaseDatabase? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? DB.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  DatabaseReference get _threadsRef => _db.ref('chatThreads');
  DatabaseReference get _msgsRef => _db.ref('chatMessages');
  DatabaseReference get _userThreadsRef => _db.ref('userThreads');
  DatabaseReference get _threadUnreadRef => _db.ref('threadUnread');

  /// Used by your screens for connection indicator
  DatabaseReference connectedRef() => _db.ref('.info/connected');

  /// Deterministic thread id so customer/worker always land in the same thread
  String _threadIdForPair(String a, String b) {
    final x = a.trim();
    final y = b.trim();
    if (x.isEmpty || y.isEmpty) throw Exception('Missing uid for thread');
    final sorted = [x, y]..sort();
    // Use a stable prefix to avoid accidental numeric keys
    return 't_${sorted[0]}_${sorted[1]}';
  }

  /// Ensures chatMessages/{threadId} is a Map. If it's corrupted legacy data (string),
  /// remove it so push() can create children under it.
  Future<void> _ensureThreadMessagesNodeIsMap(String threadId) async {
    final parentRef = _msgsRef.child(threadId);
    final snap = await parentRef.get();
    if (!snap.exists) return;

    final v = snap.value;
    if (v is Map) return;

    // Rules allow delete only if parent is string and user is a participant (via chatThreads participants check).
    // We call this after confirming thread exists with me in participants.
    await parentRef.remove();
  }

  Future<String> createOrGetThread({
    required String otherUid,
    required String myRole, // 'customer' or 'worker'
    required String otherRole, // kept for compatibility
    required String otherName,
    required String myName,
  }) async {
    final me = _uid;
    final other = otherUid.trim(); 
    if (other.isEmpty) throw Exception('Missing otherUid');

    final threadId = _threadIdForPair(me, other);
    final threadRef = _threadsRef.child(threadId);

    Map<String, dynamic> buildThreadPayload() {
      return <String, dynamic>{
        'participants': {me: true, other: true},
        'createdAt': ServerValue.timestamp,
        'lastMessageAt': ServerValue.timestamp,
        'lastMessageText': '',
        if (myRole == 'customer') ...{
          'customerUid': me,
          'workerUid': other,
          'customerName': myName,
          'workerName': otherName,
        } else ...{
          'customerUid': other,
          'workerUid': me,
          'customerName': otherName,
          'workerName': myName,
        },
      };
    }

    // 1) Try reading existing thread.
    // If read is denied (thread doesn't exist yet per your rules) we fall back to create.
    DataSnapshot? snap;
    try {
      snap = await threadRef.get();
    } catch (_) {
      snap = null;
    }

    // 2) If thread exists and is a Map, ensure my membership records exist and return.
    if (snap != null && snap.exists) {
      final v = snap.value;

      if (v is Map) {
        final tmap = Map<String, dynamic>.from(v as Map);
        final parts = (tmap['participants'] is Map)
            ? Map<String, dynamic>.from(tmap['participants'] as Map)
            : <String, dynamic>{};

        if (parts[me] != true) {
          throw Exception('Not a participant of this thread');
        }

        // Ensure both users have list/unread nodes
        await _userThreadsRef.child(me).child(threadId).set(true);
        await _userThreadsRef.child(other).child(threadId).set(true);

        final myUnread = await _threadUnreadRef.child(me).child(threadId).get();
        if (!myUnread.exists) {
          await _threadUnreadRef.child(me).child(threadId).set(0);
        }
        final otherUnread = await _threadUnreadRef
            .child(other)
            .child(threadId)
            .get();
        if (!otherUnread.exists) {
          await _threadUnreadRef.child(other).child(threadId).set(0);
        }

        return threadId;
      }

      // If it exists but is corrupted (string or other), delete and recreate.
      try {
        await threadRef.remove();
      } catch (_) {}
    }

    // 3) Create thread (or recreate after deleting corrupted node).
    // Important: for corrupted string nodes, remove() is allowed by your rules.
    // For non-existent nodes, remove() is harmless.
    try {
      await threadRef.remove();
    } catch (_) {}

    await threadRef.set(buildThreadPayload());

    await _userThreadsRef.child(me).child(threadId).set(true);
    await _userThreadsRef.child(other).child(threadId).set(true);

    await _threadUnreadRef.child(me).child(threadId).set(0);
    await _threadUnreadRef.child(other).child(threadId).set(0);

    return threadId;
  }

  /// Messages stream used by both conversation screens
  Query messagesQuery(String threadId) {
    return _msgsRef.child(threadId).orderByChild('createdAt');
  }

  /// Send a text message. Updates:
  /// - chatMessages/{threadId}/{messageId}
  /// - chatThreads/{threadId} lastMessageAt/lastMessageText
  /// - userThreads/{me}/{threadId} = true
  /// - userThreads/{other}/{threadId} = true
  /// - threadUnread/{other}/{threadId} increment
  /// - threadUnread/{me}/{threadId} set 0
  Future<void> sendTextMessage({
    required String threadId,
    required String text,
    required String otherUid,
  }) async {
    final me = _uid;
    final other = otherUid.trim();
    final msg = text.trim();
    if (msg.isEmpty) return;
    if (msg.length > 2000) {
      throw Exception('Message too long (max 2000 chars)');
    }

    final threadRef = _threadsRef.child(threadId);
    final threadSnap = await threadRef.get();
    if (!threadSnap.exists) {
      throw Exception('Thread not found');
    }

    // Confirm participant and allow message cleanup if needed
    final tv = threadSnap.value;
    if (tv is! Map) throw Exception('Thread corrupted');
    final tmap = Map<String, dynamic>.from(tv as Map);
    final parts = (tmap['participants'] is Map)
        ? Map<String, dynamic>.from(tmap['participants'] as Map)
        : <String, dynamic>{};
    if (parts[me] != true || parts[other] != true) {
      throw Exception('Invalid participants for this thread');
    }

    await _ensureThreadMessagesNodeIsMap(threadId);

    final msgRef = _msgsRef.child(threadId).push();
    final messageId = msgRef.key;
    if (messageId == null) throw Exception('Failed to create message id');

    // Must satisfy chatMessages write rule:
    // senderId == auth.uid, text string length 1..2000, createdAt number
    await msgRef.set({
      'senderId': me,
      'text': msg,
      'createdAt': ServerValue.timestamp,
      'type': 'text',
    });

    // Update thread last message fields (required by validate)
    await threadRef.update({
      'lastMessageAt': ServerValue.timestamp,
      'lastMessageText': msg,
    });

    // Ensure both users have this thread in their list (boolean true)
    await _userThreadsRef.child(me).child(threadId).set(true);
    await _userThreadsRef.child(other).child(threadId).set(true);

    // Sender unread is always 0
    await _threadUnreadRef.child(me).child(threadId).set(0);

    // Receiver unread increments
    await _threadUnreadRef.child(other).child(threadId).runTransaction((curr) {
      final n = (curr is int) ? curr : int.tryParse('$curr') ?? 0;
      return Transaction.success(n + 1);
    });
  }

  /// When opening a conversation, mark unread as 0 for current user
  Future<void> markThreadRead({required String threadId}) async {
    final me = _uid;
    await _threadUnreadRef.child(me).child(threadId).set(0);
  }

  /// Stream of inbox items for the current user, already merged with unread counts.
  /// This is the right way with your rules (since userThreads stores only true).
  Stream<List<InboxThread>> inboxStream() {
    final me = _uid;

    // We listen to userThreads first (thread IDs), then for each thread we listen to:
    // - chatThreads/{threadId}
    // - threadUnread/{me}/{threadId}
    //
    // We rebuild the combined list whenever something changes.
    late StreamController<List<InboxThread>> controller;
    StreamSubscription<DatabaseEvent>? subUserThreads;
    final Map<String, StreamSubscription<DatabaseEvent>> subThreads = {};
    final Map<String, StreamSubscription<DatabaseEvent>> subUnread = {};
    final Map<String, Map<String, dynamic>> threadCache = {};
    final Map<String, int> unreadCache = {};

    void emit() {
      final items = <InboxThread>[];
      for (final entry in threadCache.entries) {
        final threadId = entry.key;
        final t = entry.value;

        final customerUid = (t['customerUid'] ?? '').toString();
        final workerUid = (t['workerUid'] ?? '').toString();
        final customerName = (t['customerName'] ?? 'Customer').toString();
        final workerName = (t['workerName'] ?? 'Worker').toString();

        final otherUid = (me == customerUid) ? workerUid : customerUid;
        final otherName = (me == customerUid) ? workerName : customerName;

        final lastText = (t['lastMessageText'] ?? '').toString();

        final lastAt = (t['lastMessageAt'] is int)
            ? t['lastMessageAt'] as int
            : int.tryParse('${t['lastMessageAt'] ?? 0}') ?? 0;

        final unread = unreadCache[threadId] ?? 0;

        items.add(
          InboxThread(
            threadId: threadId,
            otherUid: otherUid,
            otherName: otherName,
            otherPhotoUrl: '',
            lastMessageText: lastText,
            lastMessageAt: lastAt,
            unreadCount: unread,
          ),
        );
      }

      items.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      if (!controller.isClosed) controller.add(items);
    }

    Future<void> attachThread(String threadId) async {
      if (subThreads.containsKey(threadId)) return;

      subThreads[threadId] = _threadsRef.child(threadId).onValue.listen((ev) {
        final v = ev.snapshot.value;
        if (v is Map) {
          threadCache[threadId] = Map<String, dynamic>.from(v as Map);
        } else {
          threadCache.remove(threadId);
        }
        emit();
      });

      subUnread[threadId] = _threadUnreadRef
          .child(me)
          .child(threadId)
          .onValue
          .listen((ev) {
            final v = ev.snapshot.value;
            final n = (v is int) ? v : int.tryParse('$v') ?? 0;
            unreadCache[threadId] = n;
            emit();
          });
    }

    Future<void> detachThread(String threadId) async {
      await subThreads.remove(threadId)?.cancel();
      await subUnread.remove(threadId)?.cancel();
      threadCache.remove(threadId);
      unreadCache.remove(threadId);
      emit();
    }

    controller = StreamController<List<InboxThread>>.broadcast(
      onListen: () {
        subUserThreads = _userThreadsRef.child(me).onValue.listen((ev) async {
          final v = ev.snapshot.value;
          final ids = <String>{};

          if (v is Map) {
            final m = Map<String, dynamic>.from(v as Map);
            for (final e in m.entries) {
              if (e.value == true) ids.add(e.key);
            }
          }

          // Attach new
          for (final id in ids) {
            await attachThread(id);
          }

          // Detach removed
          final existing = subThreads.keys.toList();
          for (final id in existing) {
            if (!ids.contains(id)) {
              await detachThread(id);
            }
          }
        });
      },
      onCancel: () async {
        await subUserThreads?.cancel();
        for (final s in subThreads.values) {
          await s.cancel();
        }
        for (final s in subUnread.values) {
          await s.cancel();
        }
        await controller.close();
      },
    );

    return controller.stream;
  }
}
