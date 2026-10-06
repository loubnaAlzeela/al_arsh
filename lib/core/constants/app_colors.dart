import 'package:flutter/material.dart';

/// Al Arsh Design System — Color Tokens
abstract class AppColors {
  // ── Brand ─────────────────────────────────
  static const Color primary   = Color(0xFFC9A84C); // Gold
  static const Color primaryDark = Color(0xFF9E7A30);
  static const Color primaryLight = Color(0xFFE8C87A);

  // ── Backgrounds ───────────────────────────
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface    = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF252525);
  static const Color card       = Color(0xFF1E1E1E);

  // ── Text ──────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textHint      = Color(0xFF555555);

  // ── Accent / Status ───────────────────────
  static const Color accent  = Color(0xFFE63946); // Red — danger / voting closed
  static const Color success = Color(0xFF2ECC71); // Green — winner
  static const Color warning = Color(0xFFF39C12); // Orange — caution
  static const Color info    = Color(0xFF3498DB);

  // ── Tier Colors ───────────────────────────
  static const Color tierBlue = Color(0xFF4A90D9);
  static const Color tierGold = Color(0xFFC9A84C);
  static const Color tierRed  = Color(0xFFE63946);

  // ── Live Streaming ────────────────────────────────────────────────────────
  static const Color liveRed  = Color(0xFFCC0022); // Live badge / CTA

  // ── UI Utility ────────────────────────────────────────────────────────────
  static const Color divider   = Color(0xFF2A2A2A);
  static const Color shimmer1  = Color(0xFF1A1A1A);
  static const Color shimmer2  = Color(0xFF2A2A2A);
  static const Color overlay   = Color(0x80000000);
  static const Color inputFill = Color(0xFF1E1E1E);
  static const Color border    = Color(0xFF333333);

  // ── Level Colors ──────────────────────────
  static const Map<String, Color> levelColors = {
    'مجهول'  : Color(0xFF555555),
    'موهبة'  : Color(0xFF4A90D9),
    'صاعد'   : Color(0xFFC9A84C),
    'نجم'    : Color(0xFFE8C87A),
    'ملك'    : Color(0xFFE63946),
    'أسطورة' : Color(0xFFFF6B35),
  };

  /// Get tier color from tier string
  static Color getTierColor(String tier) {
    switch (tier) {
      case 'blue': return tierBlue;
      case 'gold': return tierGold;
      case 'red':  return tierRed;
      default:     return tierBlue;
    }
  }

  /// Get level color from level string
  static Color getLevelColor(String level) => levelColors[level] ?? textSecondary;
}
