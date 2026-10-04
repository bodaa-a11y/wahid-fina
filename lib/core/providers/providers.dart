// 🏪 Riverpod Providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../services/claude_service.dart';
import '../services/one_to_one_service.dart';
import '../models/player_model.dart';
import '../models/room_model.dart';
import '../models/one_to_one_models.dart';

// --- Service Providers ---
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final roomServiceProvider = Provider<RoomService>((ref) => RoomService());
final claudeServiceProvider = Provider<ClaudeService>((ref) => ClaudeService());
final oneToOneServiceProvider = Provider<OneToOneService>((ref) => OneToOneService());

// --- Auth State ---
final currentPlayerProvider = StateProvider<PlayerModel?>((ref) => null);
final currentRoomIdProvider = StateProvider<String?>((ref) => null);

// --- Room Stream ---
final roomStreamProvider = StreamProvider.family<RoomModel, String>((ref, roomId) {
  final roomService = ref.watch(roomServiceProvider);
  return roomService.getRoomStream(roomId);
});

// --- Game State Notifier ---
class GameState {
  final bool isLoading;
  final bool hasAnswered;
  final String? selectedAnswer;
  final bool showingAnswers;
  final String? aiComment;
  final bool isLoadingAi;
  final String? error;

  const GameState({
    this.isLoading = false,
    this.hasAnswered = false,
    this.selectedAnswer,
    this.showingAnswers = false,
    this.aiComment,
    this.isLoadingAi = false,
    this.error,
  });

  GameState copyWith({
    bool? isLoading,
    bool? hasAnswered,
    String? selectedAnswer,
    bool? showingAnswers,
    String? aiComment,
    bool? isLoadingAi,
    String? error,
  }) {
    return GameState(
      isLoading: isLoading ?? this.isLoading,
      hasAnswered: hasAnswered ?? this.hasAnswered,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      showingAnswers: showingAnswers ?? this.showingAnswers,
      aiComment: aiComment ?? this.aiComment,
      isLoadingAi: isLoadingAi ?? this.isLoadingAi,
      error: error ?? this.error,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final RoomService _roomService;
  final ClaudeService _claudeService;
  final String _playerId;

  GameNotifier({
    required RoomService roomService,
    required ClaudeService claudeService,
    required String playerId,
  })  : _roomService = roomService,
        _claudeService = claudeService,
        _playerId = playerId,
        super(const GameState());

  // إرسال الإجابة
  Future<void> submitAnswer({
    required String roomId,
    required String playerName,
    required String answer,
    required int questionIndex,
  }) async {
    if (state.hasAnswered) return;

    state = state.copyWith(hasAnswered: true, selectedAnswer: answer, isLoading: true);

    try {
      await _roomService.submitAnswer(
        roomId: roomId,
        playerId: _playerId,
        playerName: playerName,
        answer: answer,
        questionIndex: questionIndex,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    state = state.copyWith(isLoading: false);
  }

  // الانتقال للسؤال التالي مع تعليق AI
  Future<void> processNextQuestion({
    required String roomId,
    required RoomModel room,
    required bool isLastQuestion,
  }) async {
    state = state.copyWith(isLoadingAi: true, showingAnswers: true);

    final currentAnswers = room.answersForQuestion(room.currentQuestionIndex);
    final answersMap = currentAnswers
        .map((a) => {'name': a.playerName, 'answer': a.answer})
        .toList();

    String? aiComment;
    try {
      aiComment = await _claudeService.getQuestionComment(
        question: room.questions[room.currentQuestionIndex],
        questionNumber: room.currentQuestionIndex + 1,
        totalQuestions: room.questions.length,
        answers: answersMap,
      );
    } catch (_) {}

    state = state.copyWith(isLoadingAi: false, aiComment: aiComment);

    // انتظر ثوانٍ لعرض الإجابات والتعليق
    await Future.delayed(const Duration(seconds: 3));

    // انتقل للسؤال التالي
    await _roomService.moveToNextQuestion(
      roomId: roomId,
      nextIndex: room.currentQuestionIndex + 1,
      aiComment: aiComment,
      isLastQuestion: isLastQuestion,
    );

    // إعادة تعيين الحالة للسؤال الجديد
    state = const GameState();
  }

  // إنهاء اللعبة
  Future<void> finishGame({
    required String roomId,
    required RoomModel room,
  }) async {
    state = state.copyWith(isLoadingAi: true);

    final strugglingPlayer = room.players.firstWhere(
      (p) => p.id == room.strugglingPlayerId,
      orElse: () => room.players.first,
    );

    final gameSummary = room.questions.asMap().entries.map((entry) {
      return {
        'question': entry.value,
        'answers': room.answersForQuestion(entry.key).map((a) => {
          'name': a.playerName,
          'answer': a.answer,
        }).toList(),
      };
    }).toList();

    String finalMessage;
    try {
      finalMessage = await _claudeService.getFinalMessage(
        strugglingPlayerName: strugglingPlayer.name,
        gameSummary: gameSummary,
        questions: room.questions,
      );
    } catch (_) {
      finalMessage = 'شكراً لكل واحد فيكم على صدقه وشجاعته. ❤️';
    }

    await _roomService.finishGame(
      roomId: roomId,
      finalAiMessage: finalMessage,
    );

    state = state.copyWith(isLoadingAi: false);
  }

  void resetForNewQuestion() {
    state = const GameState();
  }
}

// Provider للـ GameNotifier
final gameNotifierProvider = StateNotifierProvider.family<GameNotifier, GameState, String>(
  (ref, playerId) {
    return GameNotifier(
      roomService: ref.watch(roomServiceProvider),
      claudeService: ref.watch(claudeServiceProvider),
      playerId: playerId,
    );
  },
);
