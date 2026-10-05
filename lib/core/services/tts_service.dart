// 🎙️ خدمة الصوت — نطق الأسئلة بصوت درامي + مؤثرات تشويق
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _sfx = AudioPlayer();

  bool _speaking = false;
  bool get isSpeaking => _speaking;

  /// اتصل بيه لما حالة الكلام تتغير (عشان أنيميشن الفم)
  void Function(bool speaking)? onSpeakingChanged;

  Future<void> init() async {
    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.42);   // بطيء = درامي
      await _tts.setPitch(0.8);         // أعمق شوية
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() => _setSpeaking(true));
      _tts.setCompletionHandler(() => _setSpeaking(false));
      _tts.setCancelHandler(() => _setSpeaking(false));
      _tts.setErrorHandler((_) => _setSpeaking(false));
    } catch (_) {}
  }

  void _setSpeaking(bool v) {
    _speaking = v;
    onSpeakingChanged?.call(v);
  }

  /// موسيقى تشويق ثم نطق السؤال
  Future<void> speakQuestion(String question) async {
    await stop();
    try {
      await _sfx.play(AssetSource('sounds/suspense.mp3'), volume: 0.6);
      await Future.delayed(const Duration(milliseconds: 1200));
    } catch (_) {} // لو الملف مش موجود يكمّل عادي
    await _tts.speak('السؤال هو... $question');
  }

  /// نطق نص حر (تعليق AI، الكشف، إلخ)
  Future<void> speak(String text) async {
    await stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      await _sfx.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
    _sfx.dispose();
  }
}
