// lib/pages/profile/profile_page.dart

import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ لإضافة الدومين على المسار النسبي
import 'package:basma_app/config/base_url.dart';
// ✅ لعرض الصورة مع إمكانية التكبير
import 'package:basma_app/pages/reports/history/widgets/zoomable_image.dart';

const Color _pageBackground = Color(0xFFEFF1F1);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _err;

  Account? _account;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final user = await AuthService.currentUser();

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _err = "الرجاء تسجيل الدخول من جديد.";
          _loading = false;
        });
        return;
      }

      final String type = (user["type"] ?? "").toString().trim();
      if (type != "account") {
        if (!mounted) return;
        setState(() {
          _err = "نوع الحساب غير مدعوم، يرجى إعادة تسجيل الدخول.";
          _loading = false;
        });
        return;
      }

      final accountId = _parseInt(user["account_id"]);
      if (accountId == null) {
        if (!mounted) return;
        setState(() {
          _err = "تعذّر تحديد هوية الحساب، يرجى إعادة تسجيل الدخول.";
          _loading = false;
        });
        return;
      }

      final acc = await ApiService.getAccount(accountId);
      if (!mounted) return;
      setState(() {
        _account = acc;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = "تعذّر تحميل بيانات الملف الشخصي.\n$e";
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await AuthService.logout();
      Get.offAll(() => const LandingPage());
    }
  }

  /// نفس منطق BeforeAfterImages لتحويل المسار النسبي إلى URL كامل
  String? _resolveLogoUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kBaseUrl$raw';
    return '$kBaseUrl/$raw';
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_loading) {
      bodyContent = const LoadingCenter();
    } else if (_err != null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _err!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    } else if (_account != null) {
      bodyContent = _buildAccountProfile(_account!);
    } else {
      bodyContent = const Center(
        child: Text("لم يتم العثور على بيانات الحساب."),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: bodyContent,
        bottomNavigationBar: const BasmaBottomNavPage(currentIndex: 3),
      ),
    );
  }

  // ============================================================
  // ACCOUNT PROFILE (موحَّد لكل أنواع الحسابات)
  // ============================================================

  Widget _buildAccountProfile(Account a) {
    return Container(
      color: _pageBackground,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildAccountHeader(a),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildAccountInfoSection(a),
                    const SizedBox(height: 16),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 250,
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "تسجيل الخروج",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountHeader(Account a) {
    final resolvedLogoUrl = _resolveLogoUrl(a.logoUrl);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                97,
                102,
                97,
              ).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(55),
              child: resolvedLogoUrl != null
                  ? ZoomableImage(imageUrl: resolvedLogoUrl)
                  : const Icon(
                      Icons.account_balance,
                      size: 64,
                      color: Color.fromARGB(255, 47, 50, 47),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            a.nameAr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(Account a) {
    // نحاول استخدام أسماء الحقول الاختيارية لو متوفرة في الموديل
    final accountTypeName = a.accountTypeNameAr ?? "غير محدد";
    final governmentName = a.governmentNameAr ?? "غير محدد";

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "تفاصيل الحساب",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "معلومات أساسية حول الحساب المساهم في حل البلاغات.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Divider(height: 16),
            InfoRow(label: "نوع الحساب", value: accountTypeName),
            InfoRow(label: "الاسم بالعربية", value: a.nameAr),
            InfoRow(label: "الاسم بالإنجليزية", value: a.nameEn ?? "---"),
            InfoRow(label: "المحافظة", value: governmentName),
            InfoRow(label: "رقم الهاتف", value: a.mobileNumber),
            InfoRow(
              label: "عدد البلاغات المنجزة",
              value: a.reportsCompletedCount.toString(),
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_reset, color: Colors.white),
                  label: const Text(
                    "تغيير كلمة المرور",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD (لأي حساب مسجَّل)
  // ============================================================

  Future<void> _showChangePasswordDialog() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                title: const Text(
                  "تغيير كلمة المرور",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "كلمة المرور الجديدة",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "تأكيد كلمة المرور",
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      "إلغاء",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final p1 = passCtrl.text.trim();
                            final p2 = confirmCtrl.text.trim();

                            if (p1.isEmpty || p2.isEmpty) {
                              setStateDialog(() {
                                error =
                                    "يرجى إدخال كلمة المرور وتأكيدها بشكل صحيح.";
                              });
                              return;
                            }
                            if (p1.length < 8) {
                              setStateDialog(() {
                                error =
                                    "كلمة المرور يجب أن تكون 8 أحرف على الأقل.";
                              });
                              return;
                            }
                            if (p1 != p2) {
                              setStateDialog(() {
                                error = "كلمتا المرور غير متطابقتين.";
                              });
                              return;
                            }

                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (cctx) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  title: const Text('تأكيد'),
                                  content: const Text(
                                    'هل أنت متأكد من رغبتك في تغيير كلمة المرور؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(cctx).pop(false),
                                      child: const Text(
                                        'لا',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(cctx).pop(true),
                                      child: const Text('نعم'),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (confirm != true) return;

                            setStateDialog(() {
                              saving = true;
                              error = null;
                            });

                            try {
                              await ApiService.changePassword(p1);
                              if (!mounted) return;
                              Navigator.of(context).pop(true);
                            } catch (_) {
                              setStateDialog(() {
                                saving = false;
                                error =
                                    "تعذّر تغيير كلمة المرور، حاول مرة أخرى.";
                              });
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("حفظ"),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم تغيير كلمة المرور بنجاح.")),
      );
    }
  }
}
