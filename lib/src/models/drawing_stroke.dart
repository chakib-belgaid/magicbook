import 'package:flutter/material.dart';

import 'drawing_mode.dart';

@immutable
class DrawingStroke {
  const DrawingStroke({
    required this.points,
    required this.color,
    required this.brushSize,
    required this.mode,
    required this.totalSamples,
    required this.correctSamples,
    this.selectedRegionId,
  });

  final List<Offset> points;
  final Color color;
  final double brushSize;
  final DrawingMode mode;
  final int totalSamples;
  final int correctSamples;
  final int? selectedRegionId;

  DrawingStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? brushSize,
    DrawingMode? mode,
    int? totalSamples,
    int? correctSamples,
    int? selectedRegionId,
  }) {
    return DrawingStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      brushSize: brushSize ?? this.brushSize,
      mode: mode ?? this.mode,
      totalSamples: totalSamples ?? this.totalSamples,
      correctSamples: correctSamples ?? this.correctSamples,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
    );
  }
}
