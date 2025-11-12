  import 'package:flutter/material.dart';

Widget buildDropdownBox<T>({
    required String label,
    required List<T> items,
    required T? selected,
    required void Function(T?) onChanged,
    required String Function(T) getName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButton<T>(
        value: selected,
        hint: Text(label),
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item, child: Text(getName(item))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
