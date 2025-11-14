import 'package:flutter/material.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';

/// 🔥 عدّل هذا الـ baseUrl حسب بيئة السيرفر:
/// - Android Emulator:  http://10.0.2.2:8000
/// - iOS Simulator / Web / نفس الجهاز: http://127.0.0.1:8000 أو IP حقيقي
const String kApiBaseUrl = 'http://10.0.2.2:8000';

class ReportImageSection extends StatelessWidget {
  final String title;
  final String? rawUrl;

  const ReportImageSection({
    super.key,
    required this.title,
    required this.rawUrl,
  });

  String? _buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return null;

    // لو الـ API رجّع URL كامل
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    // لو رجع مسار نسبي مثل /static/uploads/xxx.jpg
    if (rawPath.startsWith('/')) {
      return '$kApiBaseUrl$rawPath';
    }

    // أي مسار نسبي بدون / في البداية
    return '$kApiBaseUrl/$rawPath';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _buildImageUrl(rawUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        if (resolvedUrl != null)
          // نستفيد من الـ NetworkImageViewer الموجود عندك أصلاً
          NetworkImageViewer(url: resolvedUrl)
        else
          Container(
            width: double.infinity,
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
}
