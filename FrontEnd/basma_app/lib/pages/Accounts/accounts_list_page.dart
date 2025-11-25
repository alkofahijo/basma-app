// lib/pages/Accounts/accounts_list_page.dart

import 'package:flutter/material.dart';

import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/network_exceptions.dart';
import 'package:basma_app/services/pagination_manager.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/inputs/app_search_field.dart';
import 'package:basma_app/widgets/inputs/app_dropdown_form_field.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:basma_app/widgets/loading_center.dart';

import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/models/report_models.dart'; // GovernmentOption
import 'package:basma_app/config/base_url.dart';
import 'package:basma_app/pages/profile/account_info_page.dart';

const Color _pageBackground = Color(0xFFEFF1F1);

class AccountsListPage extends StatefulWidget {
  const AccountsListPage({super.key});

  @override
  State<AccountsListPage> createState() => _AccountsListPageState();
}

class _AccountsListPageState extends State<AccountsListPage> {
  // ---- Data ----
  late final PaginationController<Account> _pager;
  List<GovernmentOption> _governments = [];
  List<AccountTypeOption> _accountTypes = [];

  // ---- Filters ----
  int? _selectedGovernmentId;
  int? _selectedAccountTypeId;

  // ---- Search ----
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ---- Pagination ----
  final int _pageSize = 20;

  // ---- Loading / Error ----
  String? _loadErrorMessage;
  bool _isGuestRestricted = false;

  @override
  void initState() {
    super.initState();

    // إنشاء الـ pager مرة واحدة فقط
    _pager = PaginationController<Account>(
      fetcher: (page, pageSize) => _pageFetcher(page, pageSize),
      pageSize: _pageSize,
    );
    _pager.addListener(() => _safeSetState(() {}));

    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      _pager.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ========= Helpers =========

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kBaseUrl$raw';
    return '$kBaseUrl/$raw';
  }

  /// لون مخصّص حسب نوع الحساب (متطوع / بلدية / شركة / مؤسسة ...)
  Color _accountTypeColor(String? nameAr) {
    final n = (nameAr ?? '').trim();

    if (n.isEmpty) return Colors.grey;

    if (n.contains('تطوع') || n.contains('متطوع')) {
      // فرق أو مبادرات تطوعية
      return kPrimaryColor;
    }
    if (n.contains('بلدية') || n.contains('أمانة')) {
      // بلديات / أمانة
      return Colors.orange.shade700;
    }
    if (n.contains('شركة')) {
      // شركات خاصة
      return Colors.indigo;
    }
    if (n.contains('حكومية') || n.contains('حكومي')) {
      // جهات حكومية
      return Colors.teal.shade700;
    }
    if (n.contains('مؤسسة')) {
      // مؤسسات عامة/خاصة
      return Colors.deepPurple;
    }

    return Colors.grey.shade700;
  }

  // ========= Init =========

  Future<void> _initialize() async {
    _safeSetState(() {
      _loadErrorMessage = null;
      _isGuestRestricted = false;
    });

    // تحميل خيارات الفلاتر
    List<GovernmentOption> govs = [];
    List<AccountTypeOption> types = [];

    try {
      govs = await ApiService.listGovernments();
    } catch (e) {
      if (e is NetworkException && e.error.statusCode == 401) {
        // الضيف لا يمكنه رؤية هذه البيانات، لكن نكمل تحميل الحسابات
        _safeSetState(() {
          _isGuestRestricted = true;
        });
        govs = [];
      } else {
        String message = 'تعذّر تحميل البيانات، يرجى المحاولة لاحقاً.';
        if (e is NetworkException) message = e.error.message;
        _safeSetState(() {
          _loadErrorMessage = message;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }
    }

    try {
      types = await ApiService.listAccountTypes();
    } catch (e) {
      if (e is NetworkException && e.error.statusCode == 401) {
        _safeSetState(() {
          _isGuestRestricted = true;
        });
        types = [];
      } else {
        String message = 'تعذّر تحميل البيانات، يرجى المحاولة لاحقاً.';
        if (e is NetworkException) message = e.error.message;
        _safeSetState(() {
          _loadErrorMessage = message;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }
    }

    // تحديث الخيارات في الحالة
    _safeSetState(() {
      _governments = govs;
      _accountTypes = types;
    });

    // تحديث قائمة الحسابات عبر الـ pager نفسه (بدون إعادة إنشائه)
    try {
      await _pager.refresh();
    } catch (e) {
      String message = 'تعذّر تحميل البيانات، يرجى المحاولة لاحقاً.';
      if (e is NetworkException) message = e.error.message;
      _safeSetState(() {
        _loadErrorMessage = message;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<PaginatedResult<Account>> _pageFetcher(int page, int pageSize) async {
    try {
      final res = await ApiService.listAccountsPaged(
        page: page,
        pageSize: pageSize,
        governmentId: _selectedGovernmentId,
        accountTypeId: _selectedAccountTypeId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      return PaginatedResult<Account>(res.items, res.total);
    } catch (e) {
      // في حال الـ endpoint يتطلب تسجيل دخول واليوزر ضيف، نرجع صفحة فارغة
      if (e is NetworkException && e.error.statusCode == 401) {
        return PaginatedResult<Account>([], 0);
      }
      rethrow;
    }
  }

  int get _totalPages {
    final total = _pager.total;
    if (total <= 0) return 1;
    return ((total + _pageSize - 1) ~/ _pageSize).clamp(1, 999999);
  }

  // ========= UI: Filters Bar =========

  Widget _buildFiltersBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: AppSearchField(
              controller: _searchController,
              hint: 'ابحث عن جهة...',
              onChanged: (value) => _searchQuery = value.trim(),
              onSearch: () => _pager.refresh(),
              onClear: () {
                _searchController.clear();
                _searchQuery = '';
                _pager.refresh();
              },
            ),
          ),
          const SizedBox(width: 8),
          // زر الفلاتر
          Builder(
            builder: (ctx) {
              final bool hasFilters =
                  _selectedGovernmentId != null ||
                  _selectedAccountTypeId != null;
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: ctx,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (modalCtx) {
                            return DraggableScrollableSheet(
                              initialChildSize: 0.5,
                              minChildSize: 0.3,
                              maxChildSize: 0.9,
                              builder: (_, controller) {
                                int? localGov = _selectedGovernmentId;
                                int? localType = _selectedAccountTypeId;
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(18),
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    20,
                                  ),
                                  child: StatefulBuilder(
                                    builder: (c, setModalState) {
                                      return ListView(
                                        controller: controller,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'تصفية النتائج',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    Navigator.pop(modalCtx),
                                                icon: const Icon(Icons.close),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          const Divider(),
                                          const SizedBox(height: 8),

                                          // المحافظة
                                          AppDropdownFormField<int?>(
                                            value: localGov,
                                            items: [
                                              const DropdownMenuItem<int?>(
                                                value: null,
                                                child: Text('الكل'),
                                              ),
                                              ..._governments.map(
                                                (g) => DropdownMenuItem<int?>(
                                                  value: g.id,
                                                  child: Text(g.nameAr),
                                                ),
                                              ),
                                            ],
                                            onChanged: (v) {
                                              setModalState(() {
                                                localGov = v;
                                              });
                                            },
                                            label: 'المحافظة',
                                            hint: 'الكل',
                                          ),
                                          const SizedBox(height: 12),

                                          // نوع الحساب
                                          AppDropdownFormField<int?>(
                                            value: localType,
                                            items: [
                                              const DropdownMenuItem<int?>(
                                                value: null,
                                                child: Text('الكل'),
                                              ),
                                              ..._accountTypes.map(
                                                (t) => DropdownMenuItem<int?>(
                                                  value: t.id,
                                                  child: Text(t.nameAr),
                                                ),
                                              ),
                                            ],
                                            onChanged: (v) {
                                              setModalState(() {
                                                localType = v;
                                              });
                                            },
                                            label: 'نوع الحساب',
                                            hint: 'الكل',
                                          ),
                                          const SizedBox(height: 18),

                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    setModalState(() {
                                                      localGov = null;
                                                      localType = null;
                                                    });
                                                  },
                                                  child: const Text(
                                                    'مسح الفلاتر',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    // تطبيق الفلاتر
                                                    setState(() {
                                                      _selectedGovernmentId =
                                                          localGov;
                                                      _selectedAccountTypeId =
                                                          localType;
                                                    });
                                                    Navigator.pop(modalCtx);
                                                    _pager.loadPage(1);
                                                  },
                                                  child: const Text('تطبيق'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (hasFilters)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openAccountDetails(Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountInfoPage(accountId: account.id)),
    );
  }

  // ========= UI: Account Card =========

  Widget _buildAccountCard(Account account) {
    final String displayName = account.nameAr.isNotEmpty
        ? account.nameAr
        : (account.nameEn ?? 'بدون اسم');
    final imageUrl = _resolveImageUrl(account.logoUrl);

    final String? typeName = account.accountTypeNameAr;
    final Color typeColor = _accountTypeColor(typeName);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Main info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        account.governmentNameAr ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.report_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'البلاغات المنجزة: ${account.reportsCompletedCount}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black87,
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

                // Type chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (typeName != null && typeName.trim().isNotEmpty)
                      Chip(
                        label: Text(
                          typeName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: typeColor,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => _openAccountDetails(account),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'عرض التفاصيل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========= Body =========

  Widget _buildBody() {
    if (_loadErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadErrorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _initialize(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isGuestRestricted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'يتطلب هذا المحتوى تسجيل الدخول لعرض النتائج الكاملة. يمكنك تسجيل الدخول أو المحاولة مرة أخرى.',
                style: TextStyle(color: Colors.black87, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_pager.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _pager.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_pager.items.isEmpty && !_pager.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'لا توجد جهات أو متطوعون مطابقون لخيارات التصفية الحالية.',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _pager.items.length + (_pager.isLoadingMore ? 1 : 0),
      itemBuilder: (_, index) {
        if (index < _pager.items.length) {
          final account = _pager.items[index];
          return _buildAccountCard(account);
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  // ========= Pagination Bar =========

  Widget _buildPaginationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: _pager.page > 1 && !_pager.isLoading
                  ? () {
                      _pager.loadPage(_pager.page - 1);
                    }
                  : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('السابق'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'صفحة ${_pager.page} من $_totalPages',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed:
                  _pager.page < _totalPages &&
                      !_pager.isLoading &&
                      _pager.total > 0
                  ? () {
                      _pager.loadPage(_pager.page + 1);
                    }
                  : null,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('التالي'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          systemOverlayStyle: AppSystemUi.green,
          elevation: 0,
          title: const Text(
            'قائمة المتطوعين والجهات',
            style: TextStyle(
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
              _buildFiltersBar(),
              const SizedBox(height: 4),
              Expanded(
                child: _pager.isLoading ? const LoadingCenter() : _buildBody(),
              ),
              _buildPaginationBar(),
            ],
          ),
        ),
        bottomNavigationBar: const BasmaBottomNavPage(currentIndex: -1),
      ),
    );
  }
}
