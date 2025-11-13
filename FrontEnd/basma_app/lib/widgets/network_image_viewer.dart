import 'package:flutter/material.dart';

class NetworkImageViewer extends StatelessWidget {
  final String url;
  final double height;

  const NetworkImageViewer({super.key, required this.url, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Text("تعذّر تحميل الصورة"),
        ),
      ),
    );
  }
}
