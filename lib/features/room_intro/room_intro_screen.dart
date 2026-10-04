// 🎭 شاشة مقدمة الغرفة — Room Intro Screen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/player_avatar.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../../core/models/room_model.dart';
import '../game/game_screen.dart';

// ─── Room Intro Screen ────────────────────────────────────────────────────────
class RoomIntroScreen extends ConsumerStatefulWidget {
  final String roomId;
  final PlayerModel currentPlayer;

  const RoomIntroScreen({
    super.key,
    required this.roomId,
    required this.currentPlayer,
  });

  @override
  ConsumerState<RoomIntroScreen> createState() => _RoomIntroScreenState();
}

class _RoomIntroScreenState extends ConsumerState<RoomIntroScreen>
    with TickerProviderStateMixin {
  // How many avatars have been revealed so far
  int _revealedCount = 0;
  bool _warningVisible = false;
  bool _countdownVisible = false;
  int _countdown = 5;
  bool _navigating = false;

  Timer? _revealTimer;
  Timer? _countdownTimer;

  // Animations
  late AnimationController _warningController;
  late Animation<double> _warningScale;
  late Animation<double> _warningOpacity;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Warning card animation
    _warningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _warningScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.elasticOut),
    );
    _warningOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _warningController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    // Countdown pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _countdownTimer?.cancel();
    _warningController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRevealSequence(List<PlayerModel> players) {
    if (_revealedCount > 0) return; // already started

    // Reveal avatars one by one
    _revealTimer = Timer.periodic(const Duration(milliseconds: 650), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_revealedCount < players.length) {
        setState(() => _revealedCount++);
      } else {
        t.cancel();
        // Show warning card after last avatar
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() => _warningVisible = true);
          _warningController.forward();
          // Show countdown after warning
          Future.delayed(const Duration(milliseconds: 900), () {
            if (!mounted) return;
            setState(() => _countdownVisible = true);
            _startCountdown();
          });
        });
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _pulseController.forward().then((_) => _pulseController.reverse());

      if (_countdown <= 1) {
        t.cancel();
        _navigateToGame();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _navigateToGame() {
    if (_navigating) return;
    _navigating = true;
    _revealTimer?.cancel();
    _countdownTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: GameScreen(
            roomId: widget.roomId,
            currentPlayer: widget.currentPlayer,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  String _shortRoomId() {
    final id = widget.roomId;
    return id.length >= 4 ? id.substring(id.length - 4).toUpperCase() : id;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomStreamProvider(widget.roomId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AppBackground(
          child: roomAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => _buildErrorState(e),
            data: (room) {
              // Kick off the reveal when we have data
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_revealedCount == 0 && room.players.isNotEmpty) {
                  _startRevealSequence(room.players);
                }
              });
              return _buildContent(room);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(RoomModel room) {
    return SafeArea(
      child: Stack(
        children: [
          // ── Background decorations ──────────────────────────────────────
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warm.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),

          // ── Main scrollable content ─────────────────────────────────────
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Room label
                _buildRoomLabel(),
                const SizedBox(height: 28),

                // Section title
                _buildSectionTitle(),
                const SizedBox(height: 32),

                // Avatars grid
                _buildAvatarsGrid(room.players),
                const SizedBox(height: 36),

                // Warning card (animated)
                if (_warningVisible) _buildWarningCard(),

                // Countdown + button
                if (_countdownVisible) ...[
                  const SizedBox(height: 28),
                  _buildCountdownSection(),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────
  Widget _buildRoomLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.meeting_room_outlined,
                  color: AppColors.textSecondary, size: 15),
              const SizedBox(width: 6),
              Text(
                'غرفة #${_shortRoomId()}',
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3);
  }

  Widget _buildSectionTitle() {
    return Column(
      children: [
        Text(
          'الأصحاب في الغرفة 🎉',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 6),
        Text(
          'بيدخلوا واحد واحد...',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildAvatarsGrid(List<PlayerModel> players) {
    return Wrap(
      spacing: 20,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: players.asMap().entries.map((entry) {
        final i = entry.key;
        final player = entry.value;
        final isCurrentPlayer = player.id == widget.currentPlayer.id;
        final isVisible = i < _revealedCount;

        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: isVisible ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            child: _buildSingleAvatar(player, isCurrentPlayer, isVisible),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleAvatar(
      PlayerModel player, bool isCurrentPlayer, bool isVisible) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glow ring for current player
        Stack(
          alignment: Alignment.center,
          children: [
            if (isCurrentPlayer && isVisible)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warm.withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            PlayerAvatar(
              player: player,
              size: 64,
              showName: false,
              isHighlighted: isCurrentPlayer,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          player.name,
          style: GoogleFonts.cairo(
            color: isCurrentPlayer
                ? AppColors.warm
                : AppColors.textPrimary,
            fontSize: 13,
            fontWeight:
                isCurrentPlayer ? FontWeight.w700 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // "أنت" label
        if (isCurrentPlayer)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warm.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.warm.withOpacity(0.4), width: 1),
            ),
            child: Text(
              'أنت',
              style: GoogleFonts.cairo(
                color: AppColors.warm,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWarningCard() {
    return AnimatedBuilder(
      animation: _warningController,
      builder: (context, child) => Opacity(
        opacity: _warningOpacity.value,
        child: Transform.scale(
          scale: _warningScale.value,
          child: child,
        ),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0x25F0C070), // amber tint
            Color(0x10F0C070),
          ],
        ),
        child: Column(
          children: [
            // Top icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning.withOpacity(0.15),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.5), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('🫂', style: TextStyle(fontSize: 26)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              'في الغرفة دي...',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: AppColors.warning,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 12),

            // Body text
            Text(
              'في ما بينكم شخص واحد بيمر بوقت صعب.\nمهمتكم إنكم تكونوا موجودين مع بعض\nوتجاوبوا بصدق على الأسئلة 🤍',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.warning.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Small note
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'بس في الآخر... مين فيكم؟ 🤔',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownSection() {
    return Column(
      children: [
        // Countdown circle
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _pulseAnim.value,
            child: child,
          ),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$_countdown',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.5, 0.5)),

        const SizedBox(height: 10),

        Text(
          'اللعبة بتبدأ في $_countdown ثوان',
          style: GoogleFonts.cairo(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 20),

        // Manual start button
        _buildStartButton(),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _navigateToGame,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.warm, AppColors.warmDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.warm.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'يلا نبدأ',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Text('🎮', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.25),
        );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.struggling, size: 48),
            const SizedBox(height: 16),
            Text(
              'حصل خطأ في تحميل الغرفة',
              style: GoogleFonts.cairo(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'ارجع',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
