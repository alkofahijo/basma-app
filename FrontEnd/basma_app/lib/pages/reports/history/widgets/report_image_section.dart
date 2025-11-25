import 'package:basma_app/pages/reports/history/widgets/zoomable_image.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:basma_app/config/base_url.dart';

class BeforeAfterImages extends StatelessWidget {
  final String? beforeUrl;
  final String? afterUrl;

  const BeforeAfterImages({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  String? _resolve(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kBaseUrl$raw';
    return '$kBaseUrl/$raw';
  }

  @override
  Widget build(BuildContext context) {
    final before = _resolve(beforeUrl);
    final after = _resolve(afterUrl);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          after == null
              ? _buildCard(context, "الصورة قبل", before) // FULL WIDTH
              : Row(
                  children: [
                    Expanded(child: _buildCard(context, "الصورة قبل", before)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCard(context, "الصورة بعد", after)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, String? url) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),

          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            child: Builder(
              builder: (ctx) {
                final maxH = math.min(
                  420.0,
                  MediaQuery.of(ctx).size.width * 0.45,
                );
                return Container(
                  height: maxH,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: url == null
                      ? const SizedBox()
                      : ZoomableImage(imageUrl: url),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
