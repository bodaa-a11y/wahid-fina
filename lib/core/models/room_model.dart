// 📝 نموذج الغرفة
import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_model.dart';

enum RoomStatus {
  waiting,    // بيستنى لاعبين
  intro,      // عرض مقدمة "في الغرفة دي واحد فينا"
  playing,    // اللعبة شغالة
  revealing,  // بنكشف مين واحد فينا
  finished,   // اللعبة خلصت
}

class PlayerAnswer {
  final String playerId;
  final String playerName;
  final String answer;
  final int questionIndex;

  const PlayerAnswer({
    required this.playerId,
    required this.playerName,
    required this.answer,
    required this.questionIndex,
  });

  factory PlayerAnswer.fromMap(Map<String, dynamic> map) => PlayerAnswer(
    playerId: map['playerId'] as String,
    playerName: map['playerName'] as String,
    answer: map['answer'] as String,
    questionIndex: map['questionIndex'] as int,
  );

  Map<String, dynamic> toMap() => {
    'playerId': playerId,
    'playerName': playerName,
    'answer': answer,
    'questionIndex': questionIndex,
  };
}

class RoomModel {
  final String roomId;
  final String code; // كود الغرفة المكون من 6 أرقام
  final List<PlayerModel> players;
  final RoomStatus status;
  final int currentQuestionIndex;
  final List<String> questions;
  final List<PlayerAnswer> allAnswers;
  final String? aiComment;
  final String? finalAiMessage;
  final String? strugglingPlayerId;
  final DateTime createdAt;
  final int maxPlayers;

  const RoomModel({
    required this.roomId,
    this.code = '',
    required this.players,
    required this.status,
    required this.currentQuestionIndex,
    required this.questions,
    required this.allAnswers,
    this.aiComment,
    this.finalAiMessage,
    this.strugglingPlayerId,
    required this.createdAt,
    this.maxPlayers = 5,
  });

  // عدد الإجابات للسؤال الحالي
  int get answersForCurrentQuestion =>
      allAnswers.where((a) => a.questionIndex == currentQuestionIndex).length;

  // هل الكل أجاب على السؤال الحالي؟
  bool get allPlayersAnswered =>
      answersForCurrentQuestion >= players.length;

  // هل اللاعب أجاب على السؤال الحالي؟
  bool hasPlayerAnswered(String playerId) =>
      allAnswers.any((a) => a.playerId == playerId && a.questionIndex == currentQuestionIndex);

  // إجابات سؤال معين
  List<PlayerAnswer> answersForQuestion(int questionIndex) =>
      allAnswers.where((a) => a.questionIndex == questionIndex).toList();

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      roomId: doc.id,
      code: data['code'] as String? ?? '',
      players: (data['players'] as List<dynamic>?)
          ?.map((p) => PlayerModel.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      status: _parseStatus(data['status'] as String? ?? 'waiting'),
      currentQuestionIndex: (data['currentQuestionIndex'] as int?) ?? 0,
      questions: List<String>.from(data['questions'] as List? ?? []),
      allAnswers: (data['allAnswers'] as List<dynamic>?)
          ?.map((a) => PlayerAnswer.fromMap(a as Map<String, dynamic>))
          .toList() ?? [],
      aiComment: data['aiComment'] as String?,
      finalAiMessage: data['finalAiMessage'] as String?,
      strugglingPlayerId: data['strugglingPlayerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxPlayers: (data['maxPlayers'] as int?) ?? 5,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'code': code,
    'players': players.map((p) => p.toMap()).toList(),
    'status': _statusToString(status),
    'currentQuestionIndex': currentQuestionIndex,
    'questions': questions,
    'allAnswers': allAnswers.map((a) => a.toMap()).toList(),
    'aiComment': aiComment,
    'finalAiMessage': finalAiMessage,
    'strugglingPlayerId': strugglingPlayerId,
    'createdAt': Timestamp.fromDate(createdAt),
    'maxPlayers': maxPlayers,
  };

  static RoomStatus _parseStatus(String s) {
    switch (s) {
      case 'intro': return RoomStatus.intro;
      case 'playing': return RoomStatus.playing;
      case 'revealing': return RoomStatus.revealing;
      case 'finished': return RoomStatus.finished;
      default: return RoomStatus.waiting;
    }
  }

  static String _statusToString(RoomStatus s) {
    switch (s) {
      case RoomStatus.intro: return 'intro';
      case RoomStatus.playing: return 'playing';
      case RoomStatus.revealing: return 'revealing';
      case RoomStatus.finished: return 'finished';
      default: return 'waiting';
    }
  }

  RoomModel copyWith({
    String? roomId,
    String? code,
    List<PlayerModel>? players,
    RoomStatus? status,
    int? currentQuestionIndex,
    List<String>? questions,
    List<PlayerAnswer>? allAnswers,
    String? aiComment,
    String? finalAiMessage,
    String? strugglingPlayerId,
    DateTime? createdAt,
    int? maxPlayers,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      code: code ?? this.code,
      players: players ?? this.players,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questions: questions ?? this.questions,
      allAnswers: allAnswers ?? this.allAnswers,
      aiComment: aiComment ?? this.aiComment,
      finalAiMessage: finalAiMessage ?? this.finalAiMessage,
      strugglingPlayerId: strugglingPlayerId ?? this.strugglingPlayerId,
      createdAt: createdAt ?? this.createdAt,
      maxPlayers: maxPlayers ?? this.maxPlayers,
    );
  }
}
