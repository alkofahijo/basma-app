// lib/pages/shared/view_report_location_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewReportLocationPage extends StatelessWidget {
  final double lat;
  final double lng;
  final String? locationName;

  const ViewReportLocationPage({
    super.key,
    required this.lat,
    required this.lng,
    this.locationName,
  });

  LatLng get _point => LatLng(lat, lng);

  Future<void> _openInMaps(
    BuildContext context, {
    required bool withDirections,
  }) async {
    final dest = '$lat,$lng';

    Uri uri;
    if (withDirections) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving',
      );
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$dest');
    }

    try {
      // نحاول تطبيق خارجي أولاً
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // لو ما قدر → افتحه داخل In-App Browser
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء فتح الخرائط: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locTitle = locationName?.isNotEmpty == true
        ? locationName!
        : 'موقع البلاغ';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('موقع البلاغ على الخريطة'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF009688), Color(0xFF00695C)],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // ====== الخريطة الأساسية ======
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _point,
                  initialZoom: 15.5,
                  maxZoom: 18,
                  minZoom: 3,
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
                        // ✅ فقط أيقونة داخل الـ Marker → لا Column ولا نص
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ====== كارد المعلومات + الأزرار أسفل الشاشة ======
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF009688), Color(0xFF00695C)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.place, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locTitle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "خط العرض: ${lat.toStringAsFixed(6)}، "
                                  "خط الطول: ${lng.toStringAsFixed(6)}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openInMaps(context, withDirections: false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined),
                              label: const Text("فتح الموقع في الخرائط"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _openInMaps(context, withDirections: true),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                backgroundColor: Colors.teal.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                              ),
                              icon: const Icon(
                                Icons.directions_car_outlined,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "عرض الطريق إلى الموقع",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
