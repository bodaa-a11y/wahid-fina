// 🎮 لعبة فردية بالبوتات — من غير Firebase
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/doctor_robot_widget.dart';
import '../../core/models/player_model.dart';
import '../../core/services/bot_engine.dart';
import '../../core/services/tts_service.dart';
import '../../core/providers/providers.dart';
import '../../core/constants/game_questions.dart';

class SoloGameScreen extends ConsumerStatefulWidget {
  final PlayerModel currentPlayer;
  const SoloGameScreen({super.key, required this.currentPlayer});

  @override
  ConsumerState<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends ConsumerState<SoloGameScreen> {
  static const int _totalQuestions = 8;
  static const int _maxPlayers = 6;

  late final List<BotPlayer> _bots;
  late final List<String> _questions;
  final Map<String, String> _currentAnswers = {}; // alias -> answer
  int _questionIndex = 0;
  bool _isSpeaking = false;
  bool _revealed = false;
  String? _myGuess;
  String _comment = '';
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    final needRain = widget.currentPlayer.role == PlayerRole.normal;
    _bots = BotEngine.generateBots(
      count: _maxPlayers - 1,
      needRainPlayer: needRain,
      humanAlias: widget.currentPlayer.name,
    );
    _questions = GameQuestions.getRandomQuestions(count: _totalQuestions);
    ref.read(ttsServiceProvider).onSpeakingChanged = (v) {
      if (mounted) setState(() => _isSpeaking = v);
    };
    _startQuestion();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  void _startQuestion() {
    setState(() {
      _currentAnswers.clear();
      _comment = '';
    });
    ref.read(ttsServiceProvider).speakQuestion(_questions[_questionIndex]);

    // البوتات بتجاوب بتأخير بشري
    for (final bot in _bots) {
      final delay = Duration(milliseconds: 2500 + Random().nextInt(4000));
      _timers.add(Timer(delay, () {
        if (!mounted || _revealed) return;
        setState(() {
          _currentAnswers[bot.alias] = _botAnswer(bot);
        });
        _checkAllAnswered();
      }));
    }
  }

  String _botAnswer(BotPlayer bot) {
    final pool = bot.isRain
        ? ['الفترة دي تقيلة أوي عليا...', 'مش عارف أرد بصراحة', 'بسأل نفسي نفس السؤال ده']
        : [
            'بالنسبالي تمام الحمد لله 🌸',
            'سؤال حلو! بفكر فيه كتير',
            'أنا مبسوط إني هنا معاكم',
            'الحياة بتعلمنا حاجات كتير',
            'كل حاجة بتعدي يا جماعة'
          ];
    return pool[Random().nextInt(pool.length)];
  }

  void _answer(String text) {
    HapticFeedback.lightImpact();
    setState(() => _currentAnswers[widget.currentPlayer.name] = text);
    _checkAllAnswered();
  }

  void _checkAllAnswered() {
    if (_currentAnswers.length < _maxPlayers) return;
    // كلهم أجابوا — تعليق ثم السؤال اللي بعده
    final struggling = _bots.any((b) => b.isRain);
    _comment = struggling
        ? 'حاسس إن في إجابة هنا فيها وجع أكتر مما يبدو... 🤍'
        : 'إجابات جميلة! في حد هنا بيخبي حاجة 🌧️';
    ref.read(ttsServiceProvider).speak(_comment);

    _timers.add(Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_questionIndex >= _totalQuestions - 1) {
        setState(() => _revealed = true);
        ref.read(ttsServiceProvider).speak('واحد فينا... محتاج سندكم دلوقتي. مين هو؟');
      } else {
        setState(() => _questionIndex++);
        _startQuestion();
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_questionIndex];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: _revealed
              ? _buildReveal()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    const SizedBox(height: 12),
                    Text(
                      'سؤال ${_questionIndex + 1} / $_totalQuestions',
                      style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),

                    // 🤖 الدكتور
                    DoctorRobotWidget(speaking: _isSpeaking, size: 140),
                    const SizedBox(height: 8),

                    // فقاعة السؤال
                    GlassCard(
                      gradient: AppColors.cardGradient,
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        question,
                        style: GoogleFonts.cairo(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ).animate(key: ValueKey(_questionIndex)).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    // الإجابات اللي وصلت
                    ..._currentAnswers.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Text(
                                e.key == widget.currentPlayer.name ? '⭐ أنت' : e.key,
                                style: GoogleFonts.cairo(
                                  color: AppColors.primaryLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ]),
                          ).animate().fadeIn(duration: 300.ms),
                        )),

                    // خياراتي لو لسه ما جاوبتش
                    if (!_currentAnswers.containsKey(widget.currentPlayer.name)) ...[
                      const SizedBox(height: 8),
                      ...[
                        'كويس الحمد لله 😊',
                        'سؤال فيه تفكير 🤔',
                        'صعب أوي السؤال ده',
                        'عايز أسمع من اللي معايا الأول'
                      ].map((opt) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassButton(
                              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                              borderRadius: 14,
                              onTap: () => _answer(opt),
                              child: Text(
                                opt,
                                style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 15),
                              ),
                            ),
                          )),
                    ],

                    if (_comment.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _comment,
                          style: GoogleFonts.cairo(
                            color: AppColors.warm,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 30),
                  ]),
                ),
        ),
      ),
    );
  }

  Widget _buildReveal() {
    final rain = _bots.firstWhere((b) => b.isRain, orElse: () => _bots.first);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 30),
        Text(
          '🌧️ واحد فينا...',
          style: GoogleFonts.cairo(color: AppColors.warm, fontSize: 28, fontWeight: FontWeight.w800),
        ).animate().fadeIn(duration: 800.ms).shake(delay: 600.ms),
        const SizedBox(height: 8),
        Text(
          'مين اللي بيمر بوقت صعب؟',
          style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 17),
        ),
        const SizedBox(height: 24),
        ..._bots.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassButton(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                gradient: _myGuess == b.alias ? AppColors.warmGradient : null,
                onTap: () => setState(() => _myGuess = b.alias),
                child: Row(children: [
                  Text(
                    b.alias,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (_myGuess == b.alias) ...[
                    const SizedBox(width: 8),
                    const Text('✅', style: TextStyle(fontSize: 16)),
                  ],
                ]),
              ),
            )),
        const SizedBox(height: 20),
        if (_myGuess != null)
          GlassButton(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(vertical: 16),
            gradient: AppColors.primaryGradient,
            onTap: () {
              final correct = _myGuess == rain.alias;
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    correct ? 'أحسنت! 🎉' : 'كان قريب!',
                    style: GoogleFonts.cairo(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    '${rain.alias} هو واحد فينا... وهو محتاج سندكم دلوقتي. 💜\n\n'
                    '${BotEngine.generateSupportMessage(rain)}',
                    style: GoogleFonts.cairo(color: AppColors.textPrimary, height: 1.6),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // رجوع للهوم
                      },
                      child: Text('إنهاء', style: GoogleFonts.cairo(color: AppColors.primary)),
                    ),
                  ],
                ),
              );
              ref.read(ttsServiceProvider).speak(
                    '${rain.alias} هو واحد فينا. يا جماعة، خلوا بالكم منه، هو محتاجكم دلوقتي.',
                  );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'اكشف الحقيقة 🌟',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
      ]),
    );
  }
}
