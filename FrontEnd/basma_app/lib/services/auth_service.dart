import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _tokenKey = 'token';
  static const _cachedUserKey = 'current_user';

  /// يرجع:
  /// {
  ///   id: 3,
  ///   backend_type: 3,     // citizen=3, initiative=2
  ///   citizen_id: 3,
  ///   initiative_id: null,
  ///   type: "citizen"
  /// }
  static Future<Map<String, dynamic>?> currentUser() async {
    final sp = await SharedPreferences.getInstance();

    // جرّب قراءة الكاش
    final cached = sp.getString(_cachedUserKey);
    if (cached != null) {
      try {
        return jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }

    // اقرأ الـ JWT
    final token = sp.getString(_tokenKey);
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final data = jsonDecode(payload);

      final sub = data["sub"];
      final backendType = data["user_type"]; // 3 citizen, 2 initiative

      if (sub == null || backendType == null) return null;

      // استخراج الهوية
      final citizenId = data["citizen_id"];
      final initiativeId = data["initiative_id"];

      // تحويل النوع لنص
      String typeStr;
      if (backendType == 3) {
        typeStr = "citizen";
      } else if (backendType == 2) {
        typeStr = "initiative";
      } else {
        typeStr = "unknown";
      }

      final user = {
        "id": int.tryParse(sub.toString()) ?? sub,
        "backend_type": backendType, // <-- مهم جداً
        "citizen_id": citizenId,
        "initiative_id": initiativeId,
        "type": typeStr,
      };

      // خزن في الكاش
      await sp.setString(_cachedUserKey, jsonEncode(user));

      return user;
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
    await sp.remove(_cachedUserKey);
  }
}
