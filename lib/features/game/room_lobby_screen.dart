// 🚪 لوبي الغرفة — كود الدخول + انتظار اللاعبين أو اللعب بالبوتات
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../../core/models/room_model.dart';
import 'solo_game_screen.dart';

class RoomLobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  final PlayerModel currentPlayer;

  const RoomLobbyScreen({
    super.key,
    required this.roomId,
    required this.currentPlayer,
  });

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  bool _startingWithBots = false;

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomStreamProvider(widget.roomId));

    return roomAsync.when(
      data: (room) {
        // الغرفة امتلأت — ارجع للـ matchmaking اللي بيوجه للـ intro
        if (room.status != RoomStatus.waiting) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pop(context);
          });
        }

        return Scaffold(
          body: AppBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'الغرفة جاهزة 🫂',
                      style: GoogleFonts.cairo(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'شارك الكود ده مع صحابك',
                      style: GoogleFonts.cairo(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔢 الكود
                    GlassCard(
                      gradient: AppColors.cardGradient,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: room.code));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                  'اتنسخ! ابعته لصحابك 📋',
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 1),
                              ));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: room.code.characters.map((c) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                                ),
                                child: Text(
                                  c,
                                  style: GoogleFonts.cairo(
                                    color: AppColors.primaryLight,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )).toList(),
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'اضغط على الكود للنسخ',
                            style: GoogleFonts.cairo(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 👥 اللاعبين
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'في الغرفة (${room.players.length}/${room.maxPlayers}):',
                        style: GoogleFonts.cairo(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...room.players.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                p.avatarId.isNotEmpty ? p.avatarId : (p.name.isNotEmpty ? p.name[0] : '👤'),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name,
                                style: GoogleFonts.cairo(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (p.id == widget.currentPlayer.id)
                              Text(
                                'أنت ⭐',
                                style: GoogleFonts.cairo(
                                  color: AppColors.warm,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    )),

                    // أماكن فاضية
                    ...List.generate(
                      (room.maxPlayers - room.players.length).clamp(0, room.maxPlayers),
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.transparent,
                                child: Icon(
                                  Icons.hourglass_top_rounded,
                                  color: AppColors.textHint,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'بنستنى حد يدخل...',
                                style: GoogleFonts.cairo(
                                  color: AppColors.textHint,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 🎮 خيار البوتات
                    GlassButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      borderRadius: 18,
                      gradient: AppColors.warmGradient,
                      onTap: _startingWithBots ? null : () async {
                        setState(() => _startingWithBots = true);
                        final roomService = ref.read(roomServiceProvider);
                        // امسح الغرفة الفاضية وابدأ لعبة محلية بالبوتات
                        await roomService.leaveRoom(room.roomId, widget.currentPlayer.id);
                        if (!mounted) return;
                        Navigator.pushReplacement(context, MaterialPageRoute(
                          builder: (_) => SoloGameScreen(currentPlayer: widget.currentPlayer),
                        ));
                      },
                      child: _startingWithBots
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🤖', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  'كمّل بالبوتات دلوقتي',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 12),

                    // ⏳ استنى ناس حقيقية (افتراضي)
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.people_rounded, color: AppColors.primaryLight),
                      label: Text(
                        'أو استنى ناس حقيقية — الغرفة مفتوحة للكود',
                        style: GoogleFonts.cairo(color: AppColors.primaryLight, fontSize: 13),
                      ),
                    ),
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
          child: Text('$e', style: GoogleFonts.cairo(color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}
