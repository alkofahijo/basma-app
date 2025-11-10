import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/location_models.dart';

class RegisterCitizenPage extends StatefulWidget {
  const RegisterCitizenPage({super.key});
  @override
  State createState() => _S();
}

class _S extends State<RegisterCitizenPage> {
  final _ar = TextEditingController(),
      _en = TextEditingController(),
      _mob = TextEditingController(),
      _user = TextEditingController(),
      _pass = TextEditingController();
  Government? _gov;
  List<Government> _govs = [];
  bool _loading = true;
  String? _err;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _govs = await ApiService.governments();
    } catch (e) {
      _err = 'خطأ بالتحميل';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    try {
      await ApiService.registerCitizen({
        "name_ar": _ar.text,
        "name_en": _en.text,
        "mobile_number": _mob.text,
        "government_id": _gov?.id,
        "username": _user.text,
        "password": _pass.text,
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = 'فشل التسجيل');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل مواطن')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_err != null)
                Text(_err!, style: const TextStyle(color: Colors.red)),
              TextField(
                controller: _ar,
                decoration: const InputDecoration(labelText: 'الاسم بالعربية'),
              ),
              TextField(
                controller: _en,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالإنجليزية',
                ),
              ),
              TextField(
                controller: _mob,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              ),
              DropdownButtonFormField<Government>(
                items: _govs
                    .map(
                      (g) => DropdownMenuItem(value: g, child: Text(g.nameAr)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gov = v),
                decoration: const InputDecoration(labelText: 'المحافظة'),
              ),
              TextField(
                controller: _user,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
              ),
              TextField(
                controller: _pass,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _submit, child: const Text('تسجيل')),
            ],
          ),
        ),
      ),
    );
  }
}
