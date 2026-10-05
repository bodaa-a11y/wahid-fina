// 🤖 الدكتور روبوت — مقدم الأسئلة (بالطو، قاعد، بيتكلم)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class DoctorRobotWidget extends StatefulWidget {
  final bool speaking; // هيتحرك الفم والموجات لما true
  final double size; // عرض الروبوت
  const DoctorRobotWidget({super.key, this.speaking = false, this.size = 170});

  @override
  State<DoctorRobotWidget> createState() => _DoctorRobotWidgetState();
}

class _DoctorRobotWidgetState extends State<DoctorRobotWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl; // طفو
  late AnimationController _blinkCtrl; // غمزة
  late AnimationController _mouthCtrl; // الكلام
  late AnimationController _glowCtrl; // هالة النبض

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
    _mouthCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _blinkCtrl.dispose();
    _mouthCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final h = w * 1.15;

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatCtrl, _glowCtrl, _blinkCtrl]),
        builder: (context, _) {
          final floatY = -6 * _floatCtrl.value;
          final glow = 0.5 + 0.5 * _glowCtrl.value;

          // غمزة كل دورة: أول 8% من الوقت العين مغمضة
          final t = _blinkCtrl.value;
          final eyeH = (t < 0.08) ? 2.0 : 10.0;

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // ✨ هالة نور خلفية
              Positioned(
                bottom: h * 0.25,
                child: Container(
                  width: w * 1.25,
                  height: w * 1.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.45 * glow),
                      AppColors.warm.withValues(alpha: 0.12 * glow),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

              Transform.translate(
                offset: Offset(0, floatY),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 🪑 الكرسي
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: w * 0.85,
                        height: h * 0.42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D4037),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🥼 الجسم — البالطو الأبيض
                    Positioned(
                      bottom: h * 0.28,
                      child: Container(
                        width: w * 0.72,
                        height: h * 0.42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFDCE3EE)],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // ياقة البالطو (V)
                            Positioned(
                              top: 0,
                              left: w * 0.16,
                              right: w * 0.16,
                              child: ClipPath(
                                clipper: _CollarClipper(),
                                child: Container(height: h * 0.14, color: const Color(0xFFB9C4D6)),
                              ),
                            ),
                            // 🩺 سماعة الطبيب
                            const Positioned(
                              top: 12,
                              right: 14,
                              child: Text('🩺', style: TextStyle(fontSize: 22)),
                            ),
                            // أزرار البالطو
                            ...[0.22, 0.38, 0.54].map((f) => Positioned(
                              top: h * f,
                              left: w * 0.36 - 3,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF8FA0B8),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),

                    // 🤖 الرأس
                    Positioned(
                      bottom: h * 0.62,
                      child: Container(
                        width: w * 0.62,
                        height: w * 0.52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE8ECF4), Color(0xFFAFBCD0)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // العيون
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _Eye(size: w * 0.16, eyeH: eyeH, speaking: widget.speaking),
                                _Eye(size: w * 0.16, eyeH: eyeH, speaking: widget.speaking),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // الفم — بيتحرك لما بيتكلم
                            AnimatedBuilder(
                              animation: _mouthCtrl,
                              builder: (_, __) {
                                final open = widget.speaking
                                    ? 3.0 + 7.0 * _mouthCtrl.value
                                    : 4.0;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 90),
                                  width: w * 0.2,
                                  height: open,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3A4A63),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 📡 هوائي
                    Positioned(
                      bottom: h * 0.62 + w * 0.52 - 2,
                      child: Column(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            color: const Color(0xFF8FA0B8),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warm,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warm.withValues(alpha: glow),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔊 موجات صوت لما بيتكلم
                    if (widget.speaking)
                      Positioned(
                        bottom: h * 0.55,
                        right: -6,
                        child: Row(
                          children: List.generate(3, (i) => AnimatedBuilder(
                            animation: _mouthCtrl,
                            builder: (_, __) {
                              final v = (_mouthCtrl.value + i * 0.33) % 1.0;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 4,
                                height: 6 + v * 14,
                                decoration: BoxDecoration(
                                  color: AppColors.warm.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            },
                          )),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(duration: 400.ms);
  }
}

class _Eye extends StatelessWidget {
  final double size, eyeH;
  final bool speaking;
  const _Eye({required this.size, required this.eyeH, required this.speaking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E2A3D),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.8),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: eyeH,
          decoration: BoxDecoration(
            color: speaking ? AppColors.warm : const Color(0xFF7DD3FC),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _CollarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 0);
    p.lineTo(size.width / 2, size.height);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
