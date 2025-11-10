import 'package:flutter/material.dart';
import '../../models/location_models.dart';
import '../../services/api_service.dart';
import 'guest_reports_list_page.dart';

class GuestSelectPage extends StatefulWidget {
  const GuestSelectPage({super.key});
  @override
  State createState() => _S();
}

class _S extends State<GuestSelectPage> {
  List<Government> govs = [];
  Government? g;
  List<District> dists = [];
  District? d;
  List<Area> areas = [];
  Area? a;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    govs = await ApiService.governments();
    setState(() => loading = false);
  }

  Future<void> _selG(Government? v) async {
    setState(() => g = v);
    d = null;
    a = null;
    dists = await ApiService.districts(g!.id);
    setState(() {});
  }

  Future<void> _selD(District? v) async {
    setState(() => d = v);
    a = null;
    areas = await ApiService.areas(d!.id);
    setState(() {});
  }

  void _next() {
    if (a != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GuestReportsListPage(areaId: a!.id)),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('تصفح البلاغات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<Government>(
              initialValue: g,
              items: govs
                  .map((x) => DropdownMenuItem(value: x, child: Text(x.nameAr)))
                  .toList(),
              onChanged: _selG,
              decoration: const InputDecoration(labelText: 'المحافظة'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<District>(
              initialValue: d,
              items: dists
                  .map((x) => DropdownMenuItem(value: x, child: Text(x.nameAr)))
                  .toList(),
              onChanged: _selD,
              decoration: const InputDecoration(labelText: 'اللواء/القضاء'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Area>(
              initialValue: a,
              items: areas
                  .map((x) => DropdownMenuItem(value: x, child: Text(x.nameAr)))
                  .toList(),
              onChanged: (v) => setState(() => a = v),
              decoration: const InputDecoration(labelText: 'المنطقة'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: a != null ? _next : null,
              child: const Text('عرض البلاغات'),
            ),
          ],
        ),
      ),
    );
  }
}
