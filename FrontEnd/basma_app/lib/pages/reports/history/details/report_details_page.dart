// lib/pages/report/report_details_page.dart

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/pages/auth/Login/login_page.dart';
import 'package:basma_app/pages/profile/citizen_info_page.dart';
import 'package:basma_app/pages/profile/initiative_info_page.dart';
import 'package:basma_app/pages/reports/history/details/complete_report_page.dart';
import 'package:basma_app/pages/reports/history/widgets/adopt_report_dialog.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/report_image_section.dart';
import '../widgets/view_location_page.dart';

const Color _primaryColor = Color(0xFF008000);
const Color _pageBackground = Color(0xFFEFF1F1);

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
  Map<String, dynamic>? _currentUser;

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

      if (loggedIn) {
        _currentUser = await AuthService.currentUser();
      } else {
        _currentUser = null;
      }

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
      });
    } catch (_) {
      setState(() {
        _error = 'تعذّر تحميل البلاغ';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        systemOverlayStyle: AppSystemUi.green,
        title: const Text(
          "تفاصيل البلاغ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingCenter()
            : (_error != null || _report == null)
            ? Center(
                child: Text(
                  _error ?? 'حدث خطأ غير متوقع',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(_report!),
                    const SizedBox(height: 16),
                    _buildBasicInfoSection(_report!),
                    const SizedBox(height: 16),
                    _buildImagesSection(_report!),
                    const SizedBox(height: 16),
                    _buildLocationSection(_report!),
                    const SizedBox(height: 16),
                    _buildReportingSection(_report!),
                    if (_report!.statusId == 3 || _report!.statusId == 4) ...[
                      const SizedBox(height: 16),
                      _buildSolvedBySection(_report!),
                    ],
                    const SizedBox(height: 24),
                    _buildActionButtons(_report!),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ======================= UI Helpers =======================

  Widget _buildHeader(ReportDetail rep) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color.fromARGB(255, 38, 166, 51), _primaryColor],
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
                    _formatDateTime(rep.reportedAt),
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
          bg: const Color.fromARGB(255, 188, 215, 243),
          textColor: const Color.fromARGB(255, 4, 42, 129),
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
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _primaryColor.withOpacity(0.08),
              ),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 8),
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
        rep.locationLatitude != null && rep.locationLongitude != null;

    return _buildSectionCard(
      title: "الموقع الجغرافي",
      subtitle: "بيانات المحافظة، اللواء، المنطقة والموقع.",
      children: [
        Row(
          children: [
            Expanded(
              child: InfoRow(
                label: "المحافظة",
                value: rep.governmentNameAr ?? "${rep.governmentId}",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoRow(
                label: "اللواء",
                value: rep.districtNameAr ?? "${rep.districtId}",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InfoRow(
                label: "المنطقة",
                value: rep.areaNameAr ?? "${rep.areaId}",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InfoRow(
                label: "اسم الموقع",
                value: rep.locationNameAr ?? "${rep.locationId}",
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasCoordinates)
          Column(
            children: [
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
                            child: const Icon(
                              Icons.location_on,
                              size: 36,
                              color: Color.fromARGB(255, 4, 118, 36),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewReportLocationPage(
                          lat: rep.locationLatitude!,
                          lng: rep.locationLongitude!,
                          locationName: rep.locationNameAr,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text(
                    "عرض الموقع على الخريطة",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
      title: "صورة البلاغ",
      subtitle: "قبل وبعد معالجة المشكلة.",
      children: [
        const Text(
          "الصورة قبل:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        ReportImageSection(title: "", rawUrl: rep.imageBeforeUrl),
        const SizedBox(height: 16),
        if (rep.imageAfterUrl != null && rep.imageAfterUrl!.isNotEmpty) ...[
          const Text(
            "الصورة بعد:",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          ReportImageSection(title: "", rawUrl: rep.imageAfterUrl),
        ],
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
      subtitle: "الجهة التي تبنّت حل المشكلة.",
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
        elevation: 2,
        color: Colors.white,
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
                icon: const Icon(Icons.login, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: const Text(
                  "تسجيل الدخول لحل المشكلة",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (rep.statusId) {
      case 2:
        // تبنّي بلاغ جديد
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
          icon: const Icon(Icons.handshake_outlined, color: Colors.white),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          label: const Text(
            "تبنّي البلاغ وحل المشكلة",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        );

      case 3:
        // قيد التنفيذ → فقط الجهة المتبنية يمكنها الإكمال
        bool canComplete = false;
        if (_currentUser != null &&
            rep.adoptedById != null &&
            rep.adoptedByType != null) {
          final myCitizenId = _parseInt(_currentUser!['citizen_id']);
          final myInitiativeId = _parseInt(_currentUser!['initiative_id']);

          if (rep.adoptedByType == 1 &&
              myCitizenId != null &&
              myCitizenId == rep.adoptedById) {
            canComplete = true;
          } else if (rep.adoptedByType == 2 &&
              myInitiativeId != null &&
              myInitiativeId == rep.adoptedById) {
            canComplete = true;
          }
        }

        if (canComplete) {
          return ElevatedButton.icon(
            onPressed: () async {
              final done = await Get.to(() => CompleteReportPage(report: rep));
              if (done == true) _load();
            },
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: const Text(
              "إتمام الحل ورفع الصور",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          );
        }

        // ليست الجهة المتبنية
        return Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              rep.adoptedByName != null
                  ? 'هذا البلاغ متبنّى بواسطة ${rep.adoptedByName}. فقط الجهة المتبنية يمكنها إتمام البلاغ.'
                  : 'هذا البلاغ متبنّى من قِبل جهة أخرى. فقط الجهة المتبنية يمكنها إتمام البلاغ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            ),
          ),
        );

      case 4:
        // مكتمل → لا أزرار
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
