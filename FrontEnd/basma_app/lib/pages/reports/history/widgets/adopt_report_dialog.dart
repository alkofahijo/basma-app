// lib/pages/report/solve_report_dialog.dart

import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';

class SolveReportDialog extends StatefulWidget {
  final int reportId;

  const SolveReportDialog({super.key, required this.reportId});

  @override
  State<SolveReportDialog> createState() => _SolveReportDialogState();
}

class _SolveReportDialogState extends State<SolveReportDialog> {
  bool _loading = false;
  String? _errorMessage;

  /// تحويل ديناميكي إلى int بأمان
  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> _confirmSolve() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.currentUser();

      if (user == null) {
        setState(() {
          _errorMessage = "الرجاء تسجيل الدخول من جديد.";
          _loading = false;
        });
        return;
      }

      // نوع المستخدم من الـ JWT: "citizen" أو "initiative"
      final String type = (user["type"] ?? "").toString().trim();

      int? adoptedByType; // 1: citizen, 2: initiative
      int? adoptedById;

      if (type == "citizen") {
        adoptedByType = 1;
        adoptedById = _parseInt(user["citizen_id"]);

        if (adoptedById == null) {
          setState(() {
            _errorMessage =
                "لم يتم العثور على هوية المواطن، يرجى إعادة تسجيل الدخول.";
            _loading = false;
          });
          return;
        }
      } else if (type == "initiative") {
        adoptedByType = 2;
        adoptedById = _parseInt(user["initiative_id"]);

        if (adoptedById == null) {
          setState(() {
            _errorMessage =
                "لم يتم العثور على هوية المبادرة، يرجى إعادة تسجيل الدخول.";
            _loading = false;
          });
          return;
        }
      } else {
        setState(() {
          _errorMessage = "نوع مستخدم غير صالح لاعتماد البلاغ.";
          _loading = false;
        });
        return;
      }

      await ApiService.adopt(
        reportId: widget.reportId,
        adoptedById: adoptedById,
        adoptedByType: adoptedByType,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = "فشل اعتماد البلاغ، حاول مرة أخرى.\n$e";
        _loading = false;
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
            // دائرة الأيقونة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF004d00), Color(0xFF008000)],
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
              "باستلامك لهذا البلاغ، سيتم تسجيلك كجهة مسؤولة عن حل المشكلة، "
              "وسيتغيّر حالته إلى \"قيد التنفيذ\".",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 150, 10).withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF008000)),
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
                  color: Colors.red.withOpacity(0.06),
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
            onPressed: _loading ? null : () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _confirmSolve,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF008000),
              minimumSize: const Size(110, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
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
