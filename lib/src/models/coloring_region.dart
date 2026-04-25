import 'package:flutter/material.dart';

@immutable
class ColoringRegion {
  const ColoringRegion({
    required this.id,
    required this.paletteNumber,
    required this.area,
    required this.contour,
    required this.numberPosition,
    required this.isNumberable,
  });

  final int id;
  final int paletteNumber;
  final int area;
  final List<Offset> contour;
  final Offset numberPosition;
  final bool isNumberable;
}
