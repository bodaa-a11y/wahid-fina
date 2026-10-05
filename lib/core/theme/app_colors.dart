// 🎨 نظام الألوان الكامل لـ "واحد فينا"
import 'package:flutter/material.dart';

class AppColors {
  // الخلفيات
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF13132A);
  static const Color surfaceLight = Color(0xFF1C1C38);
  static const Color cardBackground = Color(0xFF1C1C38);

  // الألوان الأساسية
  static const Color primary = Color(0xFF7B5EA7);      // بنفسجي
  static const Color primaryLight = Color(0xFF9B7EC8);
  static const Color primaryDark = Color(0xFF5A3E85);

  // الألوان الدافئة
  static const Color warm = Color(0xFFE8A87C);         // برتقالي ناعم
  static const Color warmLight = Color(0xFFF0C09A);
  static const Color warmDark = Color(0xFFD08050);

  // ألوان الحالات
  static const Color struggling = Color(0xFFE8758A);   // وردي خفيف - الشخص اللي بيمر بوقت صعب
  static const Color normal = Color(0xFF6BB5C8);       // أزرق هادئ - الشخص العادي
  static const Color success = Color(0xFF6BC8A0);      // أخضر للنجاح
  static const Color warning = Color(0xFFF0C070);      // أصفر للتحذير
  static const Color error = Color(0xFFE8758A);        // أحمر/وردي للأخطاء
  static const Color accentLight = Color(0xFF00CEC9);  // تركواز مريح

  // النصوص
  static const Color textPrimary = Color(0xFFE8E6F0);
  static const Color textSecondary = Color(0xFF7E7A9A);
  static const Color textHint = Color(0xFF4A4870);

  // الإطارات والحدود
  static const Color border = Color(0xFF2A2A50);
  static const Color borderLight = Color(0xFF3A3A65);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // التدرجات
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0D1A), Color(0xFF1A1340), Color(0xFF0D0D1A)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B5EA7), Color(0xFF5A3E85)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A87C), Color(0xFFD08050)],
  );

  static const LinearGradient strugglingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D1A2A), Color(0xFF2A1020)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1A7B5EA7), Color(0x0A5A3E85)],
  );
}
