import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:magicbook/src/models/complexity_preset.dart';
import 'package:magicbook/src/services/local_coloring_pipeline_service.dart';

void main() {
  test('local pipeline segments a real image into palette regions', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'magicbook_pipeline_',
    );
    addTearDown(() => tempDir.delete(recursive: true));

    final image = img.Image(width: 96, height: 72);
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        if (x < 48 && y < 36) {
          image.setPixelRgb(x, y, 245, 210, 92);
        } else if (x >= 48 && y < 36) {
          image.setPixelRgb(x, y, 94, 190, 102);
        } else if (x < 48) {
          image.setPixelRgb(x, y, 104, 190, 236);
        } else {
          image.setPixelRgb(x, y, 130, 84, 220);
        }
      }
    }

    final file = File('${tempDir.path}/simple_blocks.png');
    await file.writeAsBytes(img.encodePng(image));

    final progress = <double>[];
    final result = await const LocalColoringPipelineService().generate(
      inputImagePath: file.path,
      preset: ComplexityPreset.simple,
      onProgress: (value, _) => progress.add(value),
    );

    expect(result.title, 'Simple Blocks');
    expect(result.palette, hasLength(8));
    expect(result.regions.length, greaterThanOrEqualTo(4));
    expect(result.regions.length, lessThanOrEqualTo(30));
    expect(
      result.regions.every((region) => region.contour.length >= 4),
      isTrue,
    );
    expect(result.regions.any((region) => region.isNumberable), isTrue);
    expect(progress, containsAllInOrder([.10, .20, .35, .55, .70, .85, 1]));
  });

  test(
    'local pipeline keeps concave component contours in perimeter order',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'magicbook_pipeline_l_shape_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final image = img.Image(width: 80, height: 80);
      for (var y = 0; y < image.height; y += 1) {
        for (var x = 0; x < image.width; x += 1) {
          final inLShape = x < 24 || y > 56;
          if (inLShape) {
            image.setPixelRgb(x, y, 240, 80, 80);
          } else {
            image.setPixelRgb(x, y, 90, 170, 235);
          }
        }
      }

      final file = File('${tempDir.path}/l_shape.png');
      await file.writeAsBytes(img.encodePng(image));

      final result = await const LocalColoringPipelineService().generate(
        inputImagePath: file.path,
        preset: ComplexityPreset.simple,
        onProgress: (_, _) {},
      );

      expect(result.regions.any((region) => region.contour.length > 4), isTrue);
    },
  );

  test(
    'local pipeline upscales input and preserves black ink overlay',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'magicbook_pipeline_ink_',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final image = img.Image(width: 48, height: 36);
      for (var y = 0; y < image.height; y += 1) {
        for (var x = 0; x < image.width; x += 1) {
          if ((x - 24).abs() <= 1) {
            image.setPixelRgb(x, y, 0, 0, 0);
          } else if (x < 24) {
            image.setPixelRgb(x, y, 245, 110, 110);
          } else {
            image.setPixelRgb(x, y, 110, 170, 245);
          }
        }
      }

      final file = File('${tempDir.path}/ink_line.png');
      await file.writeAsBytes(img.encodePng(image));

      final result = await const LocalColoringPipelineService().generate(
        inputImagePath: file.path,
        preset: ComplexityPreset.simple,
        onProgress: (_, _) {},
      );

      expect(result.canvasWidth, 768);
      expect(result.canvasHeight, 576);
      expect(result.outlinePngBytes, isNotNull);

      final outline = img.decodePng(result.outlinePngBytes!);
      expect(outline, isNotNull);
      expect(outline!.any((pixel) => pixel.a.toInt() > 0), isTrue);
    },
  );
}
