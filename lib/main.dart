import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/secure_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Setup Arabic locale for timeago
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // Enable edge-to-edge mode to fix status bar overlapping on some Android devices
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
      // Store the session + PKCE verifier in the platform keystore/keychain
      // instead of plain (unencrypted) SharedPreferences.
      localStorage: SecureLocalStorage(
        persistSessionKey: 'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token',
      ),
      pkceAsyncStorage: SecureGotrueAsyncStorage(),
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // Initialize SharedPreferences (non-sensitive app state only — auth/session
  // data is stored separately via SecureLocalStorage above).
  final prefs = await SharedPreferences.getInstance(); // security-ignore-line

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AlArshApp(),
    ),
  );
}

/// Global Supabase client shortcut
final supabase = Supabase.instance.client;
