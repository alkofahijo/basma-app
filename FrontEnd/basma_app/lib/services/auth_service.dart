import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة خاصة بالتوثيق وقراءة بيانات المستخدم الحالي من JWT
class AuthService {
  static const String _tokenKey = 'token';
  static const String _cachedUserKey = 'current_user';

  /// شكل الكاش داخل SharedPreferences:
  /// {
  ///   "token": "<jwt-token-string>",
  ///   "user": {
  ///     "id": 3,
  ///     "backend_type": 3,
  ///     "citizen_id": 3,
  ///     "initiative_id": null,
  ///     "type": "citizen"
  ///   }
  /// }
  ///
  /// ترجع:
  /// - Map<String, dynamic> فيها معلومات المستخدم
  /// - أو null لو ما فيه توكن أو توكن غير صالح
  static Future<Map<String, dynamic>?> currentUser() async {
    final sp = await SharedPreferences.getInstance();

    // اقرأ التوكن الحالي
    final token = sp.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      // لا يوجد توكن => احذف أي كاش قديم
      await sp.remove(_cachedUserKey);
      return null;
    }

    // جرّب قراءة الكاش والتحقق أن الكاش مطابق لنفس التوكن
    final cachedStr = sp.getString(_cachedUserKey);
    if (cachedStr != null) {
      try {
        final cached = jsonDecode(cachedStr);
        if (cached is Map<String, dynamic>) {
          final cachedToken = cached['token'];
          final cachedUser = cached['user'];
          if (cachedToken == token && cachedUser is Map<String, dynamic>) {
            // الكاش يخص نفس التوكن الحالي
            return Map<String, dynamic>.from(cachedUser);
          }
        }
      } catch (_) {
        // تجاهل أي خطأ في الكاش واستمر
      }
    }

    // لم نجد كاش صالح => فكّك التوكن وجِب البيانات من الـ payload
    final user = _parseUserFromToken(token);
    if (user == null) {
      // لو التوكن غير صالح، نظف الكاش فقط
      await sp.remove(_cachedUserKey);
      return null;
    }

    // خزّن الكاش مع التوكن الحالي
    final cacheEnvelope = {"token": token, "user": user};
    await sp.setString(_cachedUserKey, jsonEncode(cacheEnvelope));

    return user;
  }

  /// يحذف التوكن الحالي وأي كاش للمستخدم.
  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
    await sp.remove(_cachedUserKey);
  }

  // ===================================================================
  // Helpers
  // ===================================================================

  /// يفكّك الـ JWT ويستخرج معلومات المستخدم.
  ///
  /// لو التوكن غير صالح أو لا يحتوي على الحقول المطلوبة يرجّع null.
  static Map<String, dynamic>? _parseUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payloadSegment = parts[1];
      final normalized = base64Url.normalize(payloadSegment);
      final payloadJson = utf8.decode(base64Url.decode(normalized));

      final data = jsonDecode(payloadJson);
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final sub = data['sub'];
      final backendType = data['user_type']; // 3 citizen, 2 initiative

      if (sub == null || backendType == null) {
        return null;
      }

      final citizenId = data['citizen_id'];
      final initiativeId = data['initiative_id'];

      // تحويل النوع إلى نص مفهوم
      String typeStr;
      if (backendType == 3) {
        typeStr = 'citizen';
      } else if (backendType == 2) {
        typeStr = 'initiative';
      } else {
        typeStr = 'unknown';
      }

      final user = <String, dynamic>{
        'id': int.tryParse(sub.toString()) ?? sub,
        'backend_type': backendType,
        'citizen_id': citizenId,
        'initiative_id': initiativeId,
        'type': typeStr,
      };

      return user;
    } catch (_) {
      // أي خطأ في فك التوكن => نرجع null بدون رمي استثناء
      return null;
    }
  }
}
