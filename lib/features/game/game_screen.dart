// 🎮 شاشة اللعبة الرئيسية — Game Screen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../../core/models/room_model.dart';
import '../results/results_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String roomId;
  final PlayerModel currentPlayer;

  const GameScreen({
    super.key,
    required this.roomId,
    required this.currentPlayer,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionController;
  late AnimationController _answersRevealController;
  late AnimationController _aiCommentController;
  
  int _lastProcessedQuestion = -1;
  bool _isProcessingTransition = false;
  StreamSubscription? _roomSub;

  @override
  void initState() {
    super.initState();
    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _answersRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _aiCommentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _questionController.forward();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answersRevealController.dispose();
    _aiCommentController.dispose();
    _roomSub?.cancel();
    super.dispose();
  }

  void _animateNewQuestion() {
    _questionController.reset();
    _questionController.forward();
    _answersRevealController.reset();
    _aiCommentController.reset();
  }

  Future<void> _handleAllAnswered(RoomModel room) async {
    if (_isProcessingTransition) return;
    if (room.currentQuestionIndex == _lastProcessedQuestion) return;

    // فقط الأول في القائمة يدير الانتقال (لتجنب التكرار)
    if (room.players.isNotEmpty && room.players.first.id != widget.currentPlayer.id) return;

    _isProcessingTransition = true;
    _lastProcessedQuestion = room.currentQuestionIndex;

    final gameNotifier = ref.read(gameNotifierProvider(widget.currentPlayer.id).notifier);
    final isLast = room.currentQuestionIndex >= room.questions.length - 1;

    if (isLast) {
      await gameNotifier.finishGame(roomId: widget.roomId, room: room);
    } else {
      await gameNotifier.processNextQuestion(
        roomId: widget.roomId,
        room: room,
        isLastQuestion: false,
      );
    }

    _isProcessingTransition = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RoomModel>>(roomStreamProvider(widget.roomId), (previous, next) {
      final prevIndex = previous?.value?.currentQuestionIndex;
      final nextIndex = next.value?.currentQuestionIndex;
      if (nextIndex != null && prevIndex != nextIndex) {
        _animateNewQuestion();
      }
    });

    final roomAsync = ref.watch(roomStreamProvider(widget.roomId));
    final gameState = ref.watch(gameNotifierProvider(widget.currentPlayer.id));

    return roomAsync.when(
      data: (room) {
        // الانتقال لشاشة النتائج
        if (room.status == RoomStatus.finished && room.finalAiMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ResultsScreen(
                  roomId: widget.roomId,
                  currentPlayer: widget.currentPlayer,
                ),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          });
        }

        // انتقال لمرحلة الكشف
        if (room.status == RoomStatus.revealing) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!_isProcessingTransition && 
                room.players.isNotEmpty && 
                room.players.first.id == widget.currentPlayer.id) {
              final gameNotifier = ref.read(gameNotifierProvider(widget.currentPlayer.id).notifier);
              await gameNotifier.finishGame(roomId: widget.roomId, room: room);
            }
          });
        }

        // الكل أجاب — ابدأ الانتقال
        if (room.allPlayersAnswered && room.status == RoomStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleAllAnswered(room));
        }

        final currentQuestion = room.questions.isNotEmpty && room.currentQuestionIndex < room.questions.length
            ? room.questions[room.currentQuestionIndex]
            : '';
        final currentAnswers = room.answersForQuestion(room.currentQuestionIndex);
        final hasAnswered = room.hasPlayerAnswered(widget.currentPlayer.id);

        return Scaffold(
          body: AppBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(room),

                  // Progress Dots
                  _buildProgressDots(room),

                  // Question Card
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // السؤال
                          _buildQuestionCard(currentQuestion, room.currentQuestionIndex, room.questions.length)
                              .animate(controller: _questionController)
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutBack),

                          const SizedBox(height: 16),

                          // خيارات الإجابة أو انتظار
                          if (!hasAnswered) ...[
                            _buildAnswerOptions(room, currentQuestion),
                          ] else ...[
                            _buildWaitingForOthers(room, currentAnswers),
                          ],

                          const SizedBox(height: 16),

                          // تعليق AI
                          if (room.aiComment != null && hasAnswered)
                            _buildAiComment(room.aiComment!)
                                .animate()
                                .fadeIn(duration: 600.ms, delay: 200.ms)
                                .slideY(begin: 0.2, end: 0, duration: 500.ms),

                          // لودينج AI
                          if (gameState.isLoadingAi)
                            _buildAiLoading(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('حدث خطأ: $e', style: GoogleFonts.cairo(color: AppColors.textPrimary)),
        ),
      ),
    );
  }

  Widget _buildHeader(RoomModel room) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // أيقونة الغرفة
          GlassCard(
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🫂', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  'واحد فينا',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // أيقونات اللاعبين المصغرة
          SizedBox(
            height: 36,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: room.players.length,
              separatorBuilder: (_, __) => const SizedBox(width: -8),
              itemBuilder: (context, i) {
                final player = room.players[i];
                final hasAns = room.hasPlayerAnswered(player.id);
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getAvatarColorForPlayer(player.name),
                    border: Border.all(
                      color: hasAns ? AppColors.success : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitialsForPlayer(player.name),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots(RoomModel room) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(room.questions.length, (i) {
          final isDone = i < room.currentQuestionIndex;
          final isCurrent = i == room.currentQuestionIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isCurrent ? 6 : 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDone
                    ? AppColors.primary
                    : isCurrent
                        ? AppColors.warm
                        : AppColors.border,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuestionCard(String question, int index, int total) {
    return GlassCard(
      gradient: AppColors.cardGradient,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  'سؤال ${index + 1} من $total',
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question,
            style: GoogleFonts.cairo(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(RoomModel room, String question) {
    // خيارات الإجابة بناءً على نوع الدور
    final isStruggling = widget.currentPlayer.role == PlayerRole.struggling;
    
    List<String> options;
    if (isStruggling) {
      options = _getStrugglingAnswers(question);
    } else {
      options = _getNormalAnswers(question);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 12),
          child: Text(
            'اختار إجابتك:',
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...options.asMap().entries.map((entry) {
          final i = entry.key;
          final option = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderRadius: 16,
              onTap: () {
                HapticFeedback.lightImpact();
                _submitAnswer(room, option);
              },
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.15),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.cairo(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.cairo(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              duration: 300.ms,
              delay: Duration(milliseconds: i * 80),
            ).slideX(begin: 0.2, end: 0),
          );
        }),

        // خيار الكتابة اليدوية
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _WriteAnswerField(
            onSubmit: (text) {
              HapticFeedback.lightImpact();
              _submitAnswer(room, text);
            },
          ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
        ),
      ],
    );
  }

  Widget _buildWaitingForOthers(RoomModel room, List<PlayerAnswer> currentAnswers) {
    final answeredCount = currentAnswers.length;
    final totalCount = room.players.length;

    return Column(
      children: [
        // إجابتك
        GlassCard(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
          ),
          child: Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'انتظر الباقين...',
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$answeredCount / $totalCount',
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // إجابات اللي أجابوا
        ...currentAnswers.map((answer) {
          final isMe = answer.playerId == widget.currentPlayer.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isMe ? '${answer.playerName} (أنت)' : answer.playerName,
                        style: GoogleFonts.cairo(
                          color: isMe ? AppColors.warm : AppColors.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Text('⭐', style: TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer.answer,
                    style: GoogleFonts.cairo(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
          );
        }),

        // شريط انتظار animated
        if (answeredCount < totalCount)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'بيستنى ${totalCount - answeredCount} شخص...',
                  style: GoogleFonts.cairo(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1500.ms,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
      ],
    );
  }

  Widget _buildAiComment(String comment) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [AppColors.warm.withOpacity(0.1), AppColors.warm.withOpacity(0.03)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.warmGradient,
            ),
            child: const Center(child: Text('✨', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رفيق',
                  style: GoogleFonts.cairo(
                    color: AppColors.warm,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: GoogleFonts.cairo(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiLoading() {
    return GlassCard(
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: AppColors.warm, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'رفيق بيفكر...',
            style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      duration: 1200.ms,
      color: AppColors.warm.withOpacity(0.2),
    );
  }

  void _submitAnswer(RoomModel room, String answer) {
    final gameNotifier = ref.read(gameNotifierProvider(widget.currentPlayer.id).notifier);
    gameNotifier.submitAnswer(
      roomId: widget.roomId,
      playerName: widget.currentPlayer.name,
      answer: answer,
      questionIndex: room.currentQuestionIndex,
    );
  }

  // إجابات الشخص العادي
  List<String> _getNormalAnswers(String question) {
    return [
      'بالنسبالي كويس الحمد لله، بمشي الحال',
      'بفكر في الموضوع ده كتير الفترة دي',
      'صعبة السؤال ده... بس هقول اللي في بالي',
      'ده سؤال مهم وعايز أتأمل فيه',
    ];
  }

  // إجابات الشخص اللي بيمر بوقت صعب
  List<String> _getStrugglingAnswers(String question) {
    return [
      'الحقيقة مش كويس أوي... بحاول أعدي بس',
      'الفترة دي تقيلة شوية على نفسي',
      'دايم بتجيلي الأسئلة دي وما بلاقيش إجابة',
      'في حاجات كتير جوايا محتاج أتكلم فيها',
    ];
  }

  Color _getAvatarColorForPlayer(String name) {
    const colors = [
      Color(0xFF7B5EA7), Color(0xFF5EA78B), Color(0xFFA75E5E),
      Color(0xFF5E7BA7), Color(0xFFA78B5E), Color(0xFF8B5EA7),
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  String _getInitialsForPlayer(String name) {
    if (name.isEmpty) return '؟';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name[0];
  }
}

// ✏️ حقل الكتابة اليدوية
class _WriteAnswerField extends StatefulWidget {
  final Function(String) onSubmit;
  const _WriteAnswerField({required this.onSubmit});

  @override
  State<_WriteAnswerField> createState() => _WriteAnswerFieldState();
}

class _WriteAnswerFieldState extends State<_WriteAnswerField> {
  final _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded ? AppColors.primary : AppColors.border,
          width: _isExpanded ? 2 : 1,
        ),
      ),
      child: _isExpanded
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 15),
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    minLines: 2,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'اكتب إجابتك هنا...',
                      hintStyle: GoogleFonts.cairo(color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isExpanded = false),
                        child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _controller.text.trim().length >= 2
                            ? () => widget.onSubmit(_controller.text.trim())
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(80, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('إرسال', style: GoogleFonts.cairo(color: Colors.white, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : InkWell(
              onTap: () => setState(() => _isExpanded = true),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'اكتب إجابتك بنفسك...',
                      style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
