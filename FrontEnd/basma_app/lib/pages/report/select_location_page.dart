import 'package:flutter/material.dart';
import '../../models/location_models.dart';
import '../../services/api_service.dart';
import 'create_report_page.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  // Data
  List<Government> _governments = <Government>[];
  List<District> _districts = <District>[];
  List<Area> _areas = <Area>[];
  List<LocationModel> _locations = <LocationModel>[];

  // Selected
  Government? _selectedGovernment;
  District? _selectedDistrict;
  Area? _selectedArea;
  LocationModel? _selectedLocation;

  // State
  bool _loading = true;
  bool _loadingDistricts = false;
  bool _loadingAreas = false;
  bool _loadingLocations = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _loadGovernments();
  }

  Future<void> _loadGovernments() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final items = await ApiService.governments();
      if (!mounted) return;
      setState(() {
        _governments = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر تحميل المحافظات';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _onSelectGovernment(Government? value) async {
    setState(() {
      _selectedGovernment = value;
      _selectedDistrict = null;
      _selectedArea = null;
      _selectedLocation = null;
      _districts = <District>[];
      _areas = <Area>[];
      _locations = <LocationModel>[];
      _loadingDistricts = true;
      _err = null;
    });
    if (value == null) {
      setState(() => _loadingDistricts = false);
      return;
    }
    try {
      final items = await ApiService.districts(value.id);
      if (!mounted) return;
      setState(() {
        _districts = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر تحميل الألوية/الأقضية';
      });
    } finally {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _onSelectDistrict(District? value) async {
    setState(() {
      _selectedDistrict = value;
      _selectedArea = null;
      _selectedLocation = null;
      _areas = <Area>[];
      _locations = <LocationModel>[];
      _loadingAreas = true;
      _err = null;
    });
    if (value == null) {
      setState(() => _loadingAreas = false);
      return;
    }
    try {
      final items = await ApiService.areas(value.id);
      if (!mounted) return;
      setState(() {
        _areas = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر تحميل المناطق';
      });
    } finally {
      if (mounted) setState(() => _loadingAreas = false);
    }
  }

  Future<void> _onSelectArea(Area? value) async {
    setState(() {
      _selectedArea = value;
      _selectedLocation = null;
      _locations = <LocationModel>[];
      _loadingLocations = true;
      _err = null;
    });
    if (value == null) {
      setState(() => _loadingLocations = false);
      return;
    }
    try {
      final items = await ApiService.locations(value.id);
      if (!mounted) return;
      setState(() {
        _locations = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = 'تعذّر تحميل المواقع';
      });
    } finally {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  void _next() {
    // Allow continue if gov+district+area are selected; location optional here.
    if (_selectedGovernment != null &&
        _selectedDistrict != null &&
        _selectedArea != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateReportPage(
            government: _selectedGovernment!,
            district: _selectedDistrict!,
            area: _selectedArea!,
            // Location can be null; next page will require selection if missing
            location: _selectedLocation,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المحافظة واللواء/القضاء والمنطقة'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار الموقع')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_err != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_err!, style: const TextStyle(color: Colors.red)),
                ),

              // Government
              DropdownButtonFormField<Government>(
                isExpanded: true,
                initialValue: _selectedGovernment,
                items: _governments
                    .map(
                      (g) => DropdownMenuItem(value: g, child: Text(g.nameAr)),
                    )
                    .toList(),
                onChanged: (v) => _onSelectGovernment(v),
                decoration: const InputDecoration(labelText: 'المحافظة'),
              ),
              const SizedBox(height: 8),

              // District
              DropdownButtonFormField<District>(
                isExpanded: true,
                initialValue: _selectedDistrict,
                items: _districts
                    .map(
                      (d) => DropdownMenuItem(value: d, child: Text(d.nameAr)),
                    )
                    .toList(),
                onChanged: (_selectedGovernment == null || _loadingDistricts)
                    ? null
                    : (v) => _onSelectDistrict(v),
                decoration: InputDecoration(
                  labelText: 'اللواء/القضاء',
                  suffixIcon: _loadingDistricts
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),

              // Area
              DropdownButtonFormField<Area>(
                isExpanded: true,
                initialValue: _selectedArea,
                items: _areas
                    .map(
                      (a) => DropdownMenuItem(value: a, child: Text(a.nameAr)),
                    )
                    .toList(),
                onChanged: (_selectedDistrict == null || _loadingAreas)
                    ? null
                    : (v) => _onSelectArea(v),
                decoration: InputDecoration(
                  labelText: 'المنطقة',
                  suffixIcon: _loadingAreas
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),

              // Location (optional here)
              DropdownButtonFormField<LocationModel>(
                isExpanded: true,
                initialValue: _selectedLocation,
                items: _locations
                    .map(
                      (l) => DropdownMenuItem(value: l, child: Text(l.nameAr)),
                    )
                    .toList(),
                onChanged: (_selectedArea == null || _loadingLocations)
                    ? null
                    : (v) => setState(() => _selectedLocation = v),
                decoration: InputDecoration(
                  labelText: 'الموقع (اختياري)',
                  suffixIcon: _loadingLocations
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_selectedGovernment != null &&
                          _selectedDistrict != null &&
                          _selectedArea != null)
                      ? _next
                      : null,
                  child: const Text('التالي'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
