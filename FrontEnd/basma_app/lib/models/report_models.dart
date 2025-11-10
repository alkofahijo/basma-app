import 'dart:convert';

/// ---- Report Type (lookup) ----
class ReportType {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;

  ReportType({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
  });

  factory ReportType.fromJson(Map<String, dynamic> json) => ReportType(
    id: _asInt(json['id']),
    code: _asString(json['code']),
    nameAr: _asString(json['name_ar']),
    nameEn: _asString(json['name_en']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name_ar': nameAr,
    'name_en': nameEn,
  };
}

/// ---- Report Status (lookup) ----
class ReportStatus {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;

  ReportStatus({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
  });

  factory ReportStatus.fromJson(Map<String, dynamic> json) => ReportStatus(
    id: _asInt(json['id']),
    code: _asString(json['code']),
    nameAr: _asString(json['name_ar']),
    nameEn: _asString(json['name_en']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name_ar': nameAr,
    'name_en': nameEn,
  };
}

/// ---- Lightweight item used by list UI ----
/// Maps items returned by GET /reports (list).
class ReportSummary {
  final int id;
  final String reportCode;
  final String nameAr;
  final String nameEn;
  final int statusId;
  final int areaId;
  final DateTime reportedAt;

  /// Optional fields that some list endpoints include
  final String?
  statusCode; // e.g., "under_review" | "open" | "in_progress" | "completed"
  final String? imageBeforeUrl;
  final String? imageAfterUrl;

  ReportSummary({
    required this.id,
    required this.reportCode,
    required this.nameAr,
    required this.nameEn,
    required this.statusId,
    required this.areaId,
    required this.reportedAt,
    this.statusCode,
    this.imageBeforeUrl,
    this.imageAfterUrl,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    id: _asInt(json['id']),
    reportCode: _asString(json['report_code']),
    nameAr: _asString(json['name_ar']),
    nameEn: _asString(json['name_en']),
    statusId: _asInt(json['status_id']),
    areaId: _asInt(json['area_id']),
    reportedAt: _asDate(json['reported_at']),
    statusCode: _asStringOrNull(json['status_code']),
    imageBeforeUrl: _asStringOrNull(json['image_before_url']),
    imageAfterUrl: _asStringOrNull(json['image_after_url']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'report_code': reportCode,
    'name_ar': nameAr,
    'name_en': nameEn,
    'status_id': statusId,
    'area_id': areaId,
    'reported_at': reportedAt.toIso8601String(),
    'status_code': statusCode,
    'image_before_url': imageBeforeUrl,
    'image_after_url': imageAfterUrl,
  };
}

/// ---- Full detail used by show page / create/adopt/complete ----
/// Mirrors backend ReportOut (FastAPI/Pydantic).
class ReportDetail {
  final int id;
  final String reportCode;
  final int reportTypeId;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String? note;
  final String imageBeforeUrl;
  final String? imageAfterUrl;
  final int statusId;
  final DateTime reportedAt;
  final int? adoptedById;
  final String? adoptedByType; // "initiative" | "citizen" | null
  final int governmentId;
  final int districtId;
  final int areaId;
  final int locationId;
  final int? userId;
  final String? reportedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportDetail({
    required this.id,
    required this.reportCode,
    required this.reportTypeId,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    this.note,
    required this.imageBeforeUrl,
    this.imageAfterUrl,
    required this.statusId,
    required this.reportedAt,
    this.adoptedById,
    this.adoptedByType,
    required this.governmentId,
    required this.districtId,
    required this.areaId,
    required this.locationId,
    this.userId,
    this.reportedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportDetail.fromJson(Map<String, dynamic> json) => ReportDetail(
    id: _asInt(json['id']),
    reportCode: _asString(json['report_code']),
    reportTypeId: _asInt(json['report_type_id']),
    nameAr: _asString(json['name_ar']),
    nameEn: _asString(json['name_en']),
    descriptionAr: _asString(json['description_ar']),
    descriptionEn: _asString(json['description_en']),
    note: _asStringOrNull(json['note']),
    imageBeforeUrl: _asString(json['image_before_url']),
    imageAfterUrl: _asStringOrNull(json['image_after_url']),
    statusId: _asInt(json['status_id']),
    reportedAt: _asDate(json['reported_at']),
    adoptedById: _asIntOrNull(json['adopted_by_id']),
    adoptedByType: _asStringOrNull(json['adopted_by_type']),
    governmentId: _asInt(json['government_id']),
    districtId: _asInt(json['district_id']),
    areaId: _asInt(json['area_id']),
    locationId: _asInt(json['location_id']),
    userId: _asIntOrNull(json['user_id']),
    reportedByName: _asStringOrNull(json['reported_by_name']),
    createdAt: _asDate(json['created_at']),
    updatedAt: _asDate(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'report_code': reportCode,
    'report_type_id': reportTypeId,
    'name_ar': nameAr,
    'name_en': nameEn,
    'description_ar': descriptionAr,
    'description_en': descriptionEn,
    'note': note,
    'image_before_url': imageBeforeUrl,
    'image_after_url': imageAfterUrl,
    'status_id': statusId,
    'reported_at': reportedAt.toIso8601String(),
    'adopted_by_id': adoptedById,
    'adopted_by_type': adoptedByType,
    'government_id': governmentId,
    'district_id': districtId,
    'area_id': areaId,
    'location_id': locationId,
    'user_id': userId,
    'reported_by_name': reportedByName,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Optional helper if you ever get a raw JSON string.
ReportDetail reportDetailFromJsonString(String src) =>
    ReportDetail.fromJson(jsonDecode(src) as Map<String, dynamic>);

ReportSummary reportSummaryFromJsonString(String src) =>
    ReportSummary.fromJson(jsonDecode(src) as Map<String, dynamic>);

/// ----------------- parsing helpers -----------------
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.parse(v);
  throw ArgumentError("Expected int, got $v");
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  return _asInt(v);
}

String _asString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

DateTime _asDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String) return DateTime.parse(v);
  throw ArgumentError("Expected ISO8601 string for DateTime, got $v");
}
