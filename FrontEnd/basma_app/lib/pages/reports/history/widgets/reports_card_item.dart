import 'package:flutter/material.dart';

import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/config/base_url.dart';

class GuestReportCard extends StatelessWidget {
  final ReportPublicSummary report;
  final VoidCallback onTap;

  final String Function(DateTime?) formatDate;
  final Color Function(int) statusColor;
  final String Function(int) statusNameAr;

  const GuestReportCard({
    super.key,
    required this.report,
    required this.onTap,
    required this.formatDate,
    required this.statusColor,
    required this.statusNameAr,
  });

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kBaseUrl$raw';
    return '$kBaseUrl/$raw';
  }

  IconData _iconForCategory(String? code) {
    switch (code) {
      case 'GRAFFITI':
        return Icons.format_paint; // رسم / كتابة على الجدران

      case 'FADED_SIGNAGE':
        return Icons.signpost_outlined; // لافتة باهتة

      case 'POTHOLES':
        return Icons.warning_amber_outlined; // حفر

      case 'GARBAGE':
        return Icons.delete_outline; // نفايات

      case 'CONSTRUCTION_ROAD':
        return Icons.engineering; // طريق قيد الإنشاء

      case 'BROKEN_SIGNAGE':
        return Icons.report_gmailerrorred_outlined; // لافتة مكسورة

      case 'BAD_BILLBOARD':
        return Icons.broken_image_outlined; // لوحة إعلانات تالفة

      case 'SAND_ON_ROAD':
        return Icons.landscape_outlined; // أتربة على الطريق

      case 'CLUTTER_SIDEWALK':
        return Icons.directions_walk; // رصيف غير صالح للمشي

      case 'UNKEPT_FACADE':
        return Icons.apartment_outlined; // واجهة مبنى سيئة المظهر

      case 'OTHERS':
        return Icons.category_outlined;

      default:
        return Icons.help_outline; // Unknown
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(report.imageBeforeUrl);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصورة + الحالة + نوع التشوّه
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 140,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // النصوص على اليمين
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // شارة الحالة
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor(
                                report.statusId,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusNameAr(report.statusId),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: statusColor(report.statusId),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              _iconForCategory(report.typeCode),
                              color: kPrimaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                report.typeNameAr ?? "أخرى",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // عنوان البلاغ
              Text(
                report.nameAr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // الموقع
              if (report.governmentNameAr != null)
                Text(
                  "${report.governmentNameAr ?? ''} - "
                  "${report.districtNameAr ?? ''} - "
                  "${report.areaNameAr ?? ''}",
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),

              // التاريخ + زر التفاصيل
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "تاريخ البلاغ: ${formatDate(report.reportedAt)}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "عرض التفاصيل",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
