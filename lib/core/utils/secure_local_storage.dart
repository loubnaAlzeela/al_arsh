import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

/// Persists the Supabase auth session in the platform keystore/keychain
/// instead of plain SharedPreferences.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({required this.persistSessionKey});

  final String persistSessionKey;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await _secureStorage.containsKey(key: persistSessionKey);
  }

  @override
  Future<String?> accessToken() {
    return _secureStorage.read(key: persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() {
    return _secureStorage.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _secureStorage.write(key: persistSessionKey, value: persistSessionString);
  }
}

/// Persists the PKCE flow's code verifier in secure storage instead of
/// plain SharedPreferences.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) {
    return _secureStorage.read(key: key);
  }

  @override
  Future<void> removeItem({required String key}) {
    return _secureStorage.delete(key: key);
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return _secureStorage.write(key: key, value: value);
  }
}
