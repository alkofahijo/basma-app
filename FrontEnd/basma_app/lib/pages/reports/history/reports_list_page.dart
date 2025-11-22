// lib/pages/reports/history/reports_list_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/models/report_models.dart';

import 'details/report_details_page.dart';
import 'widgets/reports_status_tabs.dart';
import 'widgets/reports_filters_card.dart';
import 'widgets/reports_card_item.dart';

const Color _pageBackground = Color(0xFFEFF1F1);

class GuestReportsListPage extends StatefulWidget {
  /// 'all' أو 'mine'
  final String initialMainTab;

  /// 'open' / 'in_progress' / 'completed'
  final String initialStatusTab;

  const GuestReportsListPage({
    super.key,
    this.initialMainTab = 'all',
    this.initialStatusTab = 'open',
  });

  @override
  State<GuestReportsListPage> createState() => _GuestReportsListPageState();
}

class _GuestReportsListPageState extends State<GuestReportsListPage> {
  // ---- Auth ----
  bool _isLoggedIn = false;

  // main tab: 'all' أو 'mine'
  String _mainTab = 'all';

  // status tab: 'open' / 'in_progress' / 'completed'
  String _statusTab = 'open';

  // ---- Reports ----
  List<ReportPublicSummary> _allReports = [];
  List<ReportPublicSummary> _visibleReports = [];

  // loading flags
  bool _isLoading = true; // أول تحميل / إعادة تحميل كاملة
  bool _isLoadingMore = false; // تحميل الصفحة التالية
  String? _loadErrorMessage;

  // ---- Pagination ----
  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _hasMore = true;

  // Scroll controller للـ infinite scroll
  late final ScrollController _scrollController;

  // ---- Filters (IDs + lists) ----
  List<GovernmentOption> _governments = [];
  List<ReportTypeOption> _reportTypes = [];

  int? _selectedGovernmentId;
  int? _selectedDistrictId;
  int? _selectedAreaId;
  int? _selectedReportTypeId;

  // ---- Search ----
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ضبط القيم الابتدائية القادمة من SuccessPage أو غيرها
    _mainTab = widget.initialMainTab;
    _statusTab = widget.initialStatusTab;

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _checkLoginAndInitialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ========= Init / Auth =========

  Future<void> _checkLoginAndInitialize() async {
    _safeSetState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('token');
      final bool loggedIn = token != null && token.isNotEmpty;

      _safeSetState(() {
        _isLoggedIn = loggedIn;

        if (!_isLoggedIn) {
          // لو لم يكن هناك تسجيل دخول، نعرض "الكل"
          _mainTab = 'all';
          // نترك _statusTab كما هو (open / in_progress / completed) للعرض العام
        } else {
          // في حالة الدخول
          if (_mainTab != 'all' && _mainTab != 'mine') {
            _mainTab = 'all';
          }

          if (_mainTab == 'mine') {
            // في "بلاغاتي" لا معنى لـ 'open'، فلو كانت القيمة 'open'
            // (أي لم يتم تمرير قيمة خاصة)، نضبطها إلى 'in_progress'
            if (_statusTab == 'open') {
              _statusTab = 'in_progress';
            }
          }
        }
      });

      await _initFiltersAndLoadReports();
    } catch (_) {
      _safeSetState(() {
        _isLoggedIn = false;
        _mainTab = 'all';
      });
      await _initFiltersAndLoadReports();
    }
  }

  Future<void> _initFiltersAndLoadReports() async {
    try {
      final results = await Future.wait([
        ApiService.listGovernments(),
        ApiService.listReportTypes(),
      ]);

      _governments = results[0] as List<GovernmentOption>;
      _reportTypes = results[1] as List<ReportTypeOption>;

      await _loadReports(reset: true);
    } catch (_) {
      _safeSetState(() {
        _isLoading = false;
        _loadErrorMessage = 'تعذّر تحميل البيانات، يرجى المحاولة لاحقاً.';
      });
    }
  }

  // ========= Backend-loading + Pagination =========

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

  Future<void> _loadReports({bool reset = false}) async {
    // في حالة إعادة التحميل بالكامل (تغيير التبويب / الفلاتر / الدخول)
    if (reset) {
      _currentOffset = 0;
      _hasMore = true;
      _safeSetState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _loadErrorMessage = null;
        _allReports = [];
        _visibleReports = [];
        _searchQuery = '';
        _searchController.clear();
      });
    } else {
      // تحميل صفحة جديدة
      if (_isLoading || _isLoadingMore || !_hasMore) return;
      _safeSetState(() {
        _isLoadingMore = true;
        _loadErrorMessage = null;
      });
    }

    try {
      final int statusId = _statusIdForTab(_statusTab);
      final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

      late final List<ReportPublicSummary> page;

      if (isMyReports) {
        page = await ApiService.listMyReports(
          statusId: statusId,
          governmentId: _selectedGovernmentId,
          districtId: _selectedDistrictId,
          areaId: _selectedAreaId,
          reportTypeId: _selectedReportTypeId,
          limit: _pageSize,
          offset: _currentOffset,
        );
      } else {
        page = await ApiService.listPublicReports(
          statusId: statusId,
          governmentId: _selectedGovernmentId,
          districtId: _selectedDistrictId,
          areaId: _selectedAreaId,
          reportTypeId: _selectedReportTypeId,
          limit: _pageSize,
          offset: _currentOffset,
        );
      }

      _safeSetState(() {
        if (reset) {
          _allReports = page;
        } else {
          _allReports.addAll(page);
        }

        _currentOffset = _allReports.length;

        // إذا جاءت صفحة أقل من limit فهذا يعني لا مزيد من البيانات
        if (page.length < _pageSize) {
          _hasMore = false;
        }

        // إعادة تطبيق البحث (على البيانات المحمّلة فقط)
        _applySearchFilter();
      });
    } catch (_) {
      _safeSetState(() {
        if (reset) {
          _allReports = [];
          _visibleReports = [];
          _loadErrorMessage = 'تعذّر تحميل البلاغات، يرجى المحاولة لاحقاً.';
        }
      });
    } finally {
      _safeSetState(() {
        if (reset) {
          _isLoading = false;
          _isLoadingMore = false;
        } else {
          _isLoadingMore = false;
        }
      });
    }
  }

  // مستمع الـ ScrollController للـ infinite scroll
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    final thresholdPixels = 200.0;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= thresholdPixels) {
      _loadReports(); // صفحة جديدة
    }
  }

  // ========= Tabs =========

  void _switchStatusTab(String newTab) {
    if (_statusTab == newTab) return;

    final bool isMyReports = _isLoggedIn && _mainTab == 'mine';

    // في "بلاغاتي" لا معنى لعرض "جديد"
    if (isMyReports && newTab == 'open') return;

    _safeSetState(() {
      _statusTab = newTab;
    });

    _loadReports(reset: true);
  }

  // ========= Filters (IDs only) =========

  Future<void> _onGovernmentChanged(int? governmentId) async {
    _safeSetState(() {
      _selectedGovernmentId = governmentId;
      _selectedDistrictId = null;
      _selectedAreaId = null;
    });
    await _loadReports(reset: true);
  }

  Future<void> _onDistrictChanged(int? districtId) async {
    _safeSetState(() {
      _selectedDistrictId = districtId;
      _selectedAreaId = null;
    });
    await _loadReports(reset: true);
  }

  Future<void> _onAreaChanged(int? areaId) async {
    _safeSetState(() {
      _selectedAreaId = areaId;
    });
    await _loadReports(reset: true);
  }

  Future<void> _onReportTypeChanged(int? typeId) async {
    _safeSetState(() {
      _selectedReportTypeId = typeId;
    });
    await _loadReports(reset: true);
  }

  // ========= Search (client-side) =========

  void _applySearchFilter() {
    List<ReportPublicSummary> results = List.of(_allReports);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      bool match(String? s) => (s ?? '').toLowerCase().contains(query);

      results = results.where((report) {
        return match(report.governmentNameAr) ||
            match(report.districtNameAr) ||
            match(report.areaNameAr) ||
            match(report.typeNameAr) ||
            match(report.nameAr);
      }).toList();
    }

    _safeSetState(() {
      _visibleReports = results;
    });
  }

  // ========= Navigation =========

  void _openReportDetails(int reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportDetailsPage(reportId: reportId)),
    );
  }

  // ========= Helpers =========

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
        return 'بلاغ جديد';
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
      default:
        return Icons.more_horiz;
    }
  }

  // ========= UI: Search + Filter Bar =========

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  _searchQuery = value.trim();
                  _applySearchFilter();
                },
                style: const TextStyle(fontSize: 13, height: 1.3),
                decoration: InputDecoration(
                  hintText: 'ابحث عن بلاغ معين ...',
                  hintStyle: TextStyle(
                    fontSize: 15.5,
                    color: Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _applySearchFilter();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: kPrimaryColor.withValues(alpha: 0.8),
                      width: 1.3,
                    ),
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
                    color: Colors.black12.withValues(alpha: 0.05),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: GuestFiltersCard(
              governments: _governments,
              reportTypes: _reportTypes,
              selectedGovernmentId: _selectedGovernmentId,
              selectedDistrictId: _selectedDistrictId,
              selectedAreaId: _selectedAreaId,
              selectedReportTypeId: _selectedReportTypeId,
              onGovernmentChanged: (id) async {
                await _onGovernmentChanged(id);
                _applySearchFilter();
              },
              onDistrictChanged: (id) async {
                await _onDistrictChanged(id);
                _applySearchFilter();
              },
              onAreaChanged: (id) async {
                await _onAreaChanged(id);
                _applySearchFilter();
              },
              onReportTypeChanged: (id) async {
                await _onReportTypeChanged(id);
                _applySearchFilter();
              },
              iconForReportType: _iconForReportType,
            ),
          ),
        );
      },
    );
  }

  // ========= Body =========

  Widget _buildBody() {
    if (_loadErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _loadErrorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_visibleReports.isEmpty) {
      String emptyMessage;
      switch (_statusTab) {
        case 'open':
          emptyMessage = 'لا توجد بلاغات جديدة حالياً.';
          break;
        case 'in_progress':
          emptyMessage = 'لا توجد بلاغات قيد التنفيذ حالياً.';
          break;
        case 'completed':
          emptyMessage = 'لا توجد بلاغات مكتملة في هذا القسم.';
          break;
        default:
          emptyMessage = 'لا توجد بلاغات مطابقة للبحث/التصفية.';
      }

      return Center(
        child: Text(emptyMessage, style: const TextStyle(fontSize: 14)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _visibleReports.length + (_hasMore ? 1 : 0),
      itemBuilder: (_, index) {
        // عنصر تحميل الصفحة التالية في النهاية
        if (_hasMore && index == _visibleReports.length) {
          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          } else {
            // عنصر شفاف صغير بحيث لا يأخذ مساحة إذا لم نكن نحمل الآن
            return const SizedBox.shrink();
          }
        }

        final report = _visibleReports[index];
        return GuestReportCard(
          report: report,
          onTap: () => _openReportDetails(report.id),
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          leading: _isLoggedIn
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
          backgroundColor: kPrimaryColor,
          systemOverlayStyle: AppSystemUi.green,
          elevation: 0,
          title: Text(
            isMyReports ? 'بلاغاتي' : 'تصفّح البلاغات',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 60,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchAndFilterBar(),
              const SizedBox(height: 8),
              GuestStatusTabs(
                currentStatusTab: _statusTab,
                isMyReports: isMyReports,
                onStatusChanged: _switchStatusTab,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _isLoading ? const LoadingCenter() : _buildBody(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BasmaBottomNavPage(
          currentIndex: isMyReports ? 1 : -1,
        ),
      ),
    );
  }
}
