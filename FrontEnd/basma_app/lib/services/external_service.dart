// lib/services/external_service.dart
import 'dart:convert';

import 'package:basma_app/services/network_exceptions.dart';
import 'package:basma_app/models/network_error.dart';
import 'package:http/http.dart' as http;

class ExternalService {
  /// Search OpenStreetMap Nominatim for places.
  /// Returns decoded JSON list.
  static Future<List<dynamic>> nominatimSearch(
    String query, {
    int limit = 7,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': query,
      'addressdetails': '1',
      'accept-language': 'ar',
      'limit': '$limit',
      'countrycodes': 'jo',
    });

    try {
      final resp = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'BasmaApp/1.0 (Android & iOS; contact=futuretechvoljo@gmail.com)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 403) {
        throw NetworkException(
          NetworkError(
            'خدمة البحث رفضت الطلب (403). تأكد من إعداد User-Agent.',
          ),
        );
      }

      if (resp.statusCode != 200) {
        throw mapHttpResponse(resp, fallback: 'خطأ في خدمة البحث');
      }

      final data = jsonDecode(resp.body) as List<dynamic>;
      return data;
    } catch (e) {
      throw mapException(e);
    }
  }
}
