// lib/pages/profile/change_password_page.dart

import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/inputs/app_password_field.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // تأكيد قبل التغيير
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'تأكيد تغيير كلمة المرور',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('هل أنت متأكد من رغبتك في تغيير كلمة المرور؟'),
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
      final newPass = _passCtrl.text.trim();
      await ApiService.changePassword(newPass);

      if (!mounted) return;

      // نرجع true للصفحة السابقة
      Navigator.of(context).pop<bool>(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "تعذّر تغيير كلمة المرور، حاول مرة أخرى.";
      });
    }
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
            'تغيير كلمة المرور',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              return SingleChildScrollView(
                // عشان يدعم السكول لو الشاشة صغيرة أو الكيبورد طلع
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  const Text(
                                    'تحديث كلمة المرور',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'قم بإدخال كلمة المرور الجديدة ثم تأكيدها، مع مراعاة أن لا تقل عن 8 أحرف.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // كلمة المرور الجديدة
                                  AppPasswordField(
                                    controller: _passCtrl,
                                    label: 'كلمة المرور الجديدة',
                                    validator: (v) {
                                      final val = v?.trim() ?? '';
                                      if (val.isEmpty) {
                                        return 'يرجى إدخال كلمة المرور الجديدة.';
                                      }
                                      if (val.length < 8) {
                                        return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // تأكيد كلمة المرور
                                  AppPasswordField(
                                    controller: _confirmCtrl,
                                    label: 'تأكيد كلمة المرور',
                                    validator: (v) {
                                      final confirm = v?.trim() ?? '';
                                      final pass = _passCtrl.text.trim();

                                      if (confirm.isEmpty) {
                                        return 'يرجى تأكيد كلمة المرور.';
                                      }
                                      if (confirm != pass) {
                                        return 'كلمتا المرور غير متطابقتين.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

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
                                          : const Icon(
                                              Icons.save,
                                              color: Colors.white,
                                            ),
                                      label: Text(
                                        _saving
                                            ? 'جاري تغيير كلمة المرور...'
                                            : 'حفظ كلمة المرور',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
