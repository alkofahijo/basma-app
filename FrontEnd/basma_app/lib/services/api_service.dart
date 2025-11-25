// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:basma_app/config/base_url.dart';
import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/models/location_models.dart';
import 'package:basma_app/models/report_models.dart';
import 'package:http/http.dart' as http;
import 'package:basma_app/services/network_exceptions.dart';
import 'package:basma_app/models/network_error.dart';
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
  /// Base URL (مضبوط في config/base_url.dart)
  static final String base = kBaseUrl;

  // -------------------------------------------------------------
  // TOKEN MANAGEMENT
  // -------------------------------------------------------------
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

  static Map<String, String> _headers(String? tok, {bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (tok != null && tok.isNotEmpty) h['Authorization'] = 'Bearer $tok';
    return h;
  }

  /// Ensure there's a stored token or throw a mapped NetworkException.
  static Future<String> _requireToken() async {
    final tok = await _token();
    if (tok == null || tok.isEmpty) {
      throw NetworkException(
        NetworkError('غير مصرح. الرجاء تسجيل الدخول.', statusCode: 401),
      );
    }
    return tok;
  }

  // -------------------------
  // INTERNAL HTTP HELPERS
  // -------------------------
  static const Duration _kRequestTimeout = Duration(seconds: 18);

  static Future<http.Response> _getRequest(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final res = await http
          .get(uri, headers: headers)
          .timeout(_kRequestTimeout);
      return res;
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<http.Response> _postRequest(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final res = await http
          .post(uri, headers: headers, body: body)
          .timeout(_kRequestTimeout);
      return res;
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<http.Response> _patchRequest(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final res = await http
          .patch(uri, headers: headers, body: body)
          .timeout(_kRequestTimeout);
      return res;
    } catch (e) {
      throw mapException(e);
    }
  }

  // NOTE: Error mapping is handled by `network_exceptions.dart` helpers

  // -------------------------------------------------------------
  // AUTH
  // -------------------------------------------------------------
  static Future<void> login(String username, String password) async {
    try {
      final uri = Uri.parse('$base/auth/login');
      final res = await _postRequest(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
          'grant_type': 'password',
        },
      );

      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تسجيل الدخول');

      final data = jsonDecode(res.body);
      await setToken(data['access_token']);
    } catch (e) {
      throw mapException(e);
    }
  }

  // قديمة (لو ما زالت مستخدمة في شاشات قديمة)
  static Future<void> registerCitizen(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$base/auth/register/citizen');
      final res = await _postRequest(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode != 201)
        throw mapHttpResponse(res, fallback: 'فشل إنشاء حساب المواطن');
    } catch (e) {
      throw mapException(e);
    }
  }

  // قديمة (لو ما زالت مستخدمة في شاشات قديمة)
  static Future<void> registerInitiative(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$base/auth/register/initiative');
      final res = await _postRequest(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode != 201)
        throw mapHttpResponse(res, fallback: 'فشل إنشاء حساب المبادرة');
    } catch (e) {
      throw mapException(e);
    }
  }

  /// تغيير كلمة المرور للمستخدم الحالي (حسب الـ JWT)
  static Future<void> changePassword(String newPassword) async {
    final tok = await _requireToken();
    try {
      final uri = Uri.parse('$base/auth/change-password');
      final res = await _postRequest(
        uri,
        headers: _headers(tok),
        body: jsonEncode({'new_password': newPassword}),
      );
      if (res.statusCode != 204)
        throw mapHttpResponse(res, fallback: 'فشل تغيير كلمة المرور');
    } catch (e) {
      throw mapException(e);
    }
  }

  // =================== AUTH (نظام الحسابات الجديد) ===================

  /// تسجيل حساب جديد من نوع (بلدية، شركة، مبادرة، ... إلخ)
  static Future<void> registerAccount(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$base/auth/register/account');
      final res = await _postRequest(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode != 201)
        throw mapHttpResponse(res, fallback: 'فشل إنشاء الحساب');
    } catch (e) {
      throw mapException(e);
    }
  }

  // =================== ACCOUNT TYPES ===================

  static Future<List<AccountTypeOption>> listAccountTypes() async {
    try {
      final uri = Uri.parse('$base/accounts/types');
      final res = await _getRequest(uri);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل أنواع الحسابات');
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => AccountTypeOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  // =================== PAGINATED ACCOUNTS (NEW) ===================

  /// إرجاع قائمة الحسابات (جهات / متطوعين) مع:
  /// - فلاتر على المحافظة و نوع الحساب و حالة التفعيل (اختياري)
  /// - تقسيم صفحات (page, pageSize)
  /// - نص بحثي اختياري (search) يرسل على شكل q
  static Future<PaginatedAccountsResult> listAccountsPaged({
    int? governmentId,
    int? accountTypeId,
    int? isActive,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final query = <String, String>{'page': '$page', 'page_size': '$pageSize'};

    if (governmentId != null) query['government_id'] = '$governmentId';
    if (accountTypeId != null) query['account_type_id'] = '$accountTypeId';
    if (isActive != null) query['is_active'] = '$isActive';
    if (search != null && search.trim().isNotEmpty) {
      query['q'] = search.trim();
    }

    try {
      final uri = Uri.parse(
        '$base/accounts/paged',
      ).replace(queryParameters: query);

      // First try unauthenticated (public) endpoint.
      try {
        final res = await _getRequest(uri, headers: _headers(null));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          return PaginatedAccountsResult.fromJson(data);
        }

        // If we got 401 Unauthorized, fall through to try with token below.
        if (res.statusCode != 401) {
          throw mapHttpResponse(res, fallback: 'فشل تحميل قائمة الحسابات');
        }
      } catch (e) {
        // If the exception is a NetworkException with 401 detail, try with token.
        if (e is NetworkException) {
          final sc = e.error.statusCode ?? -1;
          if (sc != 401) throw e;
          // else fallthrough and try with token
        } else {
          // Non-network errors -> rethrow
          // For timeout/socket/etc we'll try once more with token below only if we have one.
        }
      }

      // Try with token if available (some deployments protect this endpoint)
      final tok = await _token();
      if (tok == null || tok.isEmpty) {
        throw NetworkException(
          NetworkError('غير مصرح. الرجاء تسجيل الدخول.', statusCode: 401),
        );
      }

      final res2 = await _getRequest(uri, headers: _headers(tok));
      if (res2.statusCode != 200)
        throw mapHttpResponse(res2, fallback: 'فشل تحميل قائمة الحسابات');
      final data2 = jsonDecode(res2.body) as Map<String, dynamic>;
      return PaginatedAccountsResult.fromJson(data2);
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // LOCATIONS (main models)
  // -------------------------------------------------------------
  static Future<List<Government>> governments() async {
    try {
      final uri = Uri.parse('$base/locations/governments');
      final res = await _getRequest(uri);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل المحافظات');
      final data = jsonDecode(res.body);
      return (data as List).map((e) => Government.fromJson(e)).toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<List<District>> districts(int govId) async {
    try {
      final uri = Uri.parse('$base/locations/governments/$govId/districts');
      final res = await _getRequest(uri);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل المحافظات الفرعية');
      return (jsonDecode(res.body) as List)
          .map((e) => District.fromJson(e))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<List<Area>> areas(int districtId) async {
    try {
      final uri = Uri.parse('$base/locations/districts/$districtId/areas');
      final res = await _getRequest(uri);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل المناطق');
      return (jsonDecode(res.body) as List)
          .map((e) => Area.fromJson(e))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<Area> createArea({
    required int districtId,
    required String nameAr,
    required String nameEn,
  }) async {
    final tok = await _requireToken();
    try {
      final uri = Uri.parse('$base/locations/areas');
      final res = await _postRequest(
        uri,
        headers: _headers(tok, json: true),
        body: jsonEncode({
          'district_id': districtId,
          'name_ar': nameAr,
          'name_en': nameEn,
        }),
      );
      if (res.statusCode != 201)
        throw mapHttpResponse(res, fallback: 'فشل إنشاء المنطقة');
      return Area.fromJson(jsonDecode(res.body));
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<List<LocationModel>> locations(int areaId) async {
    try {
      final uri = Uri.parse('$base/locations/areas/$areaId/locations');
      final res = await _getRequest(uri);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل المواقع');
      return (jsonDecode(res.body) as List)
          .map((e) => LocationModel.fromJson(e))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // REPORT TYPES & STATUS
  // -------------------------------------------------------------
  static Future<List<ReportType>> reportTypes() async {
    try {
      final uri = Uri.parse('$base/reports/types');
      final res = await _getRequest(uri);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل أنواع البلاغات');
      return (jsonDecode(res.body) as List)
          .map((e) => ReportType.fromJson(e))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<List<ReportStatus>> reportStatuses() async {
    try {
      final uri = Uri.parse('$base/reports/status');
      final res = await _getRequest(uri);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل حالات البلاغات');
      return (jsonDecode(res.body) as List)
          .map((e) => ReportStatus.fromJson(e))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
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
    final tok = await _requireToken();
    final uri = Uri.parse('$base/reports').replace(
      queryParameters: {
        if (areaId != null) 'area_id': '$areaId',
        if (statusId != null) 'status_id': '$statusId',
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    try {
      final res = await _getRequest(uri, headers: _headers(tok, json: false));
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل قائمة البلاغات');
      return (jsonDecode(res.body) as List)
          .map((j) => ReportSummary.fromJson(j))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // REPORT DETAIL
  // -------------------------------------------------------------
  static Future<ReportDetail> getReport(int id) async {
    final tok = await _requireToken();
    try {
      final uri = Uri.parse('$base/reports/$id');
      final res = await _getRequest(uri, headers: _headers(tok, json: false));
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل تفاصيل البلاغ');
      return ReportDetail.fromJson(jsonDecode(res.body));
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // CREATE REPORT
  // -------------------------------------------------------------
  static Future<ReportDetail> createReport(Map<String, dynamic> payload) async {
    final tok = await _requireToken();
    try {
      final uri = Uri.parse('$base/reports');
      final res = await _postRequest(
        uri,
        headers: _headers(tok),
        body: jsonEncode(payload),
      );
      if (res.statusCode != 201) throw mapHttpResponse(res);
      return ReportDetail.fromJson(jsonDecode(res.body));
    } catch (e) {
      throw mapException(e);
    }
  }

  // =================== ADOPT REPORT ===================

  static Future<ReportDetail> adopt({
    required int reportId,
    required int accountId,
  }) async {
    final tok = await _requireToken();
    final uri = Uri.parse('$base/reports/$reportId/adopt');
    try {
      final res = await _patchRequest(
        uri,
        headers: _headers(tok),
        body: jsonEncode({'account_id': accountId}),
      );
      if (res.statusCode != 200) throw mapHttpResponse(res);
      return ReportDetail.fromJson(jsonDecode(res.body));
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // COMPLETE REPORT (in_progress → completed)
  // -------------------------------------------------------------
  static Future<ReportDetail> completeReport({
    required int reportId,
    required String imageAfterUrl,
    String? note,
  }) async {
    final tok = await _requireToken();
    final uri = Uri.parse('$base/reports/$reportId/complete');
    try {
      final res = await _patchRequest(
        uri,
        headers: _headers(tok),
        body: jsonEncode({
          'image_after_url': imageAfterUrl,
          if (note != null) 'note': note,
        }),
      );
      if (res.statusCode != 200) throw mapHttpResponse(res);
      return ReportDetail.fromJson(jsonDecode(res.body));
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // IMAGE UPLOAD
  // -------------------------------------------------------------
  static Future<String> uploadImage(List<int> bytes, String filename) async {
    Future<http.StreamedResponse> sendTo(String path) async {
      final req = http.MultipartRequest('POST', Uri.parse('$base$path'));

      final mime = lookupMimeType(filename) ?? 'application/octet-stream';

      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mime),
        ),
      );

      try {
        return await req.send().timeout(_kRequestTimeout);
      } catch (e) {
        throw mapException(e);
      }
    }

    http.StreamedResponse res = await sendTo('/uploads');

    if (res.statusCode == 404) {
      res = await sendTo('/files/upload');
    }

    final body = await res.stream.bytesToString();
    if (res.statusCode != 200) {
      throw mapHttpResponse(http.Response(body, res.statusCode));
    }

    return jsonDecode(body)['url'] as String;
  }

  // -------------------------------------------------------------
  // REPORT COMMENTS / ATTACHMENTS endpoints were removed —
  // pagination for comments/attachments is not included in this build.

  // -------------------------------------------------------------
  // GUEST: FILTER OPTIONS (simple models)
  // -------------------------------------------------------------
  static Future<List<GovernmentOption>> listGovernments() async {
    try {
      final url = Uri.parse('$base/locations/governments');
      final res = await _getRequest(url);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'Failed to load governments');
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => GovernmentOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<List<DistrictOption>> listDistrictsByGovernment(
    int governmentId,
  ) async {
    try {
      final url = Uri.parse(
        '$base/locations/governments/$governmentId/districts',
      );
      final res = await _getRequest(url);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'Failed to load districts');
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => DistrictOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<List<AreaOption>> listAreasByDistrict(int districtId) async {
    try {
      final url = Uri.parse('$base/locations/districts/$districtId/areas');
      final res = await _getRequest(url);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'Failed to load areas');
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => AreaOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
  }

  static Future<List<ReportTypeOption>> listReportTypes() async {
    try {
      final url = Uri.parse('$base/reports/types');
      final res = await _getRequest(url);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'Failed to load report types');
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => ReportTypeOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapException(e);
    }
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

    try {
      final url = Uri.parse(
        '$base/reports/public',
      ).replace(queryParameters: query);
      final res = await _getRequest(url);
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'Failed to load reports');
      return ReportPublicSummary.listFromJson(res.body);
    } catch (e) {
      throw mapException(e);
    }
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
    final tok = await _requireToken();

    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};

    if (statusId != null) query['status_id'] = '$statusId';
    if (governmentId != null) query['government_id'] = '$governmentId';
    if (districtId != null) query['district_id'] = '$districtId';
    if (areaId != null) query['area_id'] = '$areaId';
    if (reportTypeId != null) query['report_type_id'] = '$reportTypeId';

    try {
      final url = Uri.parse('$base/reports/my').replace(queryParameters: query);
      final res = await _getRequest(url, headers: _headers(tok, json: false));
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'Failed to load my reports');
      return ReportPublicSummary.listFromJson(res.body);
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // UPDATE CITIZEN PROFILE (لو لسا مستخدمين citizens)
  // -------------------------------------------------------------
  static Future<void> updateCitizenProfile({
    required int id,
    String? nameAr,
    String? nameEn,
    String? mobileNumber,
  }) async {
    final tok = await _requireToken();

    final uri = Uri.parse('$base/citizens/$id');

    final payload = <String, dynamic>{};
    if (nameAr != null) payload['name_ar'] = nameAr;
    if (nameEn != null) payload['name_en'] = nameEn;
    if (mobileNumber != null) payload['mobile_number'] = mobileNumber;

    try {
      final res = await _patchRequest(
        uri,
        headers: _headers(tok, json: true),
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحديث بيانات المواطن');
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // UPDATE INITIATIVE PROFILE (لو لسا مستخدمين initiatives)
  // -------------------------------------------------------------
  static Future<void> updateInitiativeProfile({
    required int id,
    String? nameAr,
    String? nameEn,
    String? mobileNumber,
    String? joinFormLink,
    String? logoUrl,
  }) async {
    final tok = await _requireToken();

    final uri = Uri.parse('$base/initiatives/$id');

    final payload = <String, dynamic>{};
    if (nameAr != null) payload['name_ar'] = nameAr;
    if (nameEn != null) payload['name_en'] = nameEn;
    if (mobileNumber != null) payload['mobile_number'] = mobileNumber;
    if (joinFormLink != null) payload['join_form_link'] = joinFormLink;
    if (logoUrl != null) payload['logo_url'] = logoUrl;

    try {
      final res = await _patchRequest(
        uri,
        headers: _headers(tok, json: true),
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحديث بيانات المبادرة');
    } catch (e) {
      throw mapException(e);
    }
  }

  // -------------------------------------------------------------
  // ACCOUNT DETAILS + UPDATE (نظام الحسابات الموحد)
  // -------------------------------------------------------------
  static Future<Account> getAccount(int id) async {
    final tok = await _requireToken(); // لو الاندبوينت محمي، خلي التوكن
    final uri = Uri.parse('$base/accounts/$id');

    try {
      final res = await _getRequest(uri, headers: _headers(tok, json: false));
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحميل بيانات الحساب');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Account.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// تحديث بيانات حساب موحّد (Account) عبر PATCH /accounts/{id}
  /// body يمكن أن يحتوي أي من الحقول:
  /// name_ar, name_en, mobile_number, logo_url, join_form_link, ...
  static Future<Account> updateAccount(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final tok = await _requireToken();

    final uri = Uri.parse('$base/accounts/$id');

    try {
      final res = await _patchRequest(
        uri,
        headers: _headers(tok, json: true),
        body: jsonEncode(payload),
      );
      if (res.statusCode != 200)
        throw mapHttpResponse(res, fallback: 'فشل تحديث بيانات الحساب');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Account.fromJson(data);
    } catch (e) {
      throw mapException(e);
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
    try {
      final tok = await _requireToken();
      final url = Uri.parse('$base/ai/resolve-location');
      final resp = await _postRequest(
        url,
        headers: _headers(tok),
        body: jsonEncode({'latitude': lat, 'longitude': lng}),
      );
      if (resp.statusCode != 200)
        throw mapHttpResponse(resp, fallback: 'فشل في تحديد الموقع');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return ResolvedLocation.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }

  /// 2) استدعاء /ai/analyze-image
  static Future<AiSuggestion> analyzeReportImage({
    required Uint8List bytes,
    required String filename,
    required int governmentId,
    required int districtId,
    required int areaId,
  }) async {
    try {
      final tok = await _requireToken();
      final url = Uri.parse(
        '$base/ai/analyze-image?gov_id=$governmentId&dist_id=$districtId&area_id=$areaId',
      );

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(_headers(tok, json: false));
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final streamedResp = await request.send().timeout(_kRequestTimeout);
      final resp = await http.Response.fromStream(
        streamedResp,
      ).timeout(_kRequestTimeout);
      if (resp.statusCode != 200)
        throw mapHttpResponse(resp, fallback: 'فشل في تحليل الصورة');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return AiSuggestion.fromJson(data);
    } catch (e) {
      throw mapException(e);
    }
  }
}
