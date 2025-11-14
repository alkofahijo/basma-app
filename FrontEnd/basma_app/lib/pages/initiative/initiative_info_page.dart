import 'package:flutter/material.dart';
import 'package:basma_app/models/initiative_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:basma_app/widgets/loading_center.dart';

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
    try {
      final i = await ApiService.getInitiative(widget.initiativeId);
      setState(() {
        _initiative = i;
        _loading = false;
        _err = null;
      });
    } catch (e) {
      setState(() {
        _err = 'تعذّر تحميل بيانات المبادرة';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingCenter();

    if (_err != null || _initiative == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(_err ?? "حدث خطأ")),
        ),
      );
    }

    final i = _initiative!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          title: const Text("بيانات المبادرة"),
          elevation: 0,
          backgroundColor: Colors.teal.shade600,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(i),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatsRow(i),
                      const SizedBox(height: 16),
                      _buildInfoSection(i),
                      const SizedBox(height: 16),
                      if (i.joinFormLink != null &&
                          i.joinFormLink!.trim().isNotEmpty)
                        _buildJoinSection(i.joinFormLink!),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.teal.shade600, Colors.teal.shade400],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          children: [
            // Logo / Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: i.logoUrl != null && i.logoUrl!.isNotEmpty
                    ? NetworkImageViewer(url: i.logoUrl!, height: 70)
                    : Icon(
                        Icons.volunteer_activism,
                        size: 36,
                        color: Colors.white.withOpacity(0.9),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.nameAr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (i.nameEn.isNotEmpty)
                    Text(
                      i.nameEn,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_in_talk,
                        size: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        i.mobileNumber,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Initiative i) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.groups_rounded,
            title: "عدد الأعضاء",
            value: "${i.membersCount}",
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.done_all_rounded,
            title: "البلاغات المنجزة",
            value: "${i.reportsCompletedCount}",
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
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
                color: color.withOpacity(0.12),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                const Text(
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  size: 18,
                  color: Colors.teal,
                ),
                const SizedBox(width: 6),
                const Text(
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
            GestureDetector(
              onTap: () {
                // لو حبيت تفتح الرابط باستخدام url_launcher مستقبلاً
                // launchUrl(Uri.parse(link));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.teal,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
