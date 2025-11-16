import 'package:flutter/material.dart';
import '../../../models/report_models.dart';

/// 🔥 عدّل هذا الـ baseUrl ليناسب بيئتك
/// Android Emulator: http://10.0.2.2:8000
/// iOS / same machine: http://127.0.0.1:8000
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

  String? _buildImageUrl(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) return null;
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }
    if (rawPath.startsWith('/')) {
      return '$kApiBaseUrl$rawPath';
    }
    return '$kApiBaseUrl/$rawPath';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _buildImageUrl(report.imageBeforeUrl);

    return Card(
      color: Colors.white,
      shadowColor: Colors.black12.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصورة
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 36),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // المعلومات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان + الحالة
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.nameAr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor(
                              report.statusId,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusNameAr(report.statusId),
                            style: TextStyle(
                              color: statusColor(report.statusId),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // if (report.descriptionAr != null &&
                    //     report.descriptionAr!.isNotEmpty)
                    //   Text(
                    //     report.descriptionAr!,
                    //     maxLines: 2,
                    //     overflow: TextOverflow.ellipsis,
                    //     style: TextStyle(
                    //       fontSize: 12.5,
                    //       color: Colors.grey.shade800,
                    //     ),
                    //   ),

                    // const SizedBox(height: 4),

                    // Text(
                    //   'رمز البلاغ: ${report.reportCode}',
                    //   style: TextStyle(
                    //     fontSize: 11.5,
                    //     color: Colors.grey.shade700,
                    //   ),
                    // ),
                    if (report.governmentNameAr != null)
                      Text(
                        'الموقع: ${report.governmentNameAr ?? ''}'
                        '${report.districtNameAr != null ? ' - ${report.districtNameAr}' : ''}'
                        '${report.areaNameAr != null ? ' - ${report.areaNameAr}' : ''}',
                        style: const TextStyle(fontSize: 11.5),
                      ),

                    const SizedBox(height: 8),

                    if (report.reportedAt != null)
                      Text(
                        'تاريخ البلاغ: ${formatDate(report.reportedAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    const SizedBox(height: 4),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF039844),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Container(
                          width: 120,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: const Color(0xFFCAF2DB),
                          ),
                          child: Center(
                            child: const Text(
                              'عرض التفاصيل',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
