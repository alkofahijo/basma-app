// lib/pages/profile/profile_page.dart
import 'package:flutter/material.dart';

import 'package:basma_app/models/citizen_models.dart';
import 'package:basma_app/models/initiative_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:basma_app/widgets/loading_center.dart';

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

  /// تحويل ديناميكي إلى int بأمان (مثل ما عملته في SolveReportDialog)
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

        final c = await ApiService.getCitizen(citizenId);
        if (!mounted) return;
        setState(() {
          _userType = 'citizen';
          _citizen = c;
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

        final i = await ApiService.getInitiative(initiativeId);
        if (!mounted) return;
        setState(() {
          _userType = 'initiative';
          _initiative = i;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingCenter();

    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _err!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_userType == 'citizen' && _citizen != null) {
      return _buildCitizenProfile(_citizen!);
    }

    if (_userType == 'initiative' && _initiative != null) {
      return _buildInitiativeProfile(_initiative!);
    }

    return const Center(child: Text("لم يتم العثور على بيانات الملف الشخصي."));
  }

  // ============================================================
  // CITIZEN PROFILE
  // ============================================================

  Widget _buildCitizenProfile(Citizen c) {
    return Container(
      color: const Color(0xFFF4F7F8),
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildCitizenHeader(c),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildCitizenStatsRow(c),
                    const SizedBox(height: 16),
                    _buildCitizenInfoSection(c),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _editCitizenProfile,
                            icon: const Icon(Icons.edit),
                            label: const Text("تعديل بياناتي"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _showChangePasswordDialog,
                            icon: const Icon(Icons.lock_reset),
                            label: const Text("تغيير كلمة المرور"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ],
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.teal.shade600, Colors.teal.shade400],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 40,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.nameAr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (c.nameEn.isNotEmpty)
                    Text(
                      c.nameEn,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.mobileNumber,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitizenStatsRow(Citizen c) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.verified_rounded,
            title: "البلاغات المنجزة",
            value: "${c.reportsCompletedCount}",
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildCitizenInfoSection(Citizen c) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  "تفاصيل المواطن",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("تعديل بيانات المواطن"),
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
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
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
      color: const Color(0xFFF4F7F8),
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildInitiativeHeader(i),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInitiativeStatsRow(i),
                    const SizedBox(height: 16),
                    _buildInitiativeInfoSection(i),
                    const SizedBox(height: 16),
                    if (i.joinFormLink != null &&
                        i.joinFormLink!.trim().isNotEmpty)
                      _buildJoinSection(i.joinFormLink!),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _editInitiativeProfile,
                            icon: const Icon(Icons.edit),
                            label: const Text("تعديل بيانات المبادرة"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _showChangePasswordDialog,
                            icon: const Icon(Icons.lock_reset),
                            label: const Text("تغيير كلمة المرور"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ],
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.teal.shade600, Colors.teal.shade400],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: i.logoUrl != null && i.logoUrl!.isNotEmpty
                    ? NetworkImageViewer(url: i.logoUrl!, height: 70)
                    : Icon(
                        Icons.volunteer_activism,
                        size: 36,
                        color: Colors.white.withOpacity(0.9),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.nameAr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (i.nameEn.isNotEmpty)
                    Text(
                      i.nameEn,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_in_talk,
                        size: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        i.mobileNumber,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitiativeStatsRow(Initiative i) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.groups_rounded,
            title: "عدد الأعضاء",
            value: "${i.membersCount}",
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.done_all_rounded,
            title: "البلاغات المنجزة",
            value: "${i.reportsCompletedCount}",
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildInitiativeInfoSection(Initiative i) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  "تفاصيل المبادرة",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
          ],
        ),
      ),
    );
  }

  Widget _buildJoinSection(String link) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person_add_alt_1, size: 18, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  "الانضمام إلى المبادرة",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "يمكنك التقدّم للانضمام للمبادرة من خلال الرابط التالي:",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.teal,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("تعديل بيانات المبادرة"),
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
                  TextField(
                    controller: joinFormCtrl,
                    decoration: const InputDecoration(
                      labelText: "رابط نموذج الانضمام (اختياري)",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nameAr = nameArCtrl.text.trim();
                  final nameEn = nameEnCtrl.text.trim();
                  final mobile = mobileCtrl.text.trim();
                  final joinFormLink = joinFormCtrl.text.trim();

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
                      joinFormLink: joinFormLink.isEmpty ? null : joinFormLink,
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
  // CHANGE PASSWORD DIALOG  (citizen + initiative)
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text("تغيير كلمة المرور"),
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
                    child: const Text("إلغاء"),
                  ),
                  ElevatedButton(
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
                            if (p1.length < 6) {
                              setStateDialog(() {
                                error =
                                    "كلمة المرور يجب أن تكون 6 أحرف على الأقل.";
                              });
                              return;
                            }
                            if (p1 != p2) {
                              setStateDialog(() {
                                error = "كلمتا المرور غير متطابقتين.";
                              });
                              return;
                            }

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

  // ============================================================
  // COMMON STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
