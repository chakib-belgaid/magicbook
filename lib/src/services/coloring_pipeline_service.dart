import 'dart:typed_data';

import '../models/coloring_result.dart';
import '../models/complexity_preset.dart';

typedef PipelineProgressCallback =
    void Function(double progress, String stageLabel);

abstract class ColoringPipelineService {
  Future<ColoringResult> generate({
    required String inputImagePath,
    Uint8List? inputImageBytes,
    String? inputImageName,
    required ComplexityPreset preset,
    required PipelineProgressCallback onProgress,
  });
}

class OpenCvColoringPipelineService implements ColoringPipelineService {
  @override
  Future<ColoringResult> generate({
    required String inputImagePath,
    Uint8List? inputImageBytes,
    String? inputImageName,
    required ComplexityPreset preset,
    required PipelineProgressCallback onProgress,
  }) {
    throw UnimplementedError(
      'OpenCV bridge pending. Implement resize, bilateral filtering, Lab '
      'k-means, connected components, region merging, contour tracing, and '
      'distance-transform number placement behind this interface.',
    );
  }
}
