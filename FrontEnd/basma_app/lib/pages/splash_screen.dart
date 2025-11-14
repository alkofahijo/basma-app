// lib/pages/splash_screen.dart
import 'package:basma_app/pages/home_page.dart';
import 'package:basma_app/pages/on_boarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  Future<void> _decideNext() async {
    // نعرض الشعار ثانيتين مثلاً
    await Future.delayed(const Duration(seconds: 2));

    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');

    Widget next;

    if (token != null && token.isNotEmpty) {
      // ✅ مستخدم مسجّل دخول → مباشرة إلى HomePage
      next = const HomePage();
    } else {
      // ❌ ضيف → إلى شاشة الـ OnBoarding
      next = const OnBoardingScreen();
    }

    if (!mounted) return;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEFF1F1),
      body: Center(
        child: Image(image: AssetImage("assets/images/logo-arabic.png")),
      ),
    );
  }
}
