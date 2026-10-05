import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../../core/widgets/glass_card.dart';
import '../auth/register_screen.dart';
import '../game/room_screen.dart';
import '../matchmaking/matchmaking_screen.dart';
import '../one_to_one/one_to_one_matchmaking_screen.dart';
import '../one_to_one/one_to_one_profile_screen.dart';
import '../vault/support_vault_screen.dart';

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _ScreenState _screenState = _ScreenState.loading;
  String? _savedName;
  String? _savedRole;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final AnimationController _particleController;
  late final AnimationController _bgGlowController;

  // Particles
  late final List<_Particle> _particles;
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _bgGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _particles = List.generate(22, (_) => _Particle(_rng));

    _checkSavedUser();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    _bgGlowController.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────
  Future<void> _checkSavedUser() async {
    await Future.delayed(const Duration(milliseconds: 900)); // splash feel

    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('player_name');
      final role = prefs.getString('player_role') ?? 'normal';

      if (name != null && name.trim().length >= 2) {
        // Restore player into provider
        final authService = ref.read(authServiceProvider);
        await authService.ensureAuthenticated();

        final uid = authService.currentUserId ??
            prefs.getString('player_uid') ??
            'guest_cached';

        final player = PlayerModel(
          id: uid,
          name: name.trim(),
          role: role == 'struggling' ? PlayerRole.struggling : PlayerRole.normal,
        );
        ref.read(currentPlayerProvider.notifier).state = player;

        if (mounted) {
          setState(() {
            _savedName = name.trim();
            _savedRole = role;
            _screenState = _ScreenState.returning;
          });
        }
      } else {
        if (mounted) {
          setState(() => _screenState = _ScreenState.newUser);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _screenState = _ScreenState.newUser);
      }
    }
  }

  void _navigateToMatchmaking() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const RoomScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const RegisterScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Animated background ──────────────────────────────────────
            _AnimatedBackground(
              bgGlowController: _bgGlowController,
              particleController: _particleController,
              particles: _particles,
            ),

            // ── Content ──────────────────────────────────────────────────
            SafeArea(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_screenState) {
      case _ScreenState.loading:
        return _LoadingView(pulseController: _pulseController);

      case _ScreenState.newUser:
        // Redirect to register
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToRegister();
        });
        return _LoadingView(pulseController: _pulseController);

      case _ScreenState.returning:
        return _ReturningUserView(
          name: _savedName ?? 'صاحبي',
          role: _savedRole ?? 'normal',
          pulseController: _pulseController,
          onPlay: _navigateToMatchmaking,
          onSwitch: _navigateToRegister,
        );
    }
  }
}

// ============================================================================
// Screen state enum
// ============================================================================
enum _ScreenState { loading, newUser, returning }

// ============================================================================
// _LoadingView
// ============================================================================
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.pulseController});
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingEmoji(controller: pulseController),
          const SizedBox(height: 24),
          Text(
            'واحد فينا',
            style: GoogleFonts.cairo(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 32),
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.primary.withOpacity(0.7),
              strokeWidth: 2.5,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
        ],
      ),
    );
  }
}

// ============================================================================
// _ReturningUserView
// ============================================================================
class _ReturningUserView extends ConsumerWidget {
  const _ReturningUserView({
    required this.name,
    required this.role,
    required this.pulseController,
    required this.onPlay,
    required this.onSwitch,
  });

  final String name;
  final String role;
  final AnimationController pulseController;
  final VoidCallback onPlay;
  final VoidCallback onSwitch;

  IconData get _roleIcon => role == 'struggling' ? Icons.nights_stay_rounded : Icons.sentiment_satisfied_alt_rounded;
  String get _roleLabel =>
      role == 'struggling' ? 'بيمر بوقت صعب' : 'شخص عادي';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentPlayerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // ── Header Row ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Profile and Support Vault buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (player != null)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
                      ),
                      tooltip: 'الملف الشخصي',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OneToOneProfileScreen(uid: player.id),
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber.withOpacity(0.15),
                        border: Border.all(color: Colors.amber.withOpacity(0.35)),
                      ),
                      child: const Icon(Icons.mark_email_read_outlined, color: Colors.amberAccent, size: 22),
                    ),
                    tooltip: 'صندوق الدعم 📬',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportVaultScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Welcome badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_roleIcon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.1, end: 0),

          const Spacer(),

          // ── Pulsing Emoji ─────────────────────────────────────────────
          _PulsingEmoji(controller: pulseController),

          const SizedBox(height: 18),

          // ── Title ─────────────────────────────────────────────────────
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.primary, AppColors.warm],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ).createShader(bounds),
            child: Text(
              'واحد فينا',
              style: GoogleFonts.cairo(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.05, end: 0),

          Text(
            'مع بعض أحسن وأقرب 🤍',
            style: GoogleFonts.cairo(
              fontSize: 15,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 32),

          // ── Mode selection subtitle ──────────────────────────────────
          Text(
            'اختر النمط المناسب لك اليوم:',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          // ── Mode Cards ────────────────────────────────────────────────
          Expanded(
            flex: 8,
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Card 1: Group Game (واحد فينا)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: onPlay,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.12),
                        ),
                        child: const Icon(Icons.groups_rounded, size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'اللعب الجماعي (واحد فينا)',
                              style: GoogleFonts.cairo(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'لعبة لـ 5-6 لاعبين. جاوبوا واكتشفوا من يمر بوقت صعب لتدعموه.',
                              style: GoogleFonts.cairo(
                                color: Colors.white60,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 12),

                // Card 2: 1-on-1 Support Chat (المساحة الآمنة)
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OneToOneMatchmakingScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.warm.withOpacity(0.12),
                        ),
                        child: const Icon(Icons.forum_rounded, size: 28, color: AppColors.warm),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'مساحة الفضفضة (دعم ثنائي)',
                              style: GoogleFonts.cairo(
                                color: AppColors.warm,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'فضفضة مجهولة 1-على-1. عبّر عن مشاعرك أو كن سنداً لمن يحتاجك.',
                              style: GoogleFonts.cairo(
                                color: Colors.white60,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                    ],
                  ),
                ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.08, end: 0),
              ],
            ),
          ),

          // ── Switch account link ───────────────────────────────────────
          GestureDetector(
            onTap: onSwitch,
            child: Text(
              'تغيير الحساب أو الاسم المستعار',
              style: GoogleFonts.cairo(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white24,
              ),
            ),
          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

          const Spacer(),
        ],
      ),
    );
  }
}



// ============================================================================
// _PulsingEmoji
// ============================================================================
class _PulsingEmoji extends StatelessWidget {
  const _PulsingEmoji({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final scale = 1.0 + t * 0.08;
        final glowRadius = 30.0 + t * 25.0;
        final glowOpacity = 0.30 + t * 0.25;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(glowOpacity),
                  blurRadius: glowRadius,
                  spreadRadius: 6 + t * 8,
                ),
                BoxShadow(
                  color: AppColors.warm.withOpacity(glowOpacity * 0.4),
                  blurRadius: glowRadius * 1.5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.diversity_1_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 700.ms).scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: 700.ms,
          curve: Curves.elasticOut,
        );
  }
}

// ============================================================================
// _AnimatedBackground  (blobs + floating particles)
// ============================================================================
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({
    required this.bgGlowController,
    required this.particleController,
    required this.particles,
  });

  final AnimationController bgGlowController;
  final AnimationController particleController;
  final List<_Particle> particles;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([bgGlowController, particleController]),
      builder: (_, __) {
        final glowT = bgGlowController.value;
        final pT = particleController.value; // 0..1 looping

        return Stack(
          children: [
            // ── Gradient base ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.5),
                  radius: 1.4,
                  colors: [
                    AppColors.primary.withOpacity(0.12 + glowT * 0.05),
                    AppColors.background,
                  ],
                ),
              ),
            ),

            // ── Large blobs ────────────────────────────────────────────
            Positioned(
              top: -100 + glowT * 30,
              right: -80,
              child: _GlowBlob(
                size: 340,
                color: AppColors.primary.withOpacity(0.13 + glowT * 0.07),
              ),
            ),
            Positioned(
              bottom: -120 + glowT * -20,
              left: -100,
              child: _GlowBlob(
                size: 380,
                color: AppColors.warm.withOpacity(0.09 + glowT * 0.05),
              ),
            ),
            Positioned(
              top: size.height * 0.38 + glowT * 20,
              left: -40,
              child: _GlowBlob(
                size: 200,
                color: AppColors.primary.withOpacity(0.07 + glowT * 0.04),
              ),
            ),

            // ── Floating particles ─────────────────────────────────────
            ...particles.map((p) {
              // Each particle loops at its own speed
              final t = (pT * p.speed + p.phase) % 1.0;
              final x = p.startX * size.width;
              final y = (p.startY + t) % 1.0 * size.height;
              final opacity = math.sin(t * math.pi).clamp(0.0, 1.0) *
                  p.maxOpacity;

              return Positioned(
                left: x,
                top: y,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.color,
                      boxShadow: [
                        BoxShadow(
                          color: p.color.withOpacity(opacity * 0.5),
                          blurRadius: p.size * 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 90, spreadRadius: 30),
        ],
      ),
    );
  }
}

// ============================================================================
// _Particle  (data class)
// ============================================================================
class _Particle {
  _Particle(math.Random rng)
      : startX = rng.nextDouble(),
        startY = rng.nextDouble() - 1.0, // start off-screen top
        size = 2.0 + rng.nextDouble() * 5.0,
        speed = 0.06 + rng.nextDouble() * 0.14,
        phase = rng.nextDouble(),
        maxOpacity = 0.25 + rng.nextDouble() * 0.45,
        color = rng.nextBool() ? AppColors.primary : AppColors.warm;

  final double startX;
  final double startY;
  final double size;
  final double speed;
  final double phase;
  final double maxOpacity;
  final Color color;
}
