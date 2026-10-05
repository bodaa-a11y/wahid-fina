// 🕹️ متحكم حالة الروم (RoomController) — State Machine وفق وثيقة تصميم "واحد فينا"
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_questions.dart';
import '../../core/services/bot_engine.dart';
import '../../core/models/player_model.dart';
import '../../core/models/vault_message_model.dart';
import '../../core/models/care_tree_model.dart';

enum RoomPhase {
  roleSelection, // الشاشة 1
  matching,      // الشاشة 2
  lobby,         // الشاشة 3
  question,      // الشاشة 4
  voting,        // الشاشة 5
  reveal,        // الشاشة 6
  support,       // الشاشة 7
  results,       // الشاشة 8
  postRoom,      // الشاشة 9
}

class RoomPlayerInfo {
  final String alias;
  final bool isHuman;
  final bool isRain;
  final Color color;
  bool isReady;
  String currentAnswer;
  bool isTyping;
  List<String> reactions;
  String? vote;
  String? supportMessage;

  RoomPlayerInfo({
    required this.alias,
    required this.isHuman,
    required this.isRain,
    required this.color,
    this.isReady = false,
    this.currentAnswer = '',
    this.isTyping = false,
    List<String>? reactions,
    this.vote,
    this.supportMessage,
  }) : reactions = reactions ?? [];
}

class RoomState {
  final RoomPhase phase;
  final String myAlias;
  final bool isMyRoleRain;
  final bool isNotAloneMode; // وضع اليد الممدودة (F4)
  final String? selectedStory; // رومات نفس الحكاية (F10)
  final List<RoomPlayerInfo> players;
  final List<QuestionData> questions;
  final int currentRound; // 0 to 9 (1 to 10)
  final int timerSeconds;
  final bool hasSubmittedAnswer;
  final bool isReadingPhase; // 15s reading after answers submitted
  final String? myVote;
  final bool hasVoted;
  final String? rainPlayerAlias;
  final String? rainPlayerBestQuote;
  final int empathyPointsEarned;
  final int insightPointsEarned;
  final String? bestGuesserAlias;
  final String? bestSupporterAlias;
  final String? bestCamouflageAlias;
  final String? resonancePairAlias; // نفس الموجة (F2)
  final bool crisisDetected;

  const RoomState({
    required this.phase,
    required this.myAlias,
    required this.isMyRoleRain,
    this.isNotAloneMode = false,
    this.selectedStory,
    required this.players,
    required this.questions,
    this.currentRound = 0,
    this.timerSeconds = 45,
    this.hasSubmittedAnswer = false,
    this.isReadingPhase = false,
    this.myVote,
    this.hasVoted = false,
    this.rainPlayerAlias,
    this.rainPlayerBestQuote,
    this.empathyPointsEarned = 0,
    this.insightPointsEarned = 0,
    this.bestGuesserAlias,
    this.bestSupporterAlias,
    this.bestCamouflageAlias,
    this.resonancePairAlias,
    this.crisisDetected = false,
  });

  RoomState copyWith({
    RoomPhase? phase,
    String? myAlias,
    bool? isMyRoleRain,
    bool? isNotAloneMode,
    String? selectedStory,
    List<RoomPlayerInfo>? players,
    List<QuestionData>? questions,
    int? currentRound,
    int? timerSeconds,
    bool? hasSubmittedAnswer,
    bool? isReadingPhase,
    String? myVote,
    bool? hasVoted,
    String? rainPlayerAlias,
    String? rainPlayerBestQuote,
    int? empathyPointsEarned,
    int? insightPointsEarned,
    String? bestGuesserAlias,
    String? bestSupporterAlias,
    String? bestCamouflageAlias,
    String? resonancePairAlias,
    bool? crisisDetected,
  }) {
    return RoomState(
      phase: phase ?? this.phase,
      myAlias: myAlias ?? this.myAlias,
      isMyRoleRain: isMyRoleRain ?? this.isMyRoleRain,
      isNotAloneMode: isNotAloneMode ?? this.isNotAloneMode,
      selectedStory: selectedStory ?? this.selectedStory,
      players: players ?? this.players,
      questions: questions ?? this.questions,
      currentRound: currentRound ?? this.currentRound,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      hasSubmittedAnswer: hasSubmittedAnswer ?? this.hasSubmittedAnswer,
      isReadingPhase: isReadingPhase ?? this.isReadingPhase,
      myVote: myVote ?? this.myVote,
      hasVoted: hasVoted ?? this.hasVoted,
      rainPlayerAlias: rainPlayerAlias ?? this.rainPlayerAlias,
      rainPlayerBestQuote: rainPlayerBestQuote ?? this.rainPlayerBestQuote,
      empathyPointsEarned: empathyPointsEarned ?? this.empathyPointsEarned,
      insightPointsEarned: insightPointsEarned ?? this.insightPointsEarned,
      bestGuesserAlias: bestGuesserAlias ?? this.bestGuesserAlias,
      bestSupporterAlias: bestSupporterAlias ?? this.bestSupporterAlias,
      bestCamouflageAlias: bestCamouflageAlias ?? this.bestCamouflageAlias,
      resonancePairAlias: resonancePairAlias ?? this.resonancePairAlias,
      crisisDetected: crisisDetected ?? this.crisisDetected,
    );
  }
}

class RoomController extends StateNotifier<RoomState> {
  Timer? _countdownTimer;
  List<BotPlayer> _bots = [];
  final Map<String, List<String>> _allAnswersHistory = {};

  RoomController()
      : super(const RoomState(
          phase: RoomPhase.roleSelection,
          myAlias: 'نور',
          isMyRoleRain: false,
          players: [],
          questions: [],
        ));

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── 1. اختيار الدور والدخول في المطابقة ────────────────────────────────────
  void selectRoleAndMatch({
    required bool wantsRainRole,
    bool isNotAloneMode = false,
    String? story,
  }) {
    state = state.copyWith(
      isMyRoleRain: wantsRainRole || isNotAloneMode,
      isNotAloneMode: isNotAloneMode,
      selectedStory: story,
      phase: RoomPhase.matching,
      timerSeconds: 15,
      myAlias: 'نور',
      players: [
        RoomPlayerInfo(
          alias: 'نور',
          isHuman: true,
          isRain: wantsRainRole || isNotAloneMode,
          color: const Color(0xFF6C5CE7),
        ),
      ],
    );

    // بدء عداد المطابقة (15 ثانية كحد أقصى ثم التعبئة بالبوتات)
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerSeconds > 1) {
        state = state.copyWith(timerSeconds: state.timerSeconds - 1);
      } else {
        timer.cancel();
        _fillWithBotsAndEnterLobby();
      }
    });
  }

  // ── 2. تعبئة الروم والانتقال للمدخل (Lobby) ─────────────────────────────────
  void _fillWithBotsAndEnterLobby() {
    _countdownTimer?.cancel();

    // اختيار أسئلة متدرجة الـ 10 (مع الأسئلة الخاصة بالقصة إن وُجدت F10)
    final stagedQuestions = GameQuestionsBank.getStagedQuestions(story: state.selectedStory);

    // توليد 5 بوتات لتكملة الـ 6
    _bots = BotEngine.generateBots(
      count: 5,
      needRainPlayer: !state.isMyRoleRain,
      humanAlias: state.myAlias,
    );

    final playerList = <RoomPlayerInfo>[
      state.players.first, // اللاعب البشري
    ];

    for (final b in _bots) {
      playerList.add(RoomPlayerInfo(
        alias: b.alias,
        isHuman: false,
        isRain: b.isRain,
        color: b.avatarColor,
      ));
    }

    // تحديد صاحب المطر للروم
    final rainPlayer = playerList.firstWhere((p) => p.isRain, orElse: () => playerList.first);

    state = state.copyWith(
      phase: RoomPhase.lobby,
      players: playerList,
      questions: stagedQuestions,
      rainPlayerAlias: rainPlayer.alias,
      timerSeconds: 30,
    );

    // محاكاة ضغط البوتات على "جاهز" بتأخير عشوائي
    for (int i = 1; i < playerList.length; i++) {
      final delay = 1500 + Random().nextInt(3000);
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted || state.phase != RoomPhase.lobby) return;
        final updated = List<RoomPlayerInfo>.from(state.players);
        if (i < updated.length) {
          updated[i].isReady = true;
          state = state.copyWith(players: updated);
          _checkAllReadyAndStart();
        }
      });
    }
  }

  void toggleHumanReady() {
    final updated = List<RoomPlayerInfo>.from(state.players);
    updated[0].isReady = true;
    state = state.copyWith(players: updated);
    _checkAllReadyAndStart();
  }

  void _checkAllReadyAndStart() {
    if (state.players.every((p) => p.isReady)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && state.phase == RoomPhase.lobby) {
          _startQuestionRound(0);
        }
      });
    }
  }

  // ── 3. جولات الأسئلة (Question Round 1–10) ──────────────────────────────────
  void _startQuestionRound(int roundIndex) {
    _countdownTimer?.cancel();

    // تنظيف إجابات الجولة السابقة
    final resetPlayers = state.players.map((p) {
      p.currentAnswer = '';
      p.isTyping = false;
      p.reactions.clear();
      return p;
    }).toList();

    state = state.copyWith(
      phase: RoomPhase.question,
      currentRound: roundIndex,
      timerSeconds: 45,
      hasSubmittedAnswer: false,
      isReadingPhase: false,
      players: resetPlayers,
    );

    // بدء مؤقت الجولة (45 ثانية إجابة)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerSeconds > 1) {
        state = state.copyWith(timerSeconds: state.timerSeconds - 1);
      } else {
        timer.cancel();
        if (!state.hasSubmittedAnswer) {
          submitAnswer('صامت ومكتفي بالاستماع 🤍');
        }
      }
    });

    // تحفيز البوتات للبدء في الكتابة وتوليد إجاباتها
    _triggerBotAnswers(roundIndex);
  }

  void _triggerBotAnswers(int roundIndex) {
    final q = state.questions[roundIndex];

    for (int i = 0; i < _bots.length; i++) {
      final bot = _bots[i];
      final botIndex = i + 1;

      // إظهار مؤشر "يكتب..." بعد 1-3 ثواني
      Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(2000)), () {
        if (!mounted || state.phase != RoomPhase.question || state.currentRound != roundIndex) return;
        final updated = List<RoomPlayerInfo>.from(state.players);
        if (botIndex < updated.length) {
          updated[botIndex].isTyping = true;
          state = state.copyWith(players: updated);
        }
      });

      // إرسال الإجابة بعد مهلة واقعية
      BotEngine.generateAnswer(bot: bot, question: q).then((ans) {
        if (!mounted || state.phase != RoomPhase.question || state.currentRound != roundIndex) return;
        final updated = List<RoomPlayerInfo>.from(state.players);
        if (botIndex < updated.length) {
          updated[botIndex].isTyping = false;
          updated[botIndex].currentAnswer = ans;
          _allAnswersHistory.putIfAbsent(bot.alias, () => []).add(ans);
          state = state.copyWith(players: updated);
          _checkAllAnswered();
        }
      });
    }
  }

  void submitAnswer(String answer) {
    if (state.hasSubmittedAnswer) return;

    final trimmed = answer.trim();

    // فحص الأمان النفسي والكشف الفوري للأزمة
    if (_detectCrisis(trimmed)) {
      state = state.copyWith(crisisDetected: true);
    }

    final updated = List<RoomPlayerInfo>.from(state.players);
    updated[0].currentAnswer = trimmed.isEmpty ? '...' : trimmed;
    _allAnswersHistory.putIfAbsent(state.myAlias, () => []).add(updated[0].currentAnswer);

    state = state.copyWith(
      hasSubmittedAnswer: true,
      players: updated,
      empathyPointsEarned: state.empathyPointsEarned + 2, // +2 شجاعة وإجابة صادقة
    );

    _checkAllAnswered();
  }

  bool _detectCrisis(String text) {
    final crisisWords = ['انتحار', 'أموت', 'أنهي حياتي', 'أؤذي نفسي', 'مش عايز أعيش'];
    for (final w in crisisWords) {
      if (text.contains(w)) return true;
    }
    return false;
  }

  void closeCrisisOverlay() {
    state = state.copyWith(crisisDetected: false);
  }

  void _checkAllAnswered() {
    if (state.players.every((p) => p.currentAnswer.isNotEmpty)) {
      // الـ 6 لاعبين أجابوا! الانتقال لمرحلة القراءة والتفاعل (15 ثانية)
      _countdownTimer?.cancel();
      state = state.copyWith(isReadingPhase: true, timerSeconds: 15);

      // البوتات ترسل تفاعلاتها الودودة
      _simulateBotReactions();

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.timerSeconds > 1) {
          state = state.copyWith(timerSeconds: state.timerSeconds - 1);
        } else {
          timer.cancel();
          // الانتقال للسؤال التالي أو مرحلة التصويت بعد الجولة العاشرة
          if (state.currentRound < 9) {
            _startQuestionRound(state.currentRound + 1);
          } else {
            // في وضع اليد الممدودة F4، نتخطى التصويت والكشف ونبدأ الدعم مباشرة
            if (state.isNotAloneMode) {
              _startSupportPhase();
            } else {
              _startVotingPhase();
            }
          }
        }
      });
    }
  }

  void sendReaction(String targetAlias, String reaction) {
    final updated = List<RoomPlayerInfo>.from(state.players);
    final target = updated.firstWhere((p) => p.alias == targetAlias, orElse: () => updated.first);
    if (!target.reactions.contains(reaction)) {
      target.reactions.add(reaction);
      state = state.copyWith(players: updated);
    }
  }

  void _simulateBotReactions() {
    final answersMap = {for (var p in state.players) p.alias: p.currentAnswer};
    final botReactions = BotEngine.generateBotReactions(bots: _bots, allAnswers: answersMap);

    botReactions.forEach((alias, reacts) {
      final target = state.players.firstWhere((p) => p.alias == alias, orElse: () => state.players.first);
      for (final r in reacts) {
        if (!target.reactions.contains(r)) {
          target.reactions.add(r);
        }
      }
    });
  }

  // ── 4. مرحلة التصويت (Voting Phase) ─────────────────────────────────────────
  void _startVotingPhase() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      phase: RoomPhase.voting,
      timerSeconds: 30,
      hasVoted: false,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerSeconds > 1) {
        state = state.copyWith(timerSeconds: state.timerSeconds - 1);
      } else {
        timer.cancel();
        _finalizeVotesAndReveal();
      }
    });

    // البوتات تصوت وفق نقاط الشك بعد تأخير 3–12 ثانية
    for (final bot in _bots) {
      final vote = BotEngine.calculateBotVote(
        votingBot: bot,
        allPlayerAnswersAcrossRounds: _allAnswersHistory,
      );
      Future.delayed(Duration(milliseconds: 3000 + Random().nextInt(7000)), () {
        if (!mounted || state.phase != RoomPhase.voting) return;
        final updated = List<RoomPlayerInfo>.from(state.players);
        final p = updated.firstWhere((pl) => pl.alias == bot.alias, orElse: () => updated.first);
        p.vote = vote;
        state = state.copyWith(players: updated);
        if (state.players.every((pl) => pl.vote != null)) {
          _countdownTimer?.cancel();
          _finalizeVotesAndReveal();
        }
      });
    }
  }

  void submitHumanVote(String guessedAlias) {
    if (state.hasVoted) return;

    final updated = List<RoomPlayerInfo>.from(state.players);
    updated[0].vote = guessedAlias;

    state = state.copyWith(
      myVote: guessedAlias,
      hasVoted: true,
      players: updated,
    );

    if (state.players.every((p) => p.vote != null)) {
      _countdownTimer?.cancel();
      _finalizeVotesAndReveal();
    }
  }

  // ── 5. الكشف والدعم (Reveal & Support Phase) ─────────────────────────────────
  void _finalizeVotesAndReveal() {
    _countdownTimer?.cancel();

    // اهتزاز حسي لطيف بدون أي صوت خسارة (F6)
    HapticFeedback.mediumImpact();

    final rainAlias = state.rainPlayerAlias ?? 'قمر';
    final rainAnswers = _allAnswersHistory[rainAlias] ?? ['صوتك مسموع ومشاعرك مقدرة'];
    final bestQuote = rainAnswers.isNotEmpty ? rainAnswers.last : 'معكم حسيت بدفا كبير';

    state = state.copyWith(
      phase: RoomPhase.reveal,
      rainPlayerBestQuote: bestQuote,
      timerSeconds: 5,
    );

    // بعد 4 ثواني أنيميشن الكشف الانتقال لشاشة رسائل الدعم
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && state.phase == RoomPhase.reveal) {
        _startSupportPhase();
      }
    });
  }

  void _startSupportPhase() {
    state = state.copyWith(
      phase: RoomPhase.support,
      timerSeconds: 45,
    );

    // البوتات ترسل رسائل دعم دافئة
    for (final bot in _bots) {
      final msg = BotEngine.generateSupportMessage(bot);
      Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(5000)), () {
        if (!mounted || state.phase != RoomPhase.support) return;
        final updated = List<RoomPlayerInfo>.from(state.players);
        final p = updated.firstWhere((pl) => pl.alias == bot.alias, orElse: () => updated.first);
        p.supportMessage = msg;
        state = state.copyWith(players: updated);
      });
    }
  }

  void submitSupportMessage(String message) {
    final updated = List<RoomPlayerInfo>.from(state.players);
    final finalMsg = message.trim().isEmpty ? 'كلنا جنبك وسند ليك 🤗' : message.trim();
    updated[0].supportMessage = finalMsg;

    // حفظ رسالة الدعم في صندوق الدعم (F1)
    SupportVaultStorage.addMessage(
      VaultMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: finalMsg,
        fromAlias: state.myAlias,
        date: DateTime.now(),
      ),
    );

    // تحديث شجرة الدعم (F3)
    CareTreeStorage.recordAction(addLeaves: 1, addStars: 1);

    state = state.copyWith(
      players: updated,
      empathyPointsEarned: state.empathyPointsEarned + 5, // +5 دعم بعد الكشف
    );

    // انتقال للنتائج بعد إرسال الدعم
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _calculateResults();
    });
  }

  // ── 6. شاشة النتائج وتوزيع الجوائز (Results & Awards) ─────────────────────────
  void _calculateResults() {
    final rainAlias = state.rainPlayerAlias ?? '';
    final isHumanCorrect = (state.myVote == rainAlias);

    // حساب أفضل كاشف
    String bestGuesser = isHumanCorrect ? state.myAlias : '';
    if (bestGuesser.isEmpty) {
      for (final p in state.players) {
        if (p.vote == rainAlias) {
          bestGuesser = p.alias;
          break;
        }
      }
    }
    if (bestGuesser.isEmpty) bestGuesser = state.players.first.alias;

    // حساب أفضل داعم (أعلى تفاعلات)
    String bestSupporter = state.players.first.alias;
    int maxReactions = -1;
    for (final p in state.players) {
      if (p.reactions.length > maxReactions) {
        maxReactions = p.reactions.length;
        bestSupporter = p.alias;
      }
    }

    // حساب أفضل تمويه (صاحب المطر إن خمّ عليه أقل عدد)
    final votesOnRain = state.players.where((p) => p.vote == rainAlias).length;
    final bestCamo = votesOnRain <= 2 ? rainAlias : 'فانوس';

    int insightEarned = isHumanCorrect ? 15 : 0;
    if (state.isMyRoleRain && votesOnRain <= 1) insightEarned += 10;

    // مضاعفة نقاط التعاطف لوضع اليد الممدودة F4
    int finalEmpathy = state.empathyPointsEarned;
    if (state.isNotAloneMode) {
      finalEmpathy *= 2;
    }

    // تحديد شريك "نفس الموجة" F2
    String? resonanceMatch;
    if (_bots.isNotEmpty) {
      resonanceMatch = _bots[Random().nextInt(_bots.length)].alias;
    }

    state = state.copyWith(
      phase: RoomPhase.results,
      bestGuesserAlias: bestGuesser,
      bestSupporterAlias: bestSupporter,
      bestCamouflageAlias: bestCamo,
      resonancePairAlias: resonanceMatch,
      empathyPointsEarned: finalEmpathy,
      insightPointsEarned: state.insightPointsEarned + insightEarned,
    );
  }

  void goToPostRoom() {
    state = state.copyWith(phase: RoomPhase.postRoom);
  }

  void restartMatch() {
    selectRoleAndMatch(
      wantsRainRole: state.isMyRoleRain,
      isNotAloneMode: state.isNotAloneMode,
      story: state.selectedStory,
    );
  }
}

final roomControllerProvider = StateNotifierProvider<RoomController, RoomState>((ref) {
  return RoomController();
});
