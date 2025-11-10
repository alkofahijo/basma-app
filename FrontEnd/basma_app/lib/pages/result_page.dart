import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String governmentNameAr;
  final String districtNameAr;
  final String areaNameAr;

  const ResultPage({
    super.key,
    required this.governmentNameAr,
    required this.districtNameAr,
    required this.areaNameAr,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      appBar: AppBar(title: const Text('الاختيار')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Directionality(
          textDirection: TextDirection.rtl, // Arabic-friendly
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المحافظة:', style: textStyle),
              Text(governmentNameAr),
              const SizedBox(height: 16),
              Text('اللواء/القضاء:', style: textStyle),
              Text(districtNameAr),
              const SizedBox(height: 16),
              Text('المنطقة:', style: textStyle),
              Text(areaNameAr),
            ],
          ),
        ),
      ),
    );
  }
}
