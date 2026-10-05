// 📬 شاشة صندوق الدعم (Support Vault) — مواصفات F1
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/models/vault_message_model.dart';

class SupportVaultScreen extends StatefulWidget {
  const SupportVaultScreen({super.key});

  @override
  State<SupportVaultScreen> createState() => _SupportVaultScreenState();
}

class _SupportVaultScreenState extends State<SupportVaultScreen> {
  List<VaultMessageModel> _messages = [];
  bool _isLoading = true;
  VaultMessageModel? _featuredMessage;

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    setState(() => _isLoading = true);
    final msgs = await SupportVaultStorage.loadMessages();
    VaultMessageModel? featured;
    if (msgs.isNotEmpty) {
      final pinned = msgs.where((m) => m.isPinned).toList();
      if (pinned.isNotEmpty) {
        featured = pinned.first;
      } else {
        featured = msgs[Random().nextInt(msgs.length)];
      }
    }
    setState(() {
      _messages = msgs;
      _featuredMessage = featured;
      _isLoading = false;
    });
  }

  Future<void> _togglePin(VaultMessageModel msg) async {
    await SupportVaultStorage.togglePin(msg.id);
    await _loadVault();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'صندوق الدعم 📬',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث واستحضار رسالة',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accentLight),
            onPressed: _loadVault,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              const Color(0xFF131127),
              AppColors.background,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
            : RefreshIndicator(
                onRefresh: _loadVault,
                color: AppColors.primaryLight,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // بطاقة رسالة أمسك بيها
                    if (_featuredMessage != null) ...[
                      _buildFeaturedCard(_featuredMessage!),
                      const SizedBox(height: 24),
                    ],

                    // عنوان القائمة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'رسائل دافية وصلتلك (${_messages.length})',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'تظل معك دائماً 🤍',
                            style: GoogleFonts.cairo(
                              color: AppColors.accentLight,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_messages.isEmpty)
                      _buildEmptyState()
                    else
                      ..._messages.map((m) => _buildMessageCard(m)),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFeaturedCard(VaultMessageModel msg) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B2D71).withValues(alpha: 0.8),
            const Color(0xFF1E163B).withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'رسالة أمسك بيها اليوم ✨',
                style: GoogleFonts.cairo(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'من: ${msg.fromAlias}',
                style: GoogleFonts.cairo(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '« ${msg.text} »',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatDate(msg.date),
              style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildMessageCard(VaultMessageModel msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        color: msg.isPinned ? Colors.amber.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.4),
                  child: Text(
                    msg.fromAlias.characters.first,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  msg.fromAlias,
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    msg.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: msg.isPinned ? Colors.amberAccent : Colors.white30,
                    size: 18,
                  ),
                  tooltip: msg.isPinned ? 'إلغاء التثبيت' : 'تثبيت كرسالة يومية',
                  onPressed: () => _togglePin(msg),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatDate(msg.date),
                style: GoogleFonts.cairo(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'صندوقك لسه في البداية',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'كل رسالة حب ودعم هتوصلك من الرومات هتتحفظ هنا للأبد عشان ترجعلها في أي وقت صعب.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day}';
  }
}
