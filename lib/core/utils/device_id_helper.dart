import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceIdHelper {
  static const _key = 'device_fingerprint_id'; // security-ignore-line

  /// Get a unique key for the viewer (user.id if logged in, otherwise persistent device ID)
  static Future<String> getViewerKey() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return session.user.id;
    }

    final prefs = await SharedPreferences.getInstance(); // security-ignore-line
    String? deviceId = prefs.getString(_key);
    
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_key, deviceId);
    }
    
    return deviceId;
  }
}
