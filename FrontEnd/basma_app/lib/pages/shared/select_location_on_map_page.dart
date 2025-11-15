// lib/pages/shared/select_location_on_map_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

const Color _primaryColor = Color(0xFF008000);

class SelectLocationOnMapPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const SelectLocationOnMapPage({super.key, this.initialLat, this.initialLng});

  @override
  State<SelectLocationOnMapPage> createState() =>
      _SelectLocationOnMapPageState();
}

class _SelectLocationOnMapPageState extends State<SelectLocationOnMapPage> {
  late final MapController _mapController;
  LatLng? _selectedLatLng;
  bool _gettingLocation = false;

  // مركز افتراضي (مثلاً على عمّان)
  final LatLng _defaultCenter = LatLng(31.9539, 35.9106);
  final double _defaultZoom = 14;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLatLng = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _gettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("يرجى تفعيل خدمة تحديد الموقع (GPS) في جهازك."),
          ),
        );
        setState(() => _gettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "تم رفض صلاحية الموقع. الرجاء السماح من إعدادات الجهاز.",
            ),
          ),
        );
        setState(() => _gettingLocation = false);
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng newPos = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _selectedLatLng = newPos;
      });

      _mapController.move(newPos, 16);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ أثناء جلب الموقع الحالي: $e")),
      );
    } finally {
      setState(() {
        _gettingLocation = false;
      });
    }
  }

  void _onTapMap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLatLng = latLng;
    });
  }

  void _onConfirm() {
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار نقطة على الخريطة أولاً.")),
      );
      return;
    }

    Navigator.pop(context, _selectedLatLng);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = _selectedLatLng ?? _defaultCenter;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            "تحديد الموقع على الخريطة",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: _primaryColor,
        ),
        body: Column(
          children: [
            // خريطة
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: _defaultZoom,
                  onTap: _onTapMap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.basma_app',
                  ),
                  if (_selectedLatLng != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLatLng!,
                          width: 50,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // معلومات أسفل الخريطة + الأزرار
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedLatLng != null)
                    Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _primaryColor.withOpacity(0.05),
                      ),
                      child: Text(
                        "الموقع المحدد:\n"
                        "خط العرض: ${_selectedLatLng!.latitude.toStringAsFixed(6)}\n"
                        "خط الطول: ${_selectedLatLng!.longitude.toStringAsFixed(6)}",
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                    )
                  else
                    const Text(
                      "اضغط على الخريطة لاختيار موقع، أو استخدم زر تحديد موقعي.",
                      style: TextStyle(fontSize: 17, color: Colors.black),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _gettingLocation
                              ? null
                              : _getCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _gettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                ),
                          label: const Text(
                            "موقعي الحالي",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            "تأكيد الموقع",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
