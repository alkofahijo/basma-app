// lib/pages/reports/history/widgets/adopt_report_dialog.dart
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/services/auth_service.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SolveReportDialog extends StatefulWidget {
  final int reportId;

  const SolveReportDialog({super.key, required this.reportId});

  @override
  State<SolveReportDialog> createState() => _SolveReportDialogState();
}

class _SolveReportDialogState extends State<SolveReportDialog> {
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _confirmAdoptReport() async {
    _safeSetState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // اقرأ المستخدم الحالي من JWT (من AuthService.currentUser)
      final user = await AuthService.currentUser();

      if (user == null) {
        _safeSetState(() {
          _errorMessage = "الرجاء تسجيل الدخول من جديد.";
          _isSubmitting = false;
        });
        return;
      }

      // نتوقع type = "account" من الـ JWT (backend_type = 1 admin, 2 account)
      final String userType = (user["type"] ?? "").toString().trim();
      if (userType != "account") {
        _safeSetState(() {
          _errorMessage = "فقط الحسابات المسجَّلة يمكنها اعتماد البلاغ.";
          _isSubmitting = false;
        });
        return;
      }

      // account_id من الـ JWT
      final int? accountId = _parseInt(user["account_id"]);
      if (accountId == null) {
        _safeSetState(() {
          _errorMessage =
              "لم يتم العثور على رقم الحساب، يرجى إعادة تسجيل الدخول.";
          _isSubmitting = false;
        });
        return;
      }

      // نادِ على API التبنّي الموحد (accounts)
      await ApiService.adopt(reportId: widget.reportId, accountId: accountId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _safeSetState(() {
        _errorMessage = "فشل اعتماد البلاغ، حاول مرة أخرى.\n$e";
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        titlePadding: const EdgeInsets.only(top: 16),
        backgroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Icon(
                Icons.handshake_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "تأكيد استلام البلاغ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              "باستلامك لهذا البلاغ، سيتم تسجيل حسابك كجهة مسؤولة عن حل المشكلة، "
              "وسيتغيّر حالته إلى \"قيد التنفيذ\".",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: kPrimaryColor),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "تأكد أنك قادر على متابعة البلاغ حتى إتمام الحل ورفع الصور بعد المعالجة.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 12,
          top: 4,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _confirmAdoptReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              minimumSize: const Size(110, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "تأكيد الاستلام",
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
