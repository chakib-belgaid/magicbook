import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/coloring_region.dart';
import '../models/coloring_result.dart';
import '../models/complexity_preset.dart';
import '../models/palette_color.dart';
import 'coloring_pipeline_service.dart';

class MockColoringPipelineService implements ColoringPipelineService {
  const MockColoringPipelineService({
    this.stageDelay = const Duration(milliseconds: 260),
  });

  final Duration stageDelay;

  @override
  Future<ColoringResult> generate({
    required String inputImagePath,
    Uint8List? inputImageBytes,
    String? inputImageName,
    required ComplexityPreset preset,
    required PipelineProgressCallback onProgress,
  }) async {
    const stages = <(double, String)>[
      (0.10, 'Loading image'),
      (0.20, 'Preprocessing'),
      (0.35, 'Reducing colors'),
      (0.55, 'Finding regions'),
      (0.70, 'Cleaning regions'),
      (0.85, 'Drawing coloring page'),
      (1.00, 'Done'),
    ];

    for (final stage in stages) {
      await Future<void>.delayed(stageDelay);
      onProgress(stage.$1, stage.$2);
    }

    final now = DateTime.now();
    return ColoringResult(
      id: 'mock-${now.microsecondsSinceEpoch}',
      title: 'Happy Puppy',
      createdAt: now,
      sourceImagePath: inputImagePath,
      palette: _paletteForPreset(preset),
      regions: _regionsForPreset(preset),
      coloredRegionIds: const <int>{},
      canvasWidth: 920,
      canvasHeight: 1000,
    );
  }

  List<PaletteColor> _paletteForPreset(ComplexityPreset preset) {
    const base = <PaletteColor>[
      PaletteColor(number: 1, hex: '#FFD980', label: 'Cream'),
      PaletteColor(number: 2, hex: '#FF9F1C', label: 'Honey'),
      PaletteColor(number: 3, hex: '#FF7B9C', label: 'Pink'),
      PaletteColor(number: 4, hex: '#F7B538', label: 'Gold'),
      PaletteColor(number: 5, hex: '#6AC46A', label: 'Leaf'),
      PaletteColor(number: 6, hex: '#3B8C3A', label: 'Grass'),
      PaletteColor(number: 7, hex: '#8A5A2B', label: 'Brown'),
      PaletteColor(number: 8, hex: '#B8DDF6', label: 'Sky'),
      PaletteColor(number: 9, hex: '#FFFFFF', label: 'White'),
      PaletteColor(number: 10, hex: '#1C163A', label: 'Ink'),
      PaletteColor(number: 11, hex: '#F66F52', label: 'Coral'),
      PaletteColor(number: 12, hex: '#AEE34B', label: 'Lime'),
    ];
    return base.take(preset.paletteSize.clamp(6, base.length)).toList();
  }

  List<ColoringRegion> _regionsForPreset(ComplexityPreset preset) {
    final regions = <ColoringRegion>[
      _region(1, 8, 46000, const [
        Offset(0, 0),
        Offset(1, 0),
        Offset(1, .45),
        Offset(0, .5),
      ], const Offset(.16, .18)),
      _region(2, 5, 38000, const [
        Offset(0, .45),
        Offset(.42, .36),
        Offset(.52, .75),
        Offset(0, 1),
      ], const Offset(.22, .68)),
      _region(3, 6, 32000, const [
        Offset(.52, .38),
        Offset(1, .42),
        Offset(1, 1),
        Offset(.48, .82),
      ], const Offset(.79, .67)),
      _region(4, 1, 52000, const [
        Offset(.35, .18),
        Offset(.68, .16),
        Offset(.75, .58),
        Offset(.44, .72),
        Offset(.28, .44),
      ], const Offset(.52, .43)),
      _region(5, 2, 26000, const [
        Offset(.28, .22),
        Offset(.44, .18),
        Offset(.38, .46),
        Offset(.24, .5),
      ], const Offset(.34, .32)),
      _region(6, 2, 24000, const [
        Offset(.65, .18),
        Offset(.80, .28),
        Offset(.75, .52),
        Offset(.62, .46),
      ], const Offset(.71, .33)),
      _region(7, 9, 21000, const [
        Offset(.43, .56),
        Offset(.56, .54),
        Offset(.55, .86),
        Offset(.39, .86),
      ], const Offset(.48, .72)),
      _region(8, 4, 18000, const [
        Offset(.28, .70),
        Offset(.44, .72),
        Offset(.45, .98),
        Offset(.26, .96),
      ], const Offset(.35, .84)),
      _region(9, 4, 17000, const [
        Offset(.58, .68),
        Offset(.75, .68),
        Offset(.78, .96),
        Offset(.57, .98),
      ], const Offset(.67, .84)),
      _region(10, 7, 9000, const [
        Offset(.45, .36),
        Offset(.56, .35),
        Offset(.58, .44),
        Offset(.48, .46),
      ], const Offset(.52, .40)),
    ];

    if (preset == ComplexityPreset.simple) {
      return regions.take(8).toList();
    }

    if (preset == ComplexityPreset.medium) {
      return regions;
    }

    return [
      ...regions,
      _region(11, 3, 3600, const [
        Offset(.12, .72),
        Offset(.18, .72),
        Offset(.20, .79),
        Offset(.14, .82),
      ], const Offset(.16, .77)),
      _region(12, 11, 3300, const [
        Offset(.82, .74),
        Offset(.88, .73),
        Offset(.90, .81),
        Offset(.84, .84),
      ], const Offset(.86, .78)),
    ];
  }

  ColoringRegion _region(
    int id,
    int paletteNumber,
    int area,
    List<Offset> contour,
    Offset numberPosition,
  ) {
    return ColoringRegion(
      id: id,
      paletteNumber: paletteNumber,
      area: area,
      contour: contour,
      numberPosition: numberPosition,
      isNumberable: area >= 3000,
    );
  }
}
