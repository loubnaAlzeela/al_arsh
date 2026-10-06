import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

import '../../features/auth/presentation/username_setup_screen.dart';
import '../../features/feed/presentation/home_feed_screen.dart';
import '../../features/upload/presentation/upload_screen.dart';
import '../../features/rankings/presentation/rankings_screen.dart';
import '../../features/winners/presentation/winners_hall_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/admin/presentation/admin_panel_screen.dart';
import '../../features/gifts/presentation/wallet_screen.dart';
import '../../features/live/presentation/live_list_screen.dart';
import '../../features/live/presentation/host_live_screen.dart';
import '../../features/live/presentation/watch_live_screen.dart';
import '../../features/messaging/presentation/conversations_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/main_shell.dart';
import '../l10n/app_l10n.dart';

part 'app_router.g.dart';

// ── Route name constants ──────────────────────
abstract class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';

  static const usernameSetup = '/setup';
  static const shell         = '/home';
  static const feed          = '/home/feed';
  static const upload        = '/home/upload';
  static const rankings      = '/home/rankings';
  static const winners       = '/home/winners';
  static const profile       = '/home/profile';
  static const profileView   = '/profile/:userId';
  static const editProfile   = '/home/profile/edit';
  static const wallet        = '/home/wallet';
  static const live          = '/home/live';
  static const messages      = '/home/messages';
  static const chat          = '/chat/:conversationId';
  static const hostLive      = '/live/host/:streamId';
  static const watchLive     = '/live/:streamId';
  static const notifications = '/notifications';
  static const admin         = '/admin';
}

/// A [ChangeNotifier] that notifies GoRouter to re-run its redirect
/// whenever the Supabase auth state changes.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    // Listen to auth state stream and notify GoRouter
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

// ── Routes that require authentication ───────────────────────────────────
abstract class _ProtectedRoutes {
  static const routes = [
    AppRoutes.upload,
    AppRoutes.profile,
    AppRoutes.editProfile,
    AppRoutes.wallet,
    AppRoutes.messages,
    AppRoutes.hostLive,
    AppRoutes.usernameSetup,
  ];

  static bool isProtected(String location) {
    return routes.any((r) => location.startsWith(r.replaceAll(':streamId', '').replaceAll(':conversationId', '').replaceAll(':userId', '')));
  }
}

@riverpod
GoRouter appRouter(Ref ref) {
  // Create the notifier once — it listens internally and pings GoRouter
  final notifier = _AuthNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthenticated = session != null;
      final location = state.matchedLocation;

      // Splash always passes through — it handles navigation itself
      if (location == AppRoutes.splash) return null;

      // If authenticated and trying to view login → go to feed
      if (isAuthenticated && location == AppRoutes.login) {
        return AppRoutes.feed;
      }

      // If NOT authenticated and trying to access a protected route → login
      if (!isAuthenticated && _ProtectedRoutes.isProtected(location)) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (ctx, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.usernameSetup,
        name: 'usernameSetup',
        builder: (ctx, state) => const UsernameSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (ctx, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        name: 'admin',
        builder: (ctx, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileView,
        name: 'profileView',
        builder: (ctx, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
      ),
      // ── Shell (bottom nav) ─────────────────
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.feed,
            name: 'feed',
            builder: (ctx, state) => const HomeFeedScreen(),
          ),
          GoRoute(
            path: AppRoutes.upload,
            name: 'upload',
            builder: (ctx, state) => const UploadScreen(),
          ),
          GoRoute(
            path: AppRoutes.rankings,
            name: 'rankings',
            builder: (ctx, state) => const RankingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.winners,
            name: 'winners',
            builder: (ctx, state) => const WinnersHallScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (ctx, state) {
              // Own profile — userId from auth
              return const ProfileScreen(userId: null);
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: 'editProfile',
                builder: (ctx, state) => const EditProfileScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.wallet,
            name: 'wallet',
            builder: (ctx, state) => const WalletScreen(),
          ),
          GoRoute(
            path: AppRoutes.live,
            name: 'live',
            builder: (ctx, state) => const LiveListScreen(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            name: 'messages',
            builder: (ctx, state) => const ConversationsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.hostLive,
        name: 'hostLive',
        builder: (ctx, state) {
          final streamId = state.pathParameters['streamId']!;
          return HostLiveScreen(streamId: streamId);
        },
      ),
      GoRoute(
        path: AppRoutes.watchLive,
        name: 'watchLive',
        builder: (ctx, state) {
          final streamId = state.pathParameters['streamId']!;
          return WatchLiveScreen(streamId: streamId);
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (ctx, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            conversationId: conversationId,
            otherUserDisplayName: extra?['displayName'] as String? ?? ref.read(appL10nProvider).conversationFallback,
            otherUserAvatarUrl: extra?['avatarUrl'] as String?,
          );
        },
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Text(
          'الصفحة غير موجودة\n${state.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
