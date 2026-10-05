// 🎮 شاشة الروم الموحدة — تطبيق مواصفات "واحد فينا" (Screen-by-Screen Spec v1.0)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/constants/game_questions.dart';
import 'room_controller.dart';
import '../one_to_one/one_to_one_chat_screen.dart';
import '../../core/models/care_tree_model.dart';
import '../../core/widgets/care_tree_widget.dart';
import '../vault/support_vault_screen.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _supportController = TextEditingController();
  int? _selectedRoleMode; // 0: rain, 1: supporter, 2: notAlone (F4)
  String? _selectedStory; // null = عام, or 'loss', 'exams', 'future', 'lonely', 'heartbreak' (F10)
  String? _selectedVoteAlias;
  CareTreeModel _careTree = const CareTreeModel(stage: 1, leaves: 4, fruits: 2, stars: 2);
  bool _earthVoiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadTree();
  }

  Future<void> _loadTree() async {
    final t = await CareTreeStorage.loadTree();
    if (mounted) setState(() => _careTree = t);
  }

  @override
  void dispose() {
    _answerController.dispose();
    _supportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomControllerProvider);
    final controller = ref.read(roomControllerProvider.notifier);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          // التنظيف يتم في dispose
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: AppBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  // المحتوى الأساسي وفق آلة الحالات (State Machine)
                  _buildContent(state, controller),

                  // زر الإبلاغ الثابت 🚩
                  if (state.phase != RoomPhase.roleSelection && state.phase != RoomPhase.results)
                    Positioned(
                      top: 12,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.flag_outlined, color: Colors.white38, size: 22),
                        tooltip: 'إبلاغ عن محتوى غير لائق',
                        onPressed: () => _showReportDialog(context),
                      ),
                    ),

                  // تنبيه الأزمة النفسية (Safety Crisis Overlay)
                  if (state.crisisDetected)
                    _buildCrisisOverlay(controller),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(RoomState state, RoomController controller) {
    switch (state.phase) {
      case RoomPhase.roleSelection:
        return _buildRoleSelectionView(controller);
      case RoomPhase.matching:
        return _buildMatchingView(state);
      case RoomPhase.lobby:
        return _buildLobbyView(state, controller);
      case RoomPhase.question:
        return _buildQuestionView(state, controller);
      case RoomPhase.voting:
        return _buildVotingView(state, controller);
      case RoomPhase.reveal:
        return _buildRevealView(state);
      case RoomPhase.support:
        return _buildSupportView(state, controller);
      case RoomPhase.results:
        return _buildResultsView(state, controller);
      case RoomPhase.postRoom:
        return _buildPostRoomView(state, controller);
    }
  }

  // ── الشاشة 1: تسجيل الدخول / اختيار الدور ────────────────────────────────────
  Widget _buildRoleSelectionView(RoomController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            'أنت جاي النهاردة عشان…',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn().slideY(begin: -0.1),
          const SizedBox(height: 24),

          // بطاقة 1: محتاج أحس إن في حد سامعني (صاحب المطر المتخفي)
          _buildRoleChoiceCard(
            title: 'محتاج أحس إن في حد سامعني 🌧️',
            subtitle: 'مش لازم تشرح كل حاجة.. وجودك كفاية',
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF00CEC9),
            isSelected: _selectedRoleMode == 0,
            onTap: () => setState(() => _selectedRoleMode = 0),
          ),
          const SizedBox(height: 12),

          // بطاقة 2: محتاج أدعم حد وأسمعه (الداعم)
          _buildRoleChoiceCard(
            title: 'محتاج أدعم حد وأسمعه ☀️',
            subtitle: 'كن سنداً ودافع أمل لشخص في الروم',
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFFDCB6E),
            isSelected: _selectedRoleMode == 1,
            onTap: () => setState(() => _selectedRoleMode = 1),
          ),
          const SizedBox(height: 12),

          // بطاقة 3: وضع اليد الممدودة (F4)
          _buildRoleChoiceCard(
            title: 'عايز أتكلم… ويسمعوني من غير ألغاز 🤝',
            subtitle: 'محدش هيخمّ عليك. الكل هيسمعك من الأول بدون تصويت',
            icon: Icons.volunteer_activism_rounded,
            color: const Color(0xFFA29BFE),
            isSelected: _selectedRoleMode == 2,
            onTap: () => setState(() => _selectedRoleMode = 2),
          ),

          const SizedBox(height: 24),

          // اختيار نوع الروم وقصة التجربة (F10 رومات نفس الحكاية)
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: AppColors.accentLight, size: 18),
              const SizedBox(width: 8),
              Text(
                'نوع الروم وتجربة المشاركة:',
                style: GoogleFonts.cairo(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStoryFilterChip('🔀 روم عام', null),
                _buildStoryFilterChip('🕊️ فقدان حد قريب', 'loss'),
                _buildStoryFilterChip('📚 ضغوط دراسة', 'exams'),
                _buildStoryFilterChip('💼 قلق المستقبل', 'future'),
                _buildStoryFilterChip('🌍 وحدة وغربة', 'lonely'),
                _buildStoryFilterChip('💔 قلب مجروح', 'heartbreak'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'اختيارك سرّي تماماً 🤍 محدش في أي روم هيعرف غيرك.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: _selectedRoleMode == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    controller.selectRoleAndMatch(
                      wantsRainRole: _selectedRoleMode == 0,
                      isNotAloneMode: _selectedRoleMode == 2,
                      story: _selectedStory,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white12,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(
              'كمّل',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStoryFilterChip(String label, String? value) {
    final isSelected = (_selectedStory == value);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: GoogleFonts.cairo(
          color: isSelected ? Colors.white : Colors.white60,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white.withOpacity(0.04),
        selectedColor: AppColors.primary.withOpacity(0.3),
        checkmarkColor: AppColors.accentLight,
        side: BorderSide(
          color: isSelected ? AppColors.accentLight : Colors.white12,
        ),
        onSelected: (_) => setState(() => _selectedStory = value),
      ),
    );
  }

  Widget _buildRoleChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 26)
                  .animate()
                  .scale(duration: 200.ms),
          ],
        ),
      ),
    );
  }

  // ── الشاشة 2: المطابقة (Matching) ──────────────────────────────────────────
  Widget _buildMatchingView(RoomState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 6 دوائر تتعبى
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < state.players.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.white10,
                    border: Border.all(
                      color: isFilled ? Colors.white : Colors.white24,
                      width: isFilled ? 2 : 1,
                    ),
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isFilled
                        ? const Icon(Icons.favorite_rounded, color: Colors.white, size: 24)
                        : Text('${index + 1}',
                            style: GoogleFonts.cairo(color: Colors.white30, fontSize: 16)),
                  ),
                ).animate(target: isFilled ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
              }),
            ),
            const SizedBox(height: 48),

            Text(
              'بنجمّعلك قلوب…',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'في 12 شخص مستنيين دلوقتي ✨',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.warm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── الشاشة 3: المدخل (Lobby) ────────────────────────────────────────────────
  Widget _buildLobbyView(RoomState state, RoomController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // شريط الاسم المستعار
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'اسمك المستعار: ${state.myAlias}',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // بطاقة القواعد (3 أسطر)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRuleLine('1. فيه واحد بينكم بيمر بوقت صعب 🌧️'),
                const SizedBox(height: 8),
                _buildRuleLine('2. هتجاوبوا على 10 أسئلة… الكل نفس السؤال 📝'),
                const SizedBox(height: 8),
                _buildRuleLine('3. في الآخر، قول مين شايفه والكل يكتب كلمة دعم 🤗'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // شبكة اللاعبين الـ 6
          Text(
            'أصحاب الروم:',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.9,
              ),
              itemCount: state.players.length,
              itemBuilder: (context, i) {
                final p = state.players[i];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: p.color.withOpacity(0.2),
                          child: Text(
                            p.alias.isNotEmpty ? p.alias[0] : '؟',
                            style: GoogleFonts.cairo(
                              color: p.color,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (p.isReady)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent,
                              ),
                              child: const Icon(Icons.check, size: 12, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.alias,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // زر جاهز
          ElevatedButton(
            onPressed: state.players.isNotEmpty && state.players[0].isReady
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    controller.toggleHumanReady();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green.withOpacity(0.4),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(
              state.players.isNotEmpty && state.players[0].isReady ? 'جاهز ✓ في انتظار الباقين...' : 'أنا جاهز 🚀',
              style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRuleLine(String text) {
    return Row(
      children: [
        const Icon(Icons.lens, size: 8, color: AppColors.warm),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── الشاشة 4: جولة السؤال (10 مرات) ──────────────────────────────────────────
  Widget _buildQuestionView(RoomState state, RoomController controller) {
    final currentQ = state.questions[state.currentRound];

    // تحديد لون شريط العمق
    Color depthColor = Colors.greenAccent;
    if (currentQ.level == QuestionLevel.mid) depthColor = Colors.amberAccent;
    if (currentQ.level == QuestionLevel.deep) depthColor = Colors.redAccent;

    return Column(
      children: [
        // AppBar مع مؤشر الجولة والتايمر وصوت الأرض (F8)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الجولة ${state.currentRound + 1} من 10',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  // F8: صوت الأرض في الجولات العميقة 8-10
                  if (state.currentRound >= 7) ...[
                    IconButton(
                      icon: Icon(
                        _earthVoiceEnabled ? Icons.waves_rounded : Icons.waves_outlined,
                        color: _earthVoiceEnabled ? AppColors.accentLight : Colors.white38,
                        size: 20,
                      ),
                      tooltip: _earthVoiceEnabled ? 'صوت الأرض مفعّل 🌊' : 'صوت الأرض متوقف',
                      onPressed: () {
                        setState(() => _earthVoiceEnabled = !_earthVoiceEnabled);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 1),
                            content: Text(
                              _earthVoiceEnabled ? 'صوت الأرض مفعّل بهدوء 🌊' : 'تم إيقاف صوت الأرض',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: AppColors.warm),
                        const SizedBox(width: 6),
                        Text(
                          '${state.timerSeconds} ث',
                          style: GoogleFonts.cairo(
                            color: AppColors.warm,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // بطاقة السؤال مع شريط العمق
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B36),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: depthColor.withOpacity(0.4), width: 1.5),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 48,
                  decoration: BoxDecoration(
                    color: depthColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    currentQ.question,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // قائمة الإجابات أو حقل الإدخال
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // حقل الإجابة قبل الإرسال
              if (!state.hasSubmittedAnswer) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _answerController,
                        maxLength: 280,
                        maxLines: 3,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'اكتب بصدق… محدش هيعرف مين كتب',
                          hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
                          border: InputBorder.none,
                          counterStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 11),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_answerController.text.trim().isNotEmpty) {
                              HapticFeedback.lightImpact();
                              controller.submitAnswer(_answerController.text);
                              _answerController.clear();
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text('إرسال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // بطاقات إجابات اللاعبين ومؤشرات "يكتب..."
              ...state.players.map((p) {
                if (p.isTyping && p.currentAnswer.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 14, backgroundColor: p.color.withOpacity(0.3), child: Text(p.alias[0], style: TextStyle(color: p.color, fontSize: 12))),
                          const SizedBox(width: 10),
                          Text('${p.alias} يكتب الآن… ✍️', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                if (p.currentAnswer.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: p.color.withOpacity(0.3),
                                child: Text(p.alias[0], style: TextStyle(color: p.color, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text(p.alias, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (p.isHuman)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                  child: Text('إجابتك', style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 11)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.currentAnswer,
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 12),

                          // شريط التفاعلات (Reactions: 🤗 💪 ❤️ 🌟)
                          Row(
                            children: [
                              ...['🤗', '💪', '❤️', '🌟'].map((react) {
                                final count = p.reactions.where((r) => r == react).length;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    controller.sendReaction(p.alias, react);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(react, style: const TextStyle(fontSize: 14)),
                                        if (count > 0) ...[
                                          const SizedBox(width: 4),
                                          Text('$count', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── الشاشة 5: التصويت ──────────────────────────────────────────────────────
  Widget _buildVotingView(RoomState state, RoomController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مين صاحب المطر؟ 🌧️',
                style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
                child: Text('${state.timerSeconds} ث', style: GoogleFonts.cairo(color: AppColors.warm, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اختر من تعتقد أنه يمر بوقت صعب بناءً على إجابات الجولات العشر:',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.2,
              ),
              itemCount: state.players.length,
              itemBuilder: (context, index) {
                final p = state.players[index];
                final isSelected = _selectedVoteAlias == p.alias;

                return GestureDetector(
                  onTap: state.hasVoted
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedVoteAlias = p.alias);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white12,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: p.color.withOpacity(0.2),
                          child: Text(p.alias[0], style: TextStyle(color: p.color, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.alias,
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          ElevatedButton(
            onPressed: (state.hasVoted || _selectedVoteAlias == null)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    controller.submitHumanVote(_selectedVoteAlias!);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(
              state.hasVoted ? 'تم تأكيد تصويتك ✓' : 'تأكيد الاختيار (مش هتقدر تغير)',
              style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── الشاشة 6: الكشف (Reveal) ────────────────────────────────────────────────
  Widget _buildRevealView(RoomState state) {
    final rainAlias = state.rainPlayerAlias ?? 'قمر';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00CEC9).withOpacity(0.15),
                border: Border.all(color: const Color(0xFF00CEC9), width: 3),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00CEC9).withOpacity(0.3), blurRadius: 40, spreadRadius: 8),
                ],
              ),
              child: const Icon(Icons.water_drop_rounded, size: 70, color: Color(0xFF00CEC9)),
            ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

            const SizedBox(height: 28),
            Text(
              'صاحب المطر في هذه الروم هو:',
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              rainAlias,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('💭', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    '«${state.rainPlayerBestQuote ?? "متحمل وبكتم كل حاجة جوايا"}»',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic, height: 1.5),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),
            Text(
              'كلامه وصلكم… دلوقتي وصلوه أنتم 🤍',
              style: GoogleFonts.cairo(color: AppColors.warm, fontSize: 14, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    );
  }

  // ── الشاشة 7: رسائل الدعم ──────────────────────────────────────────────────
  Widget _buildSupportView(RoomState state, RoomController controller) {
    final rainAlias = state.rainPlayerAlias ?? 'صاحب المطر';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'كلمة لصاحب المطر ($rainAlias) 🤍',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'اكتبله كلمة دعم صادقة.. هتوصله كلها دفعة واحدة:',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _supportController,
                  maxLength: 140,
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'كلنا جنبك، متقلقش من اللي جاي 🤗',
                    hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 13),
                    border: InputBorder.none,
                    counterStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 11),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      controller.submitSupportMessage(_supportController.text);
                      _supportController.clear();
                    },
                    icon: const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                    label: Text('ابعت ❤️', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'رسائل الروم المتدفقة:',
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView(
              children: state.players.where((p) => p.supportMessage != null && p.supportMessage!.isNotEmpty).map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: p.color.withOpacity(0.3), child: Text(p.alias[0], style: TextStyle(color: p.color, fontSize: 12))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.alias, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(p.supportMessage!, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── الشاشة 8: النتائج والجوائز ──────────────────────────────────────────────
  Widget _buildResultsView(RoomState state, RoomController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'نتائج الروم 🏆',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 18),

          // F3: شجرة الدعم الحية الخاصة باللاعب
          CareTreeWidget(tree: _careTree),
          const SizedBox(height: 18),

          // F4: وسام وضع اليد الممدودة ومضاعفة النقاط
          if (state.isNotAloneMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFA29BFE).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA29BFE), width: 1.2),
              ),
              child: Row(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'وضع اليد الممدودة: تم مضاعفة نقاط تعاطفك (×2) لشجاعتك وصدقك 🤍',
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // F2: بطاقة "نفس الموجة" (Resonance Match)
          if (state.resonancePairAlias != null) ...[
            GestureDetector(
              onTap: () => _showResonanceBottomSheet(context, state.resonancePairAlias!),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 14, spreadRadius: 1),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نفس الموجة مع ${state.resonancePairAlias}!',
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'إجاباتكم وتفاعلاتكم تقاربت جداً.. اضغط لفتح فضفضة خاصة',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3 بطاقات جوائز
          _buildAwardCard(
            title: 'أفضل كاشف 🏆',
            winner: state.bestGuesserAlias ?? 'نور',
            desc: 'أقرب تخمين وتحديد لصاحب المطر',
            color: const Color(0xFFFDCB6E),
          ),
          const SizedBox(height: 12),

          _buildAwardCard(
            title: 'أفضل داعم 🤗',
            winner: state.bestSupporterAlias ?? 'وردة',
            desc: 'جمع أكبر عدد من التفاعلات المتعاطفة',
            color: const Color(0xFFE84393),
          ),
          const SizedBox(height: 12),

          _buildAwardCard(
            title: 'أحسن تمويه 🎭',
            winner: state.bestCamouflageAlias ?? 'قمر',
            desc: 'حافظ على غموضه وأجاب بصدق',
            color: const Color(0xFF00CEC9),
          ),
          const SizedBox(height: 20),

          // رصيد النقاط
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('+${state.empathyPointsEarned}', style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text('نقاط تعاطف', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12)),
                  ],
                ),
                Container(width: 1, height: 36, color: Colors.white12),
                Column(
                  children: [
                    Text('+${state.insightPointsEarned}', style: GoogleFonts.cairo(color: AppColors.warm, fontSize: 22, fontWeight: FontWeight.w900)),
                    Text('نقاط كشف', style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => controller.goToPostRoom(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('👥 تواصل مع أصحاب الروم', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () => controller.restartMatch(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('🔄 العب تاني في روم جديدة', style: GoogleFonts.cairo(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardCard({
    required String title,
    required String winner,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.25),
            radius: 20,
            child: Text(winner.isNotEmpty ? winner[0] : '؟', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: GoogleFonts.cairo(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text('($winner)', style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(desc, style: GoogleFonts.cairo(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── الشاشة 9: ما بعد الروم (Social) ─────────────────────────────────────────
  Widget _buildPostRoomView(RoomState state, RoomController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اتعرفتوا على بعض ✨',
            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'تقدر تضيف أصحاب الروم أو تبدأ فضفضة خاصة 1-on-1:',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 18),

          Expanded(
            child: ListView.builder(
              itemCount: state.players.length,
              itemBuilder: (context, i) {
                final p = state.players[i];
                if (p.isHuman) return const SizedBox.shrink(); // لا يظهر نفسه

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: p.color.withOpacity(0.3),
                          child: Text(p.alias[0], style: TextStyle(color: p.color, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.alias, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(p.isRain ? 'صاحب المطر 🌧️' : 'داعم ☀️', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        // زر إضافة صديق
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.warm, size: 22),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم إرسال طلب صداقة لـ ${p.alias} 🤍', style: GoogleFonts.cairo())),
                            );
                          },
                        ),
                        // زر فتح محادثة خاصة 1-on-1 في المساحة الآمنة
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF00CEC9), size: 22),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OneToOneChatScreen(
                                  roomId: 'room_${p.alias}_${DateTime.now().millisecondsSinceEpoch}',
                                  currentUserId: 'me',
                                  currentUserNickname: state.myAlias,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // F1: زر فتح صندوق الدعم
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportVaultScreen()),
              );
            },
            icon: const Icon(Icons.mark_email_read_outlined, color: AppColors.accentLight),
            label: Text('📬 فتح صندوق الدعم (رسائلك المحفوظة)', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentLight),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('الرجوع للرئيسية', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // F2: نافذة نفس الموجة (Resonance Bottom Sheet)
  void _showResonanceBottomSheet(BuildContext context, String partnerAlias) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1A38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 18),
              const Text('⚡', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                'نفس الموجة! إجاباتكم اتقاربت أوي',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'تفاعلاتكم ومشاعرك تقاطعت أكتر من 3 مرات مع $partnerAlias خلال الروم 🤍',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OneToOneChatScreen(
                        roomId: 'resonance_${partnerAlias}_${DateTime.now().millisecondsSinceEpoch}',
                        currentUserId: 'me',
                        currentUserNickname: 'نور',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_rounded),
                label: Text('افتح فضفضة خاصة (1-on-1)', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('بعدين', style: GoogleFonts.cairo(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── الشاشة 10: التنبيهات الأمنية (Overlays) ──────────────────────────────────
  Widget _buildCrisisOverlay(RoomController controller) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 56),
            const SizedBox(height: 18),
            Text(
              'كلامك وصلنا.. وانت مش لوحدك 🤍',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'إذا كنت تمر بأزمة حقيقية أو تشعر بألم لا تحتمله، نحن نهتم لأمرك جداً. هناك متخصصون مستعدون للاستماع إليك ومساعدتك على مدار الساعة في سرية تامة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_in_talk, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Text('الخط الساخن للدعم النفسي: 16328 (مصر)', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.closeCrisisOverlay(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('فهمت، شكراً لكم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B36),
        title: Text('إبلاغ عن محتوى غير لائق', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('نحن نحرص على أمان هذه المساحة. سيتم فحص الروم فوراً واتخاذ الإجراء اللازم.', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استلام البلاغ، شكراً لحرصك 🤍', style: GoogleFonts.cairo())));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('إرسال البلاغ', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
