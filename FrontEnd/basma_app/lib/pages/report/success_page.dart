import 'package:flutter/material.dart';

class SuccessPage extends StatelessWidget {
  final String reportCode;
  const SuccessPage({super.key, required this.reportCode});
  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('تم الإرسال')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72),
            const SizedBox(height: 12),
            const Text('تم استلام البلاغ وحالته: قيد المراجعة'),
            const SizedBox(height: 8),
            Text('رمز المتابعة: $reportCode'),
          ],
        ),
      ),
    );
  }
}
