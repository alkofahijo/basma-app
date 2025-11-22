// lib/pages/profile/profile_page.dart

import 'package:basma_app/config/base_url.dart';
import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/pages/profile/edit_account_page.dart';
import 'package:basma_app/pages/profile/change_password_page.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// لعرض الصورة مع إمكانية التكبير
import 'package:basma_app/pages/reports/history/widgets/zoomable_image.dart';

// لفتح الروابط (رابط نموذج الانضمام / موقع الجهة)
import 'package:url_launcher/url_launcher.dart';

const Color _pageBackground = Color(0xFFEFF1F1);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _err;
  Account? _account;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }

  String? _resolveLogoUrl(String? raw) {
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

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final user = await AuthService.currentUser();

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _err = "الرجاء تسجيل الدخول من جديد.";
          _loading = false;
        });
        return;
      }

      final String type = (user["type"] ?? "").toString().trim();
      if (type != "account") {
        if (!mounted) return;
        setState(() {
          _err = "نوع الحساب غير مدعوم، يرجى إعادة تسجيل الدخول.";
          _loading = false;
        });
        return;
      }

      final accountId = _parseInt(user["account_id"]);
      if (accountId == null) {
        if (!mounted) return;
        setState(() {
          _err = "تعذّر تحديد هوية الحساب، يرجى إعادة تسجيل الدخول.";
          _loading = false;
        });
        return;
      }

      final acc = await ApiService.getAccount(accountId);
      if (!mounted) return;
      setState(() {
        _account = acc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = "تعذّر تحميل بيانات الملف الشخصي.\n$e";
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await AuthService.logout();
      Get.offAll(() => const LandingPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_loading) {
      bodyContent = const LoadingCenter();
    } else if (_err != null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _err!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadProfile,
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
    } else if (_account != null) {
      bodyContent = _buildAccountProfile(_account!);
    } else {
      bodyContent = const Center(
        child: Text("لم يتم العثور على بيانات الحساب."),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: bodyContent,
        bottomNavigationBar: const BasmaBottomNavPage(currentIndex: 3),
      ),
    );
  }

  // ============================================================
  // ACCOUNT PROFILE
  // ============================================================

  Widget _buildAccountProfile(Account a) {
    return Container(
      color: _pageBackground,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildAccountHeader(a),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _buildAccountInfoSection(a),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== Header (الصورة + الاسم + Chips) ======================

  Widget _buildAccountHeader(Account a) {
    final resolvedLogoUrl = _resolveLogoUrl(a.logoUrl);

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
              Container(
                width: 110,
                height: 110,
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
                  borderRadius: BorderRadius.circular(55),
                  child: resolvedLogoUrl != null
                      ? ZoomableImage(imageUrl: resolvedLogoUrl)
                      : const Icon(
                          Icons.account_balance,
                          size: 64,
                          color: Color.fromARGB(255, 47, 50, 47),
                        ),
                ),
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

  // ======================= تفاصيل الحساب + الأزرار =======================

  Widget _buildAccountInfoSection(Account a) {
    final String? joinLink = a.joinFormLink?.trim().isNotEmpty == true
        ? a.joinFormLink!.trim()
        : null;

    // showDetails هي bool جاهزة من الموديل
    final bool isPublicDetails = a.showDetails;
    final String visibilityText = isPublicDetails
        ? "تفاصيل الحساب ظاهرة للعامة"
        : "تفاصيل الحساب غير ظاهرة للعامة";

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                    "تفاصيل الحساب",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 16),

            _iconInfoRow(
              icon: Icons.badge_outlined,
              label: "الاسم بالعربية",
              value: a.nameAr,
            ),
            _iconInfoRow(
              icon: Icons.translate,
              label: "الاسم بالإنجليزية",
              value: a.nameEn?.trim().isNotEmpty == true
                  ? a.nameEn!.trim()
                  : "---",
            ),
            _iconInfoRow(
              icon: Icons.phone,
              label: "رقم الهاتف",
              value: a.mobileNumber,
            ),
            _iconInfoRow(
              icon: Icons.done_all_rounded,
              label: "عدد البلاغات المنجزة",
              value: a.reportsCompletedCount.toString(),
            ),
            if (a.createdAt != null)
              _iconInfoRow(
                icon: Icons.calendar_today_outlined,
                label: "تاريخ إنشاء الحساب",
                value: _formatDateTime(a.createdAt!),
              ),

            // حالة ظهور تفاصيل الحساب
            _iconInfoRow(
              icon: isPublicDetails ? Icons.visibility : Icons.visibility_off,
              label: "حالة ظهور تفاصيل الحساب",
              value: visibilityText,
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

            const SizedBox(height: 16),
            const Divider(height: 18),
            const SizedBox(height: 8),

            // ================================
            // الأزرار الأخيرة (RTL + تصميم)
            // ================================

            // زر تعديل الحساب
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_account == null) return;
                  final updated = await Navigator.push<Account?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditAccountPage(account: _account!),
                    ),
                  );
                  if (updated != null && mounted) {
                    setState(() {
                      _account = updated;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("تعديل بيانات الحساب", style: TextStyle(fontSize: 15)),
                    SizedBox(width: 8),
                    Icon(Icons.edit, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // زر تغيير كلمة المرور
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  );
                  if (changed == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تم تغيير كلمة المرور بنجاح."),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor.withValues(alpha: 0.95),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("تغيير كلمة المرور", style: TextStyle(fontSize: 15)),
                    SizedBox(width: 8),
                    Icon(Icons.lock_reset, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // زر تسجيل الخروج
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("تسجيل الخروج", style: TextStyle(fontSize: 15)),
                    SizedBox(width: 8),
                    Icon(Icons.logout, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
