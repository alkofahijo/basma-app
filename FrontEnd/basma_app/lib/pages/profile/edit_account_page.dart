// lib/pages/profile/edit_account_page.dart

import 'dart:io';

import 'package:basma_app/config/base_url.dart';
import 'package:basma_app/models/account_models.dart';
import 'package:basma_app/services/upload_service.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/inputs/app_text_field.dart';
import 'package:basma_app/widgets/inputs/app_dropdown_form_field.dart';
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
  String? _currentLogoUrl; // رابط الشعار الحالي من الـ backend (نسبي غالباً)

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

  /// تحويل المسار النسبي من الـ backend إلى رابط كامل قابل للعرض
  String? _resolveLogoUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kBaseUrl$raw';
    return '$kBaseUrl/$raw';
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
    // يتحقق من كل الـ validators بما فيها الدروب داونز
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'تأكيد التعديل',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
        final fileName = 'account_logo_${widget.account.id}.jpg';
        logoUrlToSend = await UploadService.uploadImage(bytes, fileName);
        _currentLogoUrl = logoUrlToSend;
      }

      // 2) تجهيز البودي (كل الحقول مطلوبة الآن)
      final payload = <String, dynamic>{
        'name_ar': _nameArCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim(),
        'mobile_number': _mobileCtrl.text.trim(),
        'join_form_link': _joinFormCtrl.text.trim(),
        'account_type_id': _selectedAccountTypeId,
        'government_id': _selectedGovernmentId,
        'show_details': _showDetails ? 1 : 0,
        if (logoUrlToSend != null) 'logo_url': logoUrlToSend,
      };

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

  /// label مع نجمة حمراء للحقل الإلزامي
  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPicker() {
    ImageProvider? bgImage;

    if (_logoFile != null) {
      bgImage = FileImage(_logoFile!);
    } else if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) {
      final resolved = _resolveLogoUrl(_currentLogoUrl);
      if (resolved != null) {
        bgImage = NetworkImage(resolved);
      }
    }

    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: bgImage,
                child: bgImage == null
                    ? const Icon(
                        Icons.account_balance,
                        color: Colors.grey,
                        size: 46,
                      )
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: _saving ? null : _pickLogoImage,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _saving ? Colors.grey : kPrimaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
        backgroundColor: const Color(0xFFEFF1F1),
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text(
            'تعديل بيانات الحساب',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _buildLogoPicker(),
                      const SizedBox(height: 20),

                      const Text(
                        'بيانات الجهة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // الاسم بالعربية (إلزامي)
                      AppTextField(
                        controller: _nameArCtrl,
                        labelWidget: _buildRequiredLabel('الاسم بالعربية'),
                        errorText: null,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'الاسم بالعربية مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // الاسم بالإنجليزية (إلزامي)
                      AppTextField(
                        controller: _nameEnCtrl,
                        labelWidget: _buildRequiredLabel('الاسم بالإنجليزية'),
                        errorText: null,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'الاسم بالإنجليزية مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // رقم الهاتف (إلزامي، 10 أرقام، يبدأ بـ 07)
                      AppTextField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        labelWidget: _buildRequiredLabel('رقم الهاتف'),
                        hint: 'مثال: 07XXXXXXXX',
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) {
                            return 'رقم الهاتف مطلوب';
                          }
                          final regex = RegExp(r'^07\d{8}$');
                          if (!regex.hasMatch(val)) {
                            return 'رقم الهاتف يجب أن يبدأ بـ 07 ويتكون من 10 أرقام';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // رابط نموذج التقديم / موقع أو صفحة الجهة (إلزامي فقط)
                      AppTextField(
                        controller: _joinFormCtrl,
                        labelWidget: _buildRequiredLabel(
                          'رابط نموذج التقديم / موقع أو صفحة الجهة',
                        ),
                        hint: 'مثال: https://example.com',
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) {
                            return 'هذا الحقل مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // نوع الحساب (إلزامي)
                      AppDropdownFormField<int>(
                        value: _selectedAccountTypeId,
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
                        labelWidget: _buildRequiredLabel('نوع الحساب'),
                        isEnabled: true,
                      ),
                      const SizedBox(height: 12),

                      // المحافظة (إلزامية)
                      AppDropdownFormField<int>(
                        value: _selectedGovernmentId,
                        items: _governments
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
                        labelWidget: _buildRequiredLabel('المحافظة'),
                        isEnabled: true,
                      ),
                      const SizedBox(height: 8),

                      // عرض التفاصيل للعامة (اختياري سويتش)
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
                      const SizedBox(height: 8),

                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
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
                              borderRadius: BorderRadius.circular(14),
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
        ),
      ),
    );
  }
}
