// 🌳 ويدجت شجرة الدعم (Care Tree Widget) — مواصفات F3
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../models/care_tree_model.dart';

class CareTreeWidget extends StatelessWidget {
  final CareTreeModel tree;
  final bool compact;

  const CareTreeWidget({
    super.key,
    required this.tree,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildExpanded(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStageIcon(tree.stage, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tree.stageName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '${tree.leaves} 🍃 • ${tree.fruits} 🍎',
                style: GoogleFonts.cairo(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF231A45),
            const Color(0xFF14102B),
          ],
        ),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.park_rounded, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'شجرة الدعم الخاصة بك',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'المرحلة ${tree.stage + 1} من 5',
                  style: GoogleFonts.cairo(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // مركز الشجرة المرئي
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getGlowColor(tree.stage).withValues(alpha: 0.2),
                  blurRadius: 35,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: _getStageIcon(tree.stage, size: 70)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 2.seconds),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            tree.stageName,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tree.stageDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // العدادات الثلاثة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🍃 أوراق الدعم', '${tree.leaves}', 'رسالة كتبتها'),
              _buildStatItem('🍎 ثمار المحبة', '${tree.fruits}', 'رسالة وصلتك'),
              _buildStatItem('⭐ رومات كاملة', '${tree.stars}', 'جلسات مكتملة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String count, String sub) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.cairo(
            color: AppColors.accentLight,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.cairo(
            color: Colors.white38,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _getStageIcon(int stage, {required double size}) {
    switch (stage) {
      case 0:
        return Text('🌱', style: TextStyle(fontSize: size));
      case 1:
        return Text('🌿', style: TextStyle(fontSize: size));
      case 2:
        return Text('🌳', style: TextStyle(fontSize: size));
      case 3:
        return Text('🍎\n🌳', textAlign: TextAlign.center, style: TextStyle(fontSize: size * 0.7));
      case 4:
      default:
        return Text('✨🌳✨', style: TextStyle(fontSize: size * 0.7));
    }
  }

  Color _getGlowColor(int stage) {
    switch (stage) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.lightGreenAccent;
      case 2:
        return Colors.tealAccent;
      case 3:
        return Colors.amberAccent;
      case 4:
      default:
        return Colors.purpleAccent;
    }
  }
}
