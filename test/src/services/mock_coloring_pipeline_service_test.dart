import 'package:flutter_test/flutter_test.dart';
import 'package:magicbook/src/models/complexity_preset.dart';
import 'package:magicbook/src/services/mock_coloring_pipeline_service.dart';

void main() {
  test('mock pipeline returns a complete coloring result', () async {
    final service = MockColoringPipelineService(stageDelay: Duration.zero);
    final progress = <double>[];

    final result = await service.generate(
      inputImagePath: 'demo://gallery/dog',
      preset: ComplexityPreset.simple,
      onProgress: (value, _) => progress.add(value),
    );

    expect(result.title, 'Happy Puppy');
    expect(result.palette, hasLength(8));
    expect(result.regions, isNotEmpty);
    expect(result.regions.every((region) => region.contour.isNotEmpty), isTrue);
    expect(progress.last, 1);
  });
}
