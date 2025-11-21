// lib/models/account_models.dart

class AccountTypeOption {
  final int id;
  final String code;
  final String nameAr;

  AccountTypeOption({
    required this.id,
    required this.code,
    required this.nameAr,
  });

  factory AccountTypeOption.fromJson(Map<String, dynamic> json) {
    return AccountTypeOption(
      id: json['id'] as int,
      code: json['code'] as String,
      nameAr: json['name_ar'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'code': code, 'name_ar': nameAr};

  static List<AccountTypeOption> listFromJson(List<dynamic> data) {
    return data
        .map((e) => AccountTypeOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class Account {
  final int id;
  final String nameAr;
  final String? nameEn;
  final String mobileNumber;
  final int governmentId;
  final int accountTypeId;
  final int reportsCompletedCount;
  final String? joinFormLink;
  final String? logoUrl;

  /// أسماء جاهزة من الـ backend (JOIN / flatten)
  final String? accountTypeNameAr;
  final String? governmentNameAr;

  /// حالات إضافية من الـ backend لو احتجتها لاحقاً
  final bool isActive;
  final bool showDetails;

  Account({
    required this.id,
    required this.nameAr,
    this.nameEn,
    required this.mobileNumber,
    required this.governmentId,
    required this.accountTypeId,
    required this.reportsCompletedCount,
    this.joinFormLink,
    this.logoUrl,
    this.accountTypeNameAr,
    this.governmentNameAr,
    this.isActive = true,
    this.showDetails = true,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    // نحاول استخراج اسم نوع الحساب / اسم المحافظة سواء كانت مفصولة أو ضمن كائن
    String? extractName(
      Map<String, dynamic> j,
      String flatKey,
      String nestedKey,
    ) {
      if (j[flatKey] is String) return j[flatKey] as String;
      final nested = j[nestedKey];
      if (nested is Map && nested['name_ar'] is String) {
        return nested['name_ar'] as String;
      }
      return null;
    }

    return Account(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String?,
      mobileNumber: json['mobile_number'] as String,
      governmentId: json['government_id'] as int,
      accountTypeId: json['account_type_id'] as int,
      reportsCompletedCount: (json['reports_completed_count'] as num? ?? 0)
          .toInt(),
      joinFormLink: json['join_form_link'] as String?,
      logoUrl: json['logo_url'] as String?,

      accountTypeNameAr: extractName(
        json,
        'account_type_name_ar',
        'account_type',
      ),
      governmentNameAr: extractName(json, 'government_name_ar', 'government'),

      isActive: (() {
        final v = json['is_active'];
        if (v == null) return true;
        if (v is bool) return v;
        return v.toString() == '1';
      })(),
      showDetails: (() {
        final v = json['show_details'];
        if (v == null) return true;
        if (v is bool) return v;
        return v.toString() == '1';
      })(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_ar': nameAr,
    'name_en': nameEn,
    'mobile_number': mobileNumber,
    'government_id': governmentId,
    'account_type_id': accountTypeId,
    'reports_completed_count': reportsCompletedCount,
    'join_form_link': joinFormLink,
    'logo_url': logoUrl,
    'account_type_name_ar': accountTypeNameAr,
    'government_name_ar': governmentNameAr,
    'is_active': isActive ? 1 : 0,
    'show_details': showDetails ? 1 : 0,
  };
}
