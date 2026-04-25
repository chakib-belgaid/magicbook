import 'package:flutter_test/flutter_test.dart';
import 'package:magicbook/src/models/complexity_preset.dart';

void main() {
  test('complexity presets match the pipeline spec defaults', () {
    expect(ComplexityPreset.simple.maxSide, 768);
    expect(ComplexityPreset.simple.paletteSize, 8);
    expect(ComplexityPreset.simple.minRegionAreaRatio, 0.003);

    expect(ComplexityPreset.medium.maxSide, 1024);
    expect(ComplexityPreset.medium.paletteSize, 12);
    expect(ComplexityPreset.medium.mergeColorThreshold, 15);

    expect(ComplexityPreset.detailed.maxSide, 1280);
    expect(ComplexityPreset.detailed.paletteSize, 18);
    expect(ComplexityPreset.detailed.minTextRadius, 8);
  });
}
