// 🔥 خدمة إدارة الغرف — Firebase Firestore
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../constants/game_questions.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _roomsCollection = 'wahid_fina_rooms';

  // 🔍 البحث عن غرفة متاحة أو إنشاء غرفة جديدة
  Future<String> findOrCreateRoom(PlayerModel player) async {
    // البحث عن غرفة تنتظر لاعبين (استعلام بسيط لتجنب Composite Index)
    final waitingRooms = await _db
        .collection(_roomsCollection)
        .where('status', isEqualTo: 'waiting')
        .limit(15)
        .get();

    final docs = List<QueryDocumentSnapshot>.from(waitingRooms.docs);
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aMax = aData['maxPlayers'] as int? ?? 0;
      final bMax = bData['maxPlayers'] as int? ?? 0;
      final cmp = aMax.compareTo(bMax);
      if (cmp != 0) return cmp;
      final aTime = aData['createdAt'] != null ? (aData['createdAt'] as Timestamp).toDate() : DateTime.now();
      final bTime = bData['createdAt'] != null ? (bData['createdAt'] as Timestamp).toDate() : DateTime.now();
      return aTime.compareTo(bTime);
    });

    for (final doc in docs) {
      final room = RoomModel.fromFirestore(doc);

      // التحقق من أن الغرفة لم تمتلئ
      if (room.players.length < room.maxPlayers) {
        // التحقق من عدم وجود لاعبَين struggling في نفس الغرفة
        bool canJoin = true;
        if (player.role == PlayerRole.struggling) {
          canJoin = !room.players.any((p) => p.role == PlayerRole.struggling);
        }

        if (canJoin) {
          await _joinRoom(room.roomId, player);
          return room.roomId;
        }
      }
    }

    // لم يتم العثور على غرفة — إنشاء غرفة جديدة
    return await _createRoom(player);
  }

  // 🏗️ إنشاء غرفة جديدة — توليد كود 6 أرقام
  Future<String> _createRoom(PlayerModel player) async {
    final random = Random();
    final maxPlayers = random.nextBool() ? 5 : 6; // 5 أو 6 لاعبين عشوائياً
    final questions = GameQuestions.getRandomQuestions(count: 10);

    // كود فريد 6 أرقام
    String code;
    bool exists = true;
    do {
      code = (100000 + random.nextInt(900000)).toString();
      final dup = await _db
          .collection(_roomsCollection)
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      exists = dup.docs.isNotEmpty;
    } while (exists);

    final roomRef = _db.collection(_roomsCollection).doc();
    final room = RoomModel(
      roomId: roomRef.id,
      code: code,
      players: [player],
      status: RoomStatus.waiting,
      currentQuestionIndex: 0,
      questions: questions,
      allAnswers: [],
      createdAt: DateTime.now(),
      maxPlayers: maxPlayers,
      // اللاعب struggling هو من أنشأ الغرفة لو كان struggling
      strugglingPlayerId: player.role == PlayerRole.struggling ? player.id : null,
    );

    await roomRef.set(room.toFirestore());
    return roomRef.id;
  }

  // ➕ الانضمام لغرفة موجودة
  Future<void> _joinRoom(String roomId, PlayerModel player) async {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) throw Exception('الغرفة مش موجودة');

      final room = RoomModel.fromFirestore(snapshot);
      if (room.players.length >= room.maxPlayers) throw Exception('الغرفة ممتلئة');
      if (room.status != RoomStatus.waiting) throw Exception('اللعبة بدأت');

      final updatedPlayers = [...room.players, player];
      
      // تحديد الشخص struggling
      String? strugglingId = room.strugglingPlayerId;
      if (player.role == PlayerRole.struggling && strugglingId == null) {
        strugglingId = player.id;
      }

      Map<String, dynamic> updates = {
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'strugglingPlayerId': strugglingId,
      };

      // لو الغرفة امتلأت — ابدأ اللعبة
      if (updatedPlayers.length >= room.maxPlayers) {
        updates['status'] = 'intro';
      }

      transaction.update(roomRef, updates);
    });
  }

  // 🔢 الانضمام لغرفة بالكود (6 أرقام)
  Future<String> joinRoomByCode(String code, PlayerModel player) async {
    final snap = await _db
        .collection(_roomsCollection)
        .where('code', isEqualTo: code.trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) throw Exception('مفيش غرفة بالكود ده 🤔');
    final room = RoomModel.fromFirestore(snap.docs.first);

    if (room.status != RoomStatus.waiting) throw Exception('اللعبة دي بدأت خلاص');
    if (room.players.length >= room.maxPlayers) throw Exception('الغرفة ممتلئة');
    if (room.players.any((p) => p.id == player.id)) return room.roomId;

    await _joinRoom(room.roomId, player);
    return room.roomId;
  }

  // 📡 Stream الغرفة (Real-time)
  Stream<RoomModel> getRoomStream(String roomId) {
    return _db
        .collection(_roomsCollection)
        .doc(roomId)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => RoomModel.fromFirestore(snap));
  }

  // ✍️ إرسال إجابة
  Future<void> submitAnswer({
    required String roomId,
    required String playerId,
    required String playerName,
    required String answer,
    required int questionIndex,
  }) async {
    final playerAnswer = PlayerAnswer(
      playerId: playerId,
      playerName: playerName,
      answer: answer,
      questionIndex: questionIndex,
    );

    await _db.collection(_roomsCollection).doc(roomId).update({
      'allAnswers': FieldValue.arrayUnion([playerAnswer.toMap()]),
    });
  }

  // ⏭️ الانتقال للسؤال التالي (يُستدعى من admin — أول لاعب أجاب)
  Future<void> moveToNextQuestion({
    required String roomId,
    required int nextIndex,
    required String? aiComment,
    required bool isLastQuestion,
  }) async {
    await _db.collection(_roomsCollection).doc(roomId).update({
      'currentQuestionIndex': nextIndex,
      'aiComment': aiComment,
      'status': isLastQuestion ? 'revealing' : 'playing',
    });
  }

  // 🏁 إنهاء اللعبة وتسجيل الرسالة النهائية
  Future<void> finishGame({
    required String roomId,
    required String finalAiMessage,
  }) async {
    await _db.collection(_roomsCollection).doc(roomId).update({
      'status': 'finished',
      'finalAiMessage': finalAiMessage,
    });
  }

  // 🚪 مغادرة الغرفة
  Future<void> leaveRoom(String roomId, String playerId) async {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(roomRef);
      if (!snap.exists) return;

      final room = RoomModel.fromFirestore(snap);
      final updatedPlayers = room.players.where((p) => p.id != playerId).toList();

      if (updatedPlayers.isEmpty) {
        // حذف الغرفة لو ما فيش لاعبين
        transaction.delete(roomRef);
      } else {
        transaction.update(roomRef, {
          'players': updatedPlayers.map((p) => p.toMap()).toList(),
        });
      }
    });
  }

  // 🔄 إعادة اللعبة
  Future<void> resetRoom(String roomId) async {
    final questions = GameQuestions.getRandomQuestions(count: 10);
    await _db.collection(_roomsCollection).doc(roomId).update({
      'status': 'waiting',
      'currentQuestionIndex': 0,
      'questions': questions,
      'allAnswers': [],
      'aiComment': null,
      'finalAiMessage': null,
    });
  }

  // 🧹 تنظيف الغرف القديمة (اختياري)
  Future<void> cleanupOldRooms() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));
    final old = await _db
        .collection(_roomsCollection)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .where('status', isNotEqualTo: 'finished')
        .get();

    final batch = _db.batch();
    for (final doc in old.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
