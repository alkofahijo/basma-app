// lib/pages/shared/select_location_on_map_page.dart

// dart:convert removed; ExternalService provides JSON parsing

import 'package:basma_app/services/api_service.dart';
import 'package:basma_app/theme/app_system_ui.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
// http removed; ExternalService handles external HTTP calls
import 'package:basma_app/services/external_service.dart';
import 'package:basma_app/widgets/inputs/app_search_field.dart';
import 'package:latlong2/latlong.dart';

// =============================================================

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

  // حدود الأردن التقريبية
  static const LatLng _jordanSouthWest = LatLng(29.0, 34.9);
  static const LatLng _jordanNorthEast = LatLng(33.6, 39.5);

  // النقطة المختارة على الخريطة
  LatLng? _selectedLatLng;
  bool _gettingLocation = false;

  // تفاصيل الموقع من الـ backend (/ai/resolve-location)
  ResolvedLocation? _resolvedLocation;
  bool _resolvingLocation = false;
  String? _locationError;

  // البحث
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searching = false;
  final List<_PlaceSearchResult> _searchResults = [];

  // مركز افتراضي (عمّان)
  final LatLng _defaultCenter = const LatLng(31.9539, 35.9106);
  final double _defaultZoom = 14;

  static const double _searchBarTopPadding = 12;
  static const double _searchBarHorizontalPadding = 16;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // لو جاي من صفحة ثانية ومعاه إحداثيات ابتدائية
    if (widget.initialLat != null && widget.initialLng != null) {
      final candidate = LatLng(widget.initialLat!, widget.initialLng!);
      if (_isWithinJordan(candidate)) {
        _selectedLatLng = candidate;
        Future.microtask(_resolveSelectedLocation);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ----------------- Helpers عامة -----------------

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isWithinJordan(LatLng point) {
    return point.latitude >= _jordanSouthWest.latitude &&
        point.latitude <= _jordanNorthEast.latitude &&
        point.longitude >= _jordanSouthWest.longitude &&
        point.longitude <= _jordanNorthEast.longitude;
  }

  // ----------------- جلب موقعي الحالي -----------------

  Future<void> _getCurrentLocation() async {
    setState(() {
      _gettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("يرجى تفعيل خدمة تحديد الموقع (GPS) في جهازك.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showSnack(
          "تم رفض صلاحية الموقع. الرجاء السماح بها من إعدادات الجهاز.",
        );
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng newPos = LatLng(pos.latitude, pos.longitude);

      if (!_isWithinJordan(newPos)) {
        _showSnack(
          "موقعك الحالي خارج حدود الأردن، يرجى اختيار موقع داخل الأردن.",
        );
        return;
      }

      setState(() {
        _selectedLatLng = newPos;
        _locationError = null;
        _resolvedLocation = null;
        _searchResults.clear();
      });

      _mapController.move(newPos, 16);
      _resolveSelectedLocation();
    } catch (e) {
      debugPrint('Error while getting current location: $e');
      _showSnack("حدث خطأ أثناء جلب الموقع الحالي.");
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // ----------------- التعامل مع ضغط الخريطة -----------------

  void _onTapMap(TapPosition tapPosition, LatLng latLng) {
    if (!_isWithinJordan(latLng)) {
      _showSnack("يمكنك اختيار مواقع داخل الأردن فقط.");
      return;
    }

    setState(() {
      _selectedLatLng = latLng;
      _locationError = null;
      _resolvedLocation = null;
      _searchResults.clear();
    });

    _resolveSelectedLocation();
  }

  // ----------------- استدعاء /ai/resolve-location -----------------

  Future<void> _resolveSelectedLocation() async {
    final LatLng? latLng = _selectedLatLng;
    if (latLng == null) return;

    setState(() {
      _resolvingLocation = true;
      _locationError = null;
      _resolvedLocation = null;
    });

    try {
      final result = await ApiService.resolveLocationByLatLng(
        latLng.latitude,
        latLng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _resolvedLocation = result;
      });
    } catch (e) {
      debugPrint('Error resolving location via backend: $e');
      if (!mounted) return;
      setState(() {
        _locationError = "فشل في جلب تفاصيل الموقع، حاول مرة أخرى.";
      });
      _showSnack("فشل في جلب تفاصيل الموقع.");
    } finally {
      if (mounted) {
        setState(() {
          _resolvingLocation = false;
        });
      }
    }
  }

  // ----------------- البحث (نص / إحداثيات) -----------------

  void _onSearchPressed() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showSnack("اكتب اسم مكان أو إحداثيات (مثال: 32.5456, 35.8907).");
      return;
    }
    FocusScope.of(context).unfocus();
    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    // محاولة فهمه كإحداثيات مباشرة
    final coordMatch = RegExp(
      r'^\s*([0-9\.\-]+)\s*,\s*([0-9\.\-]+)\s*$',
    ).firstMatch(query);

    setState(() {
      _searching = true;
      _searchResults.clear();
    });

    // 1) لو تنسيق إحداثيات → لا نحتاج OpenStreetMap
    if (coordMatch != null) {
      try {
        final double lat = double.parse(coordMatch.group(1)!);
        final double lng = double.parse(coordMatch.group(2)!);
        final LatLng point = LatLng(lat, lng);

        if (!_isWithinJordan(point)) {
          _showSnack(
            "الإحداثيات خارج حدود الأردن، يرجى إدخال إحداثيات داخل الأردن.",
          );
        } else {
          setState(() {
            _selectedLatLng = point;
            _locationError = null;
            _resolvedLocation = null;
          });

          _mapController.move(point, 16);
          await _resolveSelectedLocation();
        }
      } catch (e) {
        debugPrint('Error parsing coordinates from search: $e');
        _showSnack("التنسيق غير صحيح. مثال: 32.5456, 35.8907");
      } finally {
        if (mounted) {
          setState(() {
            _searching = false;
          });
        }
      }
      return;
    }

    // 2) بحث نصي عبر OpenStreetMap (Nominatim) داخل الأردن فقط
    try {
      final List<dynamic> data = await ExternalService.nominatimSearch(query);

      if (data.isEmpty) {
        _showSnack("لم يتم العثور على نتائج لهذا البحث داخل الأردن.");
        if (mounted) {
          setState(() {
            _searching = false;
          });
        }
        return;
      }

      final results = data
          .map((item) {
            final lat = double.tryParse(item['lat']?.toString() ?? '');
            final lon = double.tryParse(item['lon']?.toString() ?? '');
            final displayName = item['display_name']?.toString() ?? '';

            if (lat == null || lon == null) return null;

            final point = LatLng(lat, lon);
            if (!_isWithinJordan(point)) {
              // فلترة إضافية احتياطية
              return null;
            }

            String? subtitle;
            final address = item['address'] as Map<String, dynamic>?;
            if (address != null) {
              final parts = <String>[
                address['city']?.toString() ?? '',
                address['town']?.toString() ?? '',
                address['village']?.toString() ?? '',
                address['suburb']?.toString() ?? '',
                address['road']?.toString() ?? '',
              ].where((e) => e.isNotEmpty).toList();
              if (parts.isNotEmpty) {
                subtitle = parts.join('، ');
              }
            }

            return _PlaceSearchResult(
              lat: lat,
              lng: lon,
              title: displayName,
              subtitle: subtitle,
            );
          })
          .whereType<_PlaceSearchResult>() // ✅ يتجاهل null
          .toList();

      if (results.isEmpty) {
        _showSnack("لم يتم العثور على نتائج داخل حدود الأردن.");
      }

      if (mounted) {
        setState(() {
          _searchResults
            ..clear()
            ..addAll(results);
        });
      }
    } catch (e) {
      debugPrint('Error while searching Nominatim: $e');
      _showSnack("حدث خطأ أثناء البحث عن الموقع.");
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  void _onSelectSearchResult(_PlaceSearchResult result) {
    FocusScope.of(context).unfocus();
    final LatLng point = LatLng(result.lat, result.lng);

    if (!_isWithinJordan(point)) {
      _showSnack("يمكنك اختيار مواقع داخل الأردن فقط.");
      return;
    }

    setState(() {
      _selectedLatLng = point;
      _searchResults.clear();
      _locationError = null;
      _resolvedLocation = null;
    });
    _mapController.move(point, 16);
    _resolveSelectedLocation();
  }

  // ----------------- تأكيد -----------------

  void _onConfirm() {
    if (_selectedLatLng == null) {
      _showSnack("يرجى اختيار نقطة على الخريطة أولاً.");
      return;
    }
    Navigator.pop(context, _selectedLatLng);
  }

  // ----------------- Widgets مساعدة -----------------

  Widget _buildSearchField() {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: AppSearchField(
        controller: _searchController,
        hint: 'ابحث عن موقع',
        onChanged: (_) {},
        onSearch: _onSearchPressed,
        isLoading: _searching,
        onClear: () {
          _searchController.clear();
        },
      ),
    );
  }

  Widget _buildSearchResultsCard() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = _searchResults[index];
            return ListTile(
              dense: true,
              title: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: item.subtitle != null
                  ? Text(
                      item.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () => _onSelectSearchResult(item),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationInfoSection() {
    if (_selectedLatLng == null) {
      return const Text(
        "اضغط على الخريطة لاختيار موقع داخل الأردن، أو استخدم زر موقعي الحالي أو مربع البحث في الأعلى.",
        style: TextStyle(fontSize: 15, color: Colors.black87),
      );
    }

    if (_resolvingLocation) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: kPrimaryColor.withValues(alpha: 0.04),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "جاري تحميل تفاصيل الموقع...",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.red.withValues(alpha: 0.04),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Text(
          _locationError!,
          style: const TextStyle(fontSize: 15, color: Colors.red),
        ),
      );
    }

    if (_resolvedLocation == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.withValues(alpha: 0.05),
        ),
        child: const Text(
          "تم اختيار نقطة على الخريطة، لكن لا توجد تفاصيل عنوان متاحة.",
          style: TextStyle(fontSize: 15),
        ),
      );
    }

    final r = _resolvedLocation!;

    final govName = r.governmentNameAr;
    final districtName = r.districtNameAr;
    final areaName = r.areaNameAr;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: kPrimaryColor.withValues(alpha: 0.05),
      ),
      child: Column(
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
          _buildDetailRow("المحافظة", govName),
          _buildDetailRow("اللواء", districtName),
          _buildDetailRow("المنطقة / الحي", areaName),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
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

  // ----------------- Build -----------------

  @override
  Widget build(BuildContext context) {
    final LatLng center = _selectedLatLng ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "تحديد الموقع على الخريطة",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        systemOverlayStyle: AppSystemUi.green,
      ),
      body: Column(
        children: [
          // الخريطة + شريط البحث فوقها
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: _defaultZoom,
                    maxZoom: 18,
                    minZoom: 6,
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
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: _searchBarTopPadding,
                  left: _searchBarHorizontalPadding,
                  right: _searchBarHorizontalPadding,
                  child: _buildSearchField(),
                ),
                Positioned(
                  top: _searchBarTopPadding + 62,
                  left: _searchBarHorizontalPadding,
                  right: _searchBarHorizontalPadding,
                  child: _buildSearchResultsCard(),
                ),
              ],
            ),
          ),

          // أسفل الخريطة: تفاصيل + أزرار
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLocationInfoSection(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _gettingLocation
                              ? null
                              : _getCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
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
                          onPressed: _selectedLatLng == null
                              ? null
                              : _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
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
          ),
        ],
      ),
    );
  }
}

// ----------------- موديل بسيط لنتائج البحث -----------------

class _PlaceSearchResult {
  final double lat;
  final double lng;
  final String title;
  final String? subtitle;

  _PlaceSearchResult({
    required this.lat,
    required this.lng,
    required this.title,
    this.subtitle,
  });
}
