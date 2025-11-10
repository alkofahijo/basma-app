// lib/pages/auth/register_initiative_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Resolves the proper base URL depending on where the app runs.
/// - Android emulator must use 10.0.2.2 to hit your host machine.
/// - iOS simulator & Web can use localhost.
/// - For a physical device on the same LAN, replace with your PC's LAN IP (e.g., http://192.168.1.50:8000).
String _resolveBaseUrl() {
  if (kIsWeb) return "http://localhost:8000";
  if (Platform.isAndroid) return "http://10.0.2.2:8000";
  // iOS simulator / desktop
  return "http://127.0.0.1:8000";
}

class RegisterInitiativePage extends StatefulWidget {
  const RegisterInitiativePage({super.key});

  @override
  State<RegisterInitiativePage> createState() => _RegisterInitiativePageState();
}

class _RegisterInitiativePageState extends State<RegisterInitiativePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _joinFormCtrl = TextEditingController(); // optional
  final _logoUrlCtrl = TextEditingController(); // optional
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Governments dropdown
  List<_Government> _governments = [];
  int? _selectedGovernmentId;

  // State
  bool _loadingGovs = false;
  bool _submitting = false;
  String? _loadError;

  String get _baseUrl => _resolveBaseUrl();

  @override
  void initState() {
    super.initState();
    _fetchGovernments();
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _mobileCtrl.dispose();
    _joinFormCtrl.dispose();
    _logoUrlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGovernments() async {
    setState(() {
      _loadingGovs = true;
      _loadError = null;
    });
    try {
      // Correct endpoint according to your backend:
      // GET /locations/governments
      final uri = Uri.parse("$_baseUrl/locations/governments");

      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 10)); // avoid hanging forever

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        final govs = data
            .map(
              (e) => _Government(
                id: (e['id'] as num).toInt(),
                nameAr: (e['name_ar'] as String?) ?? '',
                nameEn: (e['name_en'] as String?) ?? '',
              ),
            )
            .cast<_Government>()
            .toList();

        setState(() {
          _governments = govs;
          if (govs.isNotEmpty) _selectedGovernmentId = govs.first.id;
        });
      } else {
        setState(() {
          _loadError = "Failed to load governments (HTTP ${res.statusCode}).";
        });
      }
    } on SocketException catch (e) {
      setState(() {
        _loadError =
            "تعذر الاتصال بالخادم (${e.osError?.errorCode ?? ''}).\n"
            "تأكد من تشغيل الخادم على $_baseUrl وأن جدار الحماية يسمح بالاتصال.\n"
            "ملاحظة: على محاكي أندرويد استخدم 10.0.2.2 للوصول إلى جهاز التطوير.";
      });
    } on HttpException catch (e) {
      setState(() {
        _loadError = "HTTP error: $e";
      });
    } on FormatException {
      setState(() {
        _loadError = "Unexpected response format (JSON parsing failed).";
      });
    } on TimeoutException {
      setState(() {
        _loadError =
            "انتهت مهلة الاتصال. تأكد من أن الخادم يعمل على $_baseUrl.";
      });
    } catch (e) {
      setState(() {
        _loadError = "Failed to load governments: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingGovs = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;
    if (_selectedGovernmentId == null) {
      _showSnack("الرجاء اختيار المحافظة");
      return;
    }

    final payload = {
      "name_ar": _nameArCtrl.text.trim(),
      "name_en": _nameEnCtrl.text.trim(),
      "mobile_number": _mobileCtrl.text.trim(),
      "join_form_link": _joinFormCtrl.text.trim().isEmpty
          ? null
          : _joinFormCtrl.text.trim(),
      "government_id": _selectedGovernmentId,
      "logo_url": _logoUrlCtrl.text.trim().isEmpty
          ? null
          : _logoUrlCtrl.text.trim(),
      "username": _usernameCtrl.text.trim(),
      "password": _passwordCtrl.text,
    };

    setState(() => _submitting = true);
    try {
      final uri = Uri.parse("$_baseUrl/auth/register/initiative");
      final res = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 201 || res.statusCode == 200) {
        _showDialogSuccess();
      } else {
        String msg = "تعذر إنشاء الحساب (${res.statusCode})";
        try {
          final body = jsonDecode(utf8.decode(res.bodyBytes));
          if (body is Map && body['detail'] != null) {
            msg = body['detail'].toString();
          }
        } catch (_) {}
        _showSnack(msg);
      }
    } on SocketException {
      _showSnack(
        "تعذر الاتصال بالخادم. تأكد من تشغيله على $_baseUrl ومن إعدادات الشبكة.",
      );
    } on TimeoutException {
      _showSnack("انتهت مهلة الاتصال بالخادم. حاول مرة أخرى.");
    } catch (e) {
      _showSnack("حدث خطأ أثناء الإرسال: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showDialogSuccess() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تم إنشاء المبادرة"),
        content: const Text(
          "تم تسجيل حساب المبادرة بنجاح. يمكنك تسجيل الدخول الآن.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  String? _requiredValidator(String? v, {String label = "هذا الحقل"}) {
    if (v == null || v.trim().isEmpty) return "$label مطلوب";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("تسجيل مبادرة")),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _loadingGovs
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                  ? _ErrorReload(
                      message: _loadError!,
                      onRetry: _fetchGovernments,
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          // Names
                          Text(
                            "معلومات المبادرة",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameArCtrl,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: "اسم المبادرة (عربي)",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _requiredValidator(
                              v,
                              label: "اسم المبادرة بالعربية",
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameEnCtrl,
                            decoration: const InputDecoration(
                              labelText: "اسم المبادرة (English)",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => _requiredValidator(
                              v,
                              label: "اسم المبادرة بالإنجليزية",
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mobile
                          TextFormField(
                            controller: _mobileCtrl,
                            decoration: const InputDecoration(
                              labelText: "رقم الجوال",
                              hintText: "07XXXXXXXX",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                _requiredValidator(v, label: "رقم الجوال"),
                          ),
                          const SizedBox(height: 12),

                          // Optional fields
                          TextFormField(
                            controller: _joinFormCtrl,
                            decoration: const InputDecoration(
                              labelText: "رابط نموذج الانضمام (اختياري)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _logoUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: "رابط الشعار (اختياري)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Government dropdown
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "المحافظة",
                              border: OutlineInputBorder(),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: _selectedGovernmentId,
                                items: _governments
                                    .map(
                                      (g) => DropdownMenuItem<int>(
                                        value: g.id,
                                        child: Text(
                                          "${g.nameAr} (${g.nameEn})",
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedGovernmentId = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Account
                          Text(
                            "بيانات الحساب",
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              labelText: "اسم المستخدم",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                _requiredValidator(v, label: "اسم المستخدم"),
                          ),
                          const SizedBox(height: 12),
                          StatefulBuilder(
                            builder: (context, setSB) {
                              return _PasswordField(
                                controller: _passwordCtrl,
                                label: "كلمة المرور",
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.app_registration),
                              label: const Text("تسجيل المبادرة"),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple password field with show/hide toggle.
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PasswordField({required this.controller, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "كلمة المرور مطلوبة";
        if (v.length < 6) return "كلمة المرور يجب ألا تقل عن 6 أحرف";
        return null;
      },
    );
  }
}

class _Government {
  final int id;
  final String nameAr;
  final String nameEn;
  _Government({required this.id, required this.nameAr, required this.nameEn});
}

class _ErrorReload extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorReload({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("إعادة المحاولة"),
          ),
        ],
      ),
    );
  }
}
