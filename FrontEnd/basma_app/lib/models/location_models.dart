class Government {
  final int id;
  final String nameAr;

  Government({required this.id, required this.nameAr});

  factory Government.fromJson(Map<String, dynamic> j) =>
      Government(id: _asInt(j['id']), nameAr: _asString(j['name_ar']));
}

class District {
  final int id;
  final int governmentId;
  final String nameAr;

  District({
    required this.id,
    required this.governmentId,
    required this.nameAr,
  });

  factory District.fromJson(Map<String, dynamic> j) => District(
    id: _asInt(j['id']),
    governmentId: _asInt(j['government_id']),
    nameAr: _asString(j['name_ar']),
  );
}

class Area {
  final int id;
  final int districtId;
  final String nameAr;
  final String nameEn;

  Area({
    required this.id,
    required this.districtId,
    required this.nameAr,
    required this.nameEn,
  });

  factory Area.fromJson(Map<String, dynamic> j) => Area(
    id: _asInt(j['id']),
    districtId: _asInt(j['district_id']),
    nameAr: _asString(j['name_ar']),
    nameEn: _asString(j['name_en']),
  );
}

class LocationModel {
  final int id;
  final int areaId;
  final String nameAr;
  final double? lon;
  final double? lat;

  LocationModel({
    required this.id,
    required this.areaId,
    required this.nameAr,
    this.lon,
    this.lat,
  });

  factory LocationModel.fromJson(Map<String, dynamic> j) => LocationModel(
    id: _asInt(j['id']),
    areaId: _asInt(j['area_id']),
    nameAr: _asString(j['name_ar']),
    lon: _asDoubleOrNull(j['longitude']),
    lat: _asDoubleOrNull(j['latitude']),
  );
}

/// ---- Helpers ----
int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is String) return int.parse(v);
  throw ArgumentError('Expected int, got $v');
}

String _asString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String && v.trim().isNotEmpty) {
    return double.tryParse(v);
  }
  return null;
}
