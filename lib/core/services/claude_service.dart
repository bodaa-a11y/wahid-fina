import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-5';
  static const String _anthropicVersion = '2023-06-01';

  // ⚠️ يتم حقن مفتاح الـ API للإنتاج عبر --dart-define=CLAUDE_API_KEY=your_key أو استخدامه مباشرة كقيمة افتراضية مضافة من قبلك
  static const String _apiKey = String.fromEnvironment(
    'CLAUDE_API_KEY',
    defaultValue: '',
  );

  static const String _systemPrompt = '''
أنت "رفيق" — المرشد الذكي للعبة "واحد فينا"، لعبة اجتماعية نفسية دافئة وإنسانية.

## دورك في اللعبة:
أنت لا تحكم ولا تحلل بشكل طبي. أنت صديق ذكي يدير جلسة تواصل إنساني بين أشخاص حقيقيين.

## قواعدك الأساسية:
1. دافئ دائماً — لا تستخدم لغة سريرية أو باردة أبداً
2. محايد — لا تكشف من هو "واحد فينا" إلا في المرحلة النهائية
3. مشجع — كل إجابة صادقة تستحق الاحترام
4. آمن — لو لاحظت محتوى يشير لأذى حقيقي، وجّه بلطف لطلب المساعدة المتخصصة
5. مختصر في التعليقات أثناء اللعبة — جملة أو اثنتين فقط
6. عربي بالكامل — تحدث بالعامية المصرية الدافئة

## ما لا تفعله أبداً:
- لا تقول "أنا ذكاء اصطناعي" أثناء اللعبة
- لا تشخّص أحداً نفسياً
- لا تكشف الشخص قبل النهاية
- لا تستخدم ردود آلية جاهزة
''';

  Future<String?> _callClaude(String userMessage, {int maxTokens = 500}) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _anthropicVersion,
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': maxTokens,
          'system': _systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['content'][0]['text'] as String?;
      } else {
        debugPrint('Claude API Error: ${response.statusCode} — ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Claude Service Error: $e');
      return null;
    }
  }

  // ✨ تعليق بعد كل سؤال
  Future<String> getQuestionComment({
    required String question,
    required int questionNumber,
    required int totalQuestions,
    required List<Map<String, String>> answers,
  }) async {
    final answersText = answers
        .map((a) => '• ${a['name']}: "${a['answer']}"')
        .join('\n');

    final prompt = '''
السؤال رقم $questionNumber من $totalQuestions: "$question"

إجابات اللاعبين:
$answersText

اكتب تعليقاً دافئاً قصيراً (جملة أو اثنتين بالحد الأقصى) على هذه الإجابات.
- شجع التواصل والتعاطف بين اللاعبين
- لا تكشف أي معلومة عن "واحد فينا"
- اجعل الجميع يحسوا إن إجاباتهم مهمة ومسموعة
- أسلوب دافئ وعفوي، مش رسمي
''';

    final result = await _callClaude(prompt, maxTokens: 200);
    return result ?? _getOfflineComment(questionNumber);
  }

  // 🏁 الرسالة النهائية بعد اكتشاف "واحد فينا"
  Future<String> getFinalMessage({
    required String strugglingPlayerName,
    required List<Map<String, dynamic>> gameSummary,
    required List<String> questions,
  }) async {
    final summaryText = gameSummary.map((item) {
      final answers = (item['answers'] as List).map((a) => '  - ${a['name']}: "${a['answer']}"').join('\n');
      return 'السؤال: "${item['question']}"\n$answers';
    }).join('\n\n');

    final prompt = '''
انتهت لعبة "واحد فينا". إليك ملخص الجلسة الكاملة:

$summaryText

الشخص الذي كان "واحد فينا" هو: $strugglingPlayerName

اكتب:
1. تقييم لطيف: هل لاحظ اللاعبون وجود شخص يحتاج دعم؟ من أكثر شخص أظهر تعاطفاً؟
2. رسالة مخصصة لـ $strugglingPlayerName — دافئة جداً، تخليه يحس إنه مش لوحده
3. رسالة للباقين عن قيمة وجودهم وتأثيرهم
4. كلمة أخيرة عن معنى الصداقة الحقيقية

الأسلوب: دافئ، إنساني، مش نصائح جاهزة. كأنك صاحب حقيقي بيتكلم معاهم.
الطول: فقرتان أو ثلاثة بالحد الأقصى.
''';

    final result = await _callClaude(prompt, maxTokens: 800);
    return result ?? _getOfflineFinalMessage(strugglingPlayerName);
  }

  // 🔒 Fallback Comments (offline)
  static const List<String> _offlineComments = [
    'كلامكم واضح فيه ناس بتحس بعمق... الصدق ده هو اللي بيخلي المحادثة حلوة 🤍',
    'في إجاباتكم حاجات كتير مشتركة... بيبين إننا في النهاية بني آدمين بنحس بنفس الأحاسيس 💫',
    'الصراحة اللي في كلامكم دي هدية لبعض... شكراً إنكم موجودين هنا 🌙',
    'كل إجابة بتقولها بتخلي حد تاني يحس إنه مش غلط في حساسيته 🫂',
    'في الكلام ده إحساس حقيقي... اللعبة دي مش بس لعبة، هي مساحة صدق ✨',
    'أسمع في كلامكم ناس عندها أعماق كتير... وده جميل جداً 🌸',
    'كل واحد فيكم بيضيف حاجة مختلفة وقيمة... ده اللي بيخلي المحادثة دافية 💜',
    'الإجابات دي مش بس كلام... هي أجزاء من قلوب ناس حقيقية 🕊️',
    'في كل إجابة قلب بيتكلم بصدق... وده أجمل حاجة ممكن تحصل 🌟',
    'شكراً لصدقكم... الصراحة دي هي اللي بتعمل فرق حقيقي 💫',
  ];

  String _getOfflineComment(int questionNumber) {
    return _offlineComments[questionNumber % _offlineComments.length];
  }

  String _getOfflineFinalMessage(String name) {
    return '''
$name، إنت مش لوحدك. اللي بتحس بيه حقيقي ومهم، والناس اللي كانت معاك النهارده شافت جزء من قلبك وحبته. 🤍

للباقين: وجودكم وكلامكم الدافي فرق فعلاً. في بعض الأوقات مجرد إن حد يحس إنه مسموع بيكون أقوى من أي كلمة. أنتم عملتوا ده اليوم.

الصداقة الحقيقية مش بتتبني في سنين... أحياناً بتتبني في سؤال واحد صادق. ❤️
''';
  }
}
