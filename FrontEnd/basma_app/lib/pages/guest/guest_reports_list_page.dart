// lib/pages/guest/guest_reports_list_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/report_models.dart';
import '../../services/api_service.dart';
import '../report/report_details_page.dart';

// custom widgets
import 'custom_widgets/guest_main_tabs.dart';
import 'custom_widgets/guest_status_tabs.dart';
import 'custom_widgets/guest_filters_card.dart';
import 'custom_widgets/guest_report_card.dart';

class GuestReportsListPage extends StatefulWidget {
  const GuestReportsListPage({super.key});

  @override
  State<GuestReportsListPage> createState() => _GuestReportsListPageState();
}

class _GuestReportsListPageState extends State<GuestReportsListPage> {
  // هل المستخدم مسجّل دخول أم لا (لتفعيل تبويب "بلاغاتي")
  bool _isLoggedIn = false;

  // التبويب الرئيسي: 'all' = كل البلاغات, 'mine' = بلاغاتي
  String _mainTab = 'all';

  // تبويب الحالة: open / in_progress / completed
  String _statusTab = 'open';

  // قائمة البلاغات
  List<ReportPublicSummary> _reports = [];
  bool _loading = true;
  String? _error;

  // الفلاتر
  List<GovernmentOption> _governments = [];
  List<DistrictOption> _districts = [];
  List<AreaOption> _areas = [];
  List<ReportTypeOption> _reportTypes = [];

  int? _selectedGovernmentId;
  int? _selectedDistrictId;
  int? _selectedAreaId;
  int? _selectedReportTypeId;

  @override
  void initState() {
    super.initState();
    _checkLoginAndInit();
  }

  /// التحقق من وجود توكن في التخزين (لتحديد حالة تسجيل الدخول)
  Future<void> _checkLoginAndInit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('token');
      final loggedIn = token != null && token.isNotEmpty;

      setState(() {
        _isLoggedIn = loggedIn;
        if (!_isLoggedIn) {
          // الضيف دائمًا على "كل البلاغات"
          _mainTab = 'all';
        }
      });

      await _initFiltersAndLoad();
    } catch (_) {
      setState(() {
        _isLoggedIn = false;
        _mainTab = 'all';
      });
      await _initFiltersAndLoad();
    }
  }

  /// تحميل القوائم الثابتة (المحافظات / أنواع البلاغات) ثم تحميل البلاغات
  Future<void> _initFiltersAndLoad() async {
    try {
      final results = await Future.wait([
        ApiService.listGovernments(),
        ApiService.listReportTypes(),
      ]);

      _governments = results[0] as List<GovernmentOption>;
      _reportTypes = results[1] as List<ReportTypeOption>;

      await _loadReports();
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل البيانات، يرجى المحاولة لاحقاً.';
      });
    }
  }

  /// تحويل تبويب الحالة إلى status_id
  int _statusIdForTab(String tab) {
    switch (tab) {
      case 'open':
        return 2; // open
      case 'in_progress':
        return 3; // in_progress
      case 'completed':
        return 4; // completed
      default:
        return 2;
    }
  }

  /// تحميل البلاغات بحسب التبويبات والفلاتر
  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final statusId = _statusIdForTab(_statusTab);
      List<ReportPublicSummary> list;

      final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

      if (isMyReports) {
        // /reports/my
        list = await ApiService.listMyReports(
          statusId: statusId,
          governmentId: _selectedGovernmentId,
          districtId: _selectedDistrictId,
          areaId: _selectedAreaId,
          reportTypeId: _selectedReportTypeId,
        );
      } else {
        // /reports/public
        list = await ApiService.listPublicReports(
          statusId: statusId,
          governmentId: _selectedGovernmentId,
          districtId: _selectedDistrictId,
          areaId: _selectedAreaId,
          reportTypeId: _selectedReportTypeId,
        );
      }

      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _reports = [];
        _loading = false;
        _error = 'تعذّر تحميل البلاغات، يرجى المحاولة لاحقاً.';
      });
    }
  }

  /// تبديل التبويب الرئيسي (كل البلاغات / بلاغاتي)
  void _switchMainTab(String tab) {
    if (_mainTab == tab) return;

    setState(() {
      _mainTab = tab;

      // لو دخل على "بلاغاتي" لا نسمح أن تبقى الحالة "مفتوح"
      if (_mainTab == 'mine' && _statusTab == 'open') {
        _statusTab = 'in_progress';
      }
    });

    _loadReports();
  }

  /// تبديل تبويب الحالة
  void _switchStatusTab(String tab) {
    if (_statusTab == tab) return;

    final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

    // في "بلاغاتي" لا نسمح باختيار "مفتوح"
    if (isMyReports && tab == 'open') {
      return;
    }

    setState(() {
      _statusTab = tab;
    });

    _loadReports();
  }

  // ========================= فلاتر =========================

  Future<void> _onGovernmentChanged(int? govId) async {
    setState(() {
      _selectedGovernmentId = govId;
      _selectedDistrictId = null;
      _selectedAreaId = null;
      _districts = [];
      _areas = [];
    });

    if (govId != null) {
      try {
        final districts = await ApiService.listDistrictsByGovernment(govId);
        setState(() {
          _districts = districts;
        });
      } catch (_) {}
    }

    await _loadReports();
  }

  Future<void> _onDistrictChanged(int? distId) async {
    setState(() {
      _selectedDistrictId = distId;
      _selectedAreaId = null;
      _areas = [];
    });

    if (distId != null) {
      try {
        final areas = await ApiService.listAreasByDistrict(distId);
        setState(() {
          _areas = areas;
        });
      } catch (_) {}
    }

    await _loadReports();
  }

  Future<void> _onAreaChanged(int? areaId) async {
    setState(() {
      _selectedAreaId = areaId;
    });
    await _loadReports();
  }

  Future<void> _onReportTypeChanged(int? typeId) async {
    setState(() {
      _selectedReportTypeId = typeId;
    });
    await _loadReports();
  }

  // ========================= تنقّل =========================

  void _openDetails(int reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportDetailsPage(reportId: reportId)),
    );
  }

  // ========================= Helpers (UI) =========================

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Color _statusColor(int statusId) {
    switch (statusId) {
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusNameAr(int statusId) {
    switch (statusId) {
      case 1:
        return 'قيد المراجعة';
      case 2:
        return 'جديد';
      case 3:
        return 'قيد التنفيذ';
      case 4:
        return 'مكتمل';
      default:
        return 'غير معروف';
    }
  }

  IconData _iconForReportType(String code) {
    switch (code) {
      case 'cleanliness':
        return Icons.cleaning_services_outlined;
      case 'potholes':
        return Icons.construction;
      case 'sidewalks':
        return Icons.directions_walk;
      case 'walls':
        return Icons.crop_landscape;
      case 'planting':
        return Icons.local_florist;
      case 'other':
      default:
        return Icons.more_horiz;
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
    }

    if (_reports.isEmpty) {
      String msg;
      switch (_statusTab) {
        case 'open':
          msg = 'لا توجد بلاغات جديدة حالياً.';
          break;
        case 'in_progress':
          msg = 'لا توجد بلاغات قيد التنفيذ حالياً.';
          break;
        case 'completed':
          msg = 'لا توجد بلاغات مكتملة في هذا القسم.';
          break;
        default:
          msg = 'لا توجد بلاغات.';
      }

      return Center(child: Text(msg, style: const TextStyle(fontSize: 14)));
    }

    return ListView.builder(
      itemCount: _reports.length,
      itemBuilder: (_, index) {
        final r = _reports[index];
        return GuestReportCard(
          report: r,
          onTap: () => _openDetails(r.id),
          formatDate: _formatDate,
          statusColor: _statusColor,
          statusNameAr: _statusNameAr,
        );
      },
    );
  }

  PreferredSizeWidget? _buildAppBarBottom(bool isMyReports) {
    if (_isLoggedIn) {
      // مستخدم مسجّل دخول: سطران (بلاغاتي / كل البلاغات) + حالات
      const double h = 150; // ارتفاع كافٍ لكل المحتوى بدون overflow
      return PreferredSize(
        preferredSize: const Size.fromHeight(h),
        child: SizedBox(
          height: h,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GuestMainTabs(
                isLoggedIn: _isLoggedIn,
                currentTab: _mainTab,
                onTabChanged: _switchMainTab,
              ),
              const SizedBox(height: 10),
              GuestStatusTabs(
                currentStatusTab: _statusTab,
                isMyReports: isMyReports,
                onStatusChanged: _switchStatusTab,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } else {
      // ضيف: فقط تبويبات حالة البلاغ
      const double h = 72;
      return PreferredSize(
        preferredSize: const Size.fromHeight(h),
        child: SizedBox(
          height: h,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GuestStatusTabs(
                currentStatusTab: _statusTab,
                isMyReports: false,
                onStatusChanged: _switchStatusTab,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          backgroundColor: Color(0xFF008000),
          elevation: 0,

          // 🔹 إخفاء العنوان تماماً
          title: const SizedBox.shrink(),
          centerTitle: true,
          bottom: _buildAppBarBottom(isMyReports),
        ),
        body: Column(
          children: [
            // كرت الفلاتر
            GuestFiltersCard(
              governments: _governments,
              districts: _districts,
              areas: _areas,
              reportTypes: _reportTypes,
              selectedGovernmentId: _selectedGovernmentId,
              selectedDistrictId: _selectedDistrictId,
              selectedAreaId: _selectedAreaId,
              selectedReportTypeId: _selectedReportTypeId,
              onGovernmentChanged: _onGovernmentChanged,
              onDistrictChanged: _onDistrictChanged,
              onAreaChanged: _onAreaChanged,
              onReportTypeChanged: _onReportTypeChanged,
              iconForReportType: _iconForReportType,
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
