import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../auth/register_screen.dart';

class OneToOneProfileScreen extends ConsumerWidget {
  final String uid;

  const OneToOneProfileScreen({
    super.key,
    required this.uid,
  });

  Map<String, dynamic> _getRankDetails(int points) {
    if (points < 50) {
      return {
        'rank': 'مستمع جديد 🌱',
        'nextRank': 'صديق داعم 🤝',
        'max': 50,
        'current': points,
        'totalRequired': 50
      };
    }
    if (points < 200) {
      return {
        'rank': 'صديق داعم 🤝',
        'nextRank': 'ملاك الرحمة 🕊️',
        'max': 200,
        'current': points - 50,
        'totalRequired': 150
      };
    }
    if (points < 500) {
      return {
        'rank': 'ملاك الرحمة 🕊️',
        'nextRank': 'أسطورة الدعم 👑',
        'max': 500,
        'current': points - 200,
        'totalRequired': 300
      };
    }
    return {
      'rank': 'أسطورة الدعم 👑',
      'nextRank': 'القمة 🚀',
      'max': points,
      'current': points,
      'totalRequired': points
    };
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13132B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تسجيل الخروج؟',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'تسجيل الخروج سيؤدي لفقدان نقاطك وجلساتك الحالية من جهازك. هل أنت متأكد؟',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              
              // مسح البيانات المحلية
              final authService = ref.read(authServiceProvider);
              await authService.clearData();
              
              // تصفير المزود المحلي
              ref.read(currentPlayerProvider.notifier).state = null;

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'متأكد، خروج',
              style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oneToOneService = ref.watch(oneToOneServiceProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'حسابي المجهول',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: FutureBuilder<PlayerModel?>(
            future: oneToOneService.getUserProfile(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                );
              }

              // إذا لم تكن البيانات مسجلة في Firestore بعد، نستخدم بيانات المزود المحلي
              final localPlayer = ref.read(currentPlayerProvider);
              final player = snapshot.data ?? localPlayer;

              if (player == null) {
                return Center(
                  child: Text(
                    'لم يتم العثور على بيانات اللاعب',
                    style: GoogleFonts.cairo(color: Colors.white70),
                  ),
                );
              }

              final avatar = player.avatarId.isNotEmpty ? player.avatarId : '👤';
              final rankDetails = _getRankDetails(player.empathyPoints);
              final String rankName = rankDetails['rank'];
              final String nextRank = rankDetails['nextRank'];
              final double progress = rankName == 'أسطورة الدعم 👑'
                  ? 1.0
                  : (rankDetails['current'] / rankDetails['totalRequired']);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // الصورة الرمزية
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00E5FF).withOpacity(0.12),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 20),

                    // الاسم واللقب
                    Text(
                      player.name,
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // رتبة التعاطف
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD180).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD180).withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'الرتبة: $rankName',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFFFD180),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),

                    // شريط التقدم للرتبة التالية
                    if (rankName != 'أسطورة الدعم 👑')
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'الرتبة القادمة: $nextRank',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${player.empathyPoints} / ${rankDetails['max']} نقطة',
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFF00E5FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00E5FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // كروت النقاط والجلسات
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFFF8A80),
                                  size: 34,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${player.empathyPoints}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'نقاط التعاطف',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF00E5FF),
                                  size: 34,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${player.sessionsCompleted}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'جلسات الدعم',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15, end: 0),

                    const SizedBox(height: 56),

                    // زر تسجيل الخروج
                    OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(Icons.logout_rounded,
                          color: Color(0xFFFF8A80), size: 18),
                      label: Text(
                        'تسجيل الخروج (مسح الهوية)',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFFFF8A80),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: BorderSide(
                          color: const Color(0xFFFF8A80).withOpacity(0.4),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ).animate().fadeIn(delay: 550.ms),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
