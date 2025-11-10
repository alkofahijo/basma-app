import 'package:flutter/material.dart';
import 'guest/guest_select_page.dart';
import 'auth/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basma App')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuestSelectPage()),
              ),
              child: const Text('تصفح كتصفح ضيف'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              child: const Text('تسجيل الدخول / التسجيل'),
            ),
          ],
        ),
      ),
    );
  }
}
