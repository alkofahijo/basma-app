// lib/pages/Accounts/accounts_list_page.dart

import 'package:flutter/material.dart';

import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
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
  List<Account> _accounts = [];
  List<GovernmentOption> _governments = [];
  List<AccountTypeOption> _accountTypes = [];

  // ---- Filters ----
  int? _selectedGovernmentId;
  int? _selectedAccountTypeId;

  // ---- Search ----
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ---- Pagination ----
  int _currentPage = 1;
  final int _pageSize = 20;
  int _total = 0;

  // ---- Loading / Error ----
  bool _isLoading = true;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.listGovernments(),
        ApiService.listAccountTypes(),
      ]);

      _governments = results[0] as List<GovernmentOption>;
      _accountTypes = results[1] as List<AccountTypeOption>;

      await _loadAccounts(resetPage: true);
    } catch (_) {
      _safeSetState(() {
        _isLoading = false;
        _loadErrorMessage = 'تعذّر تحميل البيانات، يرجى المحاولة لاحقاً.';
      });
    }
  }

  Future<void> _loadAccounts({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    _safeSetState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final result = await ApiService.listAccountsPaged(
        page: _currentPage,
        pageSize: _pageSize,
        governmentId: _selectedGovernmentId,
        accountTypeId: _selectedAccountTypeId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      _safeSetState(() {
        _accounts = result.items;
        _total = result.total;
      });
    } catch (_) {
      _safeSetState(() {
        _accounts = [];
        _total = 0;
        _loadErrorMessage = 'تعذّر تحميل قائمة الحسابات، يرجى المحاولة لاحقاً.';
      });
    } finally {
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }

  int get _totalPages {
    if (_total == 0) return 1;
    return ((_total + _pageSize - 1) ~/ _pageSize).clamp(1, 999999);
  }

  // ========= Filters =========

  Future<void> _onGovernmentChanged(int? id) async {
    _safeSetState(() {
      _selectedGovernmentId = id;
    });
    await _loadAccounts(resetPage: true);
  }

  Future<void> _onAccountTypeChanged(int? id) async {
    _safeSetState(() {
      _selectedAccountTypeId = id;
    });
    await _loadAccounts(resetPage: true);
  }

  // ========= UI: Dropdown helper =========

  Widget _buildDropdownFilter({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int?>> items,
    required ValueChanged<int?> onChanged,
  }) {
    final bool hasItemForValue =
        value != null && items.any((item) => item.value == value);
    final int? effectiveValue = hasItemForValue ? value : null;

    return DropdownButtonFormField<int?>(
      isExpanded: true,
      value: effectiveValue,
      items: items,
      onChanged: onChanged,
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.black87),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: kPrimaryColor.withValues(alpha: 0.9),
            width: 1.4,
          ),
        ),
      ),
      hint: Text(
        'الكل',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }

  // ========= UI: Filters Bar =========

  Widget _buildFiltersBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // العنوان الصغير
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryColor.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'استكشف المتطوعين والجهات المساهمة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 18),
              const SizedBox(height: 10),

              // المحافظة
              _buildDropdownFilter(
                label: 'المحافظة',
                value: _selectedGovernmentId,
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('الكل '),
                  ),
                  ..._governments.map(
                    (g) => DropdownMenuItem<int?>(
                      value: g.id,
                      child: Text(g.nameAr),
                    ),
                  ),
                ],
                onChanged: (value) => _onGovernmentChanged(value),
              ),
              const SizedBox(height: 12),

              // نوع الحساب
              _buildDropdownFilter(
                label: 'نوع الحساب',
                value: _selectedAccountTypeId,
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('الكل '),
                  ),
                  ..._accountTypes.map(
                    (t) => DropdownMenuItem<int?>(
                      value: t.id,
                      child: Text(t.nameAr),
                    ),
                  ),
                ],
                onChanged: (value) => _onAccountTypeChanged(value),
              ),
              const SizedBox(height: 12),

              // البحث
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  _searchQuery = value.trim();
                },
                onSubmitted: (_) => _loadAccounts(resetPage: true),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'بحث',
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  hintText: 'ابحث باسم الجهة   ...',
                  hintStyle: TextStyle(
                    fontSize: 13,
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
                            _loadAccounts(resetPage: true);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: kPrimaryColor.withValues(alpha: 0.9),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAccountDetails(account),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: صورة + تفاصيل + Chips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة (Thumbnail) بتصميم حديث
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 82,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            kPrimaryColor.withValues(alpha: 0.22),
                            const Color(0xFF4B5563).withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(
                              Icons.apartment,
                              size: 32,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // الاسم + البلاغات + Chips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: الاسم + Chips (الاسم يمين – Chips يسار في RTL)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // الاسم + البلاغات (يمين)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // اسم الجهة
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  Text(
                                    account.governmentNameAr != null &&
                                            account.governmentNameAr!.isNotEmpty
                                        ? 'المحافظة: ${account.governmentNameAr}'
                                        : '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  // عدد البلاغات المنجزة
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: kPrimaryColor.withValues(
                                            alpha: 0.09,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.done_all_rounded,
                                          size: 14,
                                          color: kPrimaryColor,
                                        ),
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

                            // Chips (نوع الجهة + المحافظة) على اليسار
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (typeName != null &&
                                        typeName.trim().isNotEmpty)
                                      Chip(
                                        label: Text(
                                          typeName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: typeColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // سطر أخير: موقع مختصر + زر "عرض التفاصيل"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // نص صغير عن المحافظة (إن وجد)
                  const SizedBox(width: 8),
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
      ),
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

    if (_accounts.isEmpty) {
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
      itemCount: _accounts.length,
      itemBuilder: (_, index) {
        final account = _accounts[index];
        return _buildAccountCard(account);
      },
    );
  }

  // ========= Pagination Bar =========

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 && !_isLoading
                ? () {
                    _currentPage -= 1;
                    _loadAccounts();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 8),
          Text(
            'صفحة $_currentPage من $_totalPages',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < _totalPages && !_isLoading && _total > 0
                ? () {
                    _currentPage += 1;
                    _loadAccounts();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
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
                child: _isLoading ? const LoadingCenter() : _buildBody(),
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
