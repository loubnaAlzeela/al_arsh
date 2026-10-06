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
            final event = GiftAnimationEvent(
              emoji: payload['emoji'] as String? ?? '🎁',
              giftName: payload['giftName'] as String? ?? '',
              senderName: payload['senderName'] as String? ?? '',
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
          // Floating gift emojis rising from the bottom
          for (final event in _floaters)
            _FloatingGift(
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

class _FloatingGift extends StatefulWidget {
  final GiftAnimationEvent event;
  final VoidCallback onComplete;
  const _FloatingGift({super.key, required this.event, required this.onComplete});

  @override
  State<_FloatingGift> createState() => _FloatingGiftState();
}

class _FloatingGiftState extends State<_FloatingGift> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _startX;
  late final double _swayAmplitude;
  late final double _swaySeed;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _startX = 0.15 + rand.nextDouble() * 0.5; // 15%–65% of width
    _swayAmplitude = 18 + rand.nextDouble() * 22;
    _swaySeed = rand.nextDouble() * pi * 2;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Vertical travel: from ~72% height up to ~10% height.
        final top = size.height * (0.72 - 0.62 * Curves.easeOut.transform(t));

        // Gentle side-to-side sway as it rises.
        final sway = sin(_swaySeed + t * pi * 2.2) * _swayAmplitude;
        final left = size.width * _startX + sway;

        // Bounce-in scale for the first 25%, settle after.
        final scale = t < 0.25
            ? Curves.elasticOut.transform(t / 0.25).clamp(0.0, 1.3)
            : 1.0 + (0.08 * sin(t * pi * 6)); // subtle pulse while rising

        // Fade out over the final 30%.
        final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3).clamp(0.0, 1.0);

        return Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale.toDouble(),
              child: Transform.rotate(
                angle: sin(_swaySeed + t * pi * 2.2) * 0.12,
                child: Text(widget.event.emoji, style: const TextStyle(fontSize: 46)),
              ),
            ),
          ),
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
