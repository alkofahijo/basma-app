// lib/pages/profile/account_info_page.dart

import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
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
        body: SafeArea(
          child: _loading
              ? const LoadingCenter()
              : _err != null || _account == null
              ? Center(
                  child: Text(
                    _err ?? "حدث خطأ غير متوقع",
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildHeader(_account!),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildStatsRow(_account!),
                            const SizedBox(height: 16),
                            _buildInfoSection(_account!),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ====================== Header (الصورة + الاسم) ======================

  Widget _buildHeader(Account a) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
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
              child: a.logoUrl != null && a.logoUrl!.isNotEmpty
                  ? NetworkImageViewer(url: a.logoUrl!, height: 110)
                  : const Icon(
                      Icons.apartment,
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
        ],
      ),
    );
  }

  // ================ بطاقة إحصائية للبلاغات المنجزة =================

  Widget _buildStatsRow(Account a) {
    return _buildStatCard(
      icon: Icons.done_all_rounded,
      title: "البلاغات المنجزة",
      value: "${a.reportsCompletedCount}",
      color: kPrimaryColor,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
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
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
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

  // ===================== تفاصيل الجهة (الأعمدة المطلوبة) =====================

  Widget _buildInfoSection(Account a) {
    final bool canShowDetails = a.showDetails;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                SizedBox(width: 6),
                Text(
                  "تفاصيل الجهة",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

            // 1) الاسم بالعربية
            InfoRow(label: "الاسم بالعربية", value: a.nameAr),

            // 2) الاسم بالإنجليزية
            InfoRow(label: "الاسم بالإنجليزية", value: a.nameEn ?? "غير متوفر"),

            // 3) نوع الجهة
            InfoRow(
              label: "نوع الجهة",
              value: a.accountTypeNameAr ?? "غير متوفر",
            ),

            // 4) المحافظة
            InfoRow(
              label: "المحافظة",
              value: a.governmentNameAr ?? "غير متوفر",
            ),

            // 5) رقم الهاتف (لو show_details=true فقط)
            if (canShowDetails)
              InfoRow(label: "رقم الهاتف", value: a.mobileNumber),

            // 6) رابط نموذج الانضمام
            if (a.joinFormLink != null && a.joinFormLink!.trim().isNotEmpty)
              InfoRow(label: "رابط نموذج الانضمام", value: a.joinFormLink!),

            // 7) عدد البلاغات المنجزة
            InfoRow(
              label: "عدد البلاغات المنجزة",
              value: "${a.reportsCompletedCount}",
            ),

            // 8) تاريخ الإنشاء
            InfoRow(
              label: "تاريخ إنشاء الجهة",
              value: _formatDateTime(a.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}
