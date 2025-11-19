// lib/services/auth_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة مسؤولة عن التوثيق وقراءة بيانات المستخدم من JWT.
///
/// مثال على شكل الكاش داخل SharedPreferences:
/// {
///   "token": "jwt_token_here",
///   "user": {
///     "id": 3,
///     "backend_type": 3,
///     "citizen_id": 3,
///     "initiative_id": null,
///     "type": "citizen"
///   }
/// }
class AuthService {
  static const String _tokenKey = 'token';
  static const String _cachedUserKey = 'current_user';

  /// قراءة المستخدم الحالي من الـ JWT + الـ cache.
  ///
  /// ترجع:
  /// - أو null إذا لم يكن هناك توكن أو التوكن غير صالح
  static Future<Map<String, dynamic>?> currentUser() async {
    final sp = await SharedPreferences.getInstance();

    final token = sp.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      await sp.remove(_cachedUserKey);
      return null;
    }

    // ============== قراءة الكاش ==============
    final cachedStr = sp.getString(_cachedUserKey);
    if (cachedStr != null) {
      try {
        final cached = jsonDecode(cachedStr);

        if (cached is Map<String, dynamic>) {
          final cachedToken = cached["token"];
          final cachedUser = cached["user"];

          if (cachedToken == token && cachedUser is Map<String, dynamic>) {
            return Map<String, dynamic>.from(cachedUser);
          }
        }
      } catch (_) {
        // تجاهل أي خطأ
      }
    }

    // ============== فك التوكن ==============
    final user = _parseUserFromToken(token);
    if (user == null) {
      await sp.remove(_cachedUserKey);
      return null;
    }

    // ============== تخزين الكاش ==============
    final envelope = {"token": token, "user": user};

    await sp.setString(_cachedUserKey, jsonEncode(envelope));

    return user;
  }

  /// حذف التوكن + حذف الكاش.
  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
    await sp.remove(_cachedUserKey);
  }

  // ==========================================================================
  // Helper: Decode JWT
  // ==========================================================================

  /// يحلّل JWT ويستخرج معلومات المستخدم من الـ payload.
  ///
  /// يرجّع:
  /// - Map فيها بيانات المستخدم
  /// - أو null لو التوكن غير صالح
  static Map<String, dynamic>? _parseUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // payload هو الجزء الثاني
      final payload = parts[1];

      final normalized = base64Url.normalize(payload);
      final payloadJson = utf8.decode(base64Url.decode(normalized));

      final data = jsonDecode(payloadJson);
      if (data is! Map<String, dynamic>) return null;

      final sub = data['sub'];
      final backendType = data['user_type']; // رقم نوع المستخدم

      if (sub == null || backendType == null) return null;

      final citizenId = data['citizen_id'];
      final initiativeId = data['initiative_id'];

      // نوع المستخدم نصيًا
      final typeStr = switch (backendType) {
        3 => 'citizen',
        2 => 'initiative',
        _ => 'unknown',
      };

      return {
        'id': int.tryParse(sub.toString()) ?? sub,
        'backend_type': backendType,
        'citizen_id': citizenId,
        'initiative_id': initiativeId,
        'type': typeStr,
      };
    } catch (_) {
      return null;
    }
  }
}
