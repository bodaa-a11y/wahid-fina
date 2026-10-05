import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VaultMessageModel {
  final String id;
  final String text;
  final String fromAlias;
  final DateTime date;
  final bool isPinned;

  const VaultMessageModel({
    required this.id,
    required this.text,
    required this.fromAlias,
    required this.date,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'fromAlias': fromAlias,
    'date': date.toIso8601String(),
    'isPinned': isPinned,
  };

  factory VaultMessageModel.fromMap(Map<String, dynamic> map) => VaultMessageModel(
    id: map['id'] as String? ?? '',
    text: map['text'] as String? ?? '',
    fromAlias: map['fromAlias'] as String? ?? 'صديق',
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    isPinned: (map['isPinned'] as bool?) ?? false,
  );

  VaultMessageModel copyWith({
    String? id,
    String? text,
    String? fromAlias,
    DateTime? date,
    bool? isPinned,
  }) => VaultMessageModel(
    id: id ?? this.id,
    text: text ?? this.text,
    fromAlias: fromAlias ?? this.fromAlias,
    date: date ?? this.date,
    isPinned: isPinned ?? this.isPinned,
  );
}

class SupportVaultStorage {
  static const String _key = 'wahid_fina_support_vault';

  static Future<List<VaultMessageModel>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Default initial welcome messages
      return [
        VaultMessageModel(
          id: 'welcome_1',
          text: 'أنت مش لوحدك، وكل حاجة صعبة بتعدي بإذن الله 🤍',
          fromAlias: 'فريق واحد فينا',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          isPinned: true,
        ),
        VaultMessageModel(
          id: 'welcome_2',
          text: 'وجودك هنا شجاعة، ووجودك فارق مع اللي حواليك حتى لو مش حاسس دلوقتي.',
          fromAlias: 'قمر',
          date: DateTime.now().subtract(const Duration(days: 1)),
          isPinned: false,
        ),
      ];
    }
    try {
      final List list = jsonDecode(jsonStr);
      return list.map((item) => VaultMessageModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMessages(List<VaultMessageModel> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(messages.map((m) => m.toMap()).toList());
    await prefs.setString(_key, jsonStr);
  }

  static Future<void> addMessage(VaultMessageModel msg) async {
    final current = await loadMessages();
    current.insert(0, msg);
    await saveMessages(current);
  }

  static Future<void> togglePin(String id) async {
    final current = await loadMessages();
    final updated = current.map((m) {
      if (m.id == id) {
        return m.copyWith(isPinned: !m.isPinned);
      }
      return m;
    }).toList();
    await saveMessages(updated);
  }
}
