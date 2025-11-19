// lib/pages/report/report_details_page.dart

import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/pages/auth/Login/login_page.dart';
import 'package:basma_app/pages/profile/citizen_info_page.dart';
import 'package:basma_app/pages/profile/initiative_info_page.dart';
import 'package:basma_app/pages/reports/history/details/complete_report_page.dart';
import 'package:basma_app/pages/reports/history/widgets/adopt_report_dialog.dart';
import 'package:basma_app/pages/reports/history/widgets/view_location_page.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/report_image_section.dart';

/// لون الخلفية العام للصفحة
const Color _pageBackground = Color(0xFFEFF1F1);

/// تنسيق بسيط لتاريخ/وقت البلاغ
String _formatDateTime(DateTime? dt) {
  if (dt == null) return "غير متوفر";

  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');

  return "$y-$m-$d $hh:$mm";
}

/// صف معلومات مخصص لقسم الموقع
class _LocationInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _LocationInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// نمط مخصص لتصميم حالة البلاغ
class _StatusStyle {
  final Color backgroundColor;
  final Color textColor;
  final String label;

  _StatusStyle({
    required this.backgroundColor,
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
  String? _loadErrorMessage;
  bool _isLoading = true;

  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUserJson;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _initializePage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isLoggedIn = token != null && token.isNotEmpty;

      _safeSetState(() {
        _isAuthenticated = isLoggedIn;
      });

      if (isLoggedIn) {
        _currentUserJson = await AuthService.currentUser();
      } else {
        _currentUserJson = null;
      }

      await _loadReportDetails();
    } catch (_) {
      _safeSetState(() {
        _isAuthenticated = false;
      });
      await _loadReportDetails();
    }
  }

  Future<void> _loadReportDetails() async {
    _safeSetState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final data = await ApiService.getReport(widget.reportId);
      _safeSetState(() {
        _report = data;
      });
    } catch (_) {
      _safeSetState(() {
        _loadErrorMessage = 'تعذّر تحميل بيانات البلاغ، يرجى المحاولة مجددًا.';
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse(value.toString());
  }

  // ======================= Build =======================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          systemOverlayStyle: AppSystemUi.green,
          title: const Text(
            "تفاصيل البلاغ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: SafeArea(child: _buildBody()),
        bottomNavigationBar: const BasmaBottomNavPage(currentIndex: 1),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingCenter();
    }

    if (_loadErrorMessage != null || _report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _loadErrorMessage ?? 'حدث خطأ غير متوقع.',
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final report = _report!;

    return RefreshIndicator(
      onRefresh: _loadReportDetails,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 700;

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 16,
              vertical: 16,
            ),
            children: [
              _buildHeaderCard(report),
              const SizedBox(height: 16),
              _buildBasicInfoSection(report),
              const SizedBox(height: 16),
              _buildImagesSection(report),
              const SizedBox(height: 16),
              _buildLocationSection(report),
              const SizedBox(height: 16),
              _buildReportingSection(report),
              if (report.statusId == 3 || report.statusId == 4) ...[
                const SizedBox(height: 16),
                _buildSolvedBySection(report),
              ],
              const SizedBox(height: 24),
              _buildActionSection(report),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ======================= NEW MODERN RESPONSIVE HEADER =======================

  Widget _buildHeaderCard(ReportDetail report) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 380;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.85)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW: Icon + Title + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon bubble
                  Container(
                    height: isSmall ? 48 : 56,
                    width: isSmall ? 48 : 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.nameAr,
                          style: TextStyle(
                            fontSize: isSmall ? 15 : 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(report.reportedAt),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.numbers,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "رقم البلاغ: ${report.reportCode}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  _buildStatusChip(report),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(ReportDetail report) {
    final style = _mapStatusStyle(report.statusId, report.statusNameAr);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.backgroundColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: style.textColor),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.textColor,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _StatusStyle _mapStatusStyle(int statusId, String? statusNameAr) {
    switch (statusId) {
      case 1:
        return _StatusStyle(
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.grey.shade800,
          label: statusNameAr ?? "قيد المراجعة",
        );
      case 2:
        return _StatusStyle(
          backgroundColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF0D47A1),
          label: statusNameAr ?? "بلاغ جديد",
        );
      case 3:
        return _StatusStyle(
          backgroundColor: Colors.orange.shade50,
          textColor: Colors.orange.shade700,
          label: statusNameAr ?? "قيد التنفيذ",
        );
      case 4:
        return _StatusStyle(
          backgroundColor: Colors.green.shade50,
          textColor: Colors.green.shade700,
          label: statusNameAr ?? "مكتمل",
        );
      default:
        return _StatusStyle(
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.grey.shade800,
          label: statusNameAr ?? "غير معروف",
        );
    }
  }

  // ======================= Generic Section Card =======================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: kPrimaryColor),
                ),
                const SizedBox(width: 8),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  // ======================= Sections =======================

  Widget _buildBasicInfoSection(ReportDetail report) {
    return _buildSectionCard(
      icon: Icons.info_outline,
      title: "معلومات البلاغ",
      subtitle: "تفاصيل عامة عن نوع التشوّه البصري ووصفه.",
      children: [
        InfoRow(
          label: "نوع التشوّه البصري",
          value: report.reportTypeNameAr ?? "غير محدد",
        ),
        InfoRow(label: "وصف المشكلة", value: report.descriptionAr),
        if (report.note != null && report.note!.isNotEmpty)
          InfoRow(label: "ملاحظات إضافية", value: report.note!),
      ],
    );
  }

  Widget _buildImagesSection(ReportDetail report) {
    return _buildSectionCard(
      icon: Icons.photo_library_outlined,
      title: "صور البلاغ",
      subtitle: "يمكنك استعراض صورة التشوّه قبل المعالجة وبعدها إن وُجدت.",
      children: [
        BeforeAfterImages(
          beforeUrl: report.imageBeforeUrl,
          afterUrl: report.imageAfterUrl,
        ),
      ],
    );
  }

  Widget _buildLocationSection(ReportDetail report) {
    final hasCoordinates =
        report.locationLatitude != null && report.locationLongitude != null;

    return _buildSectionCard(
      icon: Icons.place_outlined,
      title: "الموقع الجغرافي",
      subtitle:
          "يوضح موقع البلاغ على الخريطة مع بيانات المحافظة واللواء والمنطقة.",
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;

            if (isNarrow) {
              // خريطة فوق + تفاصيل تحت للشاشات الصغيرة
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMiniMap(report, hasCoordinates, height: 160),
                  const SizedBox(height: 12),
                  _buildLocationTextAndButton(report, hasCoordinates),
                ],
              );
            }

            // Row للشاشات الأوسع
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: _buildMiniMap(report, hasCoordinates, height: 150),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 4,
                  child: _buildLocationTextAndButton(report, hasCoordinates),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniMap(
    ReportDetail report,
    bool hasCoordinates, {
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Container(
          color: Colors.grey.shade200,
          child: hasCoordinates
              ? FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      report.locationLatitude!,
                      report.locationLongitude!,
                    ),
                    initialZoom: 15,
                    maxZoom: 18,
                    minZoom: 3,
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
                            report.locationLatitude!,
                            report.locationLongitude!,
                          ),
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Color(0xFF008000),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    "لا توجد إحداثيات",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLocationTextAndButton(ReportDetail report, bool hasCoordinates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LocationInfoRow(
          label: "المحافظة:",
          value: report.governmentNameAr ?? "---",
        ),
        const SizedBox(height: 6),
        _LocationInfoRow(
          label: "اللواء:",
          value: report.districtNameAr ?? "---",
        ),
        const SizedBox(height: 6),
        _LocationInfoRow(label: "المنطقة:", value: report.areaNameAr ?? "---"),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: hasCoordinates
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewReportLocationPage(
                            lat: report.locationLatitude!,
                            lng: report.locationLongitude!,
                            locationName: report.locationNameAr,
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "عرض على الخريطة",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportingSection(ReportDetail report) {
    return _buildSectionCard(
      icon: Icons.person_outline,
      title: "بيانات التبليغ",
      subtitle: "يوضح من قام بالتبليغ وتاريخ تسجيل البلاغ.",
      children: [
        InfoRow(
          label: "اسم المبلِّغ",
          value: report.reportedByName ?? "غير محدد",
        ),
        InfoRow(
          label: "تاريخ التبليغ",
          value: _formatDateTime(report.reportedAt),
        ),
      ],
    );
  }

  Widget _buildSolvedBySection(ReportDetail report) {
    final bool hasAdopter =
        report.adoptedById != null && report.adoptedByType != null;

    Widget nameWidget = const Text(
      "تفاصيل الجهة ",
      style: TextStyle(
        fontSize: 14.5,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    );

    if (hasAdopter) {
      nameWidget = GestureDetector(
        onTap: () {
          if (report.adoptedByType == 1) {
            Get.to(() => CitizenInfoPage(citizenId: report.adoptedById!));
          } else if (report.adoptedByType == 2) {
            Get.to(() => InitiativeInfoPage(initiativeId: report.adoptedById!));
          }
        },
        child: nameWidget,
      );
    }

    return _buildSectionCard(
      icon: Icons.handshake_outlined,
      title: "الجهة المسؤولة عن الحل",
      subtitle: "الجهة التي تبنّت حل المشكلة وقامت بمعالجتها.",
      children: [
        const SizedBox(height: 4),
        if (report.adoptedByType != null)
          InfoRow(
            label: "نوع الجهة",
            value: report.adoptedByType == 1
                ? "مواطن"
                : "مبادرة تطوعية أو بلدية",
          ),
        const SizedBox(height: 6),
        nameWidget,
        const SizedBox(height: 4),
      ],
    );
  }

  // ======================= Actions / Call To Action =======================

  Widget _buildActionSection(ReportDetail report) {
    if (!_isAuthenticated) {
      if (report.statusId != 2) {
        return const SizedBox.shrink();
      }

      return Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "لتتمكن من تبنّي البلاغ والمشاركة في حل المشكلة، يرجى تسجيل الدخول أو إنشاء حساب كمواطن أو مبادرة.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => LoginPage());
                },
                icon: const Icon(Icons.login, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: const Text(
                  "تسجيل الدخول لتبنّي البلاغ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (report.statusId) {
      case 2:
        // متاح للتبنّي
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => SolveReportDialog(reportId: report.id),
              );
              if (result == true) {
                _loadReportDetails();
              }
            },
            icon: const Icon(Icons.handshake_outlined, color: Colors.white),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            label: const Text(
              "تبنّي البلاغ والمساهمة في الحل",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        );

      case 3:
        // قيد التنفيذ
        final bool canComplete = _canCurrentUserComplete(report);

        if (canComplete) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final done = await Get.to(
                  () => CompleteReportPage(report: report),
                );
                if (done == true) {
                  _loadReportDetails();
                }
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(14),
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              label: const Text(
                "إتمام الحل ورفع صور المعالجة",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              report.adoptedByName != null
                  ? 'هذا البلاغ متبنّى بواسطة ${report.adoptedByName}. فقط الجهة المتبنية يمكنها إتمام البلاغ ورفع صور الحل.'
                  : 'هذا البلاغ متبنّى من قِبل جهة أخرى. فقط الجهة المتبنية يمكنها إتمام البلاغ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade800),
            ),
          ),
        );

      case 4:
        // مكتمل
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }

  bool _canCurrentUserComplete(ReportDetail report) {
    if (_currentUserJson == null ||
        report.adoptedById == null ||
        report.adoptedByType == null) {
      return false;
    }

    final myCitizenId = _parseOptionalInt(_currentUserJson!['citizen_id']);
    final myInitiativeId = _parseOptionalInt(
      _currentUserJson!['initiative_id'],
    );

    if (report.adoptedByType == 1 &&
        myCitizenId != null &&
        myCitizenId == report.adoptedById) {
      return true;
    }

    if (report.adoptedByType == 2 &&
        myInitiativeId != null &&
        myInitiativeId == report.adoptedById) {
      return true;
    }

    return false;
  }
}
