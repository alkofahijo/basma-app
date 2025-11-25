// lib/pages/profile/account_info_page.dart

import 'package:basma_app/config/base_url.dart';
import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

const Color _pageBackground = Color(0xFFEFF1F1);

class AccountInfoPage extends StatefulWidget {
  final int accountId;

  const AccountInfoPage({super.key, required this.accountId});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  Account? _account;
  String? _err;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ========= Helpers =========

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kBaseUrl$raw';
    return '$kBaseUrl/$raw';
  }

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) return;

    final String normalized = url.startsWith('http')
        ? url.trim()
        : 'https://${url.trim()}';

    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final acc = await ApiService.getAccount(widget.accountId);
      if (!mounted) return;
      setState(() {
        _account = acc;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر تحميل بيانات الجهة';
        _loading = false;
      });
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "غير متوفر";
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }

  // ========= Helper: سطر معلومات مع أيقونة صغيرة =========

  Widget _iconInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const LoadingCenter();
    } else if (_err != null || _account == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _err ?? "حدث خطأ غير متوقع",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("إعادة المحاولة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = _buildAccountView(_account!);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: const Text(
            "بيانات الجهة",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(child: body),
      ),
    );
  }

  // ========================= ACCOUNT VIEW =========================

  Widget _buildAccountView(Account a) {
    return Container(
      color: _pageBackground,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(a),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _buildStatsRow(a),
                  const SizedBox(height: 16),
                  _buildInfoSection(a),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== Header (الصورة + الاسم + Chips) ======================

  Widget _buildHeader(Account a) {
    final imageUrl = _resolveImageUrl(a.logoUrl);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            children: [
              Builder(
                builder: (ctx) {
                  final avatarSize = math.min(
                    110.0,
                    MediaQuery.of(ctx).size.width * 0.28,
                  );
                  return Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        97,
                        102,
                        97,
                      ).withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(avatarSize / 2),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? NetworkImageViewer(
                              url: imageUrl,
                              height: avatarSize,
                            )
                          : Icon(
                              Icons.apartment,
                              size: avatarSize * 0.58,
                              color: const Color.fromARGB(255, 47, 50, 47),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                a.nameAr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Chips للحالة ونوع الجهة والمحافظة والخصوصية
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  if (a.accountTypeNameAr != null &&
                      a.accountTypeNameAr!.isNotEmpty)
                    Chip(
                      label: Text(
                        a.accountTypeNameAr!,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      backgroundColor: const Color(0xFFEAF5FF),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (a.governmentNameAr != null &&
                      a.governmentNameAr!.isNotEmpty)
                    Chip(
                      label: Text(
                        a.governmentNameAr!,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      backgroundColor: const Color(0xFFEFF7EB),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================ بطاقة إحصائية للبلاغات المنجزة =================

  Widget _buildStatsRow(Account a) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.done_all_rounded,
                color: kPrimaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "البلاغات المنجزة بواسطة هذه الجهة",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${a.reportsCompletedCount}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== تفاصيل الجهة =====================

  Widget _buildInfoSection(Account a) {
    final bool canShowDetails = a.showDetails;
    final String? joinLink = a.joinFormLink?.trim().isNotEmpty == true
        ? a.joinFormLink!.trim()
        : null;

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "تفاصيل الجهة",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "معلومات أساسية حول الجهة المساهمة في حل البلاغات.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            const Divider(height: 16),

            // الاسم بالعربية
            _iconInfoRow(
              icon: Icons.badge_outlined,
              label: "الاسم بالعربية",
              value: a.nameAr,
            ),

            // الاسم بالإنجليزية
            _iconInfoRow(
              icon: Icons.translate,
              label: "الاسم بالإنجليزية",
              value: a.nameEn?.trim().isNotEmpty == true
                  ? a.nameEn!.trim()
                  : "غير متوفر",
            ),

            // نوع الجهة
            _iconInfoRow(
              icon: Icons.category_outlined,
              label: "نوع الجهة",
              value: a.accountTypeNameAr ?? "غير متوفر",
            ),

            // المحافظة
            _iconInfoRow(
              icon: Icons.location_city_outlined,
              label: "المحافظة",
              value: a.governmentNameAr ?? "غير متوفر",
            ),

            // رقم الهاتف (فقط إذا التفاصيل ظاهرة للعامة)
            if (canShowDetails)
              _iconInfoRow(
                icon: Icons.phone,
                label: "رقم الهاتف",
                value: a.mobileNumber,
              ),

            // رابط نموذج الانضمام / موقع الجهة
            if (joinLink != null) ...[
              const SizedBox(height: 10),
              const Text(
                "رابط نموذج الانضمام / موقع أو صفحة الجهة",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _openUrl(joinLink),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        joinLink,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // تاريخ الانضمام
            _iconInfoRow(
              icon: Icons.calendar_today_outlined,
              label: "تاريخ الانضمام",
              value: _formatDateTime(a.createdAt),
            ),

            const SizedBox(height: 4),

            // ملاحظة عن الخصوصية لو التفاصيل مخفية
            if (!canShowDetails)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "صاحب الحساب لم يفعّل عرض بيانات التواصل للعامة.",
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
