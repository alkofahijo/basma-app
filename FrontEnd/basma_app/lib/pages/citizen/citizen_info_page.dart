import 'package:flutter/material.dart';
import 'package:basma_app/models/citizen_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';

class CitizenInfoPage extends StatefulWidget {
  final int citizenId;

  const CitizenInfoPage({super.key, required this.citizenId});

  @override
  State<CitizenInfoPage> createState() => _CitizenInfoPageState();
}

class _CitizenInfoPageState extends State<CitizenInfoPage> {
  Citizen? _citizen;
  String? _err;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ApiService.getCitizen(widget.citizenId);
      setState(() {
        _citizen = c;
        _loading = false;
        _err = null;
      });
    } catch (e) {
      setState(() {
        _err = 'تعذّر تحميل بيانات المواطن';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingCenter();

    if (_err != null || _citizen == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(_err ?? "حدث خطأ")),
        ),
      );
    }

    final c = _citizen!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          title: const Text("بيانات المواطن"),
          elevation: 0,
          backgroundColor: Colors.teal.shade600,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(c),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatsRow(c),
                      const SizedBox(height: 16),
                      _buildInfoSection(c),
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

  Widget _buildHeader(Citizen c) {
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Row(
          children: [
            // Avatar دائرة
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 40,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nameAr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (c.nameEn.isNotEmpty)
                    Text(
                      c.nameEn,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.mobileNumber,
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

  Widget _buildStatsRow(Citizen c) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.verified_rounded,
            title: "البلاغات المنجزة",
            value: "${c.reportsCompletedCount}",
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

  Widget _buildInfoSection(Citizen c) {
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
                  "تفاصيل المواطن",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "معلومات أساسية حول المواطن المساهم في حل البلاغات.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            const Divider(height: 16),
            InfoRow(label: "الاسم بالعربية", value: c.nameAr),
            InfoRow(label: "الاسم بالإنجليزية", value: c.nameEn),
            InfoRow(label: "رقم الهاتف", value: c.mobileNumber),
          ],
        ),
      ),
    );
  }
}
