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
          backgroundColor: const Color(0xFF008000),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'موقع البلاغ على الخريطة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Colors.white,
            ),
          ),

          centerTitle: true,
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
                        child: const Icon(
                          Icons.location_on,
                          size: 50,
                          color: Color(0xFF008000),
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
                  height: 160,
                  padding: const EdgeInsets.all(16),
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
                                colors: [
                                  Color.fromARGB(255, 0, 150, 10),
                                  Color(0xFF008000),
                                ],
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
                                    fontSize: 20,
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
                      const SizedBox(height: 20),
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
                                side: BorderSide(
                                  color: Color(0xFF008000),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.map_outlined,
                                color: Color(0xFF008000),
                              ),

                              label: const Text(
                                "فتح الموقع في الخرائط",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008000),
                                ),
                              ),
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
                                backgroundColor: const Color(0xFF008000),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
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
