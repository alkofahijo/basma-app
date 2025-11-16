// lib/pages/reports/browse/guest_reports_list_page.dart

import 'package:basma_app/pages/profile/profile_page.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/report_models.dart';
import 'details/report_details_page.dart';

// custom widgets
import 'widgets/reports_status_tabs.dart';
import 'widgets/reports_filters_card.dart';
import 'widgets/reports_card_item.dart';

const Color _primaryColor = Color(0xFF008000);
const Color _pageBackground = Color(0xFFEFF1F1);

class GuestReportsListPage extends StatefulWidget {
  final String initialMainTab; // 'all' أو 'mine'

  const GuestReportsListPage({super.key, this.initialMainTab = 'all'});

  @override
  State<GuestReportsListPage> createState() => _GuestReportsListPageState();
}

class _GuestReportsListPageState extends State<GuestReportsListPage> {
  // login state
  bool _isLoggedIn = false;

  // main tab: 'all' or 'mine'
  String _mainTab = 'all';

  // status tab: 'open' / 'in_progress' / 'completed'
  String _statusTab = 'open';

  // reports
  List<ReportPublicSummary> _reports = [];
  List<ReportPublicSummary> _filteredReports = [];
  bool _loading = true;
  String? _error;

  // filters
  List<GovernmentOption> _governments = [];
  List<DistrictOption> _districts = [];
  List<AreaOption> _areas = [];
  List<ReportTypeOption> _reportTypes = [];

  int? _selectedGovernmentId;
  int? _selectedDistrictId;
  int? _selectedAreaId;
  int? _selectedReportTypeId;

  // search
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _mainTab = widget.initialMainTab;
    _checkLoginAndInit();
  }

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
          _mainTab = 'all';
        } else {
          // لو الصفحة مفتوحة على "بلاغاتي" افتراضياً → الحالة الافتراضية "قيد التنفيذ"
          if (_mainTab == 'mine') {
            _statusTab = 'in_progress';
          }
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

  int _statusIdForTab(String tab) {
    switch (tab) {
      case 'open':
        return 2; // جديد
      case 'in_progress':
        return 3; // قيد التنفيذ
      case 'completed':
        return 4; // مكتمل
      default:
        return 2;
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final statusId = _statusIdForTab(_statusTab);
      final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

      late final List<ReportPublicSummary> list;

      if (isMyReports) {
        list = await ApiService.listMyReports(
          statusId: statusId,
          governmentId: _selectedGovernmentId,
          districtId: _selectedDistrictId,
          areaId: _selectedAreaId,
          reportTypeId: _selectedReportTypeId,
        );
      } else {
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
        _searchQuery = '';
      });

      _applySearchAndFilters();
    } catch (_) {
      setState(() {
        _reports = [];
        _filteredReports = [];
        _error = 'تعذّر تحميل البلاغات، يرجى المحاولة لاحقاً.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ================== tabs switching ==================

  void _switchStatusTab(String tab) {
    if (_statusTab == tab) return;

    final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

    // في "بلاغاتي" لا معنى لعرض "جديد" (2) لأنها فقط عامة
    if (isMyReports && tab == 'open') return;

    setState(() {
      _statusTab = tab;
    });

    _loadReports();
  }

  // ================== filters ==================

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
      } catch (_) {
        // تجاهل الخطأ هنا، فقط لا نعرض مقاطعات
      }
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
      } catch (_) {
        // تجاهل الخطأ
      }
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

  // ================== search + filter client-side ==================

  void _applySearchAndFilters() {
    List<ReportPublicSummary> results = List.of(_reports);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      bool match(String? s) => (s ?? '').toLowerCase().contains(q);

      results = results.where((r) {
        return match(r.governmentNameAr) ||
            match(r.districtNameAr) ||
            match(r.areaNameAr) ||
            match(r.typeNameAr) ||
            match(r.nameAr);
      }).toList();
    }

    setState(() {
      _filteredReports = results;
    });
  }

  // ================== navigation ==================

  void _openDetails(int reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportDetailsPage(reportId: reportId)),
    );
  }

  // ================== helpers ==================

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

  // ================== UI widgets ==================

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  _searchQuery = value.trim();
                  _applySearchAndFilters();
                },
                decoration: InputDecoration(
                  hintText:
                      'ابحث عن بلاغ (محافظة، لواء، منطقة، نوع التشوه البصري...)',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openFiltersBottomSheet,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.filter_list, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _openFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: GuestFiltersCard(
              governments: _governments,
              districts: _districts,
              areas: _areas,
              reportTypes: _reportTypes,
              selectedGovernmentId: _selectedGovernmentId,
              selectedDistrictId: _selectedDistrictId,
              selectedAreaId: _selectedAreaId,
              selectedReportTypeId: _selectedReportTypeId,
              onGovernmentChanged: (id) async {
                await _onGovernmentChanged(id);
                _applySearchAndFilters();
              },
              onDistrictChanged: (id) async {
                await _onDistrictChanged(id);
                _applySearchAndFilters();
              },
              onAreaChanged: (id) async {
                await _onAreaChanged(id);
                _applySearchAndFilters();
              },
              onReportTypeChanged: (id) async {
                await _onReportTypeChanged(id);
                _applySearchAndFilters();
              },
              iconForReportType: _iconForReportType,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red, fontSize: 14),
        ),
      );
    }

    if (_filteredReports.isEmpty) {
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
      itemCount: _filteredReports.length,
      itemBuilder: (_, index) {
        final r = _filteredReports[index];
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

  @override
  Widget build(BuildContext context) {
    final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        systemOverlayStyle: AppSystemUi.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "تصفح البلاغات",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person_rounded, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
        ],
        toolbarHeight: 60,
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingCenter()
            : Column(
                children: [
                  _buildSearchAndFilterBar(),
                  const SizedBox(height: 8),
                  GuestStatusTabs(
                    currentStatusTab: _statusTab,
                    isMyReports: isMyReports,
                    onStatusChanged: _switchStatusTab,
                  ),
                  const SizedBox(height: 6),
                  Expanded(child: _buildBody()),
                ],
              ),
      ),
    );
  }
}
