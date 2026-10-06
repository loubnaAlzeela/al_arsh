import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../main.dart';
import '../../../app.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Seamless continuation of the native splash — no visible cut between
/// the OS-drawn splash and this widget.
///
///  Native splash    → [Logo centred, static]
///  Flutter frame 1  → pixel-identical logo, still centred.
///                      Native splash is removed HERE, not automatically.
///  Phase 1          → short hold, still centred (matches what the user
///                      already saw — nothing "jumps").
///  Phase 2          → logo slides left, text wipes in left → right
///                      beside it, like a curtain opening.
class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _phase2Controller;
  late Animation<double> _logoSlide; // 0 → 1  (logo moves left & shrinks)
  late Animation<double> _textReveal; // 0 → 1  (clip reveal left → right)

  bool _phase2Started = false;
  bool _bootstrapped = false;

  static const _logoAsset = 'assets/images/splash_logo.png';
  static const _textAsset = 'assets/images/splash_text.png';

  // ضبط يدوي دقيق لموقع اللوغو عمودياً — إن ظهر أعلى/أدنى من مكانه في
  // native splash بعد التجربة على جهاز حقيقي، عدّل هذه القيمة (بالبيكسل).
  static const _logoVerticalNudge = 25.0;

  @override
  void initState() {
    super.initState();

    // إخفاء شعار التطبيق (الزاوية العلوية) أثناء شاشة البداية
    Future.microtask(() {
      if (mounted) ref.read(hideGlobalLogoProvider.notifier).state = true;
    });

    _phase2Controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _logoSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _phase2Controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _textReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _phase2Controller,
        curve: const Interval(0.15, 0.90, curve: Curves.easeInOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only run this bootstrap sequence once.
    if (!_bootstrapped) {
      _bootstrapped = true;
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    // FIX #2: fully decode both images BEFORE anything is shown or
    // animated. Without this, the text image was still being decoded
    // while the reveal animation ran, so it appeared instantly instead
    // of wiping in — this is why the text looked like it had "no motion".
    await Future.wait([
      precacheImage(const AssetImage(_logoAsset), context),
      precacheImage(const AssetImage(_textAsset), context),
    ]);
    if (!mounted) return;

    // FIX #1: only remove the native splash once we're certain our own
    // first frame — logo centred, same size, same background — has
    // actually been painted. This is what eliminates the visible cut
    // between "native splash" and "our splash": from the user's eyes,
    // it's one continuous screen the whole time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 1: logo sits exactly where the native splash left it off.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Phase 2: slide logo left + reveal text.
    setState(() => _phase2Started = true);
    await _phase2Controller.forward();

    // Short pause then navigate.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    // إعادة إظهار شعار التطبيق لبقية الشاشات
    ref.read(hideGlobalLogoProvider.notifier).state = false;

    final session = supabase.auth.currentSession;
    if (session == null) {
      // المستخدم غير المسجل يذهب إلى الشاشة الرئيسية مباشرة
      context.go(AppRoutes.feed);
      return;
    }

    supabase
        .from('users')
        .select('id')
        .eq('id', session.user.id)
        .maybeSingle()
        .then((user) {
      if (!mounted) return;
      if (user == null) {
        context.go(AppRoutes.usernameSetup);
      } else {
        context.go(AppRoutes.feed);
      }
    }).catchError((_) {
      if (!mounted) return;
      // حتى عند الخطأ، نوجه إلى feed وليس login
      context.go(AppRoutes.feed);
    });
  }

  @override
  void dispose() {
    _phase2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // الحجم الأولي للوغو يجب أن يطابق تماماً حجمه في الـ native splash.
    // الحجم الدقيق المحسوب بواسطة flutter_native_splash بناءً على صورة بدقة 427 هو:
    // 427 / 4 = 106.75
    const initialLogoSize = 106.75;

    // الحجم النهائي للوغو بعد أن يصغر (مثلاً 20% من عرض الشاشة)
    final finalLogoSize = screenWidth * 0.20;

    final textWidth = screenWidth * 0.46;
    const spacing = 0.0; // no gap — text sits right beside logo

    // Combined row width (logo + gap + text) based on FINAL size
    final totalWidth = finalLogoSize + spacing + textWidth;

    // Distance the logo's center must travel to sit at the left of the centred row
    final logoOffset = (totalWidth / 2) - (finalLogoSize / 2);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      // بدون هذا، الـ body يُرسم أسفل شريط الحالة فقط، فيصبح مركز اللوغو
      // أوطأ قليلاً من مركزه الحقيقي في الشاشة (كما يظهر في native splash
      // الذي يتمركز على كامل ارتفاع الشاشة). extendBodyBehindAppBar يجعل
      // الـ body يشغل كامل الشاشة فيتطابق مركز اللوغو تماماً مع native splash.
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: const Color(0xFF0F0F11),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF0F0F11),
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      body: Center(
        // extendBodyBehindAppBar وحده لم يكفِ لمطابقة native splash تماماً —
        // لا يزال هناك انزياح صغير للأسفل، لذا نرفع اللوغو يدوياً بمقدار بسيط.
        // إن احتجت لضبط أدق، غيّر قيمة _logoVerticalNudge بالأسفل.
        child: Transform.translate(
          offset: const Offset(0, -_logoVerticalNudge),
          child: AnimatedBuilder(
            animation: _phase2Controller,
            builder: (context, _) {
              // How much the logo has moved left
              final dx = _phase2Started ? -logoOffset * _logoSlide.value : 0.0;

              // Current logo size shrinking from initial to final
              final currentLogoSize = _phase2Started
                  ? initialLogoSize -
                      ((initialLogoSize - finalLogoSize) * _logoSlide.value)
                  : initialLogoSize;

              return SizedBox(
                width: totalWidth,
                height:
                    initialLogoSize, // Need enough height for the larger initial logo
                child: Stack(
                  clipBehavior: Clip
                      .none, // Allow initial larger logo to overflow the final bounding box
                  alignment: Alignment.center,
                  children: [
                    // ── Logo (always fully visible, shrinks and slides left) ──
                    Positioned(
                      left: (totalWidth / 2 - currentLogoSize / 2) + dx,
                      child: Image.asset(
                        _logoAsset,
                        width: currentLogoSize,
                        height: currentLogoSize,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // ── Text: clip-reveal from left to right (no movement) ───
                    if (_phase2Started)
                      Positioned(
                        left: finalLogoSize + spacing,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _textReveal.value,
                            child: Image.asset(
                              _textAsset,
                              width: textWidth,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
