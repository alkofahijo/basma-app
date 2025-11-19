// lib/pages/shared/view_report_location_page.dart

import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/loading_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:basma_app/services/api_service.dart';

class ViewReportLocationPage extends StatefulWidget {
  final double lat;
  final double lng;
  final String? locationName;

  const ViewReportLocationPage({
    super.key,
    required this.lat,
    required this.lng,
    this.locationName,
  });

  @override
  State<ViewReportLocationPage> createState() => _ViewReportLocationPageState();
}

class _ViewReportLocationPageState extends State<ViewReportLocationPage> {
  ResolvedLocation? _resolved;
  bool _loading = true;
  String? _error;

  LatLng get _point => LatLng(widget.lat, widget.lng);

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await ApiService.resolveLocationByLatLng(
        widget.lat,
        widget.lng,
      );

      if (!mounted) return;

      setState(() {
        _resolved = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = "تعذّر جلب بيانات الموقع";
      });
    }
  }

  Future<void> _openInMaps({required bool withDirections}) async {
    final dest = '${widget.lat},${widget.lng}';

    final Uri uri = withDirections
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving',
          )
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=$dest');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ عند فتح الخرائط: $e')));
    }
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        systemOverlayStyle: AppSystemUi.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'موقع البلاغ على الخريطة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? LoadingCenter()
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            )
          : Stack(
              children: [
                // ================== MAP ==================
                Positioned.fill(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _point,
                      initialZoom: 15.5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.basma_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _point,
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.location_on,
                              size: 50,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ================== INFO CARD ==================
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _buildResolvedContent(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResolvedContent() {
    // now we are SAFE: _resolved is NOT NULL here
    final r = _resolved!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 0, 150, 10), kPrimaryColor],
                ),
              ),
              child: const Icon(Icons.place, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "تفاصيل الموقع",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                _buildDetailRow("المحافظة", r.governmentNameAr),
                _buildDetailRow("اللواء", r.districtNameAr),
                _buildDetailRow("المنطقة / الحي", r.areaNameAr),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openInMaps(withDirections: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text(
                  "فتح الموقع في الخرائط",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
