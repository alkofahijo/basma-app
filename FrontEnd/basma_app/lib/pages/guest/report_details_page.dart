import 'package:flutter/material.dart';
import '../../models/report_models.dart';
import '../../services/api_service.dart';

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
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext ctx) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (err != null || r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(err ?? 'حدث خطأ غير متوقع')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(r!.nameAr)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('الرمز', r!.reportCode),
              const SizedBox(height: 8),
              _kv('العنوان (عربي)', r!.nameAr),
              const SizedBox(height: 8),
              _kv('العنوان (إنجليزي)', r!.nameEn),
              const SizedBox(height: 8),
              _kv('الوصف (عربي)', r!.descriptionAr),
              const SizedBox(height: 8),
              _kv('الوصف (إنجليزي)', r!.descriptionEn),
              if (r!.note != null && r!.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _kv('ملاحظات', r!.note!),
              ],
              const SizedBox(height: 12),
              Text(
                'الصورة قبل',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              _NetImage(url: r!.imageBeforeUrl),
              if (r!.imageAfterUrl != null) ...[
                const SizedBox(height: 12),
                Text(
                  'الصورة بعد',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                _NetImage(url: r!.imageAfterUrl!),
              ],
              const SizedBox(height: 16),
              _kv('تاريخ البلاغ', r!.reportedAt.toLocal().toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        SelectableText(v),
      ],
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  const _NetImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 160,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Text('تعذّر تحميل الصورة'),
      ),
    );
  }
}
