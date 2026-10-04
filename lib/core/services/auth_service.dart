import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _nameKey = 'player_name';
  static const String _roleKey = 'player_role';

  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // تسجيل دخول مجهول
  Future<String?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user?.uid;
    } catch (e) {
      debugPrint('Auth Error: $e');
      return null;
    }
  }

  // التحقق من وجود مستخدم مسجل
  Future<String?> ensureAuthenticated() async {
    if (currentUser != null) return currentUser!.uid;
    return await signInAnonymously();
  }

  // حفظ بيانات اللاعب محلياً
  Future<void> savePlayerData({required String name, required String role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_roleKey, role);
  }

  // استرجاع اسم اللاعب
  Future<String?> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // استرجاع دور اللاعب
  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // مسح البيانات
  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
  }
}
