import 'package:flutter/material.dart';
import 'register_citizen_page.dart';
import 'register_initiative_page.dart';

class RegisterChoicePage extends StatelessWidget {
  const RegisterChoicePage({super.key});
  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('التسجيل')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const RegisterCitizenPage()),
              ),
              child: const Text('مواطن'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => const RegisterInitiativePage(),
                ),
              ),
              child: const Text('مبادرة'),
            ),
          ],
        ),
      ),
    );
  }
}
