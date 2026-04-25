import 'package:flutter/material.dart';

import 'coloring_result.dart';
import 'complexity_preset.dart';
import 'picked_image.dart';

enum ColoringJobStatus { idle, imageSelected, processing, completed, failed }

@immutable
class ColoringJob {
  const ColoringJob({
    required this.preset,
    required this.progress,
    required this.status,
    this.inputImage,
    this.result,
    this.errorMessage,
  });

  factory ColoringJob.initial() {
    return const ColoringJob(
      preset: ComplexityPreset.simple,
      progress: 0,
      status: ColoringJobStatus.idle,
    );
  }

  final PickedImage? inputImage;
  final ComplexityPreset preset;
  final double progress;
  final ColoringJobStatus status;
  final ColoringResult? result;
  final String? errorMessage;

  String? get inputImagePath => inputImage?.path;

  ColoringJob copyWith({
    PickedImage? inputImage,
    ComplexityPreset? preset,
    double? progress,
    ColoringJobStatus? status,
    ColoringResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ColoringJob(
      inputImage: inputImage ?? this.inputImage,
      preset: preset ?? this.preset,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
