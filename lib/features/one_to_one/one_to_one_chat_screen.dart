import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/providers/providers.dart';
import '../../core/models/one_to_one_models.dart';
import 'one_to_one_feedback_screen.dart';

class OneToOneChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String currentUserId;
  final String currentUserNickname;

  const OneToOneChatScreen({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.currentUserNickname,
  });

  @override
  ConsumerState<OneToOneChatScreen> createState() => _OneToOneChatScreenState();
}

class _OneToOneChatScreenState extends ConsumerState<OneToOneChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isTyping = false;

  final List<String> _badWords = ['غبي', 'حمار', 'كلب', 'زفت', 'قذر', 'حيوان'];

  // أسئلة لتفتّح القلوب في الأعلى
  final List<String> _roomQuestions = [
    'ما هو الشيء الذي تشعر بالامتنان لوجوده في حياتك اليوم؟ 🌸',
    'متى كانت آخر مرة شعرت فيها بأنك مفهوم حقاً من شخص ما؟ 🫂',
    'إذا كان بإمكانك تغيير شيء واحد في يومك، فماذا سيكون؟ 🌅',
    'ما هي الكلمة التي تحتاج لسماعها الآن من شخص يحبك؟ 💌',
    'ما هو العبء الذي تشعر أنه أثقل كاهلك مؤخراً؟ 🎒',
  ];

  // أسئلة كسر الجليد لزر كسر الجليد
  final List<String> _iceBreakerQuestions = [
    'لو كان بإمكانك السفر عبر الزمن، لأي لحظة ستعود؟ 🕰️',
    'ما هو أكثر شيء يجعلك تشعر بالسلام الداخلي؟ 🍃',
    'ما هي النصيحة التي كنت تتمنى أن تسمعها اليوم؟ 💌',
    'لو كانت حياتك فيلماً، ما هو عنوانه؟ 🎬',
    'ما هي أكبر عقبة تغلبت عليها مؤخراً؟ 🧗‍♂️',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // تفعيل الحماية ضد لقطات وتسجيلات الشاشة
    ScreenProtector.preventScreenshotOn();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _audioRecorder.dispose();
    // إيقاف الكتابة عند الخروج
    ref.read(oneToOneServiceProvider).setTypingStatus(widget.roomId, widget.currentUserId, false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ref.read(oneToOneServiceProvider).leaveRoom(widget.roomId, widget.currentUserId);
      ref.read(oneToOneServiceProvider).setTypingStatus(widget.roomId, widget.currentUserId, false);
    }
  }

  String _filterBadWords(String text) {
    String filteredText = text;
    for (String word in _badWords) {
      filteredText = filteredText.replaceAll(
          RegExp(word, caseSensitive: false), '***');
    }
    return filteredText;
  }

  String _formatTime(DateTime time) {
    int h = time.hour;
    int m = time.minute;
    String ampm = h >= 12 ? 'م' : 'ص';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    String mm = m.toString().padLeft(2, '0');
    return '$h:$mm $ampm';
  }

  void _onTextChanged(String text) {
    final oneToOneService = ref.read(oneToOneServiceProvider);
    if (text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      oneToOneService.setTypingStatus(widget.roomId, widget.currentUserId, true);
    } else if (text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      oneToOneService.setTypingStatus(widget.roomId, widget.currentUserId, false);
    }
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final cleanText = _filterBadWords(text);
    HapticFeedback.lightImpact();

    final message = OneToOneMessageModel(
      messageId: FirebaseFirestore.instance.collection('dummy').doc().id,
      senderId: widget.currentUserId,
      senderName: widget.currentUserNickname,
      text: cleanText,
      type: 'text',
      timestamp: DateTime.now(),
    );

    ref.read(oneToOneServiceProvider).sendMessage(widget.roomId, message);
    _messageController.clear();

    setState(() => _isTyping = false);
    ref.read(oneToOneServiceProvider).setTypingStatus(widget.roomId, widget.currentUserId, false);
  }

  void _sendIceBreakerMessage() {
    HapticFeedback.mediumImpact();
    String randomQ =
        _iceBreakerQuestions[math.Random().nextInt(_iceBreakerQuestions.length)];

    final message = OneToOneMessageModel(
      messageId: FirebaseFirestore.instance.collection('dummy').doc().id,
      senderId: 'system',
      senderName: 'المساحة الآمنة',
      text: '🧊 سؤال لكسر الجليد:\n$randomQ',
      type: 'system',
      timestamp: DateTime.now(),
    );
    ref.read(oneToOneServiceProvider).sendMessage(widget.roomId, message);
  }

  void _showReactionMenu(String messageId, bool isMe) {
    if (isMe) return; // لا يمكن التفاعل على رسائل النفس

    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF13132B),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['❤️', '🫂', '🩹', '✨', '👏'].map((emoji) => GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(oneToOneServiceProvider).reactToMessage(
                        widget.roomId,
                        messageId,
                        emoji,
                      );
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              )).toList(),
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
              encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
          path: path,
        );
        setState(() => _isRecording = true);
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        File audioFile = File(path.replaceFirst('file://', ''));
        if (await audioFile.exists()) {
          List<int> fileBytes = await audioFile.readAsBytes();
          if (fileBytes.length < 1000) return;
          String base64String = base64Encode(fileBytes);

          HapticFeedback.lightImpact();

          final message = OneToOneMessageModel(
            messageId: FirebaseFirestore.instance.collection('dummy').doc().id,
            senderId: widget.currentUserId,
            senderName: widget.currentUserNickname,
            type: 'audio',
            audioBase64: base64String,
            timestamp: DateTime.now(),
          );

          ref.read(oneToOneServiceProvider).sendMessage(widget.roomId, message);
        }
      }
    } catch (e) {
      print("Error stopping record: $e");
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13132B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'إنهاء الجلسة؟',
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد مغادرة هذه المساحة الآمنة؟ سيتم إغلاق الغرفة.',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(oneToOneServiceProvider).leaveRoom(widget.roomId, widget.currentUserId);
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => OneToOneFeedbackScreen(
                      currentUserId: widget.currentUserId,
                      currentUserNickname: widget.currentUserNickname,
                    ),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Text(
              'مغادرة',
              style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportAndBlockUser() async {
    try {
      final oneToOneService = ref.read(oneToOneServiceProvider);
      await FirebaseFirestore.instance.collection('Reports').add({
        'roomId': widget.roomId,
        'reporterId': widget.currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'reason': 'انتهاك قواعد المساحة الآمنة (محظور ثنائي)',
      });

      DocumentSnapshot roomDoc = await FirebaseFirestore.instance
          .collection('one_to_one_rooms')
          .doc(widget.roomId)
          .get();

      if (roomDoc.exists && roomDoc.data() != null) {
        List<dynamic> participants = roomDoc['participants'];
        String otherUserId = participants.firstWhere(
            (id) => id != widget.currentUserId,
            orElse: () => '');
        if (otherUserId.isNotEmpty) {
          await oneToOneService.blockUser(widget.currentUserId, otherUserId);
        }
      }

      await oneToOneService.leaveRoom(widget.roomId, widget.currentUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حظر المستخدم وإبلاغ الإدارة.',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
        Navigator.pop(context); // العودة للرئيسية
      }
    } catch (e) {
      print('Error blocking user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final oneToOneService = ref.watch(oneToOneServiceProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitDialog();
      },
      child: AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.block, color: Colors.orangeAccent, size: 22),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF13132B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        'إبلاغ وحظر؟',
                        style: GoogleFonts.cairo(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'هل قام هذا الشخص بانتهاك قواعد المساحة؟ سيتم حظره نهائياً ولن يتم مطابقتكم مجدداً.',
                        style: GoogleFonts.cairo(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'إلغاء',
                            style: GoogleFonts.cairo(color: Colors.white54),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _reportAndBlockUser();
                          },
                          child: Text(
                            'حظر ومغادرة',
                            style: GoogleFonts.cairo(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              TextButton.icon(
                onPressed: _showExitDialog,
                icon: const Icon(Icons.exit_to_app_rounded,
                    color: Colors.redAccent, size: 20),
                label: Text(
                  'مغادرة',
                  style: GoogleFonts.cairo(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: StreamBuilder<OneToOneRoomModel>(
              stream: oneToOneService.getRoomStream(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                  );
                }
                final room = snapshot.data!;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: room.status == 'waiting'
                      ? Center(
                          key: const ValueKey('waiting'),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 56,
                                height: 56,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFB388FF),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'نهيئ لك المساحة الآن... خذ شهيقاً وزفيراً 🍃',
                                style: GoogleFonts.cairo(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          key: const ValueKey('active'),
                          children: [
                            // سؤال فتح القلوب العلوي
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 16),
                                child: Column(
                                  children: [
                                    Text(
                                      'سؤال لتفتّح القلوب 🤍',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFF00E5FF),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _roomQuestions[room.roomId.hashCode.abs() %
                                          _roomQuestions.length],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                            ),

                            // قائمة الرسائل
                            Expanded(
                              child: StreamBuilder<List<OneToOneMessageModel>>(
                                stream: oneToOneService.getMessagesStream(widget.roomId),
                                builder: (context, chatSnapshot) {
                                  if (!chatSnapshot.hasData) {
                                    return const SizedBox();
                                  }
                                  final messages = chatSnapshot.data!;

                                  return ListView.builder(
                                    reverse: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final msg = messages[index];
                                      final isMe =
                                          msg.senderId == widget.currentUserId;

                                      if (msg.type == 'system') {
                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF69F0AE)
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF69F0AE)
                                                  .withOpacity(0.25),
                                            ),
                                          ),
                                          child: Text(
                                            msg.text,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.cairo(
                                              color: const Color(0xFF69F0AE),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              height: 1.5,
                                            ),
                                          ),
                                        );
                                      }

                                      return GestureDetector(
                                        onLongPress: () =>
                                            _showReactionMenu(msg.messageId, isMe),
                                        child: Align(
                                          alignment: isMe
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 20),
                                                padding: const EdgeInsets.all(12),
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.75,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isMe
                                                      ? const Color(0xFF00E5FF)
                                                          .withOpacity(0.15)
                                                      : Colors.white
                                                          .withOpacity(0.06),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft: const Radius.circular(20),
                                                    topRight: const Radius.circular(20),
                                                    bottomLeft: Radius.circular(
                                                        isMe ? 20 : 2),
                                                    bottomRight: Radius.circular(
                                                        isMe ? 2 : 20),
                                                  ),
                                                  border: Border.all(
                                                    color: isMe
                                                        ? const Color(0xFF00E5FF)
                                                            .withOpacity(0.3)
                                                        : Colors.white
                                                            .withOpacity(0.04),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (!isMe) ...[
                                                      Text(
                                                        msg.senderName,
                                                        style: GoogleFonts.cairo(
                                                          color: const Color(
                                                              0xFFB388FF),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                    ],
                                                    if (msg.type == 'text')
                                                      Text(
                                                        msg.text,
                                                        style: GoogleFonts.cairo(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          height: 1.4,
                                                        ),
                                                      )
                                                    else if (msg.type == 'audio' &&
                                                        msg.audioBase64 != null)
                                                      AudioPlayerWidget(
                                                          audioBase64:
                                                              msg.audioBase64!),
                                                    const SizedBox(height: 6),
                                                    Align(
                                                      alignment:
                                                          Alignment.bottomLeft,
                                                      child: Text(
                                                        _formatTime(msg.timestamp),
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.35),
                                                          fontSize: 9,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (msg.reaction != null)
                                                Positioned(
                                                  bottom: 6,
                                                  right: isMe ? null : -8,
                                                  left: isMe ? -8 : null,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF13132B),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: const Color(
                                                                0xFFB388FF)
                                                            .withOpacity(0.6),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      msg.reaction!,
                                                      style: const TextStyle(
                                                          fontSize: 15),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ).animate().scale(
                                            duration: 300.ms,
                                            alignment: isMe
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            curve: Curves.easeOutBack,
                                          );
                                    },
                                  );
                                },
                              ),
                            ),

                            // مؤشر الكتابة و كسر الجليد وصندوق الإدخال
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: (room.status == 'closed' ||
                                      room.participants.length < 2)
                                  ? Padding(
                                      key: const ValueKey('closed_input'),
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: Colors.redAccent
                                                      .withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              'لقد غادر الطرف الآخر المساحة بسلام.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.cairo(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await oneToOneService.leaveRoom(
                                                  widget.roomId,
                                                  widget.currentUserId);
                                              if (mounted) {
                                                Navigator.pushReplacement(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (_, __, ___) =>
                                                        OneToOneFeedbackScreen(
                                                      currentUserId:
                                                          widget.currentUserId,
                                                      currentUserNickname: widget
                                                          .currentUserNickname,
                                                    ),
                                                    transitionsBuilder:
                                                        (_, animation, __, child) =>
                                                            FadeTransition(
                                                                opacity:
                                                                    animation,
                                                                child: child),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.spa_rounded,
                                                size: 22),
                                            label: Text(
                                              'إنهاء الجلسة بسلام',
                                              style: GoogleFonts.cairo(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFFF8A80),
                                              foregroundColor:
                                                  const Color(0xFF0B0F19),
                                              minimumSize: const Size(
                                                  double.infinity, 56),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      key: const ValueKey('active_input'),
                                      children: [
                                        // يكتب الآن
                                        if (room.typingUsers.contains(room
                                            .participants
                                            .firstWhere(
                                                (id) =>
                                                    id != widget.currentUserId,
                                                orElse: () => '')))
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24.0, vertical: 4.0),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'يكتب بصدق الآن...',
                                                style: GoogleFonts.cairo(
                                                  color: const Color(0xFFB388FF),
                                                  fontSize: 13,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),

                                        // زر كسر الجليد
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: ActionChip(
                                              backgroundColor:
                                                  const Color(0xFF00E5FF)
                                                      .withOpacity(0.08),
                                              side: BorderSide(
                                                color: const Color(0xFF00E5FF)
                                                    .withOpacity(0.25),
                                              ),
                                              label: Text(
                                                '🧊 كسر الجليد',
                                                style: GoogleFonts.cairo(
                                                  color: const Color(0xFF00E5FF),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed: _sendIceBreakerMessage,
                                            ),
                                          ),
                                        ),

                                        // حقل الإدخال وزر الصوت
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: GlassCard(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onLongPress: _startRecording,
                                                  onLongPressUp:
                                                      _stopRecordingAndSend,
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    padding:
                                                        const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: _isRecording
                                                          ? Colors.redAccent
                                                          : const Color(
                                                                  0xFF00E5FF)
                                                              .withOpacity(0.12),
                                                    ),
                                                    child: Icon(
                                                      _isRecording
                                                          ? Icons.mic_rounded
                                                          : Icons.mic_none_rounded,
                                                      color: _isRecording
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF00E5FF),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextField(
                                                    controller: _messageController,
                                                    onChanged: _onTextChanged,
                                                    style: GoogleFonts.cairo(
                                                        color: Colors.white,
                                                        fontSize: 15),
                                                    decoration: InputDecoration(
                                                      hintText: _isRecording
                                                          ? 'نسجل فضفضتك...'
                                                          : 'تحدث... نحن هنا لنسمعك 🤍',
                                                      hintStyle: GoogleFonts.cairo(
                                                        color: _isRecording
                                                            ? Colors.redAccent
                                                            : Colors.white38,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 16),
                                                    ),
                                                    enabled: !_isRecording,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.send_rounded,
                                                      color: Color(0xFF00E5FF)),
                                                  onPressed: _sendTextMessage,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioBase64;
  const AudioPlayerWidget({super.key, required this.audioBase64});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      setState(() => _isLoading = true);
      try {
        Uint8List audioBytes = base64Decode(widget.audioBase64);
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/temp_play_${DateTime.now().millisecondsSinceEpoch}.m4a');
        await file.writeAsBytes(audioBytes);
        await _audioPlayer.play(DeviceFileSource(file.path));
      } catch (e) {
        print("Audio playback error: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
          onPressed: _isLoading ? null : _togglePlay,
        ),
        Text(
          'رسالة صوتية 🎵',
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
