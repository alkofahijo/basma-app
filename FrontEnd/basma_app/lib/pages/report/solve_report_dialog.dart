// lib/pages/report/solve_report_dialog.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class SolveReportDialog extends StatefulWidget {
  final int reportId;

  const SolveReportDialog({super.key, required this.reportId});

  @override
  State<SolveReportDialog> createState() => _SolveReportDialogState();
}

class _SolveReportDialogState extends State<SolveReportDialog> {
  bool loading = false;
  String? err;

  Future<void> _confirmSolve() async {
    setState(() {
      loading = true;
      err = null;
    });

    try {
      final user = await AuthService.currentUser();

      if (user == null) {
        setState(() {
          err = "الرجاء تسجيل الدخول من جديد";
          loading = false;
        });
        return;
      }

      debugPrint("AUTH USER = $user");

      // نستخدم الحقل النصي "type" القادم من الـ JWT:
      final String type = (user["type"] ?? "").toString();

      int? adoptedByType; // 1: citizen, 2: initiative
      int? adoptedById;

      if (type == "citizen") {
        adoptedByType = 1;

        final rawCid = user["citizen_id"];
        final cid = rawCid is int
            ? rawCid
            : int.tryParse(rawCid?.toString() ?? "");
        if (cid == null) {
          setState(() {
            err = "لم يتم العثور على هوية المواطن، أعد تسجيل الدخول.";
            loading = false;
          });
          return;
        }
        adoptedById = cid;
      } else if (type == "initiative") {
        adoptedByType = 2;

        final rawIid = user["initiative_id"];
        final iid = rawIid is int
            ? rawIid
            : int.tryParse(rawIid?.toString() ?? "");
        if (iid == null) {
          setState(() {
            err = "لم يتم العثور على هوية المبادرة، أعد تسجيل الدخول.";
            loading = false;
          });
          return;
        }
        adoptedById = iid;
      } else {
        setState(() {
          err = "نوع مستخدم غير صالح";
          loading = false;
        });
        return;
      }

      // 🔥 هذا الآن يرسل adopted_by_type = 1 أو 2 فقط
      await ApiService.adopt(
        reportId: widget.reportId,
        adoptedById: adoptedById,
        adoptedByType: adoptedByType,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        err = "فشل اعتماد البلاغ: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text("تأكيد استلام البلاغ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "هل أنت متأكد أنك تريد استلام البلاغ والبدء بحلّه؟",
              textAlign: TextAlign.center,
            ),
            if (err != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  err!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: loading ? null : _confirmSolve,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text("تأكيد"),
          ),
        ],
      ),
    );
  }
}
