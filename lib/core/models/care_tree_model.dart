import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CareTreeModel {
  final int stage; // 0 to 4
  final int leaves; // رسائل دعم كتبها
  final int fruits; // رسائل دعم وصلته
  final int stars; // رومات كاملة

  const CareTreeModel({
    this.stage = 0,
    this.leaves = 0,
    this.fruits = 0,
    this.stars = 0,
  });

  String get stageName {
    switch (stage) {
      case 0:
        return 'بذرة الأمل 🌱';
      case 1:
        return 'برعم الخير 🌿';
      case 2:
        return 'شجرة السند 🌳';
      case 3:
        return 'شجرة مثمرة 🌳🍎';
      case 4:
      default:
        return 'شجرة النور 🌳✨';
    }
  }

  String get stageDescription {
    switch (stage) {
      case 0:
        return 'بذرة طيبة تزرعها بوجودك الطيب معنا.';
      case 1:
        return 'نمت نبتتك مع أول جولة استماع ومشاركة.';
      case 2:
        return 'شجرة تكبر كلما سطّرت كلمة تطمئن بها قلباً متعباً.';
      case 3:
        return 'أثمرت شجرتك حباً ودعماً متبادلاً.';
      case 4:
      default:
        return 'شجرة مضيئة تفيض نوراً ورحمة على كل من حولك.';
    }
  }

  int calculateNextStage() {
    if (leaves >= 50 && fruits >= 5) return 4;
    if (leaves >= 30 || fruits >= 3) return 3;
    if (leaves >= 10 || stars >= 3) return 2;
    if (stars >= 1 || leaves >= 1) return 1;
    return 0;
  }

  Map<String, dynamic> toMap() => {
    'stage': stage,
    'leaves': leaves,
    'fruits': fruits,
    'stars': stars,
  };

  factory CareTreeModel.fromMap(Map<String, dynamic> map) => CareTreeModel(
    stage: (map['stage'] as int?) ?? 0,
    leaves: (map['leaves'] as int?) ?? 0,
    fruits: (map['fruits'] as int?) ?? 0,
    stars: (map['stars'] as int?) ?? 0,
  );
}

class CareTreeStorage {
  static const String _key = 'wahid_fina_care_tree';

  static Future<CareTreeModel> loadTree() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const CareTreeModel(stage: 1, leaves: 4, fruits: 2, stars: 2);
    }
    try {
      final map = jsonDecode(jsonStr);
      return CareTreeModel.fromMap(map as Map<String, dynamic>);
    } catch (_) {
      return const CareTreeModel();
    }
  }

  static Future<void> saveTree(CareTreeModel tree) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(tree.toMap()));
  }

  static Future<CareTreeModel> recordAction({int addLeaves = 0, int addFruits = 0, int addStars = 0}) async {
    final current = await loadTree();
    final newLeaves = current.leaves + addLeaves;
    final newFruits = current.fruits + addFruits;
    final newStars = current.stars + addStars;

    final temp = CareTreeModel(leaves: newLeaves, fruits: newFruits, stars: newStars);
    final calculatedStage = temp.calculateNextStage();

    final updated = CareTreeModel(
      stage: calculatedStage,
      leaves: newLeaves,
      fruits: newFruits,
      stars: newStars,
    );
    await saveTree(updated);
    return updated;
  }
}
