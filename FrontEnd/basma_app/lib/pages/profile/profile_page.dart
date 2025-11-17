// lib/pages/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:basma_app/models/citizen_models.dart';
import 'package:basma_app/models/initiative_models.dart';
import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:basma_app/widgets/basma_bottom_nav.dart';
import 'package:basma_app/theme/app_colors.dart';

// use central primary color
const Color _pageBackground = Color(0xFFEFF1F1);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _err;

  String? _userType; // 'citizen' أو 'initiative'
  Citizen? _citizen;
  Initiative? _initiative;

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

      if (type == "citizen") {
        final citizenId = _parseInt(user["citizen_id"]);
        if (citizenId == null) {
          if (!mounted) return;
          setState(() {
            _err = "تعذّر تحديد هوية المواطن، يرجى إعادة تسجيل الدخول.";
            _loading = false;
          });
          return;
        }

        final citizen = await ApiService.getCitizen(citizenId);
        if (!mounted) return;
        setState(() {
          _userType = 'citizen';
          _citizen = citizen;
          _initiative = null;
          _loading = false;
        });
      } else if (type == "initiative") {
        final initiativeId = _parseInt(user["initiative_id"]);
        if (initiativeId == null) {
          if (!mounted) return;
          setState(() {
            _err = "تعذّر تحديد هوية المبادرة، يرجى إعادة تسجيل الدخول.";
            _loading = false;
          });
          return;
        }

        final initiative = await ApiService.getInitiative(initiativeId);
        if (!mounted) return;
        setState(() {
          _userType = 'initiative';
          _initiative = initiative;
          _citizen = null;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _err = "نوع الحساب غير مدعوم، يرجى إعادة تسجيل الدخول.";
          _loading = false;
        });
      }
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
      await ApiService.setToken(null);
      final sp = await SharedPreferences.getInstance();
      await sp.remove('user_type');
      await sp.remove('citizen_id');
      await sp.remove('initiative_id');

      Get.offAll(() => LandingPage());
    }
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
    } else if (_userType == 'citizen' && _citizen != null) {
      bodyContent = _buildCitizenProfile(_citizen!);
    } else if (_userType == 'initiative' && _initiative != null) {
      bodyContent = _buildInitiativeProfile(_initiative!);
    } else {
      bodyContent = const Center(
        child: Text("لم يتم العثور على بيانات الملف الشخصي."),
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
  // CITIZEN PROFILE
  // ============================================================

  Widget _buildCitizenProfile(Citizen c) {
    return Container(
      color: _pageBackground,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildCitizenHeader(c),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildCitizenInfoSection(c),
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

  Widget _buildCitizenHeader(Citizen c) {
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

  Widget _buildCitizenInfoSection(Citizen c) {
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
              children: [
                const Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    "تفاصيل المواطن",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _editCitizenProfile,
                  icon: const Icon(Icons.edit, color: kPrimaryColor),
                  tooltip: 'تعديل',
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
            InfoRow(
              label: "عدد البلاغات المنجزة",
              value: c.reportsCompletedCount.toString(),
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_reset, color: Colors.white),
                  label: const Text("تغيير كلمة المرور"),
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

  Future<void> _editCitizenProfile() async {
    if (_citizen == null) return;
    final c = _citizen!;

    final nameArCtrl = TextEditingController(text: c.nameAr);
    final nameEnCtrl = TextEditingController(text: c.nameEn);
    final mobileCtrl = TextEditingController(text: c.mobileNumber);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            title: const Text(
              "تعديل بيانات المواطن",
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
                    controller: nameArCtrl,
                    decoration: const InputDecoration(
                      labelText: "الاسم بالعربية",
                    ),
                  ),
                  TextField(
                    controller: nameEnCtrl,
                    decoration: const InputDecoration(
                      labelText: "الاسم بالإنجليزية",
                    ),
                  ),
                  TextField(
                    controller: mobileCtrl,
                    decoration: const InputDecoration(labelText: "رقم الهاتف"),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
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
                onPressed: () async {
                  final nameAr = nameArCtrl.text.trim();
                  final nameEn = nameEnCtrl.text.trim();
                  final mobile = mobileCtrl.text.trim();

                  if (nameAr.isEmpty || mobile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("الاسم بالعربية ورقم الهاتف مطلوبان"),
                      ),
                    );
                    return;
                  }

                  try {
                    await ApiService.updateCitizenProfile(
                      id: c.id,
                      nameAr: nameAr,
                      nameEn: nameEn,
                      mobileNumber: mobile,
                    );
                    if (!mounted) return;
                    Navigator.of(ctx).pop(true);
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تعذّر حفظ التعديلات.")),
                    );
                  }
                },
                child: const Text("حفظ"),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      await _loadProfile();
    }
  }

  // ============================================================
  // INITIATIVE PROFILE
  // ============================================================

  Widget _buildInitiativeProfile(Initiative i) {
    return Container(
      color: _pageBackground,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildInitiativeHeader(i),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInitiativeInfoSection(i),
                    const SizedBox(height: 16),

                    Center(
                      child: SizedBox(
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

  Widget _buildInitiativeHeader(Initiative i) {
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(55),
              child: i.logoUrl != null && i.logoUrl!.isNotEmpty
                  ? NetworkImageViewer(url: i.logoUrl!, height: 110)
                  : const Icon(
                      Icons.volunteer_activism,
                      size: 64,
                      color: Color.fromARGB(255, 47, 50, 47),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            i.nameAr,
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

  Widget _buildInitiativeInfoSection(Initiative i) {
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
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    "تفاصيل المبادرة",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _editInitiativeProfile,
                  icon: const Icon(Icons.edit, color: kPrimaryColor),
                  tooltip: 'تعديل',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "معلومات أساسية حول المبادرة وقنوات التواصل.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            const Divider(height: 16),
            InfoRow(label: "اسم المبادرة", value: i.nameAr),
            InfoRow(label: "الاسم بالإنجليزية", value: i.nameEn),
            InfoRow(label: "رقم الهاتف", value: i.mobileNumber),
            InfoRow(
              label: "عدد البلاغات المنجزة",
              value: i.reportsCompletedCount.toString(),
            ),
            InfoRow(
              label: "رابط نموذج الانضمام",
              value: i.joinFormLink ?? "غير متوفر",
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

  Future<void> _editInitiativeProfile() async {
    if (_initiative == null) return;
    final i = _initiative!;

    final nameArCtrl = TextEditingController(text: i.nameAr);
    final nameEnCtrl = TextEditingController(text: i.nameEn);
    final mobileCtrl = TextEditingController(text: i.mobileNumber);
    final joinFormCtrl = TextEditingController(text: i.joinFormLink ?? "");

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            title: const Text(
              "تعديل بيانات المبادرة",
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
                    controller: nameArCtrl,
                    decoration: const InputDecoration(
                      labelText: "الاسم بالعربية",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameEnCtrl,
                    decoration: const InputDecoration(
                      labelText: "الاسم بالإنجليزية",
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: mobileCtrl,
                    decoration: const InputDecoration(labelText: "رقم الهاتف"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: joinFormCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رابط نموذج الانضمام (اختياري)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
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
                onPressed: () async {
                  final nameAr = nameArCtrl.text.trim();
                  final nameEn = nameEnCtrl.text.trim();
                  final mobile = mobileCtrl.text.trim();

                  if (nameAr.isEmpty || mobile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("الاسم بالعربية ورقم الهاتف مطلوبان"),
                      ),
                    );
                    return;
                  }

                  try {
                    await ApiService.updateInitiativeProfile(
                      id: i.id,
                      nameAr: nameAr,
                      nameEn: nameEn,
                      mobileNumber: mobile,
                      joinFormLink: joinFormCtrl.text.trim().isEmpty
                          ? null
                          : joinFormCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.of(ctx).pop(true);
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تعذّر حفظ التعديلات.')),
                    );
                  }
                },
                child: const Text("حفظ"),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      await _loadProfile();
    }
  }

  // ============================================================
  // CHANGE PASSWORD (citizen + initiative)
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
                              Navigator.of(ctx).pop(true);
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
