// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location_models.dart';
import '../models/report_models.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  /// ANDROID emulator: 10.0.2.2; iOS simulator: localhost
  static const String base = "http://10.0.2.2:8000";

  // -------------------- Token helpers --------------------
  static Future<String?> _token() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('token');
  }

  static Future<void> setToken(String? token) async {
    final sp = await SharedPreferences.getInstance();
    if (token == null) {
      await sp.remove('token');
    } else {
      await sp.setString('token', token);
    }
  }

  static Map<String, String> _headers(String? tok, {bool json = true}) => {
    if (json) 'Content-Type': 'application/json',
    if (tok != null) 'Authorization': 'Bearer $tok',
  };

  // -------------------- Utilities --------------------
  static Never _throwHttp(
    http.Response res, {
    String fallback = "Request failed",
  }) {
    // Try to surface FastAPI's "detail" if JSON, otherwise include raw text.
    String message = "$fallback (${res.statusCode})";
    final raw = utf8.decode(res.bodyBytes);
    try {
      final body = jsonDecode(raw);
      if (body is Map && body['detail'] != null) {
        message = "${body['detail']}";
      } else {
        if (raw.isNotEmpty) message = "$message: $raw";
      }
    } catch (_) {
      if (raw.isNotEmpty) message = "$message: $raw";
    }
    throw HttpException(message);
  }

  // -------------------- Locations --------------------
  static Future<List<Government>> governments() async {
    final uri = Uri.parse("$base/locations/governments");
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load governments");
    }
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Government.fromJson(e)).toList();
  }

  static Future<List<District>> districts(int govId) async {
    final uri = Uri.parse("$base/locations/governments/$govId/districts");
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load districts");
    }
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => District.fromJson(e)).toList();
  }

  static Future<List<Area>> areas(int districtId) async {
    final uri = Uri.parse("$base/locations/districts/$districtId/areas");
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load areas");
    }
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => Area.fromJson(e)).toList();
  }

  static Future<List<LocationModel>> locations(int areaId) async {
    final uri = Uri.parse("$base/locations/areas/$areaId/locations");
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load locations");
    }
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => LocationModel.fromJson(e)).toList();
  }

  // -------------------- Auth --------------------
  /// FastAPI OAuth2PasswordRequestForm expects form-encoded.
  static Future<void> login(String username, String password) async {
    final uri = Uri.parse("$base/auth/login");
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
        'grant_type': 'password',
        'scope': '',
        'client_id': '',
        'client_secret': '',
      },
    );
    if (res.statusCode != 200) _throwHttp(res, fallback: "Login failed");
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    await setToken(data['access_token'] as String?);
  }

  static Future<void> registerCitizen(Map<String, dynamic> payload) async {
    final uri = Uri.parse("$base/auth/register/citizen");
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      _throwHttp(res, fallback: "Citizen registration failed");
    }
  }

  static Future<void> registerInitiative(Map<String, dynamic> payload) async {
    final uri = Uri.parse("$base/auth/register/initiative");
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      _throwHttp(res, fallback: "Initiative registration failed");
    }
  }

  // -------------------- Files --------------------
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    Future<http.StreamedResponse> _sendTo(String path) async {
      final req = http.MultipartRequest('POST', Uri.parse("$base$path"));

      // Detect content-type from filename (or bytes if you prefer)
      final mime = lookupMimeType(filename) ?? 'application/octet-stream';
      final mt = MediaType.parse(mime);

      req.files.add(
        http.MultipartFile.fromBytes(
          'file', // <-- field name expected by backend
          bytes,
          filename: filename, // keep original name if possible
          contentType: mt, // <-- IMPORTANT: set content-type
        ),
      );
      return req.send();
    }

    http.StreamedResponse res = await _sendTo("/uploads");
    if (res.statusCode == 404) {
      res = await _sendTo("/files/upload");
    }
    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) {
      throw HttpException("Upload failed (${res.statusCode}): $body");
    }
    final decoded = jsonDecode(body);
    return decoded['url'] as String;
  }

  // -------------------- Report Types / Status --------------------
  static Future<List<ReportType>> reportTypes() async {
    final uri = Uri.parse("$base/reports/types");
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load report types");
    }
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => ReportType.fromJson(e)).toList();
  }

  static Future<List<ReportStatus>> reportStatuses() async {
    final uri = Uri.parse("$base/reports/status");
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load report status list");
    }
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => ReportStatus.fromJson(e)).toList();
  }

  // -------------------- Reports --------------------
  static Future<List<ReportSummary>> listReports({
    int? areaId,
    String? statusCode,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String, String>{
      if (areaId != null) 'area_id': areaId.toString(),
      if (statusCode != null && statusCode.trim().isNotEmpty)
        'status_code': statusCode.trim(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final uri = Uri.parse("$base/reports").replace(queryParameters: params);
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load reports");
    }
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => ReportSummary.fromJson(e)).toList();
  }

  static Future<ReportDetail> getReport(int id) async {
    final uri = Uri.parse("$base/reports/$id");
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load report");
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return ReportDetail.fromJson(data);
  }

  static Future<ReportDetail> createReport(Map<String, dynamic> payload) async {
    final tok = await _token();
    final uri = Uri.parse("$base/reports");
    final res = await http.post(
      uri,
      headers: _headers(tok),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 201) {
      _throwHttp(res, fallback: "Create report failed");
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return ReportDetail.fromJson(data);
  }

  static Future<ReportDetail> adopt(int reportId, String type, int byId) async {
    final tok = await _token();
    final uri = Uri.parse("$base/reports/$reportId/adopt");
    final res = await http.patch(
      uri,
      headers: _headers(tok),
      body: jsonEncode({"adopted_by_type": type, "adopted_by_id": byId}),
    );
    if (res.statusCode != 200) _throwHttp(res, fallback: "Adopt failed");
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return ReportDetail.fromJson(data);
  }

  static Future<ReportDetail> complete(
    int reportId,
    String imageAfterUrl,
  ) async {
    final tok = await _token();
    final uri = Uri.parse("$base/reports/$reportId/complete");
    final res = await http.patch(
      uri,
      headers: _headers(tok),
      body: jsonEncode({"image_after_url": imageAfterUrl}),
    );
    if (res.statusCode != 200) _throwHttp(res, fallback: "Complete failed");
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return ReportDetail.fromJson(data);
  }
}
