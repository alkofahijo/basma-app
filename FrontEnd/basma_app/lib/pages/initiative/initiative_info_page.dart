import 'package:flutter/material.dart';
import 'package:basma_app/models/initiative_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/network_image_viewer.dart';
import 'package:basma_app/widgets/loading_center.dart';

class InitiativeInfoPage extends StatefulWidget {
  final int initiativeId;

  const InitiativeInfoPage({super.key, required this.initiativeId});

  @override
  State<InitiativeInfoPage> createState() => _InitiativeInfoPageState();
}

class _InitiativeInfoPageState extends State<InitiativeInfoPage> {
  Initiative? data;
  String? err;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final i = await ApiService.getInitiative(widget.initiativeId);
      setState(() {
        data = i;
        loading = false;
      });
    } catch (e) {
      setState(() {
        err = 'تعذّر تحميل بيانات المبادرة';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingCenter();

    if (err != null || data == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(err ?? "حدث خطأ")),
      );
    }

    final i = data!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("بيانات المبادرة")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              if (i.logoUrl != null)
                NetworkImageViewer(url: i.logoUrl!, height: 180),

              const SizedBox(height: 16),

              InfoRow(label: "اسم المبادرة", value: i.nameAr),
              InfoRow(label: "الاسم EN", value: i.nameEn),
              InfoRow(label: "رقم الهاتف", value: i.mobileNumber),
              InfoRow(label: "عدد الأعضاء", value: "${i.membersCount}"),
              InfoRow(
                label: "البلاغات المنجزة",
                value: "${i.reportsCompletedCount}",
              ),
              if (i.joinFormLink != null)
                InfoRow(label: "رابط الانضمام", value: i.joinFormLink!),
            ],
          ),
        ),
      ),
    );
  }
}
