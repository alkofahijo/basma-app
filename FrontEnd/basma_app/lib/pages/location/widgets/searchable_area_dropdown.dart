import 'package:basma_app/models/location_models.dart';
import 'package:flutter/material.dart';

class SearchableAreaDropdown extends StatefulWidget {
  final List<Area> areas;
  final Area? selected;
  final ValueChanged<Area?> onChanged;
  final VoidCallback onAddNew;

  const SearchableAreaDropdown({
    super.key,
    required this.areas,
    required this.selected,
    required this.onChanged,
    required this.onAddNew,
  });

  @override
  State<SearchableAreaDropdown> createState() => _SearchableAreaDropdownState();
}

class _SearchableAreaDropdownState extends State<SearchableAreaDropdown> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Area> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = widget.areas;
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final query = _searchCtrl.text.trim();

    setState(() {
      filtered = widget.areas.where((a) => a.nameAr.contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notFound = _searchCtrl.text.isNotEmpty && filtered.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("المنطقة:", style: TextStyle(fontSize: 16)),

        const SizedBox(height: 6),

        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'ابحث عن المنطقة...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 10),

        if (notFound)
          TextButton.icon(
            onPressed: widget.onAddNew,
            icon: const Icon(Icons.add),
            label: Text("إضافة منطقة جديدة: ${_searchCtrl.text}"),
          ),

        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final a = filtered[i];
              return ListTile(
                title: Text(a.nameAr),
                trailing: widget.selected?.id == a.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => widget.onChanged(a),
              );
            },
          ),
        ),
      ],
    );
  }
}
