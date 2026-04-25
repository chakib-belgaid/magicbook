import 'package:flutter/material.dart';

@immutable
class PaletteColor {
  const PaletteColor({
    required this.number,
    required this.hex,
    required this.label,
  });

  final int number;
  final String hex;
  final String label;

  Color get color {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }
}
