// lib/models/initiative_models.dart

class Initiative {
  final int id;
  final String nameAr;
  final String nameEn;
  final String mobileNumber;
  final String? logoUrl;
  final String? joinFormLink;
  final int membersCount;
  final int reportsCompletedCount;

  Initiative({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.mobileNumber,
    this.logoUrl,
    this.joinFormLink,
    required this.membersCount,
    required this.reportsCompletedCount,
  });

  factory Initiative.fromJson(Map<String, dynamic> j) {
    return Initiative(
      id: j["id"],
      nameAr: j["name_ar"] ?? "",
      nameEn: j["name_en"] ?? "",
      mobileNumber: j["mobile_number"] ?? "",
      logoUrl: j["logo_url"],
      joinFormLink: j["join_form_link"],
      membersCount: j["members_count"] ?? 0,
      reportsCompletedCount: j["reports_completed_count"] ?? 0,
    );
  }
}
