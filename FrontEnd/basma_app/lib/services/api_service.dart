// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basma_app/models/citizen_models.dart';
import 'package:basma_app/models/initiative_models.dart';
import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/models/report_models.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// -------------------------
/// AI MODELS (DTOs)
/// -------------------------
class ResolvedLocation {
  final int governmentId;
  final String governmentNameAr;
  final int districtId;
  final String districtNameAr;
  final int areaId;
  final String areaNameAr;

  /// اختياري: لو الـ backend رجّع location
  final int? locationId;
  final String? locationNameAr;

  ResolvedLocation({
    required this.governmentId,
    required this.governmentNameAr,
    required this.districtId,
    required this.districtNameAr,
    required this.areaId,
    required this.areaNameAr,
    this.locationId,
    this.locationNameAr,
  });

  factory ResolvedLocation.fromJson(Map<String, dynamic> json) {
    final loc = json['location'];

    return ResolvedLocation(
      governmentId: json['government']['id'] as int,
      governmentNameAr: json['government']['name_ar'] as String,
      districtId: json['district']['id'] as int,
      districtNameAr: json['district']['name_ar'] as String,
      areaId: json['area']['id'] as int,
      areaNameAr: json['area']['name_ar'] as String,
      locationId: loc != null ? loc['id'] as int? : null,
      locationNameAr: loc != null ? loc['name_ar'] as String? : null,
    );
  }
}

class AiSuggestion {
  final int reportTypeId;
  final String reportTypeNameAr;
  final double confidence;
  final String suggestedTitle;
  final String suggestedDescription;

  AiSuggestion({
    required this.reportTypeId,
    required this.reportTypeNameAr,
    required this.confidence,
    required this.suggestedTitle,
    required this.suggestedDescription,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      reportTypeId: json['report_type_id'] as int,
      reportTypeNameAr: json['report_type_name_ar'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      suggestedTitle: json['suggested_title'] as String,
      suggestedDescription: json['suggested_description'] as String,
    );
  }
}

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
    if (tok != null && tok.isNotEmpty) h["Authorization"] = "Bearer $tok";
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
      } else if (raw.isNotEmpty) {
        msg = "$msg: $raw";
      }
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

  /// تغيير كلمة المرور للمستخدم الحالي (حسب الـ JWT)
  static Future<void> changePassword(String newPassword) async {
    final tok = await _token();
    if (tok == null || tok.isEmpty) {
      throw Exception("Not authenticated");
    }

    final uri = Uri.parse("$base/auth/change-password");
    final res = await http.post(
      uri,
      headers: _headers(tok),
      body: jsonEncode({"new_password": newPassword}),
    );

    if (res.statusCode != 204) {
      _throwHttp(res, fallback: "فشل تغيير كلمة المرور");
    }
  }

  // -------------------------------------------------------------
  // LOCATIONS (main models)
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
  // REPORT LIST (internal)
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

    return jsonDecode(body)["url"] as String;
  }

  // -------------------------------------------------------------
  // GUEST: FILTER OPTIONS (simple models)
  // -------------------------------------------------------------
  static Future<List<GovernmentOption>> listGovernments() async {
    final url = Uri.parse('$base/locations/governments');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load governments');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => GovernmentOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<DistrictOption>> listDistrictsByGovernment(
    int governmentId,
  ) async {
    final url = Uri.parse(
      '$base/locations/governments/$governmentId/districts',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load districts');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => DistrictOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AreaOption>> listAreasByDistrict(int districtId) async {
    final url = Uri.parse('$base/locations/districts/$districtId/areas');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load areas');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => AreaOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ReportTypeOption>> listReportTypes() async {
    final url = Uri.parse('$base/reports/types');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load report types');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => ReportTypeOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------------------------------------------------------------
  // PUBLIC REPORTS (for guest UI)
  // -------------------------------------------------------------
  static Future<List<ReportPublicSummary>> listPublicReports({
    int? statusId,
    int? governmentId,
    int? districtId,
    int? areaId,
    int? reportTypeId,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};

    if (statusId != null) query['status_id'] = '$statusId';
    if (governmentId != null) query['government_id'] = '$governmentId';
    if (districtId != null) query['district_id'] = '$districtId';
    if (areaId != null) query['area_id'] = '$areaId';
    if (reportTypeId != null) query['report_type_id'] = '$reportTypeId';

    final url = Uri.parse(
      '$base/reports/public',
    ).replace(queryParameters: query);
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('Failed to load reports');
    }

    return ReportPublicSummary.listFromJson(res.body);
  }

  // -------------------------------------------------------------
  // MY REPORTS (adopted by current user)
  // -------------------------------------------------------------
  static Future<List<ReportPublicSummary>> listMyReports({
    int? statusId,
    int? governmentId,
    int? districtId,
    int? areaId,
    int? reportTypeId,
    int limit = 100,
    int offset = 0,
  }) async {
    final tok = await _token();
    if (tok == null || tok.isEmpty) {
      throw Exception("Not authenticated");
    }

    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};

    if (statusId != null) query['status_id'] = '$statusId';
    if (governmentId != null) query['government_id'] = '$governmentId';
    if (districtId != null) query['district_id'] = '$districtId';
    if (areaId != null) query['area_id'] = '$areaId';
    if (reportTypeId != null) query['report_type_id'] = '$reportTypeId';

    final url = Uri.parse('$base/reports/my').replace(queryParameters: query);
    final res = await http.get(url, headers: _headers(tok, json: false));

    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "Failed to load my reports");
    }

    return ReportPublicSummary.listFromJson(res.body);
  }

  // -------------------------------------------------------------
  // UPDATE CITIZEN PROFILE
  // -------------------------------------------------------------
  static Future<void> updateCitizenProfile({
    required int id,
    String? nameAr,
    String? nameEn,
    String? mobileNumber,
  }) async {
    final tok = await _token();
    if (tok == null || tok.isEmpty) {
      throw Exception("Not authenticated");
    }

    final uri = Uri.parse("$base/citizens/$id");

    final payload = <String, dynamic>{};
    if (nameAr != null) payload["name_ar"] = nameAr;
    if (nameEn != null) payload["name_en"] = nameEn;
    if (mobileNumber != null) payload["mobile_number"] = mobileNumber;

    final res = await http.patch(
      uri,
      headers: _headers(tok, json: true),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "فشل تحديث بيانات المواطن");
    }
  }

  // -------------------------------------------------------------
  // UPDATE INITIATIVE PROFILE
  // -------------------------------------------------------------
  static Future<void> updateInitiativeProfile({
    required int id,
    String? nameAr,
    String? nameEn,
    String? mobileNumber,
    String? joinFormLink,
    String? logoUrl,
  }) async {
    final tok = await _token();
    if (tok == null || tok.isEmpty) {
      throw Exception("Not authenticated");
    }

    final uri = Uri.parse("$base/initiatives/$id");

    final payload = <String, dynamic>{};
    if (nameAr != null) payload["name_ar"] = nameAr;
    if (nameEn != null) payload["name_en"] = nameEn;
    if (mobileNumber != null) payload["mobile_number"] = mobileNumber;
    if (joinFormLink != null) payload["join_form_link"] = joinFormLink;
    if (logoUrl != null) payload["logo_url"] = logoUrl;

    final res = await http.patch(
      uri,
      headers: _headers(tok, json: true),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      _throwHttp(res, fallback: "فشل تحديث بيانات المبادرة");
    }
  }

  // -------------------------------------------------------------
  // AI ENDPOINTS
  // -------------------------------------------------------------

  /// 1) استدعاء /ai/resolve-location
  static Future<ResolvedLocation> resolveLocationByLatLng(
    double lat,
    double lng,
  ) async {
    final tok = await _token();
    final url = Uri.parse('$base/ai/resolve-location');
    final resp = await http.post(
      url,
      headers: _headers(tok), // JSON + Authorization لو متوفر
      body: jsonEncode({'latitude': lat, 'longitude': lng}),
    );
    if (resp.statusCode != 200) {
      throw Exception('فشل في تحديد الموقع (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return ResolvedLocation.fromJson(data);
  }

  /// 2) استدعاء /ai/analyze-image
  static Future<AiSuggestion> analyzeReportImage({
    required Uint8List bytes,
    required String filename,
    required int governmentId,
    required int districtId,
    required int areaId,
  }) async {
    final tok = await _token();
    final url = Uri.parse(
      '$base/ai/analyze-image?gov_id=$governmentId&dist_id=$districtId&area_id=$areaId',
    );

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(_headers(tok, json: false));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode != 200) {
      throw Exception('فشل في تحليل الصورة (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiSuggestion.fromJson(data);
  }
}
