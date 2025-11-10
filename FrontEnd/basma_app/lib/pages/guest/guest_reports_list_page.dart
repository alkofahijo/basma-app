import 'package:flutter/material.dart';
import '../../models/report_models.dart';
import '../../services/api_service.dart';
import 'report_details_page.dart';

class GuestReportsListPage extends StatefulWidget {
  final int areaId;
  const GuestReportsListPage({super.key, required this.areaId});

  @override
  State<GuestReportsListPage> createState() => _GuestReportsListPageState();
}

class _GuestReportsListPageState extends State<GuestReportsListPage> {
  List<ReportSummary> _reports = <ReportSummary>[];
  String _tab = "open"; // "open" or "completed"
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<ReportSummary> list;
      if (_tab == "completed") {
        // Ask backend for completed only
        list = await ApiService.listReports(
          areaId: widget.areaId,
          statusCode: "completed",
          limit: 200,
          offset: 0,
        );
      } else {
        // Fetch all, then keep non-completed on client
        list = await ApiService.listReports(
          areaId: widget.areaId,
          limit: 200,
          offset: 0,
        );
        list = list.where((r) {
          // Prefer explicit statusCode if backend sends it
          if (r.statusCode != null) {
            return r.statusCode != "completed";
          }
          // Fallback: consider completed if image_after_url is present
          return r.imageAfterUrl == null;
        }).toList();
      }

      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "تعذّر تحميل البلاغات";
        _loading = false;
      });
    }
  }

  void _switchTab(String tab) {
    if (_tab == tab) {
      return;
    }
    setState(() {
      _tab = tab;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _tab == "open";

    return Scaffold(
      appBar: AppBar(title: const Text('البلاغات')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('مفتوح'),
                selected: isOpen,
                onSelected: (sel) {
                  if (sel) {
                    _switchTab("open");
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('مكتمل'),
                selected: !isOpen,
                onSelected: (sel) {
                  if (sel) {
                    _switchTab("completed");
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _reports.isEmpty
                ? Center(
                    child: Text(
                      isOpen
                          ? 'لا توجد بلاغات مفتوحة حالياً'
                          : 'لا توجد بلاغات مكتملة',
                    ),
                  )
                : ListView.separated(
                    itemCount: _reports.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = _reports[index];
                      final isCompleted =
                          (r.statusCode == "completed") ||
                          (r.imageAfterUrl != null);

                      return ListTile(
                        title: Text(r.nameAr),
                        subtitle: Text(r.reportCode),
                        trailing: Text(
                          isCompleted ? 'مكتمل' : 'قيد المعالجة',
                          style: TextStyle(
                            color: isCompleted ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportDetailsPage(reportId: r.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
