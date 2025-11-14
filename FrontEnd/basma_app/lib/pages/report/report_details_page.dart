// lib/pages/report/report_details_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/pages/auth/login_page.dart';
import 'package:basma_app/pages/citizen/citizen_info_page.dart';
import 'package:basma_app/pages/initiative/initiative_info_page.dart';
import 'package:basma_app/pages/report/complete_report_page.dart';
import 'package:basma_app/pages/report/solve_report_dialog.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';

import 'widgets/report_image_section.dart';
import '../shared/view_report_location_page.dart';

String _formatDateTime(DateTime? dt) {
  if (dt == null) return "غير متوفر";

  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');

  return "$y-$m-$d $hh:$mm";
}

class _StatusStyle {
  final Color bg;
  final Color textColor;
  final String label;

  _StatusStyle({
    required this.bg,
    required this.textColor,
    required this.label,
  });
}

class ReportDetailsPage extends StatefulWidget {
  final int reportId;

  const ReportDetailsPage({super.key, required this.reportId});

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  ReportDetail? _report;
  String? _error;
  bool _loading = true;

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString("token");
      final loggedIn = token != null && token.isNotEmpty;

      setState(() {
        _isLoggedIn = loggedIn;
      });

      await _load();
    } catch (_) {
      setState(() {
        _isLoggedIn = false;
      });
      await _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getReport(widget.reportId);
      setState(() {
        _report = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل البلاغ';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingCenter();

    if (_error != null || _report == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(_error ?? 'حدث خطأ غير متوقع')),
        ),
      );
    }

    final rep = _report!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(rep.nameAr)),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(rep),
                const SizedBox(height: 16),
                _buildBasicInfoSection(rep),
                const SizedBox(height: 16),
                _buildLocationSection(rep),
                const SizedBox(height: 16),
                _buildImagesSection(rep),
                const SizedBox(height: 16),
                _buildReportingSection(rep),
                if (rep.statusId == 4 || rep.statusId == 3) ...[
                  const SizedBox(height: 16),
                  _buildSolvedBySection(rep),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(rep),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ======================= UI Helpers =======================

  Widget _buildHeader(ReportDetail rep) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Colors.teal.shade400, Colors.teal.shade700],
                ),
              ),
              child: const Icon(
                Icons.report_problem_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rep.nameAr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "رمز البلاغ: ${rep.reportCode}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(rep),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ReportDetail rep) {
    final style = _mapStatus(rep.statusId, rep.statusNameAr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _StatusStyle _mapStatus(int statusId, String? statusNameAr) {
    switch (statusId) {
      case 1:
        return _StatusStyle(
          bg: Colors.grey.shade200,
          textColor: Colors.grey.shade800,
          label: statusNameAr ?? "قيد المراجعة",
        );
      case 2:
        return _StatusStyle(
          bg: Colors.red.shade50,
          textColor: Colors.red.shade700,
          label: statusNameAr ?? "جديد",
        );
      case 3:
        return _StatusStyle(
          bg: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
          label: statusNameAr ?? "قيد التنفيذ",
        );
      case 4:
        return _StatusStyle(
          bg: Colors.green.shade50,
          textColor: Colors.green.shade700,
          label: statusNameAr ?? "مكتمل",
        );
      default:
        return _StatusStyle(
          bg: Colors.grey.shade200,
          textColor: Colors.grey.shade800,
          label: statusNameAr ?? "غير معروف",
        );
    }
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
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
                const Icon(Icons.circle, size: 8, color: Colors.teal),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // ----- القسم: معلومات أساسية -----
  Widget _buildBasicInfoSection(ReportDetail rep) {
    return _buildSectionCard(
      title: "معلومات البلاغ",
      subtitle: "تفاصيل عامة عن نوع البلاغ ووصفه.",
      children: [
        InfoRow(
          label: "نوع التشوه البصري",
          value: rep.reportTypeNameAr ?? "غير محدد",
        ),
        InfoRow(label: "الوصف", value: rep.descriptionAr),
        if (rep.note != null && rep.note!.isNotEmpty)
          InfoRow(label: "ملاحظات إضافية", value: rep.note!),
      ],
    );
  }

  // ----- القسم: الموقع + mini-map + زر الانتقال -----
  Widget _buildLocationSection(ReportDetail rep) {
    final hasCoordinates =
        (rep.locationLatitude != null && rep.locationLongitude != null);

    return _buildSectionCard(
      title: "الموقع الجغرافي",
      subtitle: "بيانات المحافظة، اللواء، المنطقة والموقع.",
      children: [
        InfoRow(
          label: "المحافظة",
          value: rep.governmentNameAr ?? "${rep.governmentId}",
        ),
        InfoRow(
          label: "اللواء",
          value: rep.districtNameAr ?? "${rep.districtId}",
        ),
        InfoRow(label: "المنطقة", value: rep.areaNameAr ?? "${rep.areaId}"),
        InfoRow(
          label: "اسم الموقع",
          value: rep.locationNameAr ?? "${rep.locationId}",
        ),
        const SizedBox(height: 12),
        if (hasCoordinates)
          Column(
            children: [
              // ====== mini-map ======
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        rep.locationLatitude!,
                        rep.locationLongitude!,
                      ),
                      initialZoom: 15,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.basma_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              rep.locationLatitude!,
                              rep.locationLongitude!,
                            ),
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            // ✅ فقط أيقونة → لا Column → لا Overflow
                            child: const Icon(
                              Icons.location_on,
                              size: 36,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ViewReportLocationPage(
                          lat: rep.locationLatitude!,
                          lng: rep.locationLongitude!,
                          locationName: rep.locationNameAr,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, color: Colors.white),
                  label: const Text(
                    "عرض موقع البلاغ على الخريطة",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            "لا توجد إحداثيات محفوظة لهذا البلاغ.",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
      ],
    );
  }

  // ----- القسم: الصور -----
  Widget _buildImagesSection(ReportDetail rep) {
    return _buildSectionCard(
      title: "الصور",
      subtitle: "قبل وبعد معالجة المشكلة.",
      children: [
        const Text(
          "الصورة قبل:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ReportImageSection(title: "", rawUrl: rep.imageBeforeUrl),
        const SizedBox(height: 16),
        if (rep.imageAfterUrl != null && rep.imageAfterUrl!.isNotEmpty) ...[
          const Text(
            "الصورة بعد:",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ReportImageSection(title: "", rawUrl: rep.imageAfterUrl),
        ] else
          Text(
            "لم يتم رفع صورة بعد المعالجة حتى الآن.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
      ],
    );
  }

  // ----- القسم: بيانات التبليغ -----
  Widget _buildReportingSection(ReportDetail rep) {
    return _buildSectionCard(
      title: "بيانات التبليغ",
      subtitle: "متى تم التبليغ ومن قام بالتبليغ.",
      children: [
        InfoRow(label: "اسم المبلِّغ", value: rep.reportedByName ?? "غير محدد"),
        InfoRow(label: "تاريخ التبليغ", value: _formatDateTime(rep.reportedAt)),
      ],
    );
  }

  // ----- القسم: من قام بالحل -----
  Widget _buildSolvedBySection(ReportDetail rep) {
    final String name = rep.adoptedByName ?? "بيانات الجهة";
    final bool canNavigate =
        rep.adoptedById != null && rep.adoptedByType != null;

    Widget nameWidget = Text(
      name,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    );

    if (canNavigate) {
      nameWidget = GestureDetector(
        onTap: () {
          if (rep.adoptedByType == 1) {
            Get.to(() => CitizenInfoPage(citizenId: rep.adoptedById!));
          } else if (rep.adoptedByType == 2) {
            Get.to(() => InitiativeInfoPage(initiativeId: rep.adoptedById!));
          }
        },
        child: nameWidget,
      );
    }

    return _buildSectionCard(
      title: "الجهة المسؤولة",
      subtitle: "الجهة التي تبنّت حل المشكة  .",
      children: [
        const SizedBox(height: 6),
        if (rep.adoptedByType != null)
          InfoRow(
            label: "نوع الجهة التي تبنت حل المشكلة",
            value: rep.adoptedByType == 1 ? "مواطن" : "مبادرة تطوعية",
          ),
        const SizedBox(height: 8),
        nameWidget,
        const SizedBox(height: 8),
      ],
    );
  }

  // ======================= أزرار الإجراءات =======================

  Widget _buildActionButtons(ReportDetail rep) {
    if (!_isLoggedIn) {
      if (rep.statusId != 2) {
        return const SizedBox.shrink();
      }

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "لتتمكن من حل المشكلة، يرجى تسجيل الدخول أو إنشاء حساب كمواطن أو مبادرة.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => LoginPage());
                },
                icon: const Icon(Icons.login),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: const Text(
                  "تسجيل الدخول لحل المشكلة",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (rep.statusId) {
      case 2:
        return ElevatedButton.icon(
          onPressed: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (_) => SolveReportDialog(reportId: rep.id),
            );
            if (result == true) {
              _load();
            }
          },
          icon: const Icon(Icons.handshake_outlined),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          label: const Text(
            "تبنّي البلاغ وحل المشكلة",
            style: TextStyle(color: Colors.white),
          ),
        );

      case 3:
        return ElevatedButton.icon(
          onPressed: () async {
            final done = await Get.to(() => CompleteReportPage(report: rep));
            if (done == true) _load();
          },
          icon: const Icon(Icons.check_circle_outline),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          label: const Text(
            "إتمام الحل ورفع الصور",
            style: TextStyle(color: Colors.white),
          ),
        );

      case 4:
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
