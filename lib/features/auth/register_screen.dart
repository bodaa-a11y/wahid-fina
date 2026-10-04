// 🎨 شاشة التسجيل — أول ما يشوفه المستخدم
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../../core/models/player_model.dart';
import '../home/home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PlayerRole _selectedRole = PlayerRole.normal;
  bool _isLoading = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _enterRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final authService = ref.read(authServiceProvider);
      final uid = await authService.ensureAuthenticated();

      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ في الاتصال', style: GoogleFonts.cairo()),
              backgroundColor: AppColors.struggling,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final name = _nameController.text.trim();
      await authService.savePlayerData(name: name, role: _selectedRole == PlayerRole.struggling ? 'struggling' : 'normal');

      final player = PlayerModel(
        id: uid,
        name: name,
        role: _selectedRole,
      );

      ref.read(currentPlayerProvider.notifier).state = player;

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.struggling,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ===== LOGO =====
                  _buildLogo(),

                  const SizedBox(height: 40),

                  // ===== NAME FIELD =====
                  _buildNameField(),

                  const SizedBox(height: 28),

                  // ===== ROLE SELECTION =====
                  _buildRoleLabel(),
                  const SizedBox(height: 12),
                  _buildRoleCards(),

                  const SizedBox(height: 36),

                  // ===== ENTER BUTTON =====
                  _buildEnterButton(),

                  const SizedBox(height: 20),

                  // ===== DISCLAIMER =====
                  _buildDisclaimer(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Emoji with glow
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3 + _glowController.value * 0.3),
                    blurRadius: 30 + _glowController.value * 20,
                    spreadRadius: 5 + _glowController.value * 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.diversity_1_rounded,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            );
          },
        ).animate().scale(
          duration: 800.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.5, 0.5),
        ).fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // Title
        Text(
          'واحد فينا',
          style: GoogleFonts.cairo(
            color: AppColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.3, end: 0),

        const SizedBox(height: 8),

        Text(
          'لعبة بتجمعك مع ناس حقيقيين 🤍',
          style: GoogleFonts.cairo(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اسمك إيه؟',
          style: GoogleFonts.cairo(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 17),
          decoration: InputDecoration(
            hintText: 'اكتب اسمك هنا...',
            hintStyle: GoogleFonts.cairo(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.struggling),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          validator: (v) {
            if (v == null || v.trim().length < 2) {
              return 'الاسم لازم يكون حرفين على الأقل';
            }
            return null;
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildRoleLabel() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'انت إيه النهارده؟',
        style: GoogleFonts.cairo(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 650.ms);
  }

  Widget _buildRoleCards() {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            icon: Icons.sentiment_satisfied_alt_rounded,
            title: 'شخص عادي',
            subtitle: 'تعرف على ناس جديدة وكن موجود',
            isSelected: _selectedRole == PlayerRole.normal,
            selectedColor: AppColors.primary,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedRole = PlayerRole.normal);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            icon: Icons.nights_stay_rounded,
            title: 'بيمر بوقت صعب',
            subtitle: 'مش لازم تتكلم... بس ارتاح مع ناس',
            isSelected: _selectedRole == PlayerRole.struggling,
            selectedColor: AppColors.struggling,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedRole = PlayerRole.struggling);
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 750.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildEnterButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _enterRoom,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ادخل غرفة عشوائية',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.login_rounded, color: Colors.white, size: 22),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 900.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildDisclaimer() {
    return Text(
      'باضغاطك على الدخول بتوافق على احترام الجميع\nوالحفاظ على مساحة آمنة 🤍',
      style: GoogleFonts.cairo(
        color: AppColors.textHint,
        fontSize: 12,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(duration: 400.ms, delay: 1000.ms);
  }
}

// ===== Role Selection Card =====
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: selectedColor.withOpacity(0.25), blurRadius: 16, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? selectedColor : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: isSelected ? selectedColor : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
