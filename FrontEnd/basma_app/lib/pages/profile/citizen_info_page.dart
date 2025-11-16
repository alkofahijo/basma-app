// lib/pages/profile/citizen_info_page.dart

import 'package:flutter/material.dart';

import 'package:basma_app/models/citizen_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';

const Color _primaryColor = Color(0xFF008000);
const Color _pageBackground = Color(0xFFEFF1F1);

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
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final citizen = await ApiService.getCitizen(widget.citizenId);
      if (!mounted) return;
      setState(() {
        _citizen = citizen;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر تحميل بيانات المواطن';
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
          backgroundColor: _primaryColor,
          elevation: 0,
          title: const Text(
            "بيانات المواطن",
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
              : _err != null || _citizen == null
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
                      _buildHeader(_citizen!),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildStatsRow(_citizen!),
                            const SizedBox(height: 16),
                            _buildInfoSection(_citizen!),
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
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 97, 102, 97).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 64,
              color: Color.fromARGB(255, 47, 50, 47),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.nameAr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
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
            color: _primaryColor,
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
              children: const [
                Icon(Icons.info_outline, size: 18, color: _primaryColor),
                SizedBox(width: 6),
                Text(
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
