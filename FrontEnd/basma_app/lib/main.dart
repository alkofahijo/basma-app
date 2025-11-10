import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const BasmaApp());
}

class BasmaApp extends StatelessWidget {
  const BasmaApp({super.key});
  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
      title: 'Basma App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
