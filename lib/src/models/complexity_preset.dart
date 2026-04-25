enum ComplexityPreset {
  simple(
    label: 'Simple',
    iconLabel: ':)',
    maxSide: 768,
    paletteSize: 8,
    minRegionAreaRatio: 0.003,
    mergeColorThreshold: 22,
    contourEpsilonFactor: 0.015,
    strokeWidth: 3,
    minNumberArea: 800,
    minTextRadius: 14,
    targetRegionRange: '20-30',
  ),
  medium(
    label: 'Medium',
    iconLabel: ':|',
    maxSide: 1024,
    paletteSize: 12,
    minRegionAreaRatio: 0.0015,
    mergeColorThreshold: 15,
    contourEpsilonFactor: 0.008,
    strokeWidth: 2,
    minNumberArea: 600,
    minTextRadius: 10,
    targetRegionRange: '40-70',
  ),
  detailed(
    label: 'Detailed',
    iconLabel: '*',
    maxSide: 1280,
    paletteSize: 18,
    minRegionAreaRatio: 0.0007,
    mergeColorThreshold: 10,
    contourEpsilonFactor: 0.004,
    strokeWidth: 2,
    minNumberArea: 400,
    minTextRadius: 8,
    targetRegionRange: '80-140',
  );

  const ComplexityPreset({
    required this.label,
    required this.iconLabel,
    required this.maxSide,
    required this.paletteSize,
    required this.minRegionAreaRatio,
    required this.mergeColorThreshold,
    required this.contourEpsilonFactor,
    required this.strokeWidth,
    required this.minNumberArea,
    required this.minTextRadius,
    required this.targetRegionRange,
  });

  final String label;
  final String iconLabel;
  final int maxSide;
  final int paletteSize;
  final double minRegionAreaRatio;
  final double mergeColorThreshold;
  final double contourEpsilonFactor;
  final int strokeWidth;
  final int minNumberArea;
  final int minTextRadius;
  final String targetRegionRange;
}
