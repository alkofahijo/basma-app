import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../report/select_location_page.dart';
import 'register_choice_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _loading = false;
  String? _err;
  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await ApiService.login(_u.text.trim(), _p.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SelectLocationPage()),
      );
    } catch (e) {
      setState(() => _err = 'فشل تسجيل الدخول');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_err != null)
              Text(_err!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: _u,
              decoration: const InputDecoration(labelText: 'اسم المستخدم'),
            ),
            TextField(
              controller: _p,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('دخول'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterChoicePage()),
              ),
              child: const Text('تسجيل جديد'),
            ),
          ],
        ),
      ),
    );
  }
}
