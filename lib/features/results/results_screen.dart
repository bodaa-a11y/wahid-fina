// 🏆 شاشة النتائج — Results Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../../core/models/room_model.dart';
import '../auth/register_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String roomId;
  final PlayerModel currentPlayer;

  const ResultsScreen({
    super.key,
    required this.roomId,
    required this.currentPlayer,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _confettiController;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // بدء الكشف بعد ثانيتين
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _revealed = true);
        HapticFeedback.mediumImpact();
        _revealController.forward();
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _revealController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomStreamProvider(widget.roomId));

    return roomAsync.when(
      data: (room) {
        final struggling = room.players.firstWhere(
          (p) => p.id == room.strugglingPlayerId,
          orElse: () => room.players.first,
        );
        final isStruggling = widget.currentPlayer.id == struggling.id;

        return Scaffold(
          body: AppBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // عنوان اللحظة
                    _buildTopHeader(),

                    const SizedBox(height: 24),

                    // كشف "واحد فينا"
                    _buildRevealSection(room, struggling),

                    const SizedBox(height: 24),

                    // رسالة AI
                    if (room.finalAiMessage != null)
                      _buildFinalMessage(room.finalAiMessage!, isStruggling),

                    const SizedBox(height: 24),

                    // كروت اللاعبين
                    _buildPlayersGrid(room, struggling),

                    const SizedBox(height: 24),

                    // نقاط الصداقة
                    _buildFriendshipScore(room),

                    const SizedBox(height: 24),

                    // الأزرار
                    _buildButtons(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('حدث خطأ', style: GoogleFonts.cairo(color: AppColors.textPrimary)),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            '🎊',
            style: const TextStyle(fontSize: 48),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
          ),
          const SizedBox(height: 12),
          Text(
            'انتهت الجلسة',
            style: GoogleFonts.cairo(
              color: AppColors.warm,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 4),
          Text(
            'شكراً لصدقكم وشجاعتكم 🤍',
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildRevealSection(RoomModel room, PlayerModel struggling) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: !_revealed
            ? GlassCard(
                key: const ValueKey('hidden'),
                child: Column(
                  children: [
                    const Text('❓', style: TextStyle(fontSize: 40))
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1000.ms, color: AppColors.primary.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'مين كان "واحد فينا"؟',
                      style: GoogleFonts.cairo(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'بنكشف الآن...',
                      style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              )
            : _buildRevealCard(struggling),
      ),
    );
  }

  Widget _buildRevealCard(PlayerModel struggling) {
    return GlassCard(
      key: const ValueKey('revealed'),
      gradient: LinearGradient(
        colors: [AppColors.struggling.withOpacity(0.15), AppColors.struggling.withOpacity(0.05)],
      ),
      child: Column(
        children: [
          Text(
            '💙',
            style: const TextStyle(fontSize: 48),
          ).animate().scale(
            duration: 800.ms,
            curve: Curves.elasticOut,
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
          ),
          const SizedBox(height: 12),
          Text(
            'واحد فينا كان...',
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            struggling.name,
            style: GoogleFonts.cairo(
              color: AppColors.struggling,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.struggling.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.struggling.withOpacity(0.3)),
            ),
            child: Text(
              '💪 شجاعة إنك كنت هنا معانا',
              style: GoogleFonts.cairo(
                color: AppColors.struggling,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildFinalMessage(String message, bool isStruggling) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        gradient: LinearGradient(
          colors: [AppColors.warm.withOpacity(0.12), AppColors.warm.withOpacity(0.04)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.warmGradient,
                  ),
                  child: const Center(child: Text('✨', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Text(
                  'رفيق يقول...',
                  style: GoogleFonts.cairo(
                    color: AppColors.warm,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.cairo(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.8,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms, delay: 800.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildPlayersGrid(RoomModel room, PlayerModel struggling) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الغرفة 👥',
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: room.players.asMap().entries.map((entry) {
                final player = entry.value;
                final isStruggling = player.id == struggling.id;
                return PlayerAvatar(
                  player: player,
                  size: 56,
                  isHighlighted: isStruggling,
                  isRevealed: true,
                  showRole: true,
                ).animate().fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: 1000 + entry.key * 150),
                ).scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                );
              }).toList(),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
    );
  }

  Widget _buildFriendshipScore(RoomModel room) {
    // عدد الأصدقاء = عدد اللاعبين - 1 (استثناء نفسك)
    final newFriends = room.players.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        gradient: AppColors.cardGradient,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🫂', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كسبت $newFriends صاحب جديد!',
                  style: GoogleFonts.cairo(
                    color: AppColors.warm,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'الصداقة الحقيقية بتبدأ بسؤال واحد صادق',
                  style: GoogleFonts.cairo(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, delay: 1200.ms).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        curve: Curves.easeOutBack,
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'العب تاني 🎮',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 1400.ms),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // TODO: مشاركة
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'شارك تجربتك ✨',
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 1600.ms),
        ],
      ),
    );
  }
}
