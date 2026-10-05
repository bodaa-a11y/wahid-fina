// 🪟 GlassCard Widget — بطاقة زجاجية شفافة
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool hasBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = 20.0,
    this.borderRadius = 24.0,
    this.padding,
    this.color,
    this.gradient,
    this.onTap,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color ?? AppColors.glassWhite,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: hasBorder
                  ? Border.all(color: AppColors.glassBorder, width: 1.0)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// بطاقة شفافة مع تأثير hover
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? selectedColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Gradient? gradient;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
    this.padding,
    this.borderRadius = 16,
    this.gradient,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.gradient != null
                ? null
                : (widget.isSelected
                    ? (widget.selectedColor ?? AppColors.primary).withOpacity(0.25)
                    : AppColors.glassWhite),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.isSelected
                  ? (widget.selectedColor ?? AppColors.primary)
                  : AppColors.glassBorder,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// الخلفية المتدرجة
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: child,
    );
  }
}
