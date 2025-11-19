// lib/pages/profile/initiative_info_page.dart

import 'package:flutter/material.dart';

import 'package:basma_app/models/initiative_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/theme/app_colors.dart';

const Color _pageBackground = Color(0xFFEFF1F1);

class InitiativeInfoPage extends StatefulWidget {
  final int initiativeId;

  const InitiativeInfoPage({super.key, required this.initiativeId});

  @override
  State<InitiativeInfoPage> createState() => _InitiativeInfoPageState();
}

class _InitiativeInfoPageState extends State<InitiativeInfoPage> {
  Initiative? _initiative;
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
      final initiative = await ApiService.getInitiative(widget.initiativeId);
      if (!mounted) return;
      setState(() {
        _initiative = initiative;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر تحميل بيانات المبادرة';
        _loading = false;
      });
    }
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
            "بيانات المبادرة",
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
              : _err != null || _initiative == null
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
                      _buildHeader(_initiative!),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildStatsRow(_initiative!),
                            const SizedBox(height: 16),
                            _buildInfoSection(_initiative!),
                            const SizedBox(height: 16),
                            if (_initiative!.joinFormLink != null &&
                                _initiative!.joinFormLink!.trim().isNotEmpty)
                              _buildJoinSection(_initiative!.joinFormLink!),
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

  // ======================= UI PARTS =======================

  Widget _buildHeader(Initiative i) {
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
              child: i.logoUrl != null && i.logoUrl!.isNotEmpty
                  ? NetworkImageViewer(url: i.logoUrl!, height: 110)
                  : const Icon(
                      Icons.volunteer_activism,
                      size: 64,
                      color: Color.fromARGB(255, 47, 50, 47),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            i.nameAr,
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

  Widget _buildStatsRow(Initiative i) {
    return _buildStatCard(
      icon: Icons.done_all_rounded,
      title: "البلاغات المنجزة",
      value: "${i.reportsCompletedCount}",
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

  Widget _buildInfoSection(Initiative i) {
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
                  "تفاصيل المبادرة",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "معلومات أساسية حول المبادرة وقنوات التواصل.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            const Divider(height: 16),
            InfoRow(label: "اسم المبادرة", value: i.nameAr),
            InfoRow(label: "الاسم بالإنجليزية", value: i.nameEn),
            InfoRow(label: "رقم الهاتف", value: i.mobileNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinSection(String link) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person_add_alt_1, size: 18, color: kPrimaryColor),
                SizedBox(width: 6),
                Text(
                  "الانضمام إلى المبادرة",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "يمكنك التقدّم للانضمام للمبادرة من خلال الرابط التالي:",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kPrimaryColor,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
