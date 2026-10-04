// 🔍 شاشة البحث عن غرفة — Matchmaking Screen
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../../core/models/room_model.dart';
import '../room_intro/room_intro_screen.dart';

// ─── Radar Painter ───────────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  final List<double> ringValues; // 0.0 → 1.0 per ring
  final Color primaryColor;

  const _RadarPainter({required this.ringValues, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < ringValues.length; i++) {
      final t = ringValues[i];
      final radius = maxRadius * t;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = primaryColor.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - (t * 1.5);

      canvas.drawCircle(center, radius, paint);

      // Filled soft glow
      final fillPaint = Paint()
        ..color = primaryColor.withOpacity(opacity * 0.04)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => true;
}

// ─── Radar Widget ─────────────────────────────────────────────────────────────
class _RadarWidget extends StatefulWidget {
  const _RadarWidget();

  @override
  State<_RadarWidget> createState() => _RadarWidgetState();
}

class _RadarWidgetState extends State<_RadarWidget>
    with TickerProviderStateMixin {
  static const int _ringCount = 5;
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _ringCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800),
      );
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
      _controllers.add(controller);
      _animations.add(animation);

      // Stagger each ring
      Future.delayed(Duration(milliseconds: i * 560), () {
        if (mounted) controller.repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (context, _) {
        return CustomPaint(
          size: const Size(280, 280),
          painter: _RadarPainter(
            ringValues: _animations.map((a) => a.value).toList(),
            primaryColor: AppColors.primary,
          ),
        );
      },
    );
  }
}

// ─── Spinning Dots ────────────────────────────────────────────────────────────
class _SpinningDots extends StatefulWidget {
  const _SpinningDots();

  @override
  State<_SpinningDots> createState() => _SpinningDotsState();
}

class _SpinningDotsState extends State<_SpinningDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(8, (i) {
              final angle = (i / 8) * 2 * math.pi;
              const radius = 22.0;
              final phase = (_controller.value - i / 8).abs() % 1.0;
              final opacity = (math.sin(phase * math.pi)).clamp(0.0, 1.0);
              return Positioned(
                left: 30 + radius * math.cos(angle) - 4,
                top: 30 + radius * math.sin(angle) - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(opacity.toDouble()),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ─── Matchmaking Screen ───────────────────────────────────────────────────────
class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  // Cycling subtitle messages
  static const List<String> _subtitles = [
    'بندور على ناس بتشبهك...',
    'بنجمع ناس من كل مكان...',
    'اللحظة دي فيها ناس تانية بتستنى...',
    'قريباً هتقابل حد جديد ✨',
  ];

  int _subtitleIndex = 0;
  Timer? _subtitleTimer;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  String? _roomId;
  StreamSubscription<RoomModel>? _roomSub;
  bool _navigating = false;
  bool _searchStarted = false;
  String? _error;

  // Subtitle fade controller
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.value = 1.0;

    // Start after first frame so we have a valid BuildContext + ref
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSearch());
  }

  @override
  void dispose() {
    _subtitleTimer?.cancel();
    _elapsedTimer?.cancel();
    _roomSub?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Search Logic ─────────────────────────────────────────────────────────
  Future<void> _startSearch() async {
    if (_searchStarted) return;
    _searchStarted = true;

    final player = ref.read(currentPlayerProvider);
    if (player == null) {
      setState(() => _error = 'بيانات اللاعب مش موجودة');
      return;
    }

    // Start elapsed timer
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    // Start subtitle cycling
    _subtitleTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _subtitleIndex = (_subtitleIndex + 1) % _subtitles.length;
        });
        _fadeController.forward();
      });
    });

    try {
      final roomService = ref.read(roomServiceProvider);
      final roomId = await roomService.findOrCreateRoom(player);

      if (!mounted) return;

      setState(() => _roomId = roomId);
      ref.read(currentRoomIdProvider.notifier).state = roomId;

      // Listen to room stream
      _roomSub = roomService.getRoomStream(roomId).listen((room) {
        if (!mounted || _navigating) return;
        if (room.status == RoomStatus.intro) {
          _navigateToIntro(room);
        }
      });
    } catch (e) {
      debugPrint('Group Matchmaking Error: $e');
      if (mounted) {
        setState(() => _error = 'حصل خطأ: ${e.toString()}');
      }
    }
  }

  void _navigateToIntro(RoomModel room) {
    if (_navigating) return;
    _navigating = true;
    _subtitleTimer?.cancel();
    _elapsedTimer?.cancel();
    _roomSub?.cancel();

    final player = ref.read(currentPlayerProvider);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: RoomIntroScreen(
            roomId: room.roomId,
            currentPlayer: player!,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _cancel() {
    _subtitleTimer?.cancel();
    _elapsedTimer?.cancel();
    _roomSub?.cancel();

    // Remove player from room if joined
    final roomId = _roomId;
    final player = ref.read(currentPlayerProvider);
    if (roomId != null && player != null) {
      ref.read(roomServiceProvider).leaveRoom(roomId, player.id).catchError((e) {
        debugPrint("Error leaving group room: $e");
      });
    }

    ref.read(currentRoomIdProvider.notifier).state = null;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatElapsed() {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return m > 0
        ? '$m دقيقة و$s ثانية'
        : '$s ${_elapsedSeconds == 1 ? 'ثانية' : 'ثانية'}';
  }

  String _roleLabel(PlayerRole role) =>
      role == PlayerRole.struggling ? 'واحد بيمر بوقت صعب 💙' : 'صاحب داعم 🤍';

  Color _roleColor(PlayerRole role) =>
      role == PlayerRole.struggling ? AppColors.struggling : AppColors.primary;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final player = ref.watch(currentPlayerProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _subtitleTimer?.cancel();
          _elapsedTimer?.cancel();
          _roomSub?.cancel();

          final roomId = _roomId;
          final player = ref.read(currentPlayerProvider);
          if (roomId != null && player != null) {
            ref.read(roomServiceProvider).leaveRoom(roomId, player.id).catchError((e) {
              debugPrint("Error leaving group room: $e");
            });
          }
          ref.read(currentRoomIdProvider.notifier).state = null;
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: AppBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // ── Decorative background blobs ────────────────────────────
                Positioned(
                  top: -80,
                  right: -60,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warm.withOpacity(0.05),
                    ),
                  ),
                ),

                // ── Main content ───────────────────────────────────────────
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Radar + Center icon ─────────────────────────
                        _buildRadarSection(),

                        const SizedBox(height: 36),

                        // ── Title ───────────────────────────────────────
                        Text(
                          'بنبحث لك على أصحاب',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                        const SizedBox(height: 12),

                        // ── Cycling subtitle ────────────────────────────
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Text(
                            _subtitles[_subtitleIndex],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 32),

                        // ── Error display ───────────────────────────────
                        if (_error != null)
                          _buildErrorCard()
                                  .animate()
                                  .fadeIn()
                                  .shake(hz: 2, offset: const Offset(4, 0)),

                        // ── Player card ─────────────────────────────────
                        if (player != null && _error == null)
                          _buildPlayerCard(player)
                              .animate()
                              .fadeIn(delay: 600.ms)
                              .slideY(begin: 0.3),

                        const SizedBox(height: 20),

                        // ── Timer chip ──────────────────────────────────
                        if (_error == null)
                          _buildTimerChip()
                              .animate()
                              .fadeIn(delay: 800.ms),

                        const SizedBox(height: 36),

                        // ── Cancel button ───────────────────────────────
                        _buildCancelButton()
                            .animate()
                            .fadeIn(delay: 900.ms)
                            .slideY(begin: 0.2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  // ── Sub-builders ─────────────────────────────────────────────────────────
  Widget _buildRadarSection() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar rings
          const _RadarWidget(),

          // Static outer glow circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
            ),
          ),

          // Center spinning dots
          const _SpinningDots(),

          // Center icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.search_rounded, color: Colors.white, size: 28),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(PlayerModel player) {
    final roleColor = _roleColor(player.role);
    final roleLabel = _roleLabel(player.role);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          roleColor.withOpacity(0.12),
          AppColors.glassWhite,
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withOpacity(0.2),
              border: Border.all(color: roleColor, width: 2),
              boxShadow: [
                BoxShadow(
                    color: roleColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1),
              ],
            ),
            child: Center(
              child: Text(
                player.name.isNotEmpty ? player.name[0] : '؟',
                style: GoogleFonts.cairo(
                  color: roleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name & role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: GoogleFonts.cairo(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: roleColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleLabel,
                      style: GoogleFonts.cairo(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pulse indicator
          _PulseDot(color: roleColor),
        ],
      ),
    );
  }

  Widget _buildTimerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 6),
          Text(
            'أسرع من لقيت غرفة: ',
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatElapsed(),
            style: GoogleFonts.cairo(
              color: AppColors.warm,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      color: AppColors.struggling.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.struggling, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error ?? '',
              style: GoogleFonts.cairo(
                color: AppColors.struggling,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _error = null;
                _searchStarted = false;
              });
              _startSearch();
            },
            icon: const Icon(Icons.refresh, color: AppColors.struggling),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _cancel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.4), width: 1),
          color: AppColors.surface.withOpacity(0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              'إلغاء البحث',
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulse Dot ────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_a.value),
          boxShadow: [
            BoxShadow(
                color: widget.color.withOpacity(_a.value * 0.6),
                blurRadius: 6,
                spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
