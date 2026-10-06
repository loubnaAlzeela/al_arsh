import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';

/// Displays a color-coded level badge (translated label + colored chip)
class LevelBadgeWidget extends ConsumerWidget {
  final String level;
  final bool showLabel;
  final double fontSize;

  const LevelBadgeWidget({
    super.key,
    required this.level,
    this.showLabel = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appL10nProvider);
    final color = AppColors.getLevelColor(level);
    final displayLevel = s.translateLevel(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              displayLevel,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tier-colored border avatar
class TierAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String tier;
  final double radius;

  const TierAvatarWidget({
    super.key,
    this.avatarUrl,
    required this.tier,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.getTierColor(tier);
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [tierColor, tierColor.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Icon(Icons.person, size: radius, color: AppColors.textHint)
            : null,
      ),
    );
  }
}
