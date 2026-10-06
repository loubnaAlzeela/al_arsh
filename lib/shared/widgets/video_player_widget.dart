import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';

/// Global tracker: only one video plays at a time.
/// The currently-playing widget registers itself here; any other widget
/// that tries to play first calls [ActiveVideoKey.pause] on the previous one.
class ActiveVideoKey {
  static _VideoPlayerWidgetState? _current;

  static void register(_VideoPlayerWidgetState state) {
    if (_current != null && _current != state) {
      _current!._pauseBySystem();
    }
    _current = state;
  }

  static void unregister(_VideoPlayerWidgetState state) {
    if (_current == state) _current = null;
  }
}

/// A video player widget that lazily initializes the controller
/// only when the widget is visible on screen (≥ 30% visible).
///
/// Auto-retries while Cloudflare Stream processes the video (up to 6 times,
/// every 10 seconds = 60 s total). After that shows a manual retry button.
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

final ValueNotifier<bool> globalIsMuted = ValueNotifier<bool>(false);

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;      // permanent error — show manual retry
  bool _isLoading = false;
  bool _isProcessing = false;  // Cloudflare still processing — auto retry
  bool _didStartInit = false;
  bool _wasPlayingBeforePause = false;  // لإعادة التشغيل عند العودة للتطبيق

  int _retryCount = 0;
  static const _maxAutoRetries = 6;    // 6 × 10 s = 60 s
  static const _retryDelay = Duration(seconds: 10);

  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    globalIsMuted.addListener(_onGlobalMuteChanged);
  }

  void _onGlobalMuteChanged() {
    if (!mounted) return;
    _controller?.setVolume(globalIsMuted.value ? 0.0 : 1.0);
    setState(() {});
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final ctrl = _controller;
    if (ctrl == null) return;
    if (ctrl.value.hasError && !_hasError) {
      debugPrint('[VideoPlayer] Runtime error: ${ctrl.value.errorDescription}');
      _handleFailure(isPermanent: true);
    }
  }

  /// مراقبة حالة دورة حياة التطبيق
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // التطبيق ذهب للخلفية — نحفظ الحالة ونوقف
      _wasPlayingBeforePause = _controller?.value.isPlaying ?? false;
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed) {
      // عاد التطبيق للواجهة — أعد التشغيل إن كان يشتغل قبل
      if (_wasPlayingBeforePause && _isInitialized) {
        ActiveVideoKey.register(this);
        _controller?.play();
      }
    }
  }

  Future<void> _initPlayer() async {
    if (_didStartInit) return;
    _didStartInit = true;
    _retryTimer?.cancel();

    if (!mounted) return;
    setState(() { _isLoading = true; _isProcessing = false; });

    VideoPlayerController? ctrl;
    try {
      ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: const {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36'
              ' (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        },
        // mixWithOthers: false → only one video plays at a time (OS-level)
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      await ctrl.initialize().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw PlatformException(
          code: 'TIMEOUT',
          message: 'Video initialization timed out.',
        ),
      );

      if (!mounted) { ctrl.dispose(); return; }

      if (ctrl.value.hasError) {
        ctrl.dispose();
        _handleFailure(isPermanent: false);
        return;
      }

      ctrl.setLooping(true);
      ctrl.setVolume(globalIsMuted.value ? 0.0 : 1.0);
      ctrl.addListener(_onControllerUpdate);

      setState(() {
        _controller = ctrl;
        _isInitialized = true;
        _isLoading = false;
        _isProcessing = false;
        _retryCount = 0;
      });
      // Pause any other playing video before starting this one
      ActiveVideoKey.register(this);
      ctrl.play();
    } on PlatformException catch (e) {
      debugPrint('[VideoPlayer] PlatformException ($e)');
      ctrl?.dispose();
      // 404 / network error → likely Cloudflare still processing
      _handleFailure(isPermanent: false);
    } catch (e) {
      debugPrint('[VideoPlayer] Error: $e');
      ctrl?.dispose();
      _handleFailure(isPermanent: false);
    }
  }

  /// Decides whether to auto-retry or show a permanent error.
  void _handleFailure({required bool isPermanent}) {
    if (!mounted) return;

    if (!isPermanent && _retryCount < _maxAutoRetries) {
      // Auto-retry: Cloudflare Stream may still be processing
      _retryCount++;
      debugPrint('[VideoPlayer] Auto-retry $_retryCount/$_maxAutoRetries in ${_retryDelay.inSeconds}s');
      setState(() {
        _isLoading = false;
        _isProcessing = true;
        _hasError = false;
        _didStartInit = false;
      });
      _retryTimer = Timer(_retryDelay, () {
        if (mounted) _initPlayer();
      });
    } else {
      // Give up — show manual retry button
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isProcessing = false;
      });
    }
  }

  void _manualRetry() {
    _retryTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    setState(() {
      _controller = null;
      _hasError = false;
      _isProcessing = false;
      _didStartInit = false;
      _isLoading = false;
      _isInitialized = false;
      _retryCount = 0;
    });
    _initPlayer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    ActiveVideoKey.unregister(this);
    super.dispose();
  }

  /// Called by [ActiveVideoKey] when another video starts playing.
  void _pauseBySystem() {
    _controller?.pause();
  }

  void _togglePlay() {
    final ctrl = _controller;
    if (ctrl == null || !_isInitialized) return;
    ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
  }



  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('vp_${widget.videoUrl.hashCode}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        // Only auto-play when the video is at least 80% visible
        // to avoid two videos playing at the same time while scrolling.
        if (info.visibleFraction >= 0.8) {
          if (!_didStartInit && !_isProcessing && !_hasError) _initPlayer();
          if (_isInitialized) {
            ActiveVideoKey.register(this);
            _controller?.play();
          }
        } else {
          // Pause as soon as it leaves the main focus area
          if (_isInitialized) _controller?.pause();
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // ── Processing / Auto-retry state ─────────────────────────────────────
    if (_isProcessing) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _thumbnail(),
          Container(color: Colors.black.withValues(alpha: 0.6)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28, height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'جاري تجهيز الفيديو...\n(محاولة $_retryCount من $_maxAutoRetries)',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Permanent error state ──────────────────────────────────────────────
    if (_hasError) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _thumbnail(),
          Container(color: Colors.black.withValues(alpha: 0.6)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_outlined,
                    color: Colors.white54, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'تعذّر تشغيل الفيديو',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _manualRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: const Text('إعادة المحاولة',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Loading ────────────────────────────────────────────────────────────
    if (!_isInitialized || _controller == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _thumbnail(),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
        ],
      );
    }

    // ── Playing ───────────────────────────────────────────────────────────
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller!,
            builder: (_, value, __) {
              if (value.isPlaying) return const SizedBox.shrink();
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 44),
                ),
              );
            },
          ),
          // Logo Overlay Watermark
          PositionedDirectional(
            top: 24,
            start: 16,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/z_logo.png',
                width: 40,
                height: 40,
                color: Colors.white.withValues(alpha: 0.7),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _thumbnail() {
    if (widget.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.black),
        errorWidget: (_, __, ___) => Container(color: Colors.black),
      );
    }
    return Container(color: Colors.black);
  }
}
