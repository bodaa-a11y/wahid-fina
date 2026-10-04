import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../models/one_to_one_models.dart';

class OneToOneService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _roomsCollection = 'one_to_one_rooms';
  static const String _usersCollection = 'Users';

  // 1. حفظ ملف المستخدم الشخصي
  Future<void> saveUserProfile(PlayerModel player) async {
    await _db.collection(_usersCollection).doc(player.id).set(
      player.toMap(),
      SetOptions(merge: true),
    );
  }

  // 2. جلب ملف المستخدم الشخصي
  Future<PlayerModel?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return PlayerModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  // 3. تحديث نقاط التعاطف والجلسات المكتملة
  Future<void> updateUserStats(String uid, int pointsToAdd) async {
    try {
      final userRef = _db.collection(_usersCollection).doc(uid);
      await userRef.set({
        'sessionsCompleted': FieldValue.increment(1),
        'empathyPoints': FieldValue.increment(pointsToAdd),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user stats: $e");
    }
  }

  // 4. حظر مستخدم آخر
  Future<void> blockUser(String currentUserId, String userToBlockId) async {
    await _db.collection(_usersCollection).doc(currentUserId).set({
      'blockedUsers': FieldValue.arrayUnion([userToBlockId])
    }, SetOptions(merge: true));
  }

  // 5. البحث عن غرفة فضفضة ثنائية أو إنشاؤها
  Future<String> findOrCreateRoom(PlayerModel currentUser, String topic) async {
    // جلب قائمة المحظورين أولاً
    final userDoc = await _db.collection(_usersCollection).doc(currentUser.id).get();
    List<dynamic> blockedUsers = [];
    if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('blockedUsers')) {
      blockedUsers = userDoc.data()!['blockedUsers'] ?? [];
    }

    // البحث عن غرفة تنتظر
    final availableRooms = await _db.collection(_roomsCollection)
        .where('status', isEqualTo: 'waiting')
        .where('topic', isEqualTo: topic)
        .limit(10)
        .get();

    String? validRoomId;

    for (var doc in availableRooms.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      final existingUserId = participants.isNotEmpty ? participants.first : '';

      // عدم مطابقة المستخدمين مع المحظورين أو مع نفسه
      if (existingUserId.isNotEmpty && 
          existingUserId != currentUser.id && 
          !blockedUsers.contains(existingUserId)) {
        validRoomId = doc.id;
        break;
      }
    }

    if (validRoomId != null) {
      await _db.collection(_roomsCollection).doc(validRoomId).update({
        'participants': FieldValue.arrayUnion([currentUser.id]),
        'status': 'active',
      });
      return validRoomId;
    } else {
      final newRoomRef = await _db.collection(_roomsCollection).add({
        'participants': [currentUser.id],
        'status': 'waiting',
        'typingUsers': [],
        'topic': topic,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await newRoomRef.update({'roomId': newRoomRef.id});
      return newRoomRef.id;
    }
  }

  // 6. Stream لمتابعة الغرفة لحظياً
  Stream<OneToOneRoomModel> getRoomStream(String roomId) {
    return _db.collection(_roomsCollection).doc(roomId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return OneToOneRoomModel.fromMap(snapshot.data()!);
      }
      throw Exception('الغرفة غير موجودة');
    });
  }

  // 7. إرسال رسالة
  Future<void> sendMessage(String roomId, OneToOneMessageModel message) async {
    await _db.collection(_roomsCollection)
        .doc(roomId)
        .collection('Messages')
        .doc(message.messageId)
        .set(message.toMap());
  }

  // 8. التفاعل مع الرسائل (Reactions)
  Future<void> reactToMessage(String roomId, String messageId, String emoji) async {
    try {
      await _db.collection(_roomsCollection)
          .doc(roomId)
          .collection('Messages')
          .doc(messageId)
          .update({'reaction': emoji});
    } catch (e) {
      print("Error reacting to message: $e");
    }
  }

  // 9. Stream لمتابعة الرسائل
  Stream<List<OneToOneMessageModel>> getMessagesStream(String roomId) {
    return _db.collection(_roomsCollection)
        .doc(roomId)
        .collection('Messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OneToOneMessageModel.fromMap(doc.data()))
            .toList());
  }

  // 10. تحديث حالة الكتابة
  Future<void> setTypingStatus(String roomId, String uid, bool isTyping) async {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);
    if (isTyping) {
      await roomRef.update({'typingUsers': FieldValue.arrayUnion([uid])});
    } else {
      await roomRef.update({'typingUsers': FieldValue.arrayRemove([uid])});
    }
  }

  // 11. مغادرة الغرفة
  Future<void> leaveRoom(String roomId, String uid) async {
    await _db.collection(_roomsCollection).doc(roomId).update({
      'participants': FieldValue.arrayRemove([uid]),
      'status': 'closed',
    });
  }
}
