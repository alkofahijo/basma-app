import 'dart:convert';

/// =====================================================
/// Helpers (Internal)
/// =====================================================

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

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String && v.trim().isNotEmpty) {
    return double.tryParse(v);
  }
  return null;
}

/// =====================================================
/// Report Lookups
/// =====================================================

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

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name_ar': nameAr};

  static List<ReportType> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => ReportType.fromJson(e as Map<String, dynamic>))
        .toList();
  }
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

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name_ar': nameAr};

  static List<ReportStatus> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => ReportStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// =====================================================
/// Report Summary (internal list)
/// =====================================================

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'report_code': reportCode,
    'name_ar': nameAr,
    'status_id': statusId,
    'area_id': areaId,
    'reported_at': reportedAt.toIso8601String(),
    'status_code': statusCode,
    'image_before_url': imageBeforeUrl,
    'image_after_url': imageAfterUrl,
  };

  static List<ReportSummary> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => ReportSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// =====================================================
/// Full Report Detail
/// =====================================================

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

  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  // أسماء عربية من الـ backend (JOIN)
  final String? reportTypeNameAr;
  final String? statusNameAr;
  final String? governmentNameAr;
  final String? districtNameAr;
  final String? areaNameAr;
  final String? locationNameAr;

  // 🔥 جديد: إحداثيات الموقع
  final double? locationLongitude;
  final double? locationLatitude;

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
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.reportTypeNameAr,
    this.statusNameAr,
    this.governmentNameAr,
    this.districtNameAr,
    this.areaNameAr,
    this.locationNameAr,
    this.locationLongitude,
    this.locationLatitude,
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
    isActive: json['is_active'] == null
        ? true
        : (json['is_active'] is bool
              ? json['is_active'] as bool
              : json['is_active'].toString() == '1'),
    createdAt: _asDate(json['created_at']),
    updatedAt: _asDate(json['updated_at']),
    reportTypeNameAr: _asStringOrNull(json['report_type_name_ar']),
    statusNameAr: _asStringOrNull(json['status_name_ar']),
    governmentNameAr: _asStringOrNull(json['government_name_ar']),
    districtNameAr: _asStringOrNull(json['district_name_ar']),
    areaNameAr: _asStringOrNull(json['area_name_ar']),
    locationNameAr: _asStringOrNull(json['location_name_ar']),
    locationLongitude: _asDoubleOrNull(json['location_longitude']),
    locationLatitude: _asDoubleOrNull(json['location_latitude']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'report_code': reportCode,
    'report_type_id': reportTypeId,
    'name_ar': nameAr,
    'description_ar': descriptionAr,
    'note': note,
    'image_before_url': imageBeforeUrl,
    'image_after_url': imageAfterUrl,
    'status_id': statusId,
    'reported_at': reportedAt.toIso8601String(),
    'adopted_by_id': adoptedById,
    'adopted_by_type': adoptedByType,
    'adopted_by_name': adoptedByName,
    'government_id': governmentId,
    'district_id': districtId,
    'area_id': areaId,
    'location_id': locationId,
    'user_id': userId,
    'reported_by_name': reportedByName,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'report_type_name_ar': reportTypeNameAr,
    'status_name_ar': statusNameAr,
    'government_name_ar': governmentNameAr,
    'district_name_ar': districtNameAr,
    'area_name_ar': areaNameAr,
    'location_name_ar': locationNameAr,
    'location_longitude': locationLongitude,
    'location_latitude': locationLatitude,
  };
}

/// =====================================================
/// Public Report Summary (for guest UI)
/// =====================================================

class ReportPublicSummary {
  final int id;
  final String reportCode;
  final int reportTypeId;
  final String reportTypeCode;
  final String reportTypeNameAr;

  final String nameAr;
  final String? descriptionAr;

  final String? imageBeforeUrl;

  final int statusId;
  final String statusNameAr;
  final DateTime? reportedAt;

  final int? governmentId;
  final String? governmentNameAr;

  final int? districtId;
  final String? districtNameAr;

  final int? areaId;
  final String? areaNameAr;

  ReportPublicSummary({
    required this.id,
    required this.reportCode,
    required this.reportTypeId,
    required this.reportTypeCode,
    required this.reportTypeNameAr,
    required this.nameAr,
    this.descriptionAr,
    this.imageBeforeUrl,
    required this.statusId,
    required this.statusNameAr,
    this.reportedAt,
    this.governmentId,
    this.governmentNameAr,
    this.districtId,
    this.districtNameAr,
    this.areaId,
    this.areaNameAr,
  });

  factory ReportPublicSummary.fromJson(Map<String, dynamic> json) {
    return ReportPublicSummary(
      id: _asInt(json['id']),
      reportCode: _asString(json['report_code']),
      reportTypeId: _asInt(json['report_type_id']),
      reportTypeCode: _asString(json['report_type_code']),
      reportTypeNameAr: _asString(json['report_type_name_ar']),
      nameAr: _asString(json['name_ar']),
      descriptionAr: _asStringOrNull(json['description_ar']),
      imageBeforeUrl: _asStringOrNull(json['image_before_url']),
      statusId: _asInt(json['status_id']),
      statusNameAr: _asString(json['status_name_ar']),
      reportedAt: json['reported_at'] != null
          ? _asDate(json['reported_at'])
          : null,
      governmentId: _asIntOrNull(json['government_id']),
      governmentNameAr: _asStringOrNull(json['government_name_ar']),
      districtId: _asIntOrNull(json['district_id']),
      districtNameAr: _asStringOrNull(json['district_name_ar']),
      areaId: _asIntOrNull(json['area_id']),
      areaNameAr: _asStringOrNull(json['area_name_ar']),
    );
  }

  String? get typeNameAr => null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'report_code': reportCode,
    'report_type_id': reportTypeId,
    'report_type_code': reportTypeCode,
    'report_type_name_ar': reportTypeNameAr,
    'name_ar': nameAr,
    'description_ar': descriptionAr,
    'image_before_url': imageBeforeUrl,
    'status_id': statusId,
    'status_name_ar': statusNameAr,
    'reported_at': reportedAt?.toIso8601String(),
    'government_id': governmentId,
    'government_name_ar': governmentNameAr,
    'district_id': districtId,
    'district_name_ar': districtNameAr,
    'area_id': areaId,
    'area_name_ar': areaNameAr,
  };

  static List<ReportPublicSummary> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => ReportPublicSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// =====================================================
/// Simple filter models (governments / districts / areas)
/// =====================================================

class GovernmentOption {
  final int id;
  final String nameAr;

  GovernmentOption({required this.id, required this.nameAr});

  factory GovernmentOption.fromJson(Map<String, dynamic> json) {
    return GovernmentOption(
      id: _asInt(json['id']),
      nameAr: _asString(json['name_ar']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name_ar': nameAr};

  static List<GovernmentOption> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => GovernmentOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class DistrictOption {
  final int id;
  final String nameAr;

  DistrictOption({required this.id, required this.nameAr});

  factory DistrictOption.fromJson(Map<String, dynamic> json) {
    return DistrictOption(
      id: _asInt(json['id']),
      nameAr: _asString(json['name_ar']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name_ar': nameAr};

  static List<DistrictOption> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => DistrictOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class AreaOption {
  final int id;
  final String nameAr;

  AreaOption({required this.id, required this.nameAr});

  factory AreaOption.fromJson(Map<String, dynamic> json) {
    return AreaOption(
      id: _asInt(json['id']),
      nameAr: _asString(json['name_ar']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name_ar': nameAr};

  static List<AreaOption> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => AreaOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ReportTypeOption {
  final int id;
  final String code;
  final String nameAr;

  ReportTypeOption({
    required this.id,
    required this.code,
    required this.nameAr,
  });

  factory ReportTypeOption.fromJson(Map<String, dynamic> json) {
    return ReportTypeOption(
      id: _asInt(json['id']),
      code: _asString(json['code']),
      nameAr: _asString(json['name_ar']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name_ar': nameAr};

  static List<ReportTypeOption> listFromJson(String body) {
    final data = jsonDecode(body) as List<dynamic>;
    return data
        .map((e) => ReportTypeOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
