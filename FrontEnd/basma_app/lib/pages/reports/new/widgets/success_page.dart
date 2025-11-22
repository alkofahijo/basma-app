// lib/pages/reports/new/widgets/success_page.dart

import 'package:basma_app/pages/reports/history/reports_list_page.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// صفحة نجاح عامة قابلة لإعادة الاستخدام.
/// - يمكن استخدامها لنجاح إنشاء بلاغ جديد.
/// - أو لنجاح إكمال/معالجة بلاغ موجود.
/// - قابلة للتخصيص بالنصوص والحالة.
class SuccessPage extends StatelessWidget {
  /// رقم البلاغ (اختياري). إذا لم يُمرر لن يظهر البوكس الخاص به.
  final String? reportCode;

  /// عنوان كبير في الأعلى (مثلاً: "تم إرسال البلاغ بنجاح" أو "تم إكمال معالجة البلاغ").
  final String title;

  /// نص الشرح داخل البوكس الثاني.
  final String message;

  /// نص الحالة (مثلاً: "قيد المراجعة" أو "مكتمل").
  final String statusText;

  /// نص زر الإجراء الرئيسي.
  final String primaryButtonText;

  /// مسار صورة النجاح (يمكن تغييره إن رغبت).
  final String imageAsset;

  /// هل نعرض بوكس الحالة أم لا.
  final bool showStatus;

  /// هل نعرض بوكس رقم البلاغ أم لا.
  final bool showReportCode;

  /// أي تبويب رئيسي يُفتح في صفحة البلاغات: 'all' أو 'mine'
  final String initialMainTab;

  /// أي حالة تُفتح في صفحة البلاغات: 'open' أو 'in_progress' أو 'completed'
  final String initialStatusTab;

  const SuccessPage({
    super.key,
    this.reportCode,
    String? title,
    String? message,
    String? statusText,
    String? primaryButtonText,
    this.imageAsset = "assets/images/success.png",
    this.showStatus = true,
    this.showReportCode = true,
    this.initialMainTab = 'all',
    this.initialStatusTab = 'open',
  }) : title = title ?? 'تم إرسال البلاغ بنجاح',
       message =
           message ??
           'شكرًا لمساهمتك في تحسين مدينتنا. سيتم مراجعة بلاغك من قبل فريقنا المختص، '
               'ويمكنك متابعة الحالة من خلال "بلاغي" في قائمة البلاغات.',
       statusText = statusText ?? 'قيد المراجعة',
       primaryButtonText = primaryButtonText ?? 'الانتقال إلى بلاغاتي';

  /// Factory مخصصة لحالة "إنشاء بلاغ جديد"
  factory SuccessPage.forNewReport({required String reportCode}) {
    return SuccessPage(
      reportCode: reportCode,
      title: 'تم إرسال البلاغ بنجاح',
      statusText: 'قيد المراجعة',
      message:
          'شكرًا لمساهمتك في تحسين مدينتنا. سيتم مراجعة البلاغ من قبل الجهة المختصة، '
          'ويمكنك متابعة الحالة وتحديثاتها من صفحة "بلاغاتي".',
      primaryButtonText: 'الانتقال إلى بلاغاتي',
      showReportCode: true,
      showStatus: true,
      // ممكن لاحقاً نضبطها حسب سيناريو المستخدم
    );
  }

  /// Factory مخصصة لحالة "إكمال / معالجة بلاغ"
  factory SuccessPage.forCompletedReport({required String reportCode}) {
    return SuccessPage(
      reportCode: reportCode,
      title: 'تم إكمال معالجة البلاغ',
      statusText: 'مكتمل',
      message:
          'تم توثيق إكمال معالجة التشوّه البصري لهذا البلاغ مع صورة ما بعد الإصلاح وملاحظاتك. '
          'يمكنك مراجعة التفاصيل من صفحة "بلاغاتي".',
      primaryButtonText: 'الانتقال إلى بلاغاتي',
      showReportCode: true,
      showStatus: true,
      // 👇 افتح صفحة البلاغات على "بلاغاتي / مكتمل"
      initialMainTab: 'mine',
      initialStatusTab: 'completed',
    );
  }

  void _goToReportsHistory() {
    // إرسال المستخدم إلى قائمة بلاغاته (سجل البلاغات)
    Get.offAll(
      () => GuestReportsListPage(
        initialMainTab: initialMainTab,
        initialStatusTab: initialStatusTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                imageAsset,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),

              // العنوان الرئيسي
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // بوكس رقم البلاغ (اختياري)
              if (showReportCode && reportCode != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رقم البلاغ:',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reportCode!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // بوكس الحالة والرسالة
              if (showStatus) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحالة: $statusText',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: size.height * 0.08),

              // زر الانتقال إلى قائمة البلاغات
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _goToReportsHistory,
                  child: Text(
                    primaryButtonText,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
