import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import 'one_to_one_chat_screen.dart';

class OneToOneMatchmakingScreen extends ConsumerStatefulWidget {
  const OneToOneMatchmakingScreen({super.key});

  @override
  ConsumerState<OneToOneMatchmakingScreen> createState() =>
      _OneToOneMatchmakingScreenState();
}

class _OneToOneMatchmakingScreenState
    extends ConsumerState<OneToOneMatchmakingScreen>
    with TickerProviderStateMixin {
  bool _isSearching = false;
  final List<String> _topics = [
    'فضفضة عامة',
    'ضغط دراسة',
    'موضوع عاطفي',
    'اكتئاب ووحدة'
  ];
  String _selectedTopic = 'فضفضة عامة';

  IconData _getTopicIcon(String topic) {
    switch (topic) {
      case 'فضفضة عامة':
        return Icons.chat_bubble_outline_rounded;
      case 'ضغط دراسة':
        return Icons.menu_book_rounded;
      case 'موضوع عاطفي':
        return Icons.favorite_border_rounded;
      case 'اكتئاب ووحدة':
        return Icons.wb_cloudy_outlined;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  final List<String> _dailyQuotes = [
    'لا بأس ألا تكون بخير دائماً 💙',
    'أنت لست وحدك، نحن هنا لنسمعك 🌿',
    'كل يوم هو بداية جديدة ✨',
    'خذ نفساً عميقاً.. كل شيء سيمضي 🍃',
    'صوتك مسموع ومشاعرك مقدرة 🕊️'
  ];
  late String _todaysQuote;

  late AnimationController _radarController;
  late AnimationController _floatController;
  StreamSubscription? _roomSubscription;
  String? _currentRoomId;

  @override
  void initState() {
    super.initState();
    _todaysQuote = _dailyQuotes[math.Random().nextInt(_dailyQuotes.length)];
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _radarController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    final player = ref.read(currentPlayerProvider);
    if (player == null) return;

    setState(() {
      _isSearching = true;
      _radarController.repeat();
    });
    HapticFeedback.mediumImpact();

    try {
      final oneToOneService = ref.read(oneToOneServiceProvider);
      // حفظ ملف تعريف المستخدم لضمان إتاحة نقاطه وجلساته في Firestore
      await oneToOneService.saveUserProfile(player);

      final roomId = await oneToOneService.findOrCreateRoom(player, _selectedTopic);
      _currentRoomId = roomId;

      // الاشتراك لمتابعة حالة الغرفة
      _roomSubscription = oneToOneService.getRoomStream(roomId).listen((room) {
        if (room.status == 'active' && room.participants.length >= 2) {
          _roomSubscription?.cancel();
          _radarController.stop();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => OneToOneChatScreen(
                  roomId: roomId,
                  currentUserId: player.id,
                  currentUserNickname: player.name,
                ),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Matchmaking Error: $e');
      setState(() => _isSearching = false);
      _radarController.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
            backgroundColor: AppColors.struggling,
          ),
        );
      }
    }
  }

  void _cancelMatchmaking() async {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _radarController.stop();

    final roomId = _currentRoomId;
    if (mounted) {
      setState(() {
        _isSearching = false;
        _currentRoomId = null;
      });
    }

    if (roomId != null) {
      final player = ref.read(currentPlayerProvider);
      if (player != null) {
        try {
          await ref.read(oneToOneServiceProvider).leaveRoom(roomId, player.id);
        } catch (e) {
          debugPrint("Error leaving room: $e");
        }
      }
    }
  }

  void _showCommunityGuidelines() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13132B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: Color(0xFF00E5FF), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: Color(0xFF69F0AE), size: 32),
                const SizedBox(width: 12),
                Text(
                  'ميثاق المساحة الآمنة',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRuleItem(
              Icons.visibility_off_outlined,
              'السرية التامة',
              'ما يقال هنا يبقى هنا. هويتك وهويتهم بأمان بالكامل.',
            ),
            _buildRuleItem(
              Icons.favorite_border_rounded,
              'الاحترام والتعاطف',
              'نحن هنا لندعم بعضنا، لا مكان للتنمر أو الاستهزاء بالمشاعر.',
            ),
            _buildRuleItem(
              Icons.gavel_outlined,
              'بدون أحكام مسبقة',
              'استمع لتفهم وتشعر بغيرك، لا لتُطلق الأحكام أو تقدم المواعظ.',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startMatchmaking();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE).withOpacity(0.15),
                foregroundColor: const Color(0xFF69F0AE),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFF69F0AE).withOpacity(0.4),
                  ),
                ),
              ),
              child: Text(
                'أوافق وأتعهد بالالتزام',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarAnimation() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        final val = _radarController.value;
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160 + (val * 120),
                  height: 160 + (val * 120),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withOpacity((1.0 - val) * 0.4),
                  ),
                ),
                Container(
                  width: 110 + (val * 80),
                  height: 110 + (val * 80),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00E5FF).withOpacity((1.0 - val) * 0.7),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF13132B),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.35),
                        blurRadius: 25,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    color: Color(0xFF00E5FF),
                    size: 52,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'نبحث لك عن شخص الآن...',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().shimmer(duration: 2000.ms),
            const SizedBox(height: 8),
            Text(
              'التنفس بعمق يساعد على تهدئة الروح 🧘‍♂️',
              style: GoogleFonts.cairo(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 36),
            OutlinedButton(
              onPressed: _cancelMatchmaking,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'إلغاء البحث',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _roomSubscription?.cancel();
          _roomSubscription = null;
          _radarController.stop();

          final roomId = _currentRoomId;
          if (roomId != null) {
            final player = ref.read(currentPlayerProvider);
            if (player != null) {
              ref.read(oneToOneServiceProvider).leaveRoom(roomId, player.id).catchError((e) {
                debugPrint("Error leaving room: $e");
              });
            }
          }
        }
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () {
                if (_isSearching) {
                  _cancelMatchmaking();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
            'المساحة الآمنة',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── رسالة الطمأنينة العائمة ──────────────────────────────
                AnimatedBuilder(
                  animation: _floatController,
                  builder: (context, child) {
                    final t = _floatController.value;
                    return Transform.translate(
                      offset: Offset(0, 5 * math.sin(t * 2 * math.pi)),
                      child: child,
                    );
                  },
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.self_improvement_rounded,
                          color: Color(0xFFB388FF),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _todaysQuote,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                if (!_isSearching) ...[
                  Text(
                    'أهلاً بك يا ${player?.name ?? "صديقي"}',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    player?.role == PlayerRole.struggling
                        ? 'أنت هنا لتفضفض مع شخص يستمع إليك بصدق 💜'
                        : 'أنت هنا لتكون مستمعاً وداعماً يداوي الجراح 💙',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 36),

                  Text(
                    'بماذا تشعر اليوم؟',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),

                  // قائمة الموضوعات
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _topics.asMap().entries.map((entry) {
                      final topic = entry.value;
                      final isSelected = _selectedTopic == topic;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTopic = topic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF00E5FF).withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white.withOpacity(0.08),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTopicIcon(topic),
                                size: 16,
                                color: isSelected
                                    ? const Color(0xFF00E5FF)
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                topic,
                                style: GoogleFonts.cairo(
                                  color: isSelected
                                      ? const Color(0xFF00E5FF)
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                  const Spacer(),

                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.spatial_audio_off_rounded,
                          color: Color(0xFF00E5FF),
                          size: 56,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'اضغط للبدء وسنطابقك مع شخص يشاركك نفس المساحة باحترام وسرية.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _showCommunityGuidelines,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: const Color(0xFF0B0F19),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'البحث عن شريك فضفضة',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                ] else ...[
                  const Spacer(),
                  _buildRadarAnimation(),
                  const Spacer(),
                ],
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
