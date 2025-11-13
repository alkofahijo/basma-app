/// =============================
/// Report Lookups
/// =============================
class ReportType {
  final int id;
  final String code;
  final String nameAr;

  ReportType({required this.id, required this.code, required this.nameAr});

  factory ReportType.fromJson(Map<String, dynamic> json) => ReportType(
    id: _asInt(json['id']),
    code: _asString(json['code']),
    nameAr: _asString(json['name_ar']),
  );
}

class ReportStatus {
  final int id;
  final String code;
  final String nameAr;

  ReportStatus({required this.id, required this.code, required this.nameAr});

  factory ReportStatus.fromJson(Map<String, dynamic> json) => ReportStatus(
    id: _asInt(json['id']),
    code: _asString(json['code']),
    nameAr: _asString(json['name_ar']),
  );
}

/// =============================
/// Report Summary
/// =============================
class ReportSummary {
  final int id;
  final String reportCode;
  final String nameAr;
  final int statusId;

  final int areaId;
  final DateTime reportedAt;

  final String? statusCode;
  final String? imageBeforeUrl;
  final String? imageAfterUrl;

  ReportSummary({
    required this.id,
    required this.reportCode,
    required this.nameAr,
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
    statusId: _asInt(json['status_id']),
    areaId: _asInt(json['area_id']),
    reportedAt: _asDate(json['reported_at']),
    statusCode: _asStringOrNull(json['status_code']),
    imageBeforeUrl: _asStringOrNull(json['image_before_url']),
    imageAfterUrl: _asStringOrNull(json['image_after_url']),
  );
}

/// =============================
/// Full Report Detail
/// =============================
class ReportDetail {
  final int id;
  final String reportCode;
  final int reportTypeId;
  final String nameAr;
  final String descriptionAr;
  final String? note;

  final String imageBeforeUrl;
  final String? imageAfterUrl;

  final int statusId;

  final DateTime reportedAt;

  final int? adoptedById;
  final int? adoptedByType;
  final String? adoptedByName;

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
    required this.descriptionAr,
    this.note,
    required this.imageBeforeUrl,
    this.imageAfterUrl,
    required this.statusId,
    required this.reportedAt,
    this.adoptedById,
    this.adoptedByType,
    this.adoptedByName,
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
    descriptionAr: _asString(json['description_ar']),
    note: _asStringOrNull(json['note']),
    imageBeforeUrl: _asString(json['image_before_url']),
    imageAfterUrl: _asStringOrNull(json['image_after_url']),
    statusId: _asInt(json['status_id']),
    reportedAt: _asDate(json['reported_at']),
    adoptedById: _asIntOrNull(json['adopted_by_id']),
    adoptedByType: _asIntOrNull(json['adopted_by_type']),
    adoptedByName: _asStringOrNull(json['adopted_by_name']),
    governmentId: _asInt(json['government_id']),
    districtId: _asInt(json['district_id']),
    areaId: _asInt(json['area_id']),
    locationId: _asInt(json['location_id']),
    userId: _asIntOrNull(json['user_id']),
    reportedByName: _asStringOrNull(json['reported_by_name']),
    createdAt: _asDate(json['created_at']),
    updatedAt: _asDate(json['updated_at']),
  );
}

/// =============================
/// Helpers
/// =============================
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.parse(v);
  throw Exception("Invalid int: $v");
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  return _asInt(v);
}

String _asString(dynamic v) => v?.toString() ?? "";

String? _asStringOrNull(dynamic v) => v?.toString();

DateTime _asDate(dynamic v) {
  if (v is String) return DateTime.parse(v);
  if (v is DateTime) return v;
  throw Exception("Invalid Date: $v");
}
