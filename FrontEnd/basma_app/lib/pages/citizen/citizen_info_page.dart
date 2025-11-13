import 'package:flutter/material.dart';
import 'package:basma_app/models/citizen_models.dart';
import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/widgets/info_row.dart';
import 'package:basma_app/widgets/loading_center.dart';

class CitizenInfoPage extends StatefulWidget {
  final int citizenId;

  const CitizenInfoPage({super.key, required this.citizenId});

  @override
  State<CitizenInfoPage> createState() => _CitizenInfoPageState();
}

class _CitizenInfoPageState extends State<CitizenInfoPage> {
  Citizen? citizen;
  String? err;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await ApiService.getCitizen(widget.citizenId);
      setState(() {
        citizen = c;
        loading = false;
      });
    } catch (e) {
      setState(() {
        err = 'تعذّر تحميل بيانات المواطن';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingCenter();

    if (err != null || citizen == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(err ?? "حدث خطأ")),
      );
    }

    final c = citizen!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("بيانات المواطن")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              InfoRow(label: "الاسم", value: c.nameAr),
              InfoRow(label: "الاسم EN", value: c.nameEn),
              InfoRow(label: "رقم الهاتف", value: c.mobileNumber),
              InfoRow(
                label: "البلاغات المنجزة",
                value: "${c.reportsCompletedCount}",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
