// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:basma_app/models/citizen_models.dart';
import 'package:basma_app/models/initiative_models.dart';
import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/models/report_models.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  /// Emulator base URL
  static const String base = "http://10.0.2.2:8000";

  // -------------------------------------------------------------
  // TOKEN MANAGEMENT
  // -------------------------------------------------------------
  static Future<String?> _token() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString("token");
  }

  static Future<void> setToken(String? token) async {
    final sp = await SharedPreferences.getInstance();
    if (token == null) {
      await sp.remove("token");
    } else {
      await sp.setString("token", token);
    }
  }

  static Map<String, String> _headers(String? tok, {bool json = true}) {
    final h = <String, String>{};
    if (json) h["Content-Type"] = "application/json";
    if (tok != null) h["Authorization"] = "Bearer $tok";
    return h;
  }

  // -------------------------------------------------------------
  // ERROR HANDLING
  // -------------------------------------------------------------
  static Never _throwHttp(
    http.Response res, {
    String fallback = "Request failed",
  }) {
    String msg = "$fallback (${res.statusCode})";
    final raw = utf8.decode(res.bodyBytes);

    try {
      final body = jsonDecode(raw);
      if (body is Map && body["detail"] != null) {
        msg = body["detail"].toString();
      } else if (raw.isNotEmpty)
        // ignore: curly_braces_in_flow_control_structures
        msg = "$msg: $raw";
    } catch (_) {
      if (raw.isNotEmpty) msg = "$msg: $raw";
    }

    throw HttpException(msg);
  }

  // -------------------------------------------------------------
  // AUTH
  // -------------------------------------------------------------
  static Future<void> login(String username, String password) async {
    final uri = Uri.parse("$base/auth/login");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "username": username,
        "password": password,
        "grant_type": "password",
      },
    );

    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "فشل تسجيل الدخول");
    }

    final data = jsonDecode(res.body);
    await setToken(data["access_token"]);
  }

  static Future<void> registerCitizen(Map<String, dynamic> payload) async {
    final uri = Uri.parse("$base/auth/register/citizen");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201) {
      _throwHttp(res, fallback: "فشل إنشاء حساب المواطن");
    }
  }

  static Future<void> registerInitiative(Map<String, dynamic> payload) async {
    final uri = Uri.parse("$base/auth/register/initiative");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201) {
      _throwHttp(res, fallback: "فشل إنشاء حساب المبادرة");
    }
  }

  // -------------------------------------------------------------
  // LOCATIONS
  // -------------------------------------------------------------
  static Future<List<Government>> governments() async {
    final uri = Uri.parse("$base/locations/governments");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    final data = jsonDecode(res.body);
    return (data as List).map((e) => Government.fromJson(e)).toList();
  }

  static Future<List<District>> districts(int govId) async {
    final uri = Uri.parse("$base/locations/governments/$govId/districts");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return (jsonDecode(res.body) as List)
        .map((e) => District.fromJson(e))
        .toList();
  }

  static Future<List<Area>> areas(int districtId) async {
    final uri = Uri.parse("$base/locations/districts/$districtId/areas");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return (jsonDecode(res.body) as List).map((e) => Area.fromJson(e)).toList();
  }

  static Future<Area> createArea({
    required int districtId,
    required String nameAr,
    required String nameEn,
  }) async {
    final uri = Uri.parse("$base/locations/areas");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "district_id": districtId,
        "name_ar": nameAr,
        "name_en": nameEn,
      }),
    );

    if (res.statusCode != 201) _throwHttp(res);

    return Area.fromJson(jsonDecode(res.body));
  }

  static Future<List<LocationModel>> locations(int areaId) async {
    final uri = Uri.parse("$base/locations/areas/$areaId/locations");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return (jsonDecode(res.body) as List)
        .map((e) => LocationModel.fromJson(e))
        .toList();
  }

  // -------------------------------------------------------------
  // REPORT TYPES & STATUS
  // -------------------------------------------------------------
  static Future<List<ReportType>> reportTypes() async {
    final uri = Uri.parse("$base/reports/types");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return (jsonDecode(res.body) as List)
        .map((e) => ReportType.fromJson(e))
        .toList();
  }

  static Future<List<ReportStatus>> reportStatuses() async {
    final uri = Uri.parse("$base/reports/status");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return (jsonDecode(res.body) as List)
        .map((e) => ReportStatus.fromJson(e))
        .toList();
  }

  // -------------------------------------------------------------
  // REPORT LIST
  // -------------------------------------------------------------
  static Future<List<ReportSummary>> listReports({
    int? areaId,
    int? statusId,
    int limit = 200,
    int offset = 0,
  }) async {
    final uri = Uri.parse("$base/reports").replace(
      queryParameters: {
        if (areaId != null) "area_id": "$areaId",
        if (statusId != null) "status_id": "$statusId",
        "limit": "$limit",
        "offset": "$offset",
      },
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return (jsonDecode(res.body) as List)
        .map((j) => ReportSummary.fromJson(j))
        .toList();
  }

  // -------------------------------------------------------------
  // REPORT DETAIL
  // -------------------------------------------------------------
  static Future<ReportDetail> getReport(int id) async {
    final uri = Uri.parse("$base/reports/$id");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return ReportDetail.fromJson(jsonDecode(res.body));
  }

  // -------------------------------------------------------------
  // CREATE REPORT
  // -------------------------------------------------------------
  static Future<ReportDetail> createReport(Map<String, dynamic> payload) async {
    final tok = await _token();
    final uri = Uri.parse("$base/reports");

    final res = await http.post(
      uri,
      headers: _headers(tok),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 201) _throwHttp(res);

    return ReportDetail.fromJson(jsonDecode(res.body));
  }

  // -------------------------------------------------------------
  // ADOPT REPORT (open → in_progress)
  // -------------------------------------------------------------
  static Future<ReportDetail> adopt({
    required int reportId,
    required int adoptedById,
    required int adoptedByType, // 1 citizen, 2 initiative
  }) async {
    final tok = await _token();
    final uri = Uri.parse("$base/reports/$reportId/adopt");

    final res = await http.patch(
      uri,
      headers: _headers(tok),
      body: jsonEncode({
        "adopted_by_id": adoptedById,
        "adopted_by_type": adoptedByType,
      }),
    );

    if (res.statusCode != 200) _throwHttp(res);

    return ReportDetail.fromJson(jsonDecode(res.body));
  }

  // -------------------------------------------------------------
  // COMPLETE REPORT (in_progress → completed)
  // -------------------------------------------------------------
  static Future<ReportDetail> completeReport({
    required int reportId,
    required String imageAfterUrl,
    String? note,
  }) async {
    final tok = await _token();
    final uri = Uri.parse("$base/reports/$reportId/complete");

    final res = await http.patch(
      uri,
      headers: _headers(tok),
      body: jsonEncode({
        "image_after_url": imageAfterUrl,
        if (note != null) "note": note,
      }),
    );

    if (res.statusCode != 200) _throwHttp(res);

    return ReportDetail.fromJson(jsonDecode(res.body));
  }

  // -------------------------------------------------------------
  // CITIZEN / INITIATIVE DETAILS
  // -------------------------------------------------------------
  static Future<Citizen> getCitizen(int id) async {
    final uri = Uri.parse("$base/citizens/$id");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return Citizen.fromJson(jsonDecode(res.body));
  }

  static Future<Initiative> getInitiative(int id) async {
    final uri = Uri.parse("$base/initiatives/$id");
    final res = await http.get(uri);

    if (res.statusCode != 200) _throwHttp(res);

    return Initiative.fromJson(jsonDecode(res.body));
  }

  // -------------------------------------------------------------
  // IMAGE UPLOAD
  // -------------------------------------------------------------
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    Future<http.StreamedResponse> sendTo(String path) async {
      final req = http.MultipartRequest("POST", Uri.parse("$base$path"));

      final mime = lookupMimeType(filename) ?? "application/octet-stream";

      req.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: filename,
          contentType: MediaType.parse(mime),
        ),
      );

      return req.send();
    }

    http.StreamedResponse res = await sendTo("/uploads");

    if (res.statusCode == 404) {
      res = await sendTo("/files/upload");
    }

    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) {
      throw HttpException("Upload failed: $body");
    }

    return jsonDecode(body)["url"];
  }
}
