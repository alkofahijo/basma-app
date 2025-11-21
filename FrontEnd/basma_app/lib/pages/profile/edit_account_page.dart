// lib/pages/profile/edit_account_page.dart

import 'dart:io';

import 'package:basma_app/models/account_models.dart';

import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/report_models.dart';

class EditAccountPage extends StatefulWidget {
  final Account account;

  const EditAccountPage({super.key, required this.account});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameArCtrl;
  late TextEditingController _nameEnCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _joinFormCtrl;

  bool _saving = false;
  String? _error;

  // لوك أب
  List<AccountTypeOption> _accountTypes = [];
  List<GovernmentOption> _governments = [];

  int? _selectedAccountTypeId;
  int? _selectedGovernmentId;
  bool _showDetails = true;

  // الشعار
  final ImagePicker _picker = ImagePicker();
  File? _logoFile; // صورة جديدة من الجهاز (إن وُجدت)
  String? _currentLogoUrl; // رابط الشعار الحالي من الـ backend

  @override
  void initState() {
    super.initState();

    final a = widget.account;

    _nameArCtrl = TextEditingController(text: a.nameAr);
    _nameEnCtrl = TextEditingController(text: a.nameEn ?? '');
    _mobileCtrl = TextEditingController(text: a.mobileNumber);
    _joinFormCtrl = TextEditingController(text: a.joinFormLink ?? '');

    _selectedAccountTypeId = a.accountTypeId;
    _selectedGovernmentId = a.governmentId;
    _showDetails = a.showDetails;

    _currentLogoUrl = a.logoUrl;

    _loadLookups();
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _mobileCtrl.dispose();
    _joinFormCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final at = await ApiService.listAccountTypes();
      final govs = await ApiService.listGovernments();

      if (!mounted) return;

      setState(() {
        _accountTypes = at;
        _governments = govs;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error ??= "تعذّر تحميل بيانات أنواع الحساب والمحافظات.";
      });
    }
  }

  Future<void> _pickLogoImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _logoFile = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountTypeId == null || _selectedGovernmentId == null) {
      setState(() {
        _error = "يرجى اختيار نوع الحساب والمحافظة.";
      });
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد التعديل'),
          content: const Text(
            'هل أنت متأكد من حفظ التعديلات على بيانات الحساب؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // 1) رفع الشعار لو تم اختيار صورة جديدة
      String? logoUrlToSend;
      if (_logoFile != null) {
        final bytes = await _logoFile!.readAsBytes();
        // اسم افتراضي للملف
        final fileName = 'account_logo_${widget.account.id}.jpg';
        logoUrlToSend = await ApiService.uploadImage(bytes, fileName);
        _currentLogoUrl = logoUrlToSend;
      }

      // 2) تجهيز البودي
      final payload = <String, dynamic>{
        'name_ar': _nameArCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim().isEmpty
            ? null
            : _nameEnCtrl.text.trim(),
        'mobile_number': _mobileCtrl.text.trim(),
        'join_form_link': _joinFormCtrl.text.trim().isEmpty
            ? null
            : _joinFormCtrl.text.trim(),
        'account_type_id': _selectedAccountTypeId,
        'government_id': _selectedGovernmentId,
        'show_details': _showDetails ? 1 : 0,
        // نرسل logo_url فقط لو رفعنا شعار جديد
        if (logoUrlToSend != null) 'logo_url': logoUrlToSend,
      };

      // إزالة nulls من البودي
      payload.removeWhere((key, value) => value == null);

      // 3) استدعاء API للتعديل
      final updated = await ApiService.updateAccount(
        widget.account.id,
        payload,
      );

      if (!mounted) return;

      // 4) نرجع الحساب المحدَّث للصفحة السابقة
      Navigator.of(context).pop<Account>(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث بيانات الحساب بنجاح.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildLogoPicker() {
    ImageProvider? bgImage;

    if (_logoFile != null) {
      bgImage = FileImage(_logoFile!);
    } else if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) {
      bgImage = NetworkImage(_currentLogoUrl!);
    }

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: bgImage,
                child: bgImage == null
                    ? const Icon(
                        Icons.account_circle_outlined,
                        color: Colors.grey,
                        size: 40,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _saving ? null : _pickLogoImage,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _saving ? Colors.grey : kPrimaryColor,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'يمكنك تغيير شعار الجهة بالضغط على أيقونة الكاميرا.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
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
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text(
            'تعديل بيانات الحساب',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // شعار الحساب
                  _buildLogoPicker(),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameArCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالعربية',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'الاسم بالعربية مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameEnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالإنجليزية (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) {
                        return 'رقم الهاتف مطلوب';
                      }
                      if (val.length < 9) {
                        return 'يرجى إدخال رقم هاتف صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _joinFormCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رابط نموذج الانضمام (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // نوع الحساب
                  DropdownButtonFormField<int>(
                    initialValue: _selectedAccountTypeId,
                    decoration: const InputDecoration(
                      labelText: 'نوع الحساب',
                      border: OutlineInputBorder(),
                    ),
                    items: _accountTypes
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.nameAr),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedAccountTypeId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // المحافظة (مع التعامل مع null في GovernmentOption)
                  DropdownButtonFormField<int>(
                    initialValue: _selectedGovernmentId,
                    decoration: const InputDecoration(
                      labelText: 'المحافظة',
                      border: OutlineInputBorder(),
                    ),
                    items: _governments
                        // ignore: unnecessary_null_comparison
                        .where((g) => g.id != null)
                        .map(
                          (g) => DropdownMenuItem<int>(
                            value: g.id,
                            child: Text(g.nameAr),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedGovernmentId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text('عرض تفاصيل الحساب للعامة'),
                    subtitle: const Text(
                      'في حال الإيقاف لن يظهر رقم الهاتف/التفاصيل في الواجهة العامة.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _showDetails,
                    activeThumbColor: kPrimaryColor,
                    onChanged: (v) {
                      setState(() {
                        _showDetails = v;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _saving ? 'جاري الحفظ...' : 'حفظ التعديلات',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
