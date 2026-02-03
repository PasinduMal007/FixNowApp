import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    return u.uid;
  }

  DatabaseReference get _threadsRef => _db.ref('chatThreads');
  DatabaseReference get _msgsRef => _db.ref('chatMessages');
  DatabaseReference get _userThreadsRef => _db.ref('userThreads');

  Future<String> createOrGetThread({
    required String otherUid,
    required String myRole,
    required String otherRole,
    required String otherName,
    String? otherPhotoUrl,

    required String myName,
    String? myPhotoUrl,
  }) async {
    final me = _uid;

    final myThreadsSnap = await _userThreadsRef.child(me).get();
    if (myThreadsSnap.exists) {
      final map = Map<String, dynamic>.from(myThreadsSnap.value as Map);
      for (final entry in map.entries) {
        final t = Map<String, dynamic>.from(entry.value as Map);
        if ((t['otherUid'] ?? '').toString() == otherUid) {
          return entry.key; // threadId
        }
      }
    }

    final threadId = _threadsRef.push().key!;
    final now = ServerValue.timestamp;

    final threadData = {
      'customerUid': myRole == 'customer' ? me : otherUid,
      'workerUid': myRole == 'worker' ? me : otherUid,
      'lastMessageText': '',
      'lastMessageAt': now,
      'participants': {me: true, otherUid: true},
      'createdAt': now,
    };

    final myInboxItem = {
      'otherUid': otherUid,
      'otherName': otherName,
      'otherRole': otherRole,
      'otherPhotoUrl': otherPhotoUrl ?? '',
      'lastMessageText': '',
      'lastMessageAt': now,
      'unreadCount': 0,
    };

    final otherInboxItem = {
      'otherUid': me,
      'otherName': myName,
      'otherRole': myRole,
      'otherPhotoUrl': myPhotoUrl ?? '',
      'lastMessageText': '',
      'lastMessageAt': now,
      'unreadCount': 0,
    };

    await _db.ref().update({
      'chatThreads/$threadId': threadData,
      'userThreads/$me/$threadId': myInboxItem,
      'userThreads/$otherUid/$threadId': otherInboxItem,
    });

    return threadId;
  }

  Query messagesQuery(String threadId) {
    return _msgsRef.child(threadId).orderByChild('createdAt');
  }

  Query inboxQuery() {
    final path = 'userThreads/$_uid';
    print('DEBUG: inboxQuery path: $path');
    return _userThreadsRef.child(_uid);
  }

  Future<void> sendTextMessage({
    required String threadId,
    required String text,
    required String otherUid,
  }) async {
    final me = _uid;
    final msgId = _msgsRef.child(threadId).push().key!;
    final now = ServerValue.timestamp;

    final msg = {
      'senderId': me,
      'text': text,
      'createdAt': now,
      'type': 'text',
    };

    // 1) message
    await _msgsRef.child(threadId).child(msgId).set(msg);

    // 2) thread last
    await _threadsRef.child(threadId).update({
      'lastMessageText': text,
      'lastMessageAt': now,
    });

    // 3) my inbox last (my unread stays 0)
    await _userThreadsRef.child(me).child(threadId).update({
      'lastMessageText': text,
      'lastMessageAt': now,
      'unreadCount': 0,
    });

    // 4) other inbox unread increment + last
    final otherItemRef = _userThreadsRef.child(otherUid).child(threadId);

    await otherItemRef.child('unreadCount').runTransaction((value) {
      final current = (value is num) ? value.toInt() : 0;
      return Transaction.success(current + 1);
    });

    await otherItemRef.update({'lastMessageText': text, 'lastMessageAt': now});
  }

  Future<void> markThreadRead({required String threadId}) async {
    final me = _uid;
    await _userThreadsRef.child(me).child(threadId).update({'unreadCount': 0});
  }

  Future<DataSnapshot> inboxOnce() {
    return _userThreadsRef.child(_uid).get();
  }

  DatabaseReference connectedRef() {
    return _db.ref('.info/connected');
  }
}
