import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:basma_app/pages/home_page.dart';

class CompleteSuccessPage extends StatelessWidget {
  final String reportCode;

  const CompleteSuccessPage({super.key, required this.reportCode});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 120, color: Colors.green),
                const SizedBox(height: 20),
                const Text(
                  "تم إكمال البلاغ بنجاح",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "رمز البلاغ: $reportCode",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Get.offAll(HomePage());
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 60,
                      vertical: 14,
                    ),
                    backgroundColor: const Color.fromARGB(255, 7, 104, 10),
                  ),
                  child: const Text(
                    "تم",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
