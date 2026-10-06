import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../main.dart';

/// One gift-sent event broadcast over Supabase Realtime.
class GiftAnimationEvent {
  final String id;
  final String emoji;
  final String giftName;
  final String senderName;

  GiftAnimationEvent({
    required this.emoji,
    required this.giftName,
    required this.senderName,
  }) : id = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
}

/// Broadcasts a gift-sent event to everyone currently viewing [postId],
/// so their [GiftAnimationLayer] plays the TikTok-style animation live.
Future<void> broadcastGiftAnimation({
  required String postId,
  required String emoji,
  required String giftName,
  required String senderName,
}) async {
  try {
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']!;
    final accessToken = supabase.auth.currentSession?.accessToken ?? anonKey;
    final url = Uri.parse('${dotenv.env['SUPABASE_URL']}/realtime/v1/api/broadcast');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'messages': [
          {
            'topic': 'gift-anim-$postId',
            'event': 'gift',
            'payload': {
              'emoji': emoji,
              'giftName': giftName,
              'senderName': senderName,
            },
            'private': false,
          },
        ],
      }),
    );
    debugPrint('[gift-anim] broadcast -> ${response.statusCode} ${response.body}');
  } catch (e) {
    debugPrint('[gift-anim] broadcast FAILED: $e');
    // Animation is cosmetic — never let a broadcast failure affect the gift flow.
  }
}

/// Full-screen overlay that listens for gift events on [postId] and plays
/// a TikTok-style animation (floating emoji + a sliding notification banner)
/// for every viewer currently watching that post.
class GiftAnimationLayer extends ConsumerStatefulWidget {
  final String postId;
  const GiftAnimationLayer({super.key, required this.postId});

  @override
  ConsumerState<GiftAnimationLayer> createState() => _GiftAnimationLayerState();
}

class _GiftAnimationLayerState extends ConsumerState<GiftAnimationLayer> {
  final List<GiftAnimationEvent> _floaters = [];
  final List<GiftAnimationEvent> _banners = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    debugPrint('[gift-anim] subscribing to gift-anim-${widget.postId}');
    _channel = supabase
        .channel('gift-anim-${widget.postId}')
        .onBroadcast(
          event: 'gift',
          callback: (payload) {
            debugPrint('[gift-anim] received on gift-anim-${widget.postId}: $payload');
            if (!mounted) return;
            // Phoenix wraps the actual data one level deeper:
            // {event: 'gift', type: 'broadcast', payload: {emoji: ..., ...}}
            final data = (payload['payload'] as Map?)?.cast<String, dynamic>() ?? payload;
            final event = GiftAnimationEvent(
              emoji: data['emoji'] as String? ?? '🎁',
              giftName: data['giftName'] as String? ?? '',
              senderName: data['senderName'] as String? ?? '',
            );
            _addEvent(event);
          },
        )
        .subscribe((status, error) {
          debugPrint('[gift-anim] subscribe status for ${widget.postId}: $status, error: $error');
        });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _addEvent(GiftAnimationEvent event) {
    setState(() {
      _floaters.add(event);
      _banners.add(event);
      if (_banners.length > 3) _banners.removeAt(0);
    });

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _banners.removeWhere((e) => e.id == event.id));
    });
  }

  void _removeFloater(String id) {
    if (!mounted) return;
    setState(() => _floaters.removeWhere((e) => e.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Liquid-fill gift splash rising from the bottom
          for (final event in _floaters)
            _GiftSplash(
              key: ValueKey(event.id),
              event: event,
              onComplete: () => _removeFloater(event.id),
            ),

          // Sliding notification banners, stacked above the caption area
          Positioned(
            left: 16,
            right: 90,
            bottom: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final event in _banners)
                  _GiftBanner(key: ValueKey(event.id), event: event),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps a gift's emoji to a themed liquid color for its splash effect.
Color _colorForEmoji(String emoji) {
  switch (emoji) {
    case '☕':
      return const Color(0xFF8B5A2B); // coffee brown
    case '💐':
      return const Color(0xFFE85D9C); // flower pink
    case '🎤':
      return const Color(0xFFFFC94A); // gold
    case '🏎️':
      return const Color(0xFFE63946); // racing red
    default:
      return AppColors.primary;
  }
}

/// Paints an animated liquid wave filling up from the bottom of the screen.
class _WavePainter extends CustomPainter {
  final double fillHeight; // fraction of canvas height, 0..1
  final double wavePhase;
  final Color color;

  _WavePainter({required this.fillHeight, required this.wavePhase, required this.color});

  Path _wavePath(Size size, double baseY, double amplitude, double phaseOffset) {
    const waveLength = 180.0;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseY);
    for (double x = 0; x <= size.width; x += 6) {
      final y = baseY + sin((x / waveLength * 2 * pi) + wavePhase + phaseOffset) * amplitude;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  Path _crestLine(Size size, double baseY, double amplitude, double phaseOffset) {
    final path = Path();
    for (double x = 0; x <= size.width; x += 6) {
      final y = baseY + sin((x / 180.0 * 2 * pi) + wavePhase + phaseOffset) * amplitude;
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (fillHeight <= 0) return;
    final baseY = size.height * (1 - fillHeight);

    // One solid, fully-saturated body fill so the gift's color reads clearly
    canvas.drawPath(
      _wavePath(size, baseY, 10, 0),
      Paint()..color = color.withValues(alpha: 0.92),
    );
    // A thin bright stroke right at the crest for a liquid shine — not a
    // second fill, or it washes the body color out into a muddy tint.
    canvas.drawPath(
      _crestLine(size, baseY, 10, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.fillHeight != fillHeight || oldDelegate.wavePhase != wavePhase;
}

/// TikTok-style splash: a colored liquid rises and fills the bottom half of
/// the screen while the gift emoji floats and bounces on top of it, themed
/// per gift type (e.g. coffee-brown liquid for the coffee gift).
class _GiftSplash extends StatefulWidget {
  final GiftAnimationEvent event;
  final VoidCallback onComplete;
  const _GiftSplash({super.key, required this.event, required this.onComplete});

  @override
  State<_GiftSplash> createState() => _GiftSplashState();
}

class _GiftSplashState extends State<_GiftSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color = _colorForEmoji(widget.event.emoji);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Fill: rises 0%-30%, holds 30%-70%, recedes 70%-100%.
        double fillProgress;
        if (t < 0.3) {
          fillProgress = Curves.easeOutBack.transform(t / 0.3).clamp(0.0, 1.0);
        } else if (t < 0.7) {
          fillProgress = 1.0;
        } else {
          fillProgress = (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
        }
        final fillHeight = 0.65 * fillProgress;

        // Emoji: bounces in, settles, shrinks away with the liquid. Kept in
        // a fixed safe band (18%-46% up from the bottom) so it always clears
        // the vote/gift/action buttons and bottom nav bar.
        final emojiBottom = size.height * (0.18 + 0.28 * fillProgress);
        final emojiScale = t < 0.25
            ? Curves.elasticOut.transform(t / 0.25).clamp(0.0, 1.3)
            : (t < 0.75 ? 1.0 + 0.05 * sin(t * pi * 8) : (1.0 - (t - 0.75) / 0.25 * 0.3).clamp(0.7, 1.0));
        final emojiOpacity = t < 0.85 ? 1.0 : (1.0 - (t - 0.85) / 0.15).clamp(0.0, 1.0);

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WavePainter(
                  fillHeight: fillHeight,
                  wavePhase: t * pi * 6,
                  color: color,
                ),
              ),
            ),
            Positioned(
              bottom: emojiBottom,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: emojiOpacity,
                child: Transform.scale(
                  scale: emojiScale.toDouble(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.event.emoji, style: const TextStyle(fontSize: 90)),
                      const SizedBox(height: 6),
                      Text(
                        widget.event.giftName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          shadows: [
                            Shadow(color: color, blurRadius: 14),
                            const Shadow(color: Colors.black, blurRadius: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GiftBanner extends StatefulWidget {
  final GiftAnimationEvent event;
  const _GiftBanner({super.key, required this.event});

  @override
  State<_GiftBanner> createState() => _GiftBannerState();
}

class _GiftBannerState extends State<_GiftBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.primaryDark.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.event.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${widget.event.senderName} ➜ ${widget.event.giftName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
