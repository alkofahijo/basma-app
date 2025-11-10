class Government {
  final int id;
  final String nameAr;
  final String nameEn;
  Government({required this.id, required this.nameAr, required this.nameEn});
  factory Government.fromJson(Map<String, dynamic> j) =>
      Government(id: j['id'], nameAr: j['name_ar'], nameEn: j['name_en']);
}

class District {
  final int id;
  final int governmentId;
  final String nameAr;
  final String nameEn;
  District({
    required this.id,
    required this.governmentId,
    required this.nameAr,
    required this.nameEn,
  });
  factory District.fromJson(Map<String, dynamic> j) => District(
    id: j['id'],
    governmentId: j['government_id'],
    nameAr: j['name_ar'],
    nameEn: j['name_en'],
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
    id: j['id'],
    districtId: j['district_id'],
    nameAr: j['name_ar'],
    nameEn: j['name_en'],
  );
}

class LocationModel {
  final int id;
  final int areaId;
  final String nameAr;
  final String nameEn;
  final double? lon;
  final double? lat;
  LocationModel({
    required this.id,
    required this.areaId,
    required this.nameAr,
    required this.nameEn,
    this.lon,
    this.lat,
  });
  factory LocationModel.fromJson(Map<String, dynamic> j) => LocationModel(
    id: j['id'],
    areaId: j['area_id'],
    nameAr: j['name_ar'],
    nameEn: j['name_en'],
    lon: (j['longitude'] as num?)?.toDouble(),
    lat: (j['latitude'] as num?)?.toDouble(),
  );
}
