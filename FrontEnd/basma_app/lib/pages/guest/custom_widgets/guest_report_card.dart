import 'package:flutter/material.dart';
import '../../../models/report_models.dart';

/// 🔥 عدّل هذا الـ baseUrl ليناسب بيئتك (Emulator / جهاز حقيقي)
/// - للـ Android Emulator عادةً: http://10.0.2.2:8000
/// - للـ iOS Simulator / Web / نفس الجهاز: http://127.0.0.1:8000 أو IP الشبكة
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

    // لو الـ API رجّع URL كامل
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    // لو رجع مسار نسبي من نوع /static/uploads/xxx.jpg
    if (rawPath.startsWith('/')) {
      return '$kApiBaseUrl$rawPath';
    }

    // أي حالة أخرى نضيف سلاش في النص
    return '$kApiBaseUrl/$rawPath';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _buildImageUrl(report.imageBeforeUrl);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصورة
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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

                    // الوصف
                    if (report.descriptionAr != null &&
                        report.descriptionAr!.isNotEmpty)
                      Text(
                        report.descriptionAr!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 4),

                    // الرمز + التاريخ
                    Text(
                      'رمز البلاغ: ${report.reportCode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (report.reportedAt != null)
                      Text(
                        'تاريخ البلاغ: ${formatDate(report.reportedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // الموقع
                    if (report.governmentNameAr != null)
                      Text(
                        'الموقع: ${report.governmentNameAr ?? ''}'
                        '${report.districtNameAr != null ? ' - ${report.districtNameAr}' : ''}'
                        '${report.areaNameAr != null ? ' - ${report.areaNameAr}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),

                    const SizedBox(height: 8),

                    // زر عرض التفاصيل
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onTap,
                        child: const Text('عرض التفاصيل'),
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
