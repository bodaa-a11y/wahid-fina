// 🤖 محرك البوتات الذكي والواقعي — واحد فينا (BotEngine v1.0)
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/game_questions.dart';

class BotPlayer {
  final String id;
  final String alias;
  final String persona;
  final bool isRain;
  final Color avatarColor;
  int suspicionScore;
  int empathyPoints;
  int receivedReactions;

  BotPlayer({
    required this.id,
    required this.alias,
    required this.persona,
    required this.isRain,
    required this.avatarColor,
    this.suspicionScore = 0,
    this.empathyPoints = 0,
    this.receivedReactions = 0,
  });
}

class BotEngine {
  static const List<String> availableAliases = [
    'وردة',
    'قمر',
    'غيمة',
    'فانوس',
    'سحابة',
    'نجمة',
    'نور',
    'بحر',
    'شمس',
  ];

  static const List<Color> avatarColors = [
    Color(0xFF6C5CE7), // Purple
    Color(0xFF00CEC9), // Cyan
    Color(0xFFFF7675), // Coral
    Color(0xFFFDCB6E), // Amber
    Color(0xFF00B894), // Emerald
    Color(0xFFE84393), // Pink
    Color(0xFF0984E3), // Blue
  ];

  static const List<String> painKeywords = [
    'تعبان',
    'وحيد',
    'مكسور',
    'زهقان',
    'مقهور',
    'ساكت',
    'متحمل',
    'شايل',
    'وجع',
    'خايف',
    'ضعيف',
    'حابس',
    'أعافر',
    'لوحدي',
    'كتم',
    'ثقيلة',
  ];

  static const List<String> supportiveKeywords = [
    'سند',
    'معاك',
    'فخور',
    'جنبك',
    'خير',
    'أمل',
    'طيب',
    'نور',
    'أحب',
    'سلام',
  ];

  static const List<String> cannedSupportMessages = [
    'ربنا يقويك ويجبر بخاطرك دايماً، كلامك لمس قلوبنا كلنا 🤍',
    'أنت مش لوحدك، كلنا هنا بنحبك وسند ليك في أي وقت 🤗',
    'كل ضيقة وليها فرج، خليك دايماً شجاع ومكمل وربنا هيفرحك 💪',
    'شكراً على صدقك وشجاعتك، كلامك نور في قلوبنا كلنا ❤️',
    'وجودك وسطنا نعمة كبيرة، متقلقش من اللي جاي كلنا في ضهرك ✨',
  ];

  /// توليد فريق من البوتات لتكملة الروم حتى 6 لاعبين
  static List<BotPlayer> generateBots({
    required int count,
    required bool needRainPlayer,
    required String humanAlias,
  }) {
    final rng = Random();
    final remainingAliases = availableAliases.where((a) => a != humanAlias).toList()..shuffle(rng);
    final remainingColors = List<Color>.from(avatarColors)..shuffle(rng);

    final personas = ['supporter', 'supporter', 'funny', 'wise', 'playful'];
    personas.shuffle(rng);

    final bots = <BotPlayer>[];
    int rainAssignedIndex = needRainPlayer ? rng.nextInt(count) : -1;

    for (int i = 0; i < count; i++) {
      final isRain = (i == rainAssignedIndex);
      final persona = isRain ? 'rain-hidden' : personas[i % personas.length];
      final alias = remainingAliases[i % remainingAliases.length];
      final color = remainingColors[i % remainingColors.length];

      bots.add(BotPlayer(
        id: 'bot_${rng.nextInt(999999)}_$i',
        alias: alias,
        persona: persona,
        isRain: isRain,
        avatarColor: color,
      ));
    }

    return bots;
  }

  /// إجابة البوت على سؤال معين مع تأخير عشوائي بشري (3–8 ثواني)
  static Future<String> generateAnswer({
    required BotPlayer bot,
    required QuestionData question,
  }) async {
    final rng = Random();
    // تأخير واقعي
    await Future.delayed(Duration(milliseconds: 2500 + rng.nextInt(3500)));

    final persona = bot.isRain ? 'rain-hidden' : bot.persona;
    final answers = question.getAnswersFor(persona);
    final chosen = answers[rng.nextInt(answers.length)];

    return chosen;
  }

  /// محاكاة تفاعلات البوتات على الإجابات
  static Map<String, List<String>> generateBotReactions({
    required List<BotPlayer> bots,
    required Map<String, String> allAnswers,
  }) {
    final rng = Random();
    final reactionTypes = ['🤗', '💪', '❤️', '🌟'];
    final reactions = <String, List<String>>{}; // {alias: ['🤗', '❤️']}

    for (final bot in bots) {
      // كل بوت يرسل 1 إلى 3 تفاعلات على إجابات الآخرين
      final targetAliases = allAnswers.keys.where((a) => a != bot.alias).toList();
      targetAliases.shuffle(rng);

      final giveCount = min(targetAliases.length, 1 + rng.nextInt(2));
      for (int i = 0; i < giveCount; i++) {
        final target = targetAliases[i];
        final reaction = reactionTypes[rng.nextInt(reactionTypes.length)];
        reactions.putIfAbsent(target, () => []).add(reaction);
      }
    }

    return reactions;
  }

  /// حساب درجات الشك لتصويت البوتات (Section 6.4 Suspicion Score)
  static String calculateBotVote({
    required BotPlayer votingBot,
    required Map<String, List<String>> allPlayerAnswersAcrossRounds,
  }) {
    final rng = Random();
    final candidates = allPlayerAnswersAcrossRounds.keys.where((a) => a != votingBot.alias).toList();
    if (candidates.isEmpty) return '';

    // لو البوت هو نفسه صاحب المطر، يصوت على أي شخص آخر عشوائياً للتمويه
    if (votingBot.isRain) {
      return candidates[rng.nextInt(candidates.length)];
    }

    final scores = <String, double>{};

    for (final candidate in candidates) {
      double score = 0.0;
      final answers = allPlayerAnswersAcrossRounds[candidate] ?? [];

      for (final ans in answers) {
        // فحص كلمات الوجع والغموض
        for (final keyword in painKeywords) {
          if (ans.contains(keyword)) {
            score += 3.0;
          }
        }

        // فحص الإجابات القصيرة جداً في الأسئلة العميقة
        if (ans.trim().length < 20) {
          score += 1.5;
        }
      }

      // إضافة نسبة عشوائية ±20% كما بالوثيقة
      final randomness = (rng.nextDouble() * 0.4) - 0.2; // -0.2 to +0.2
      score = max(0.0, score * (1.0 + randomness));
      scores[candidate] = score;
    }

    // إيجاد المرشح صاحب أعلى نسبة شك
    String highestCandidate = candidates.first;
    double maxScore = -1.0;

    scores.forEach((cand, s) {
      if (s > maxScore) {
        maxScore = s;
        highestCandidate = cand;
      }
    });

    return highestCandidate;
  }

  /// إرسال رسائل دعم عاطفية لصاحب المطر في مرحلة الدعم
  static String generateSupportMessage(BotPlayer bot) {
    final rng = Random();
    return cannedSupportMessages[rng.nextInt(cannedSupportMessages.length)];
  }
}
