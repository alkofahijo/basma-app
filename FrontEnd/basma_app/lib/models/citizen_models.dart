// lib/models/citizen_models.dart

class Citizen {
  final int id;
  final String nameAr;
  final String nameEn;
  final String mobileNumber;
  final int reportsCompletedCount;

  Citizen({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.mobileNumber,
    required this.reportsCompletedCount,
  });

  factory Citizen.fromJson(Map<String, dynamic> j) {
    return Citizen(
      id: j["id"],
      nameAr: j["name_ar"] ?? "",
      nameEn: j["name_en"] ?? "",
      mobileNumber: j["mobile_number"] ?? "",
      reportsCompletedCount: j["reports_completed_count"] ?? 0,
    );
  }
}
