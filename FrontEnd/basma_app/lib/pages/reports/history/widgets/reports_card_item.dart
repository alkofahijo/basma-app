import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';
import '../../../../models/report_models.dart';

const String kApiBaseUrl = 'http://10.0.2.2:8000';

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

  String? _img(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kApiBaseUrl$raw';
    return '$kApiBaseUrl/$raw';
  }

  /// ICON BASED ON CATEGORY TYPE (from your API)
  IconData _iconForCategory(String? code) {
    switch (code) {
      case 'cleanliness':
        return Icons.cleaning_services_outlined;
      case 'potholes':
        return Icons.warning_amber_outlined;
      case 'sidewalks':
        return Icons.directions_walk;
      case 'walls':
        return Icons.crop_landscape;
      case 'planting':
        return Icons.local_florist;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _img(report.imageBeforeUrl);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 180,
                      height: 115,
                      color: Colors.grey.shade200,
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.image, size: 40),
                    ),
                  ),

                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 90.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor(
                              report.statusId,
                            ).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusNameAr(report.statusId),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor(report.statusId),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 27),
                      Row(
                        children: [
                          Icon(
                            _iconForCategory(report.typeCode),
                            color: kPrimaryColor,
                            size: 40,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            report.typeNameAr ?? "اخرى",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              /// RIGHT SIDE CONTENT
              const SizedBox(height: 8),

              Text(
                report.nameAr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              /// LOCATION
              if (report.governmentNameAr != null)
                Text(
                  "${report.governmentNameAr ?? ''} - "
                  "${report.districtNameAr ?? ''} - "
                  "${report.areaNameAr ?? ''}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // const SizedBox(height: 6),

              /// DATE — ONLY DATE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "تاريخ البلاغ: ${formatDate(report.reportedAt)}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),

                  /// VIEW DETAILS BUTTON
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 150,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCAF2DB),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        onPressed: onTap,
                        child: const Text(
                          "عرض التفاصيل",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
