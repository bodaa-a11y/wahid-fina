// 👤 Player Avatar Widget
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/player_model.dart';

// قائمة الألوان للـ Avatars
const List<Color> _avatarColors = [
  Color(0xFF7B5EA7),
  Color(0xFF5EA78B),
  Color(0xFFA75E5E),
  Color(0xFF5E7BA7),
  Color(0xFFA78B5E),
  Color(0xFF8B5EA7),
];

Color _getAvatarColor(String name) {
  final index = name.codeUnits.fold(0, (a, b) => a + b) % _avatarColors.length;
  return _avatarColors[index];
}

String _getInitials(String name) {
  if (name.isEmpty) return '؟';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
  return name[0];
}

class PlayerAvatar extends StatelessWidget {
  final PlayerModel player;
  final double size;
  final bool showName;
  final bool isHighlighted;
  final bool isRevealed;
  final bool showRole;

  const PlayerAvatar({
    super.key,
    required this.player,
    this.size = 56,
    this.showName = true,
    this.isHighlighted = false,
    this.isRevealed = false,
    this.showRole = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getAvatarColor(player.name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
                border: Border.all(
                  color: isHighlighted
                      ? AppColors.warm
                      : isRevealed && player.role == PlayerRole.struggling
                          ? AppColors.struggling
                          : color,
                  width: isHighlighted ? 3 : 2,
                ),
                boxShadow: isHighlighted
                    ? [BoxShadow(color: AppColors.warm.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
                    : [],
              ),
              child: Center(
                child: Text(
                  _getInitials(player.name),
                  style: GoogleFonts.cairo(
                    color: color,
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // بادج الدور لو مكشوف
            if (isRevealed && showRole)
              Container(
                width: size * 0.35,
                height: size * 0.35,
                decoration: BoxDecoration(
                  color: player.role == PlayerRole.struggling
                      ? AppColors.struggling
                      : AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    player.role == PlayerRole.struggling ? '💙' : '✨',
                    style: TextStyle(fontSize: size * 0.18),
                  ),
                ),
              ),
          ],
        ),
        if (showName) ...[
          const SizedBox(height: 6),
          Text(
            player.name,
            style: GoogleFonts.cairo(
              color: isHighlighted ? AppColors.warm : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isRevealed && showRole)
            Text(
              player.role == PlayerRole.struggling ? 'واحد فينا 💙' : 'صاحب 🤍',
              style: GoogleFonts.cairo(
                color: player.role == PlayerRole.struggling
                    ? AppColors.struggling
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ],
    );
  }
}

// شريط اللاعبين الأفقي
class PlayersBar extends StatelessWidget {
  final List<PlayerModel> players;
  final String? highlightPlayerId;
  final bool showRoles;

  const PlayersBar({
    super.key,
    required this.players,
    this.highlightPlayerId,
    this.showRoles = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((player) {
        return PlayerAvatar(
          player: player,
          size: 44,
          isHighlighted: player.id == highlightPlayerId,
          isRevealed: showRoles,
          showRole: showRoles,
        );
      }).toList(),
    );
  }
}
