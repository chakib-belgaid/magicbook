import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'coloring_region.dart';
import 'palette_color.dart';

@immutable
class ColoringResult {
  const ColoringResult({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.palette,
    required this.regions,
    required this.coloredRegionIds,
    required this.canvasWidth,
    required this.canvasHeight,
    this.sourceImagePath,
    this.outlinePngBytes,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final List<PaletteColor> palette;
  final List<ColoringRegion> regions;
  final Set<int> coloredRegionIds;
  final int canvasWidth;
  final int canvasHeight;
  final String? sourceImagePath;
  final Uint8List? outlinePngBytes;

  double get aspectRatio => canvasWidth / canvasHeight;

  ColoringResult copyWith({
    String? title,
    List<PaletteColor>? palette,
    List<ColoringRegion>? regions,
    Set<int>? coloredRegionIds,
    int? canvasWidth,
    int? canvasHeight,
    String? sourceImagePath,
    Uint8List? outlinePngBytes,
  }) {
    return ColoringResult(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      palette: palette ?? this.palette,
      regions: regions ?? this.regions,
      coloredRegionIds: coloredRegionIds ?? this.coloredRegionIds,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      sourceImagePath: sourceImagePath ?? this.sourceImagePath,
      outlinePngBytes: outlinePngBytes ?? this.outlinePngBytes,
    );
  }
}
