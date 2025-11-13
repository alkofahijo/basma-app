// lib/pages/report/report_details_page.dart
import 'package:basma_app/models/report_models.dart';
import 'package:basma_app/pages/citizen/citizen_info_page.dart';
import 'package:basma_app/pages/initiative/initiative_info_page.dart';
import 'package:basma_app/pages/report/complete_report_page.dart';
import 'package:basma_app/pages/report/solve_report_dialog.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportDetailsPage extends StatefulWidget {
  final int reportId;
  const ReportDetailsPage({super.key, required this.reportId});

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  ReportDetail? r;
  String? err;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getReport(widget.reportId);
      setState(() {
        r = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        err = 'تعذّر تحميل البلاغ';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext ctx) {
    if (loading) return const LoadingCenter();
    if (err != null || r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(err ?? 'حدث خطأ غير متوقع')),
      );
    }

    final rep = r!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(rep.nameAr)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              InfoRow(label: "رمز البلاغ", value: rep.reportCode),
              InfoRow(label: "العنوان", value: rep.nameAr),
              InfoRow(label: "الوصف", value: rep.descriptionAr),

              if (rep.note != null && rep.note!.isNotEmpty)
                InfoRow(label: "ملاحظات", value: rep.note!),

              const SizedBox(height: 16),
              const Text("الصورة قبل:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              NetworkImageViewer(url: rep.imageBeforeUrl),

              if (rep.imageAfterUrl != null) ...[
                const SizedBox(height: 16),
                const Text("الصورة بعد:", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                NetworkImageViewer(url: rep.imageAfterUrl!),
              ],

              const SizedBox(height: 30),
              _buildActionButtons(rep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReportDetail rep) {
    switch (rep.statusId) {
      case 2: // open -> can adopt
        return ElevatedButton(
          onPressed: () async {
            final result = await showDialog(
              context: context,
              builder: (_) => SolveReportDialog(reportId: rep.id),
            );

            if (result == true) {
              _load();
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.orange,
          ),
          child: const Text(
            "حل المشكلة",
            style: TextStyle(color: Colors.white),
          ),
        );

      case 3: // in_progress -> can complete
        return ElevatedButton(
          onPressed: () async {
            final done = await Get.to(() => CompleteReportPage(report: rep));
            if (done == true) _load();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.green,
          ),
          child: const Text(
            "إتمام الحل",
            style: TextStyle(color: Colors.white),
          ),
        );

      case 4: // completed
        return _buildSolvedBy(rep);

      default:
        // 1 (under_review) or unknown -> no actions
        return const SizedBox.shrink();
    }
  }

  Widget _buildSolvedBy(ReportDetail rep) {
    if (rep.adoptedById == null || rep.adoptedByType == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "تم الحل بواسطة:",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (rep.adoptedByType == 1) {
              // citizen
              Get.to(() => CitizenInfoPage(citizenId: rep.adoptedById!));
            } else if (rep.adoptedByType == 2) {
              // initiative
              Get.to(() => InitiativeInfoPage(initiativeId: rep.adoptedById!));
            }
          },
          child: Text(
            rep.adoptedByName ?? "عرض التفاصيل",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
