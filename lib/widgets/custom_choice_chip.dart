import 'package:flutter/material.dart';
import 'package:form_order_app/core/theme.dart';

class CustomChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const CustomChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      label: Text(label, style: TextStyle(fontSize: isSelected ? 14 : 12)),
      selected: isSelected,
      checkmarkColor: isSelected ? Colors.white : Colors.black,
      onSelected: onSelected,
    );
  }
}
