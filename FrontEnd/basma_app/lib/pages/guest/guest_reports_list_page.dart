import 'package:flutter/material.dart';
import '../../models/report_models.dart';
import '../../services/api_service.dart';
import '../report/report_details_page.dart';

class GuestReportsListPage extends StatefulWidget {
  final int areaId;
  const GuestReportsListPage({super.key, required this.areaId});

  @override
  State<GuestReportsListPage> createState() => _GuestReportsListPageState();
}

class _GuestReportsListPageState extends State<GuestReportsListPage> {
  List<ReportSummary> _reports = [];
  bool _loading = true;
  String? _error;
  String _tab = "open"; // open = status 2, completed = 4

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
      final status = _tab == "open" ? 2 : 4;

      final list = await ApiService.listReports(
        areaId: widget.areaId,
        statusId: status,
        limit: 200,
        offset: 0,
      );

      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _reports = [];
        _loading = false;
        _error = "تعذّر تحميل البلاغات";
      });
    }
  }

  void _switchTab(String tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpenTab = _tab == "open";

    return Scaffold(
      appBar: AppBar(title: const Text("البلاغات")),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // ------------------- TABS -------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("مفتوح"),
                selected: isOpenTab,
                onSelected: (_) => _switchTab("open"),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("مكتمل"),
                selected: !isOpenTab,
                onSelected: (_) => _switchTab("completed"),
              ),
            ],
          ),

          const SizedBox(height: 10),

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
                      isOpenTab
                          ? "لا توجد بلاغات مفتوحة"
                          : "لا توجد بلاغات مكتملة",
                    ),
                  )
                : ListView.separated(
                    itemCount: _reports.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = _reports[i];
                      final isCompleted = r.statusId == 4;

                      return ListTile(
                        title: Text(r.nameAr),
                        subtitle: Text(r.reportCode),
                        trailing: Text(
                          isCompleted ? "مكتمل" : "قيد المعالجة",
                          style: TextStyle(
                            color: isCompleted ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailsPage(reportId: r.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
