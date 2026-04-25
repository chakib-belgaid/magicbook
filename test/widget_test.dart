import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:magicbook/src/models/coloring_result.dart';
import 'package:magicbook/src/models/drawing_mode.dart';
import 'package:magicbook/src/models/picked_image.dart';
import 'package:magicbook/src/screens/home_shell.dart';
import 'package:magicbook/src/services/export_service.dart';
import 'package:magicbook/src/services/gallery_storage_service.dart';
import 'package:magicbook/src/services/image_pick_service.dart';
import 'package:magicbook/src/services/mock_coloring_pipeline_service.dart';
import 'package:magicbook/src/state/magic_book_controller.dart';
import 'package:magicbook/src/state/magic_book_scope.dart';
import 'package:magicbook/src/theme/magic_book_theme.dart';

void main() {
  testWidgets('app launches to the Create screen', (tester) async {
    await _pumpTestApp(tester);

    expect(find.text('Create'), findsWidgets);
    expect(find.text('1. Upload a picture'), findsOneWidget);
    expect(find.text('2. Choose complexity'), findsOneWidget);
    expect(find.byTooltip('Premium'), findsNothing);
  });

  testWidgets('complexity picker changes selected preset', (tester) async {
    final controller = _controller(stageDelay: const Duration(seconds: 1));
    await _pumpTestApp(tester, controller: controller);

    await tester.tap(find.text('Detailed'));
    await tester.pump();

    expect(controller.job.preset.label, 'Detailed');
    expect(controller.job.preset.paletteSize, 18);
  });

  testWidgets('picked gallery image is rendered in upload preview', (
    tester,
  ) async {
    String? tempPath;
    final pickedImage = await tester.runAsync(() async {
      final tempDir = await Directory.systemTemp.createTemp(
        'magicbook_upload_preview_',
      );
      tempPath = tempDir.path;

      final previewImage = img.Image(width: 10, height: 10);
      for (var y = 0; y < previewImage.height; y += 1) {
        for (var x = 0; x < previewImage.width; x += 1) {
          previewImage.setPixelRgb(x, y, 120, 84, 245);
        }
      }
      final file = File('${tempDir.path}/picked.png');
      await file.writeAsBytes(img.encodePng(previewImage));
      return PickedImage(
        path: file.path,
        name: 'picked.png',
        bytes: await file.readAsBytes(),
      );
    });
    addTearDown(() {
      final path = tempPath;
      if (path != null) {
        Directory(path).deleteSync(recursive: true);
      }
    });

    final controller = _controller(
      imagePickService: _StaticImagePickService(pickedImage!),
    );
    await _pumpTestApp(tester, controller: controller);

    await tester.tap(find.byKey(const ValueKey('choosePhotoButton')));
    await tester.pump();

    expect(controller.job.inputImagePath, pickedImage.path);
    expect(find.byKey(const ValueKey('selectedPhotoPreview')), findsOneWidget);
    expect(find.text('Photo added'), findsOneWidget);
  });

  testWidgets('starting generation navigates through Processing to Ready', (
    tester,
  ) async {
    final controller = _controller(
      stageDelay: const Duration(milliseconds: 100),
    );
    await _pumpTestApp(tester, controller: controller);

    await tester.ensureVisible(
      find.byKey(const ValueKey('useDemoPhotoButton')),
    );
    await tester.tap(find.byKey(const ValueKey('useDemoPhotoButton')));
    await tester.pump();
    expect(controller.canCreate, isTrue);
    await tester.ensureVisible(
      find.byKey(const ValueKey('createColoringButton')),
    );
    await tester.tap(find.byKey(const ValueKey('createColoringButton')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Creating...', skipOffstage: false), findsOneWidget);
    expect(
      find.byKey(const ValueKey('loadingMascotAsset'), skipOffstage: false),
      findsWidgets,
    );

    await tester.pumpAndSettle();

    expect(find.text('Your Coloring is Ready!'), findsOneWidget);
    expect(find.text('Draw Now'), findsOneWidget);
  });

  testWidgets('palette legend renders expected numbered colors', (
    tester,
  ) async {
    await _pumpTestApp(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('useDemoPhotoButton')),
    );
    await tester.tap(find.byKey(const ValueKey('useDemoPhotoButton')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('createColoringButton')),
    );
    await tester.tap(find.byKey(const ValueKey('createColoringButton')));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Cream'), findsOneWidget);
    expect(find.text('Honey'), findsOneWidget);
  });

  testWidgets('drawing screen shows modes, score, swatches, and tools', (
    tester,
  ) async {
    await _pumpReadyApp(tester);

    await tester.tap(find.text('Draw Now'));
    await tester.pumpAndSettle();

    expect(find.text('Draw'), findsOneWidget);
    expect(find.byKey(const ValueKey('drawingModeSelector')), findsOneWidget);
    expect(find.byKey(const ValueKey('drawingScoreChip')), findsOneWidget);
    expect(find.byKey(const ValueKey('drawingSwatchTray')), findsOneWidget);
    expect(find.text('Right color'), findsOneWidget);
    expect(find.text('Zone color'), findsOneWidget);
    expect(find.text('Free draw'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  test(
    'drawing accuracy follows right-color, zone, and free-draw rules',
    () async {
      final controller = _controller(stageDelay: Duration.zero);
      controller.useDemoPhoto();
      await controller.createColoring();

      controller.beginDrawing(const Offset(.52, .50));
      controller.updateDrawing(const Offset(.22, .68));
      controller.endDrawing();

      expect(controller.drawingMode, DrawingMode.rightColor);
      expect(controller.drawingCorrectSamples, 1);
      expect(controller.drawingTotalSamples, 2);
      expect(controller.drawingScorePercent, 50);
      expect(controller.drawingStrokes.single.points.length, 1);

      controller.undoDrawingStroke();
      expect(controller.drawingTotalSamples, 0);

      controller.setDrawingMode(DrawingMode.zoneColor);
      controller.beginDrawing(const Offset(.22, .68));
      controller.updateDrawing(const Offset(.79, .67));
      controller.endDrawing();

      expect(controller.selectedDrawingRegionId, 2);
      expect(controller.drawingCorrectSamples, 1);
      expect(controller.drawingTotalSamples, 2);
      expect(controller.drawingScorePercent, 50);

      controller.resetDrawing();
      controller.setDrawingMode(DrawingMode.freeDraw);
      controller.selectPaletteNumber(5);
      controller.beginDrawing(const Offset(.22, .68));
      controller.updateDrawing(const Offset(.52, .50));
      controller.endDrawing();

      expect(controller.drawingCorrectSamples, 1);
      expect(controller.drawingTotalSamples, 2);
      expect(controller.drawingScorePercent, 50);

      controller.resetDrawing();
      expect(controller.drawingScorePercent, 100);
      expect(controller.drawingStrokes, isEmpty);
    },
  );

  testWidgets(
    'bottom navigation switches between Create, Gallery, and My Works',
    (tester) async {
      await _pumpTestApp(tester);

      await tester.tap(find.byIcon(Icons.image_outlined));
      await tester.pump();
      expect(find.text('Your gallery is waiting'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();
      expect(find.text('Saved favorites will live here.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pump();
      expect(find.text('1. Upload a picture'), findsOneWidget);
    },
  );
}

Future<void> _pumpTestApp(
  WidgetTester tester, {
  MagicBookController? controller,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 980));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_testApp(controller: controller));
}

Future<void> _pumpReadyApp(WidgetTester tester) async {
  final controller = _controller(stageDelay: Duration.zero);
  await _pumpTestApp(tester, controller: controller);
  await tester.ensureVisible(find.byKey(const ValueKey('useDemoPhotoButton')));
  await tester.tap(find.byKey(const ValueKey('useDemoPhotoButton')));
  await tester.pump();
  await tester.ensureVisible(
    find.byKey(const ValueKey('createColoringButton')),
  );
  await tester.tap(find.byKey(const ValueKey('createColoringButton')));
  await tester.pumpAndSettle();
}

Widget _testApp({MagicBookController? controller}) {
  return MagicBookScope(
    controller: controller ?? _controller(),
    child: MaterialApp(theme: MagicBookTheme.light(), home: const HomeShell()),
  );
}

MagicBookController _controller({
  Duration stageDelay = const Duration(milliseconds: 10),
  ImagePickService? imagePickService,
}) {
  return MagicBookController(
    imagePickService: imagePickService ?? DemoImagePickService(),
    pipelineService: MockColoringPipelineService(stageDelay: stageDelay),
    galleryStorageService: InMemoryGalleryStorageService(),
    exportService: _FakeExportService(),
  );
}

class _StaticImagePickService implements ImagePickService {
  const _StaticImagePickService(this.image);

  final PickedImage image;

  @override
  Future<PickedImage?> pickFromCamera() async => image;

  @override
  Future<PickedImage?> pickFromGallery() async => image;
}

class _FakeExportService implements ExportService {
  @override
  Future<void> print(ColoringResult result) async {}

  @override
  Future<void> saveToGallery(ColoringResult result) async {}

  @override
  Future<void> share(ColoringResult result) async {}
}
