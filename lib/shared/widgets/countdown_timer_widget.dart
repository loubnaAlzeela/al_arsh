import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';

/// Live countdown timer to voting close or announcement
class CountdownTimerWidget extends ConsumerStatefulWidget {
  final DateTime targetTime;
  final String label;
  final Color color;

  const CountdownTimerWidget({
    super.key,
    required this.targetTime,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  ConsumerState<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends ConsumerState<CountdownTimerWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.targetTime.isAfter(now)
          ? widget.targetTime.difference(now)
          : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appL10nProvider);
    final isArabic = s.isArabic;

    if (_remaining == Duration.zero) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          s.votingClosed,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    final days    = _remaining.inDays;
    final hours   = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    final dayLabel    = isArabic ? 'يوم'    : 'd';
    final hourLabel   = isArabic ? 'ساعة'   : 'h';
    final minLabel    = isArabic ? 'دقيقة'  : 'm';
    final secLabel    = isArabic ? 'ثانية'  : 's';

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (days > 0) ...[
            _TimeUnit(value: _pad(days), label: dayLabel, color: widget.color),
            _Separator(color: widget.color),
          ],
          _TimeUnit(value: _pad(hours),   label: hourLabel, color: widget.color),
          _Separator(color: widget.color),
          _TimeUnit(value: _pad(minutes), label: minLabel,  color: widget.color),
          _Separator(color: widget.color),
          _TimeUnit(value: _pad(seconds), label: secLabel,  color: widget.color),
        ],
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _TimeUnit({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      Text(
        label,
        style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 9),
      ),
    ],
  );
}

class _Separator extends StatelessWidget {
  final Color color;
  const _Separator({required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(':', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
  );
}
