import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../home/home_screen.dart';

class OneToOneFeedbackScreen extends ConsumerStatefulWidget {
  final String currentUserId;
  final String currentUserNickname;

  const OneToOneFeedbackScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserNickname,
  });

  @override
  ConsumerState<OneToOneFeedbackScreen> createState() =>
      _OneToOneFeedbackScreenState();
}

class _OneToOneFeedbackScreenState extends ConsumerState<OneToOneFeedbackScreen>
    with TickerProviderStateMixin {
  int _selectedRating = 0;
  bool _isCelebrating = false;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_selectedRating == 0) return;

    setState(() => _isCelebrating = true);
    _celebrationController.forward();

    try {
      final oneToOneService = ref.read(oneToOneServiceProvider);
      // إضافة نقاط تعاطف وتحديث الجلسات المكتملة في Firestore
      await oneToOneService.updateUserStats(widget.currentUserId, 10);
      
      // تحديث البيانات المحلية للمستخدم
      final currentPlayer = ref.read(currentPlayerProvider);
      if (currentPlayer != null) {
        ref.read(currentPlayerProvider.notifier).state = currentPlayer.copyWith(
          empathyPoints: currentPlayer.empathyPoints + 10,
          sessionsCompleted: currentPlayer.sessionsCompleted + 1,
        );
      }
    } catch (e) {
      print('Error updating empathy points: $e');
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  Widget _buildRatingEmoji(String emoji, int ratingValue) {
    bool isSelected = _selectedRating == ratingValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedRating = ratingValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.25)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Text(emoji, style: const TextStyle(fontSize: 34)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.spa_rounded,
                        color: Color(0xFF69F0AE),
                        size: 64,
                      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 24),
                      Text(
                        'انتهت الجلسة بسلام',
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      Text(
                        'كيف تشعر الآن بعد هذه المساحة؟',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 40),

                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildRatingEmoji('😞', 1),
                            _buildRatingEmoji('😐', 2),
                            _buildRatingEmoji('😌', 3),
                            _buildRatingEmoji('✨', 4),
                          ],
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 48),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _selectedRating == 0 || _isCelebrating
                              ? null
                              : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: const Color(0xFF0B0F19),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            disabledBackgroundColor: Colors.white12,
                          ),
                          child: Text(
                            'إرسال والعودة للرئيسية',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15, end: 0),
                    ],
                  ),
                ),
              ),

              // أنيميشن الجائزة والاحتفال
              if (_isCelebrating)
                Container(
                  color: const Color(0xFF0B0F19).withOpacity(0.85),
                  child: Center(
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _celebrationController,
                        curve: Curves.elasticOut,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 100))
                              .animate()
                              .shake(duration: 800.ms),
                          const SizedBox(height: 16),
                          Text(
                            '+10',
                            style: GoogleFonts.cairo(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD180),
                            ),
                          ),
                          Text(
                            'نقاط تعاطف!',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'شكراً لكونك سبباً في راحة إنسان اليوم 🌸',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: const Color(0xFF69F0AE),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
