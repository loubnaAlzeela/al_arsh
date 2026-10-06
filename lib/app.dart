import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/locale_provider.dart';

final hideGlobalLogoProvider = StateProvider<bool>((ref) => false);

class AlArshApp extends ConsumerWidget {
  const AlArshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';

    return MaterialApp.router(
      title: 'ZUVOXA',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final topPadding = MediaQuery.of(context).padding.top;
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            children: [
              child!,
              // ── Z Logo top-corner ──
              Consumer(
                builder: (context, ref, child) {
                  final hideLogo = ref.watch(hideGlobalLogoProvider);
                  if (hideLogo) return const SizedBox.shrink();

                  return PositionedDirectional(
                    top: topPadding + 8,
                    start: 16,
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/z_logo.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

